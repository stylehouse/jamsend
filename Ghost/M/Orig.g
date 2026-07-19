// Orig.g — the %Original / grade-dispatch layer (Radio_spec §2.4).  Ra.g owns the streaming pipeline
//  (raw length-prefixed opus packets, container DELETED from the wire); THIS ghost is where a real
//   RFC-7845 Ogg/Opus container gets written BACK — for EXPORT only, never onto the chunk format.
//    Androids play `.ogg` more happily than `.opus`, so a phone-sync ships a real Ogg file.
//  TONIGHT: only the ogg128 export (Orig_ogg_export) + its structural reader (Orig_ogg_parse).  The
//   full %Original master (rung 3 — the flac source that encodes DOWN to any grade) is later work; the
//    export homes its %Blob,grade:ogg128 beside the %Record it read (r3 re-homes into the shop).
//  THE MUX IS FLAT RAW JS (owner's law: closure-heavy .g parse-storms the compiler) — plain loops,
//   Uint8Array + DataView, one CRC table computed per call (a one-shot export pays no cost that matters).

// ── the packet source ─────────────────────────────────────────────────────────────────────────────
// Orig_rec_packets — collect a Record's opus packets IN SEQ ORDER across %Preview|%Stream (one seq
//  space, the transport slices of ONE encode per side).  Reads every chunk's buf back through
//   Ra_chunk_packets (the read twin of the packing) and concatenates — the same order the far decoder
//    plays.  A gap (a seq with no buf) stops the collection: an ogg128 export needs the WHOLE track, so
//     a hole is a caller error (drive the transcode to the end first), reported as {gap:seq}.
Orig_rec_packets(rec):
    let total = +(rec.sc.total || 0)
    let map = this.Ra_chunk_map(rec)
    let packets = []
    let s = 0
    while (s < total) {
        let buf = map[s]
        if (buf == null) return { gap: s, packets: packets }
        for (const p of this.Ra_chunk_packets(buf)) packets.push(p)
        s = s + 1
    }
    return { packets: packets }

// ── the Ogg CRC (RFC 3533 §6): poly 0x04C11DB7, NO reflection, init 0, no final xor ────────────────
// Orig_crc_table — the 256-entry lookup, MSB-first (no input|output reflection — Ogg's is the unusual
//  un-reflected CRC-32).  Recomputed per export; a one-shot pays nothing.
Orig_crc_table():
    let table = new Uint32Array(256)
    let i = 0
    while (i < 256) {
        let r = (i << 24) >>> 0
        let k = 0
        while (k < 8) {
            if (r & 0x80000000) {
                r = (((r << 1) >>> 0) ^ 0x04C11DB7) >>> 0
            } else {
                r = (r << 1) >>> 0
            }
            k = k + 1
        }
        table[i] = r >>> 0
        i = i + 1
    }
    return table

// Orig_crc — CRC-32 over a whole page (the crc field already zeroed by the caller).  MSB-first: the
//  running value's top byte XORs the next byte to index the table.
Orig_crc(bytes, table):
    let crc = 0
    let i = 0
    while (i < bytes.length) {
        let idx = (((crc >>> 24) ^ bytes[i]) & 0xff) >>> 0
        crc = (((crc << 8) >>> 0) ^ table[idx]) >>> 0
        i = i + 1
    }
    return crc >>> 0

// ── the page writer ───────────────────────────────────────────────────────────────────────────────
// Orig_ogg_page — one Ogg page: header + lacing + body, CRC computed over the whole page with the crc
//  field zeroed, then written back in.  `packets` is an array of Uint8Array (one page carries a batch);
//   each packet's length lands as 255-runs of lacing (a packet of exactly n*255 needs a trailing 0
//    lacing so a reader knows the packet ENDED — else it reads on into the next).  header_type: 0x02
//     BOS on the first page, 0x04 EOS on the last, 0 otherwise.  granule = cumulative 48k samples
//      COMPLETED through this page (including preskip); serial fixed; page_seq monotone.
Orig_ogg_page(packets, htype, granule, serial, pageno, table):
    // lacing: each packet contributes floor(len/255) 0xff bytes then len%255 (a 0 when len is a 255
    //  multiple — the explicit "packet ended here" mark).  segs caps at 255 per page; the caller batches
    //   well under that, so no packet spans pages here (the export never needs page-continuation).
    let lacing = []
    let body_len = 0
    for (const p of packets) {
        let n = p.length
        while (n >= 255) {
            lacing.push(255)
            n = n - 255
        }
        lacing.push(n)
        body_len = body_len + p.length
    }
    let nsegs = lacing.length
    let head_len = 27 + nsegs
    let page = new Uint8Array(head_len + body_len)
    let dv = new DataView(page.buffer)
    // capture pattern "OggS"
    page[0] = 0x4f
    page[1] = 0x67
    page[2] = 0x67
    page[3] = 0x53
    page[4] = 0                     // stream structure version 0
    page[5] = htype & 0xff          // header_type flags
    // granule position u64 LE — split into two u32 halves (granule stays well under 2^53 for any track).
    let glo = granule >>> 0
    let ghi = Math.floor(granule / 4294967296) >>> 0
    dv.setUint32(6, glo, true)
    dv.setUint32(10, ghi, true)
    dv.setUint32(14, serial >>> 0, true)     // bitstream serial number
    dv.setUint32(18, pageno >>> 0, true)     // page sequence number
    dv.setUint32(22, 0, true)                // CRC checksum — zeroed for the compute pass
    page[26] = nsegs & 0xff                  // number of segments
    let o = 27
    let li = 0
    while (li < nsegs) {
        page[o] = lacing[li] & 0xff
        o = o + 1
        li = li + 1
    }
    // the body: packets back to back after the segment table.
    for (const p of packets) {
        page.set(p, o)
        o = o + p.length
    }
    let crc = this.Orig_crc(page, table)
    dv.setUint32(22, crc >>> 0, true)
    return page

// Orig_opus_head — the OpusHead identification header (RFC 7845 §5.1), its own BOS page body.  magic
//  "OpusHead" + version 1 + channel count + preskip u16 LE + input sample rate u32 LE (the ORIGINAL
//   rate; 48000 here) + output gain i16 LE (0 — the loudness is already baked into the PCM) + channel
//    mapping family 0 (mono|stereo, no mapping table).
Orig_opus_head(nch, preskip, rate):
    let b = new Uint8Array(19)
    let dv = new DataView(b.buffer)
    b[0] = 0x4f   // O
    b[1] = 0x70   // p
    b[2] = 0x75   // u
    b[3] = 0x73   // s
    b[4] = 0x48   // H
    b[5] = 0x65   // e
    b[6] = 0x61   // a
    b[7] = 0x64   // d
    b[8] = 1                        // version
    b[9] = nch & 0xff               // channel count
    dv.setUint16(10, preskip & 0xffff, true)   // pre-skip
    dv.setUint32(12, rate >>> 0, true)         // input sample rate (informational)
    dv.setInt16(16, 0, true)                   // output gain Q7.8 dB (0)
    b[18] = 0                       // mapping family 0
    return b

// Orig_str_bytes — UTF-8 bytes of a string (TextEncoder is ambient in the runner).
Orig_str_bytes(s):
    return new TextEncoder().encode('' + (s == null ? '' : s))

// Orig_opus_tags — the OpusTags comment header (RFC 7845 §5.2), its own page body.  magic "OpusTags" +
//  vendor string (u32 LE len + bytes) + comment count u32 LE + each comment (u32 LE len + "KEY=value"
//   bytes).  Only the tags the record actually carries are stamped (guard every maybe-undefined
//    scalar — an undefined TITLE would write "TITLE=undefined").  Built into a growable array then
//     flattened, so the length math can't drift from the bytes.
Orig_opus_tags(rec, vendor):
    let magic = [0x4f, 0x70, 0x75, 0x73, 0x54, 0x61, 0x67, 0x73]   // "OpusTags"
    let comments = []
    if (rec.sc.title) comments.push('TITLE=' + rec.sc.title)
    if (rec.sc.artist) comments.push('ARTIST=' + rec.sc.artist)
    if (rec.sc.album) comments.push('ALBUM=' + rec.sc.album)
    let vb = this.Orig_str_bytes(vendor)
    // total length: magic + (4 + vendor) + 4 + sum(4 + comment)
    let total = magic.length + 4 + vb.length + 4
    let cbs = []
    for (const c of comments) {
        let cb = this.Orig_str_bytes(c)
        cbs.push(cb)
        total = total + 4 + cb.length
    }
    let b = new Uint8Array(total)
    let dv = new DataView(b.buffer)
    let o = 0
    let mi = 0
    while (mi < magic.length) {
        b[o] = magic[mi]
        o = o + 1
        mi = mi + 1
    }
    dv.setUint32(o, vb.length >>> 0, true)
    o = o + 4
    b.set(vb, o)
    o = o + vb.length
    dv.setUint32(o, cbs.length >>> 0, true)
    o = o + 4
    for (const cb of cbs) {
        dv.setUint32(o, cb.length >>> 0, true)
        o = o + 4
        b.set(cb, o)
        o = o + cb.length
    }
    return b

// ── the mux ───────────────────────────────────────────────────────────────────────────────────────
// Orig_ogg_mux — turn a run of raw opus packets + head facts into a complete Ogg/Opus byte stream.
//  Page 0 = OpusHead ALONE (BOS, granule 0), page 1 = OpusTags ALONE (granule 0), then audio pages
//   batching ~50 packets each.  A page's granule = cumulative 48k samples of every packet COMPLETED
//    through it INCLUDING preskip (Ra_opus_samples per packet), so a player's duration reads
//     (final_granule − preskip)/48000.  The FINAL audio page carries the EOS flag.  Serial fixed at 1.
Orig_ogg_mux(packets, nch, preskip, rate, tags_bytes):
    let table = this.Orig_crc_table()
    let serial = 1
    let pages = []
    let pageno = 0
    // page 0 — OpusHead, BOS, granule 0
    pages.push(this.Orig_ogg_page([this.Orig_opus_head(nch, preskip, rate)], 0x02, 0, serial, pageno, table))
    pageno = pageno + 1
    // page 1 — OpusTags, granule 0
    pages.push(this.Orig_ogg_page([tags_bytes], 0x00, 0, serial, pageno, table))
    pageno = pageno + 1
    // audio pages — batch ~50 packets (well under the 255-segment cap and a comfy page size); the
    //  granule advances by every packet's 48k sample count, preskip added in from the very first sample.
    let BATCH = 50
    let granule = preskip
    let i = 0
    let N = packets.length
    while (i < N) {
        let batch = []
        let j = i
        while (j < N && batch.length < BATCH) {
            batch.push(packets[j])
            granule = granule + this.Ra_opus_samples(packets[j])
            j = j + 1
        }
        let last = j >= N
        let htype = last ? 0x04 : 0x00
        pages.push(this.Orig_ogg_page(batch, htype, granule, serial, pageno, table))
        pageno = pageno + 1
        i = j
    }
    // flatten the pages into ONE byte array.
    let total = 0
    for (const pg of pages) total = total + pg.length
    let out = new Uint8Array(total)
    let o = 0
    for (const pg of pages) {
        out.set(pg, o)
        o = o + pg.length
    }
    return out

// ── the export verb ───────────────────────────────────────────────────────────────────────────────
// Orig_ogg_export — the whole export for ONE Record: collect its packets, mux to Ogg/Opus, write the
//  file to (dir,name) via nav.bin_write, and mint the %Blob,id:<rec id>,grade:ogg128 beside the Record
//   carrying sc.path (NEVER the bytes — the file IS the artifact; a giant scalar snaps as a smell and is
//    fatal at the storage encoder).  As-built home = under the Record's container (rec.c.up, the shop
//     library); rung 3 re-homes into the shop proper.  Returns { blob, path, bytes, pages, seconds } or
//      { gap:seq } when the track isn't whole yet (drive the transcode to the end first).
async Orig_ogg_export(w, nav, rec, dir, name):
    let got = this.Orig_rec_packets(rec)
    if (got.gap != null) return { gap: got.gap }
    if (!got.packets.length) return { gap: 0 }
    let nch = +(rec.sc.nch || 1)
    let preskip = this.Orig_export_preskip(rec)
    let rate = +(rec.sc.sr || 48000)
    let tags = this.Orig_opus_tags(rec, 'jamsend Orig ogg128')
    let bytes = this.Orig_ogg_mux(got.packets, nch, preskip, rate, tags)
    await nav.bin_write(dir, name, bytes)
    // the %Blob home beside the Record — id joins to the Record (identity-per-shelf: a Blob wears its OWN
    //  mainkey and carries the id, never a second %Record).  path is the one real file on the nav; guard
    //   it (only stamp what we wrote).  The bytes never ride sc.
    let home = rec.c.up || w
    let blob = home.oai({ Blob: 1, id: rec.sc.id, grade: 'ogg128' })
    blob.c.up = home
    // device-local furniture: the home is now the Mag PAGE (rec.c.up), and pages cross the wire
    //  whole in a Mag fragment — the export path is this machine's business, never a friend's.
    blob.c.repli_skip = 1
    let path = dir + '/' + name
    if (path) blob.sc.path = path
    // the byte SIZE is non-reproducible (the opus encode differs run-to-run), so it rides .c for a live
    //  eye — never sc (a drifting scalar breaks a snap fixture; the path is the durable identity).
    if (bytes && bytes.length) blob.c.size = bytes.length
    blob.bump()
    // pages count: 2 header pages + ceil(packets/50) audio pages — a stable structural fact.
    let apages = Math.ceil(got.packets.length / 50)
    return { blob: blob, path: path, bytes: bytes, pages: 2 + apages, packets: got.packets.length }

// Orig_export_preskip — the preskip to bake into the exported OpusHead.  The chunk-particle model
//  carries preskip on each HEAD chunk (%Preview,seq:0 and the boundary %Stream head — TWO encodes, one
//   number, same config).  The head chunk's preskip IS the encoder's convergence pad the container drops
//    at the start; read it off seq 0's head, falling back to the record card default (312).
Orig_export_preskip(rec):
    let head0 = rec.o({ seq: '0' })[0]
    if (head0 && head0.sc.preskip != null && head0.sc.preskip !== '') return +head0.sc.preskip
    if (rec.sc.preskip != null && rec.sc.preskip !== '') return +rec.sc.preskip
    return 312

// ── the structural reader (the Book's gate re-reads the written file with this) ─────────────────────
// Orig_ogg_parse — walk a byte stream page by page: every page's stored CRC must match a recompute over
//  the page with its crc field zeroed (crc_ok false the moment one fails).  Lifts the OpusHead facts
//   (preskip/rate/nch) off the FIRST page's body and returns the LAST page's granule.  A structural
//    reader, NOT a decoder — it proves the container is well-formed and self-consistent, which is exactly
//     the ogg128 promise (a real Ogg file an Android player accepts).  Returns
//      { pages, crc_ok, preskip, rate, nch, granule, eos, channels }.
Orig_ogg_parse(bytes):
    let b = (bytes instanceof Uint8Array) ? bytes : new Uint8Array(bytes)
    let dv = new DataView(b.buffer, b.byteOffset, b.byteLength)
    let table = this.Orig_crc_table()
    let o = 0
    let pages = 0
    let crc_ok = 1
    let preskip = 0
    let rate = 0
    let nch = 0
    let granule = 0
    let eos = 0
    let first = 1
    while (o + 27 <= b.length) {
        // capture pattern
        if (!(b[o] === 0x4f && b[o + 1] === 0x67 && b[o + 2] === 0x67 && b[o + 3] === 0x53)) {
            crc_ok = 0
            break
        }
        let htype = b[o + 5]
        let glo = dv.getUint32(o + 6, true)
        let ghi = dv.getUint32(o + 10, true)
        let stored = dv.getUint32(o + 22, true)
        let nsegs = b[o + 26]
        if (o + 27 + nsegs > b.length) {
            crc_ok = 0
            break
        }
        let body_len = 0
        let si = 0
        while (si < nsegs) {
            body_len = body_len + b[o + 27 + si]
            si = si + 1
        }
        let page_len = 27 + nsegs + body_len
        if (o + page_len > b.length) {
            crc_ok = 0
            break
        }
        // recompute the CRC over a COPY of the page with the crc field zeroed.
        let page = b.subarray(o, o + page_len)
        let copy = new Uint8Array(page_len)
        copy.set(page)
        let cdv = new DataView(copy.buffer)
        cdv.setUint32(22, 0, true)
        let got = this.Orig_crc(copy, table)
        if ((got >>> 0) !== (stored >>> 0)) crc_ok = 0
        // OpusHead facts off the very first page's body.
        if (first) {
            let bo = o + 27 + nsegs
            if (b[bo] === 0x4f && b[bo + 1] === 0x70 && b[bo + 2] === 0x75 && b[bo + 3] === 0x73) {
                nch = b[bo + 9]
                preskip = dv.getUint16(bo + 10, true)
                rate = dv.getUint32(bo + 12, true)
            }
            first = 0
        }
        granule = glo + ghi * 4294967296
        if (htype & 0x04) eos = 1
        pages = pages + 1
        o = o + page_len
    }
    return { pages: pages, crc_ok: crc_ok ? 1 : 0, preskip: preskip, rate: rate, nch: nch, granule: granule, eos: eos, channels: nch }

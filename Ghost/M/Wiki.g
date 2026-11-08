// Wiki.g — CELL:WIKIPEDIA's verbs, out of Sounditron (2026-11-09, spec/AtheoryArrive_todo.md §6): /Radio has no Sounditron, so the cell's
//  press, fill and pace live here, renamed Wiki_* (Sounditron_wiki_* → Wiki_*, otherwise verbatim).  Loaded by Ground/Radio's Load: row.
//   On / the Sounditron Book still carries its own copy — that copy goes when / mounts /Radio (§6 (4)).  WikipediaFace asks Wiki_* first,
//    then Sounditron_wiki_*.

// ── CELL:WIKIPEDIA — click for a random page (spec/WikipediaCell_todo.md) ───────────────────────
//  The owner, 2026-09-18/20: a "top-level app personality quirk … an important 'thing on the internet'";
//   then, on where the fetch lives (09-20): the client talks to Wikipedia directly — a public JSON GET
//    needs nothing a tab doesn't have, and the API is CORS-open for exactly this.  No daemon, no route.
//  THE SHAPE.  `%Wikipedia,face:Wikipedia,dontSnap` is the anchor (one per glass, minted at commission).
//   Under it, `%Page,title,url[,extract,thumb]` rows — the QUEUE.  The one wearing `shown` is on the
//    card; the rest are fetched AHEAD so a press is a swap, not a wait ("a queue of these … run users
//     through them").  `Wiki_roll` is the only press: it retires the shown page, promotes the
//      next, and tops the queue back up.  Everything is a particle, so minisnap 'mundo>…>Wikipedia'
//       reads the queue and the face reads it off H.version like every other organ.
//  WHY dontSnap.  The rows are third-party content that changes every press; without the fold every
//   Sounditron fixture would churn on the wire's mood.  The anchor line still snaps (the cell exists).
Wiki_ensure(w):
    let wiki = w.o({ Wikipedia: 1 })[0]
    if (!wiki) {
        wiki = w.i({ Wikipedia: 1, face: 'Wikipedia', dontSnap: 1 })
        console.log('📖 wiki: cell minted')
    }
    if (!wiki.sc.dontSnap) { wiki.sc.dontSnap = 1 }   // an anchor from before the fold wears it now
    wiki.c.up = w
    return wiki
// the page on the card, or null
Wiki_shown(w):
    let wiki = w.o({ Wikipedia: 1 })[0]
    return wiki ? (wiki.o({ Page: 1, shown: 1 })[0] || null) : null
// the queue ahead of the card
Wiki_ahead(w):
    let wiki = w.o({ Wikipedia: 1 })[0]
    return wiki ? wiki.o({ Page: 1 }).filter((p) => !p.sc.shown) : []
// Wiki_roll — THE PRESS.  `why` is only for the log (belly | press | face).  Retires the shown
//  page (dropped, not kept — a history shelf is a later ask), promotes the next fetched row, and refills.
//   With nothing ahead (first press, or the wire was slow) it fills INLINE and then promotes, so the first
//    press waits once and every later one is instant.  Returns the page now shown, or null.
async Wiki_roll(w, why):
    let wiki = this.Wiki_ensure(w)
    if (wiki.c.rolling) { return this.Wiki_shown(w) }
    wiki.c.rolling = 1
    wiki.bump()   // the face shows "fetching…" off this
    try {
        if (!this.Wiki_ahead(w).length) { await this.Wiki_fill(w, 1) }
        let next = this.Wiki_ahead(w)[0]
        if (!next) {
            console.log('📖⚠ wiki roll (' + (why || '') + ') — nothing fetched; Wikipedia unreachable?')
            return this.Wiki_shown(w)
        }
        let old = this.Wiki_shown(w)
        if (old) { wiki.drop(old) }
        next.sc.shown = 1
        next.bump()
        console.log('📖 wiki roll (' + (why || '') + ') → ' + next.sc.title + ' · ' + this.Wiki_ahead(w).length + ' ahead')
        return next
    } finally {
        delete wiki.c.rolling
        wiki.bump()
        this.Wiki_fill(w, 2)   // top back up in the background; not awaited
    }
// Wiki_section — A RANDOM SECTION, LINKS AND ALL (the owner 2026-09-20: "aren't we supposed
//  to have lots of blue underline all through wikipedia pages? … cough up a random other section of each
//   page besides the top").  The summary endpoint is plain text; the MediaWiki action API (CORS-open with
//    origin=*) renders one section as HTML.  Two paced requests: the section list, then one section —
//     uniformly among top-level sections with a body, skipping the furniture (References, See also…);
//      the lead (section 0) when a page has none.  Returns {heading, html} or null; never throws.
// `want` names a section index to fetch as-is ('0' = the lead, links and all); absent ⇒ a random one.
async Wiki_section(title, want):
    // ⚠ the .g dialect reads `\x26name` as a verb call, INSIDE string literals too — a query string written
    //  out literally compiled to `.origin()=*this.action()…` (the CORS error of 2026-09-20).  So the query is
    //   built with URLSearchParams and no ampersand ever appears in this source.
    let api = (q) => 'https://en.wikipedia.org/w/api.php?' + new URLSearchParams(Object.assign({ format: 'json', origin: '*', action: 'parse', redirects: '1', page: String(title) }, q)).toString()
    let SKIP = /^(references|notes|citations|sources|external links|see also|further reading|bibliography|footnotes|gallery)$/i
    try {
        let index = want ? String(want) : ''
        let heading = ''
        if (!index) {
            await this.Wiki_pace()
            let r = await fetch(api({ prop: 'sections' }), { signal: AbortSignal.timeout(8000) })
            if (!r.ok) { console.log('📖⚠ wiki sections: HTTP ' + r.status); return null }
            let j = await r.json()
            let all = (j && j.parse && j.parse.sections) || []
            let picks = all.filter((s) => String(s.toclevel) === '1' && !SKIP.test(String(s.line || '').trim()) && /^\d+$/.test(String(s.index)))
            let pick = picks.length ? picks[Math.floor(Math.random() * picks.length)] : null
            index = pick ? String(pick.index) : '0'
            heading = pick ? String(pick.line).replace(/<[^>]+>/g, '') : ''
        }
        await this.Wiki_pace()
        let r2 = await fetch(api({ prop: 'text', disableeditsection: '1', disabletoc: '1', disablelimitreport: '1', section: index }), { signal: AbortSignal.timeout(8000) })
        if (!r2.ok) { console.log('📖⚠ wiki section ' + index + ': HTTP ' + r2.status); return null }
        let j2 = await r2.json()
        let html = j2 && j2.parse && j2.parse.text && j2.parse.text['*']
        if (!html) { return null }
        return { heading: heading, html: String(html) }
    } catch (e) {
        console.log('📖⚠ wiki section failed: ' + String(e && e.message || e).slice(0, 100))
        return null
    }
// Wiki_summary — the REST summary of a named page: the lead paragraph (`extract`), the
//  thumbnail, the canonical title + url.  {title, url, extract?, thumb?} or null; never throws.
async Wiki_summary(title):
    try {
        await this.Wiki_pace()
        let r = await fetch('https://en.wikipedia.org/api/rest_v1/page/summary/' + encodeURIComponent(String(title).replace(/ /g, '_')), { signal: AbortSignal.timeout(8000) })
        if (!r.ok) { console.log('📖⚠ wiki summary "' + title + '": HTTP ' + r.status); return null }
        let j = await r.json()
        if (!j || !j.title) { return null }
        let out = { title: String(j.title), url: String((j.content_urls && j.content_urls.desktop && j.content_urls.desktop.page) || ('https://en.wikipedia.org/wiki/' + encodeURIComponent(j.title))) }
        if (j.extract) { out.extract = String(j.extract) }
        if (j.thumbnail && j.thumbnail.source) { out.thumb = String(j.thumbnail.source) }
        return out
    } catch (e) {
        console.log('📖⚠ wiki summary failed: ' + String(e && e.message || e).slice(0, 100))
        return null
    }
// Wiki_wander — A BLUE LINK IS A PRESS (the owner chose "wander" over "escape", 2026-09-20):
//  clicking a wikilink in the card rolls THAT page into the cell — a random section of it — so the queue
//   becomes a trail and the cell is the rabbit hole, one hop per press.  The random queue ahead is left
//    standing for the next ⟳.  Returns the page now shown, or null (the old page stays if the hop fails).
async Wiki_wander(w, title):
    let wiki = this.Wiki_ensure(w)
    if (!title || wiki.c.rolling) { return this.Wiki_shown(w) }
    wiki.c.rolling = 1
    wiki.bump()
    try {
        let sect = await this.Wiki_section(title)
        if (!sect) {
            console.log('📖⚠ wiki wander → "' + title + '" — nothing came back; staying put')
            return this.Wiki_shown(w)
        }
        // the lead too (the owner: "an overall section — the first paragraph — and this random one"):
        //  the summary is the lead paragraph + the thumbnail, one more paced request; a miss is not fatal.
        let sum = await this.Wiki_summary(title)
        let lead = await this.Wiki_section(title, '0')
        let old = this.Wiki_shown(w)
        if (old) { wiki.drop(old) }
        let sc = { Page: 1, title: String((sum && sum.title) || title), url: (sum && sum.url) || ('https://en.wikipedia.org/wiki/' + encodeURIComponent(String(title).replace(/ /g, '_'))), shown: 1 }
        if (sect.heading) { sc.section = sect.heading }
        if (sum && sum.extract) { sc.extract = sum.extract }
        if (sum && sum.thumb) { sc.thumb = sum.thumb }
        let page = wiki.i(sc)
        page.c.up = wiki
        page.c.html = sect.html
        if (lead) { page.c.lead_html = lead.html }
        page.bump()
        console.log('📖 wiki wander → "' + title + '"' + (sect.heading ? ' § ' + sect.heading : ''))
        return page
    } finally {
        delete wiki.c.rolling
        wiki.bump()
    }
// Wiki_pace — DON'T DDOS WIKIPEDIA (the owner 2026-09-20: "not 5 requests per second, and
//  dwindle that to 2ps").  A per-TAB ledger of request times on the top House (every glass shares it):
//   at most 5 in any 1s window (the burst), at most 10 in any 5s window (2/s sustained).  Resolves when
//    a request may go, having slept if it must; the caller records the send by pushing now().
async Wiki_pace():
    let M = this.top_House()
    let ts = M.c.wiki_ts || (M.c.wiki_ts = [])
    while (true) {
        let now = Date.now()
        while (ts.length && now - ts[0] > 5000) { ts.shift() }
        let burst = ts.filter((t) => now - t < 1000).length
        let wait = 0
        if (burst >= 5) { wait = 1000 - (now - ts[ts.length - 5]) }
        if (ts.length >= 10) { wait = Math.max(wait, 5000 - (now - ts[0])) }
        if (wait <= 0) { ts.push(now); return }
        console.log('📖 wiki pace — holding ' + wait + 'ms (' + burst + ' in 1s, ' + ts.length + ' in 5s)')
        await new Promise((res) => setTimeout(res, wait + 5))
    }
// Wiki_fill — fetch until `want` pages stand ahead.  ONE in flight per glass (a shared promise
//  on .c, so a concurrent caller awaits the same work instead of racing past it).  A disambiguation page
//   or a miss just rerolls, up to 3 misses.  Never stamps a maybe-undefined sc value (extract/thumb are
//    set only when present — the album/body_hash idiom).
async Wiki_fill(w, want):
    let wiki = this.Wiki_ensure(w)
    if (wiki.c.filling) { return wiki.c.filling }
    let need = () => this.Wiki_ahead(w).length < (want || 2)
    if (!need()) { return Promise.resolve(0) }
    wiki.c.filling = (async () => {
        let got = 0
        let misses = 0     // the wire failing us — HTTP error, timeout, bad JSON
        let rerolls = 0    // Wikipedia handing us the wrong KIND of page — not a failure, just go again
        try {
            while (need() && misses < 3 && rerolls < 8) {
                try {
                    await this.Wiki_pace()
                    let r = await fetch('https://en.wikipedia.org/api/rest_v1/page/random/summary', { signal: AbortSignal.timeout(8000) })
                    if (!r.ok) { misses = misses + 1; console.log('📖⚠ wiki fetch: HTTP ' + r.status); continue }
                    let j = await r.json()
                    if (!j || !j.title || j.type !== 'standard') { rerolls = rerolls + 1; console.log('📖 wiki reroll — ' + (j && j.type || 'no title')); continue }
                    let sc = { Page: 1, title: String(j.title), url: String((j.content_urls && j.content_urls.desktop && j.content_urls.desktop.page) || ('https://en.wikipedia.org/wiki/' + encodeURIComponent(j.title))) }
                    if (j.extract) { sc.extract = String(j.extract) }
                    if (j.thumbnail && j.thumbnail.source) { sc.thumb = String(j.thumbnail.source) }
                    let sect = await this.Wiki_section(sc.title)   // a random section, links and all
                    let lead = await this.Wiki_section(sc.title, '0')   // the lead, links and all
                    if (sect) { sc.section = sect.heading }
                    let page = wiki.i(sc)
                    page.c.up = wiki
                    if (sect) { page.c.html = sect.html }
                    if (lead) { page.c.lead_html = lead.html }
                    got = got + 1
                    console.log('📖 wiki fetched "' + sc.title + '"' + (sect ? ' § ' + sect.heading : ' (lead only)') + ' · ' + this.Wiki_ahead(w).length + ' ahead')
                } catch (e) {
                    misses = misses + 1
                    console.log('📖⚠ wiki fetch failed: ' + String(e && e.message || e).slice(0, 100))
                }
            }
        } finally {
            delete wiki.c.filling
            if (got) { wiki.bump() }
        }
        return got
    })()
    return wiki.c.filling


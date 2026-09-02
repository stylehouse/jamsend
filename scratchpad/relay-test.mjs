// scripts/relay-test.ts
import { createServer } from "node:http";
import { WebSocket as WebSocket2 } from "ws";
import * as ed2 from "@noble/ed25519";

// src/lib/server/relay.ts
import { WebSocketServer, WebSocket } from "ws";
import { writeFile, mkdir } from "node:fs/promises";
import { resolve, dirname, sep } from "node:path";
import { createHash } from "node:crypto";

// src/lib/p2p/cluster_trust.ts
import * as ed from "@noble/ed25519";
var enhex = ed.etc.bytesToHex;
var dehex = ed.etc.hexToBytes;
var enc = (s) => new TextEncoder().encode(s);
function canonicalHeader(header) {
  const { sign: _drop, ...rest } = header;
  const sorted = {};
  for (const k of Object.keys(rest).sort()) sorted[k] = rest[k];
  return JSON.stringify(sorted);
}
function loadTrustedPubs(env = process.env) {
  return (env.CLUSTER_TRUSTED_PUBS ?? "").split(",").map((s) => s.trim()).filter(Boolean);
}
var prepubOf = (pubHex) => pubHex.slice(0, 16);
async function signHeader(header, privHex) {
  const sig = await ed.signAsync(enc(canonicalHeader(header)), dehex(privHex));
  return enhex(sig);
}
async function verifyHeader(header, trustedPubs) {
  const sign = header.sign;
  if (typeof sign !== "string" || !sign || !trustedPubs.length) return null;
  const from = header.from;
  const ordered = typeof from === "string" ? [...trustedPubs.filter((p) => prepubOf(p) === from), ...trustedPubs.filter((p) => prepubOf(p) !== from)] : trustedPubs;
  const msg = enc(canonicalHeader(header));
  let sig;
  try {
    sig = dehex(sign);
  } catch {
    return null;
  }
  for (const pub of ordered) {
    try {
      if (await ed.verifyAsync(sig, msg, dehex(pub))) return pub;
    } catch {
    }
  }
  return null;
}

// src/lib/server/relay.ts
var GEN_ROOT = resolve("src/lib/gen");
var GEN_PATH_RE = /^gen\/[A-Za-z0-9_][A-Za-z0-9_\-/]*\.go$/;
var GEN_MAX_BYTES = 5e6;
var DEFAULT_EDITOR_RELAY = "ws://172.17.0.1:9092/relay?r2r=1";
var ATTACHED = Symbol.for("peeroleum.relay.attached");
var TALLY_MS = 1e4;
var tally = /* @__PURE__ */ new Map();
var TSEP = "\0";
function noteRoute(to, type, lane, bytes) {
  const k = to + TSEP + type + TSEP + lane;
  let t = tally.get(k);
  if (!t) tally.set(k, t = { n: 0, bytes: 0 });
  t.n += 1;
  t.bytes += bytes;
}
function humanBytes(n) {
  if (n < 1024) return `${n}B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)}KB`;
  return `${(n / (1024 * 1024)).toFixed(1)}MB`;
}
function attachRelay(httpServer, opts = {}) {
  const existing = httpServer[ATTACHED];
  if (existing) return existing;
  const PATH = opts.path ?? "/relay";
  const editorRelayUrl = opts.editorRelayUrl ?? process.env.EDITOR_RELAY ?? DEFAULT_EDITOR_RELAY;
  const bridgeOff = !editorRelayUrl || /^(off|none|0|false)$/i.test(editorRelayUrl.trim());
  if (bridgeOff) console.log("\u{1F6F0} relay attach \u2014 r2r bridge OFF (EDITOR_RELAY=" + JSON.stringify(process.env.EDITOR_RELAY ?? null) + "); this relay has no peer");
  const wss = new WebSocketServer({ noServer: true });
  const locals = /* @__PURE__ */ new Map();
  const ackBack = /* @__PURE__ */ new Map();
  const claims = /* @__PURE__ */ new Map();
  let role = null;
  let peerLink = null;
  let selfHost = "";
  let closed = false;
  let redialTimer = null;
  let redialTries = 0;
  function relayLog(line) {
    const tag = `\u{1F6F0} relay${selfHost ? "[" + selfHost + "]" : ""}${role ? "/" + role : ""}`;
    console.log(`${tag} ${line}`);
    sendControlTo("editor", { control: "log", line: `${tag} ${line}` });
  }
  function sendControlTo(addr, obj) {
    const set = locals.get(addr);
    if (!set) return;
    const text = JSON.stringify(obj);
    for (const ws of set) if (ws.readyState === WebSocket.OPEN) ws.send(text);
  }
  function broadcastControl(obj) {
    const text = JSON.stringify(obj);
    for (const set of locals.values())
      for (const ws of set) if (ws.readyState === WebSocket.OPEN) ws.send(text);
  }
  function bind(addr, ws) {
    let set = locals.get(addr);
    if (!set) locals.set(addr, set = /* @__PURE__ */ new Set());
    set.add(ws);
  }
  function unbind(addr, ws) {
    const set = locals.get(addr);
    if (!set) return;
    set.delete(ws);
    if (!set.size) locals.delete(addr);
  }
  function deliverLocal(to, payload) {
    const set = locals.get(to);
    if (!set || !set.size) return false;
    let own = false;
    for (const ws of set) if (ws.readyState === WebSocket.OPEN && String(ws.qaddr || "") === to) {
      own = true;
      break;
    }
    let delivered = false;
    for (const ws of set)
      if (ws.readyState === WebSocket.OPEN && (!own || String(ws.qaddr || "") === to)) {
        ws.send(payload);
        delivered = true;
      }
    return delivered;
  }
  function setRole(next) {
    if (role && role !== next) throw new Error(`relay role already '${role}', refusing '${next}'`);
    if (role === next) return;
    role = next;
    relayLog(`role set \u2192 ${role}`);
    if (role === "runner") dialEditor();
  }
  function dialEditor() {
    if (bridgeOff) return;
    if (peerLink && peerLink.readyState === WebSocket.OPEN) return;
    if (peerLink) {
      try {
        peerLink.close();
      } catch {
      }
      ;
      peerLink = null;
    }
    const target = (() => {
      try {
        return new URL(editorRelayUrl).host;
      } catch {
        return "";
      }
    })();
    if (target && selfHost && target === selfHost) {
      const msg = `editor-relay points at SELF (${editorRelayUrl}) \u2014 bridge cannot form. Set EDITOR_RELAY to the EDITOR origin's port (the other dev server), not ${selfHost}.`;
      relayLog(`\u2717 ${msg}`);
      broadcastControl({ control: "peer-relay", up: false, error: "self-dial", detail: msg, target: editorRelayUrl });
      return;
    }
    relayLog(`dialing editor relay \u2192 ${editorRelayUrl} \u2026`);
    const link = new WebSocket(editorRelayUrl);
    peerLink = link;
    let lastError = "";
    const watchdog = setTimeout(() => {
      if (link.readyState === WebSocket.OPEN) return;
      const msg = `editor relay ${editorRelayUrl} not connectable after 5s (readyState=${link.readyState}${lastError ? ", " + lastError : ""})`;
      relayLog(`\u2717 ${msg}`);
      broadcastControl({ control: "peer-relay", up: false, error: lastError || "timeout", detail: msg, target: editorRelayUrl });
      scheduleRedial("not connectable after 5s");
    }, 5e3);
    link.on("open", () => {
      clearTimeout(watchdog);
      redialTries = 0;
      link.isAlive = true;
      try {
        link._socket?.setNoDelay(true);
      } catch {
      }
      relayLog(`\u2713 peer relay LINKED (outbound r2r) \u2192 ${editorRelayUrl}`);
      broadcastControl({ control: "peer-relay", up: true, target: editorRelayUrl });
    });
    link.on("pong", () => {
      link.isAlive = true;
    });
    link.on("message", (data, isBinary) => routeFromPeer(isBinary ? asBuffer(data) : asText(data)));
    link.on("close", (code) => {
      clearTimeout(watchdog);
      if (peerLink === link) peerLink = null;
      relayLog(`\u2717 peer relay CLOSED code=${code} \u2192 ${editorRelayUrl}`);
      broadcastControl({ control: "peer-relay", up: false, error: `close:${code}`, target: editorRelayUrl });
      scheduleRedial(`bridge closed code=${code}`);
    });
    link.on("error", (err) => {
      lastError = err && (err.code || err.message) || "error";
      if (peerLink === link) peerLink = null;
      relayLog(`\u2717 peer relay ERROR ${lastError} \u2192 ${editorRelayUrl}`);
      broadcastControl({ control: "peer-relay", up: false, error: lastError, target: editorRelayUrl });
      scheduleRedial(`bridge error ${lastError}`);
    });
  }
  function scheduleRedial(why) {
    if (bridgeOff) return;
    if (closed || role !== "runner") return;
    if (peerLink && peerLink.readyState === WebSocket.OPEN) return;
    if (redialTimer) return;
    const delay = Math.min(15e3, 500 * Math.pow(2, redialTries++)) + Math.floor(Math.random() * 300);
    relayLog(`r2r re-dial in ${delay}ms (attempt ${redialTries}) \u2014 ${why}`);
    redialTimer = setTimeout(() => {
      redialTimer = null;
      if (!closed) dialEditor();
    }, delay);
  }
  const dropCounts = /* @__PURE__ */ new Map();
  function noteDeliver(to) {
    if (dropCounts.has(to)) dropCounts.delete(to);
  }
  function warnDrop(where, to, kind, why) {
    const n = (dropCounts.get(to) ?? 0) + 1;
    dropCounts.set(to, n);
    if (n === 1 || n % 20 === 0)
      relayLog(`\u26A0 DROPPED ${where} ${kind} \u2192 '${to}' \xD7${n} \u2014 ${why}. Frames addressed to '${to}' are being discarded (no live socket bound here); that side's inbound is DEAD.`);
  }
  function routeFromBrowser(payload) {
    const bin = typeof payload !== "string";
    const to = bin ? headerToBin(payload) : headerTo(payload);
    if (!to) return "dropped";
    const type = bin ? frameTypeBin(payload) : frameType(payload);
    const size = bin ? payload.length : payload.length;
    if (deliverLocal(to, payload)) {
      noteDeliver(to);
      noteRoute(to, type, "local", size);
      return "local";
    }
    if (peerLink && peerLink.readyState === WebSocket.OPEN) {
      peerLink.send(payload);
      noteRoute(to, type, "bridge", size);
      return "bridge";
    }
    const kind = bin ? frameKindBin(payload) : frameKind(payload);
    warnDrop("browser", to, kind, peerLink ? "bridge not OPEN" : "no bridge + no local socket");
    return "dropped";
  }
  function routeFromPeer(payload) {
    const bin = typeof payload !== "string";
    const to = bin ? headerToBin(payload) : headerTo(payload);
    if (!to) return;
    const type = bin ? frameTypeBin(payload) : frameType(payload);
    const size = bin ? payload.length : payload.length;
    if (deliverLocal(to, payload)) {
      noteDeliver(to);
      noteRoute(to, type, "from-bridge", size);
    } else {
      const kind = bin ? frameKindBin(payload) : frameKind(payload);
      warnDrop("bridge\u2192", to, kind, "arrived over the r2r bridge but no local socket is bound");
    }
  }
  const BRIDGE_ROLES = /* @__PURE__ */ new Set(["editor", "runner"]);
  const SANE_ROLE = /^[A-Za-z0-9_:.-]{1,64}$/;
  const IDENTITY_SHAPED = /^[0-9a-fA-F]{16,}$/;
  const WHO_MAX = 512;
  function handleControl(ws, msg) {
    if (msg.control === "become" && typeof msg.role === "string" && IDENTITY_SHAPED.test(msg.role)) {
      ws.send(JSON.stringify({ control: "error", error: `become '${msg.role.slice(0, 12)}\u2026' refused \u2014 identity-shaped; identities bind via signed hello only` }));
      relayLog(`\u2717 become REFUSED (identity-shaped) '${msg.role.slice(0, 16)}' \u2014 a role name is never pure hex; signed hello is the identity bind`);
      return;
    }
    if (msg.control === "become" && typeof msg.role === "string" && SANE_ROLE.test(msg.role)) {
      bind(msg.role, ws);
      (ws.roleBound ??= /* @__PURE__ */ new Set()).add(msg.role);
      relayLog(`\u{1F3AD} become ${msg.role} \u2014 bound addr=${msg.role} (locals: ${[...locals.keys()].join(",")})`);
      if (!BRIDGE_ROLES.has(msg.role)) {
        ws.send(JSON.stringify({ control: "role", role: msg.role, bridge: role ?? null }));
        return;
      }
      try {
        setRole(msg.role);
        ws.send(JSON.stringify({ control: "role", role }));
      } catch (e) {
        ws.send(JSON.stringify({ control: "error", error: String(e.message) }));
      }
      return;
    }
    if (msg.control === "gen_write") {
      void handleGenWrite(ws, msg);
      return;
    }
    if (msg.control === "hello") {
      void handleHello(ws, msg);
      return;
    }
    if (msg.control === "claim" && typeof msg.channel === "string") {
      const ch = msg.channel;
      const cur = claims.get(ch);
      if (cur && cur !== ws && cur.readyState === WebSocket.OPEN) {
        try {
          ws.send(JSON.stringify({ control: "claim_error", channel: ch, reason: "taken" }));
        } catch {
        }
        relayLog(`\u2717 claim ${ch} REFUSED \u2014 already owned`);
      } else {
        claims.set(ch, ws);
        (ws.owns ??= /* @__PURE__ */ new Set()).add(ch);
        try {
          ws.send(JSON.stringify({ control: "claimed", channel: ch }));
        } catch {
        }
        relayLog(`\u{1F399} claim ${ch}`);
      }
      return;
    }
    if (msg.control === "subscribe" && typeof msg.channel === "string") {
      const ch = msg.channel;
      if (ch[0] !== "@" || !SANE_ROLE.test(ch.slice(1))) {
        try {
          ws.send(JSON.stringify({ control: "subscribe_error", channel: ch, reason: "channel must be @-prefixed (identity addresses bind via signed hello, not subscribe)" }));
        } catch {
        }
        relayLog(`\u2717 subscribe REFUSED '${ch.slice(0, 20)}' \u2014 not an @channel; identities never bind via subscribe`);
        return;
      }
      bind(ch, ws);
      (ws.subs ??= /* @__PURE__ */ new Set()).add(ch);
      try {
        ws.send(JSON.stringify({ control: "subscribed", channel: ch }));
      } catch {
      }
      relayLog(`\u{1F4FB} subscribe ${ch} (subs: ${locals.get(ch)?.size ?? 0})`);
      return;
    }
    if (msg.control === "unsubscribe" && typeof msg.channel === "string") {
      const ch = msg.channel;
      unbind(ch, ws);
      ws.subs?.delete(ch);
      relayLog(`\u{1F4FB} unsubscribe ${ch} (subs: ${locals.get(ch)?.size ?? 0})`);
      return;
    }
    if (msg.control === "who" && Array.isArray(msg.addrs)) {
      const asker = ws.bound;
      if (!asker || !asker.size) {
        try {
          ws.send(JSON.stringify({ control: "who_error", reason: "not hello-bound \u2014 presence answers only to verified identities", corr: msg.corr }));
        } catch {
        }
        if (!ws.whoRefused) {
          ws.whoRefused = 1;
          relayLog(`\u2717 who REFUSED \u2014 asking socket has no verified hello bind`);
        }
        return;
      }
      const asked = msg.addrs.slice(0, WHO_MAX);
      if (msg.addrs.length > WHO_MAX) relayLog(`\u26A0 who list truncated ${msg.addrs.length}\u2192${WHO_MAX}`);
      const online = [];
      for (const a of asked) {
        if (typeof a !== "string") continue;
        const set = locals.get(a);
        if (!set) continue;
        for (const s of set)
          if (s.readyState === WebSocket.OPEN && s.bound?.has(a)) {
            online.push(a);
            break;
          }
      }
      try {
        ws.send(JSON.stringify({ control: "who_ok", online, asked: asked.length, corr: msg.corr }));
      } catch {
      }
      const sig = online.join(",");
      if (ws.whoSig !== sig) {
        const was = ws.whoSig;
        ws.whoSig = sig;
        relayLog(`\u{1F465} who ${asked.length} asked \u2192 ${online.length} online${was === void 0 ? "" : " (changed)"} (verified binds only)`);
      }
      return;
    }
    if (msg.control === "ghost_compile_ack" && msg.corr) {
      const cli = ackBack.get(String(msg.corr));
      if (cli && cli.readyState === WebSocket.OPEN) {
        cli.send(JSON.stringify(msg));
        relayLog(`\u2192 cli ghost_compile_ack ${msg.phase ?? "?"} corr=${msg.corr}`);
      } else relayLog(`ghost_compile_ack ${msg.phase ?? "?"} corr=${msg.corr} \u2014 no asking socket (gone)`);
      if (msg.phase === "done" || msg.phase === "error") ackBack.delete(String(msg.corr));
      return;
    }
    if (msg.control === "runner_ack" && msg.corr) {
      const cli = ackBack.get(String(msg.corr));
      if (cli && cli.readyState === WebSocket.OPEN) {
        cli.send(JSON.stringify(msg));
        relayLog(`\u2192 cli runner_ack ${msg.op ?? "?"} corr=${msg.corr}`);
      } else relayLog(`runner_ack ${msg.op ?? "?"} corr=${msg.corr} \u2014 no asking socket (gone)`);
      ackBack.delete(String(msg.corr));
      return;
    }
  }
  function heldByAnother(addr, ws) {
    const set = locals.get(addr);
    if (!set) return false;
    for (const s of set) {
      if (s === ws || s.readyState !== WebSocket.OPEN) continue;
      const seats = s.seats;
      if (seats && !seats.has(addr)) continue;
      return true;
    }
    return false;
  }
  function familyAddr(prepub, a) {
    return a === prepub || a.startsWith(prepub + "_") && /^[1-9]\d*$/.test(a.slice(prepub.length + 1));
  }
  async function handleHello(ws, msg) {
    const pub = typeof msg.pub === "string" ? msg.pub : "";
    const fresh = typeof msg.ts === "number" && Math.abs(Date.now() - msg.ts) < 3e4;
    const header = { control: "hello", from: msg.from, pub, ts: msg.ts, sign: msg.sign };
    const signer = pub ? await verifyHeader(header, [pub]) : null;
    if (signer === pub && pub && fresh) {
      const addr = prepubOf(pub);
      const want = typeof msg.want === "string" ? msg.want : "";
      if (want && !familyAddr(addr, want)) {
        try {
          ws.send(JSON.stringify({ control: "hello_error", reason: "foreign want" }));
        } catch {
        }
        relayLog(`\u2717 hello REJECTED (foreign want) \u2014 ${addr} wanted '${want.slice(0, 24)}', not of its own prepub family`);
        return;
      }
      const qaddr = String(ws.qaddr || "");
      bind(addr, ws);
      const bound = ws.bound ??= /* @__PURE__ */ new Set();
      bound.add(addr);
      let grant = addr;
      let taken;
      if (want) {
        if (heldByAnother(want, ws)) {
          taken = [...locals.keys()].filter((a) => familyAddr(addr, a) && heldByAnother(a, ws));
          for (let n = 1; ; n++) {
            const s = addr + "_" + n;
            if (!heldByAnother(s, ws)) {
              grant = s;
              break;
            }
          }
        } else grant = want;
        bind(grant, ws);
        bound.add(grant);
      }
      ;
      (ws.seats ??= /* @__PURE__ */ new Set()).add(grant);
      try {
        ws.send(JSON.stringify(taken ? { control: "hello_ok", addr: grant, taken } : { control: "hello_ok", addr: grant }));
      } catch {
      }
      relayLog(`\u{1FAAA} hello bound ${addr}${want ? ` want=${want} \u2192 seat ${grant}${taken ? ` (taken: ${taken.join(",")} \u2014 suffixed)` : ""}` : ""}${qaddr && qaddr !== addr ? ` (role channel ${qaddr} \u2014 delivery prefers the station socket)` : ""} (verified self-sig)`);
    } else {
      const reason = !pub ? "no pub" : !fresh ? "stale (ts skew)" : "bad self-signature";
      try {
        ws.send(JSON.stringify({ control: "hello_error", reason }));
      } catch {
      }
      relayLog(`\u2717 hello REJECTED (${reason})${pub ? " for " + prepubOf(pub) : ""}`);
    }
  }
  async function handleGenWrite(ws, msg) {
    const rel = String(msg.path ?? "");
    const body = typeof msg.body === "string" ? msg.body : "";
    const reject = (reason) => {
      relayLog(`\u2717 gen_write REJECTED ${rel || "(no path)"} \u2014 ${reason}`);
      try {
        ws.send(JSON.stringify({ control: "gen_write_error", path: rel, reason }));
      } catch {
      }
    };
    if (!GEN_PATH_RE.test(rel) || rel.includes("..")) return reject(`bad path ${JSON.stringify(rel)}`);
    if (body.length > GEN_MAX_BYTES) return reject(`too large (${body.length}c > ${GEN_MAX_BYTES})`);
    const abs = resolve("src/lib", rel);
    if (abs !== GEN_ROOT && !abs.startsWith(GEN_ROOT + sep)) return reject("escapes gen root");
    const trusted = loadTrustedPubs();
    if (trusted.length) {
      if (msg.body_hash == null) return reject("unsigned \u2014 no body_hash (cluster trust enforced; the editor needs its cluster key)");
      const expect = createHash("sha256").update(body).digest("hex");
      if (msg.body_hash !== expect) return reject("body_hash \u2260 sha256(body) (tampered or wrong digest)");
      const header = { control: "gen_write", path: rel, from: msg.from, body_hash: msg.body_hash, sign: msg.sign };
      const signer = await verifyHeader(header, trusted);
      if (!signer) return reject("foreign or unsigned \u2014 not a trusted cluster key");
      relayLog(`\u{1F511} gen_write authorised by ${prepubOf(signer)}`);
    } else {
      relayLog(`\u26A0 gen_write UNAUTHENTICATED ${rel} \u2014 cluster trust not configured (set CLUSTER_TRUSTED_PUBS / .env.cluster-identos to enforce)`);
    }
    const t0 = Date.now();
    try {
      await mkdir(dirname(abs), { recursive: true });
      await writeFile(abs, body);
      relayLog(`\u270D gen_write ${rel} (${body.length}c, ${Date.now() - t0}ms)`);
    } catch (e) {
      return reject(`fs write failed: ${e.message}`);
    }
  }
  wss.on("connection", (ws, meta) => {
    ;
    ws.isAlive = true;
    ws.on("pong", () => {
      ws.isAlive = true;
    });
    if (meta.r2r) {
      try {
        setRole("editor");
      } catch (e) {
        ws.close(1011, String(e.message));
        return;
      }
      peerLink = ws;
      relayLog(`\u2713 peer relay LINKED (inbound r2r) \u2014 editor end`);
      broadcastControl({ control: "peer-relay", up: true });
      ws.on("message", (data, isBinary) => routeFromPeer(isBinary ? asBuffer(data) : asText(data)));
      ws.on("close", (code) => {
        if (peerLink === ws) peerLink = null;
        relayLog(`\u2717 peer relay CLOSED code=${code} (inbound r2r)`);
        broadcastControl({ control: "peer-relay", up: false, error: `close:${code}` });
      });
      ws.on("error", (err) => {
        if (peerLink === ws) peerLink = null;
        relayLog(`\u2717 peer relay ERROR ${err && (err.code || err.message) || "error"} (inbound r2r)`);
      });
      return;
    }
    ;
    ws.qaddr = meta.addr || "";
    if (meta.addr) {
      bind(meta.addr, ws);
      relayLog(`browser bound addr=${meta.addr} (locals: ${[...locals.keys()].join(",")})`);
    }
    if (role === "runner" && !(peerLink && peerLink.readyState === WebSocket.OPEN)) {
      relayLog(`browser (re)connected, bridge down \u2014 re-dialing`);
      dialEditor();
    }
    ws.on("message", (data, isBinary) => {
      if (isBinary) {
        routeFromBrowser(asBuffer(data));
        return;
      }
      const text = asText(data);
      const msg = parse(text);
      if (msg && msg.control) {
        handleControl(ws, msg);
        return;
      }
      const askType = msg?.header?.type;
      const askCorr = (askType === "ghost_compile" || askType === "runner_ask") && (msg.corr ?? msg.header?.corr);
      if (askCorr) ackBack.set(String(askCorr), ws);
      const outcome = routeFromBrowser(text);
      if (askCorr && outcome === "dropped") {
        try {
          ws.send(JSON.stringify({ control: "undeliverable", to: msg.header?.to ?? "?", path: msg.dock?.path, corr: String(askCorr) }));
        } catch {
        }
        ackBack.delete(String(askCorr));
      }
    });
    const drop = () => {
      if (meta.addr) unbind(meta.addr, ws);
      for (const [corr, s] of ackBack) if (s === ws) ackBack.delete(corr);
      const subs = ws.subs;
      if (subs) for (const ch of subs) unbind(ch, ws);
      const owns = ws.owns;
      if (owns) {
        for (const ch of owns) if (claims.get(ch) === ws) claims.delete(ch);
      }
      const bound = ws.bound;
      if (bound) for (const a of bound) unbind(a, ws);
      const roleBound = ws.roleBound;
      if (roleBound) for (const a of roleBound) unbind(a, ws);
    };
    ws.on("close", (code) => {
      drop();
      if (meta.addr) relayLog(`browser DISCONNECTED addr=${meta.addr} code=${code} (locals: ${[...locals.keys()].join(",") || "none"})`);
    });
    ws.on("error", drop);
  });
  const tallyTimer = setInterval(() => {
    if (!tally.size) return;
    const rows = [...tally.entries()].sort((a, b) => b[1].bytes - a[1].bytes || b[1].n - a[1].n);
    tally.clear();
    for (const [k, t] of rows) {
      const [to, type, lane] = k.split(TSEP);
      relayLog(`\u{1F4CA} ${to} ${type} \xD7${t.n} ${humanBytes(t.bytes)} (${lane}, ${TALLY_MS / 1e3}s)`);
    }
  }, TALLY_MS);
  const HEARTBEAT_MS = 15e3;
  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (ws.isAlive === false) {
        relayLog(`\u2702 half-open socket terminated (missed pong)`);
        ws.terminate();
        continue;
      }
      ;
      ws.isAlive = false;
      try {
        ws.ping();
      } catch {
      }
    }
    const link = peerLink;
    if (link && link.readyState === WebSocket.OPEN && !wss.clients.has(link)) {
      if (link.isAlive === false) {
        relayLog(`\u2702 half-open r2r bridge terminated (missed pong) \u2014 will re-dial`);
        try {
          link.terminate();
        } catch {
        }
        if (peerLink === link) peerLink = null;
        scheduleRedial("half-open bridge (missed pong)");
      } else {
        ;
        link.isAlive = false;
        try {
          link.ping();
        } catch {
        }
      }
    }
  }, HEARTBEAT_MS);
  const onUpgrade = (req, socket, head) => {
    let u;
    try {
      u = new URL(req.url ?? "", "http://localhost");
    } catch {
      return;
    }
    if (u.pathname !== PATH) return;
    try {
      socket.setNoDelay(true);
    } catch {
    }
    selfHost = selfHost || req.headers?.host || "";
    const meta = { addr: u.searchParams.get("addr"), r2r: u.searchParams.get("r2r") === "1" };
    wss.handleUpgrade(req, socket, head, (ws) => wss.emit("connection", ws, meta));
  };
  httpServer.on("upgrade", onUpgrade);
  const handle = {
    wss,
    get role() {
      return role;
    },
    get localCount() {
      return locals.size;
    },
    get peerReady() {
      return !!peerLink && peerLink.readyState === WebSocket.OPEN;
    },
    close() {
      closed = true;
      if (redialTimer) {
        clearTimeout(redialTimer);
        redialTimer = null;
      }
      httpServer.off("upgrade", onUpgrade);
      clearInterval(heartbeat);
      clearInterval(tallyTimer);
      peerLink?.close();
      wss.close();
      delete httpServer[ATTACHED];
    }
  };
  httpServer[ATTACHED] = handle;
  return handle;
}
function asText(data) {
  return typeof data === "string" ? data : data.toString();
}
function parse(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}
function headerTo(text) {
  const m = parse(text);
  return m && m.header && m.header.to;
}
function frameKind(text) {
  const m = parse(text);
  const h = m && m.header;
  return h ? `${h.type}${h.seq != null ? " seq=" + h.seq : ""}` : "(headerless)";
}
function frameType(text) {
  const m = parse(text);
  return m && m.header && m.header.type || "";
}
function asBuffer(data) {
  if (Buffer.isBuffer(data)) return data;
  if (Array.isArray(data)) return Buffer.concat(data);
  return Buffer.from(data);
}
function binHeader(buf) {
  const nl = buf.indexOf(10);
  if (nl < 0) return null;
  try {
    return JSON.parse(buf.subarray(0, nl).toString());
  } catch {
    return null;
  }
}
function headerToBin(buf) {
  const h = binHeader(buf);
  return h && h.to;
}
function frameTypeBin(buf) {
  const h = binHeader(buf);
  return h && h.type || "";
}
function frameKindBin(buf) {
  const h = binHeader(buf);
  if (!h) return "(binary, no header line)";
  const nl = buf.indexOf(10);
  return `${h.type}${h.seq != null ? " seq=" + h.seq : ""} +buf=${buf.length - nl - 1}`;
}

// scripts/relay-test.ts
var enhex2 = ed2.etc.bytesToHex;
async function mint() {
  const priv = ed2.utils.randomPrivateKey();
  const pub = await ed2.getPublicKeyAsync(priv);
  return { privHex: enhex2(priv), pubHex: enhex2(pub) };
}
var log = (...a) => console.log(...a);
var failures = 0;
function check(name, ok) {
  log(`${ok ? "  \u2713" : "  \u2717 FAIL"}  ${name}`);
  if (!ok) failures++;
}
function listen(server) {
  return new Promise((res) => server.listen(0, "127.0.0.1", () => res(server.address().port)));
}
function listenOn(server, port) {
  return new Promise((res, rej) => {
    server.once("error", rej);
    server.listen(port, "127.0.0.1", () => res());
  });
}
var wait = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(pred, ms = 2e3) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    if (pred()) return true;
    await wait(20);
  }
  return pred();
}
function browser(port, addr) {
  const ws = new WebSocket2(`ws://127.0.0.1:${port}/relay?addr=${addr}`);
  const got = [];
  const ctrl = [];
  ws.on("message", (d, isBinary) => {
    if (isBinary) {
      const buf = Buffer.isBuffer(d) ? d : Buffer.from(d);
      const nl = buf.indexOf(10);
      const header = JSON.parse(buf.subarray(0, nl).toString());
      got.push({ header, buffer: buf.subarray(nl + 1) });
      return;
    }
    const m = JSON.parse(d.toString());
    (m.control ? ctrl : got).push(m);
  });
  const open = new Promise((r) => ws.on("open", () => r()));
  const send = (o) => ws.send(JSON.stringify(o));
  const frame = (to, type, seq = 1) => send({ header: { from: addr, to, type, seq } });
  const binframe = (to, type, seq, buffer) => {
    const hj = Buffer.from(JSON.stringify({ from: addr, to, type, seq, body_len: buffer.length }));
    ws.send(Buffer.concat([hj, Buffer.from([10]), buffer]));
  };
  return { ws, got, ctrl, open, send, frame, binframe };
}
async function main() {
  const editorSrv = createServer();
  const runnerSrv = createServer();
  const editorPort = await listen(editorSrv);
  const runnerPort = await listen(runnerSrv);
  const editor = attachRelay(editorSrv);
  const runner = attachRelay(runnerSrv, {
    editorRelayUrl: `ws://127.0.0.1:${editorPort}/relay?r2r=1`
  });
  const alice = browser(editorPort, "ALICE");
  const alice2 = browser(editorPort, "ALICE2");
  const bob = browser(runnerPort, "BOB");
  await Promise.all([alice.open, alice2.open, bob.open]);
  alice.send({ control: "become", role: "editor" });
  bob.send({ control: "become", role: "runner" });
  const bridged = await until(() => editor.peerReady && runner.peerReady && editor.role === "editor" && runner.role === "runner");
  check("relay\u2194relay bridge comes up (runner dialed editor)", bridged);
  check("editor role locked editor", editor.role === "editor");
  check("runner role locked runner", runner.role === "runner");
  alice.frame("ALICE2", "dock_push", 1);
  const same = await until(() => alice2.got.some((m) => m.header?.to === "ALICE2" && m.header?.from === "ALICE"));
  check("same-origin deliver ALICE\u2192ALICE2", same);
  alice.frame("BOB", "dock_push", 2);
  const fwd = await until(() => bob.got.some((m) => m.header?.to === "BOB" && m.header?.from === "ALICE"));
  check("cross-relay deliver ALICE\u2192BOB (editor\u2192runner)", fwd);
  bob.frame("ALICE", "run_result", 3);
  const back = await until(() => alice.got.some((m) => m.header?.to === "ALICE" && m.header?.from === "BOB"));
  check("cross-relay deliver BOB\u2192ALICE (runner\u2192editor)", back);
  const payload = Buffer.from([1, 2, 3, 4, 250, 128, 0, 99, 17]);
  alice.binframe("ALICE2", "test_binary", 5, payload);
  const binSame = await until(() => alice2.got.some((m) => m.buffer && m.header?.from === "ALICE" && m.header?.type === "test_binary"));
  check("binary same-origin deliver ALICE\u2192ALICE2", binSame);
  const binSameRow = alice2.got.find((m) => m.buffer && m.header?.type === "test_binary");
  check("binary buffer intact (same-origin)", !!binSameRow && Buffer.compare(binSameRow.buffer, payload) === 0);
  alice.binframe("BOB", "test_binary", 6, payload);
  const binFwd = await until(() => bob.got.some((m) => m.buffer && m.header?.from === "ALICE" && m.header?.type === "test_binary"));
  check("binary cross-relay deliver ALICE\u2192BOB (over bridge)", binFwd);
  const binFwdRow = bob.got.find((m) => m.buffer && m.header?.type === "test_binary");
  check("binary buffer intact (cross-relay)", !!binFwdRow && Buffer.compare(binFwdRow.buffer, payload) === 0);
  log("\n\u2014 to:<pub> signed-hello binding \u2014");
  const carolKey = await mint();
  const carolAddr = prepubOf(carolKey.pubHex);
  const carol = browser(editorPort, "");
  await carol.open;
  const cts = Date.now();
  const csign = await signHeader({ control: "hello", from: carolAddr, pub: carolKey.pubHex, ts: cts }, carolKey.privHex);
  carol.send({ control: "hello", from: carolAddr, pub: carolKey.pubHex, ts: cts, sign: csign });
  const helloOk = await until(() => carol.ctrl.some((m) => m.control === "hello_ok" && m.addr === carolAddr));
  check("signed hello accepted (hello_ok, bound by verified prepub)", helloOk);
  alice.frame(carolAddr, "dock_push", 20);
  const toPub = await until(() => carol.got.some((m) => m.header?.to === carolAddr && m.header?.from === "ALICE"));
  check("to:<pub> delivers to the hello-bound socket", toPub);
  const evil = browser(editorPort, "");
  await evil.open;
  const evilKey = await mint();
  const ets = Date.now();
  const esign = await signHeader({ control: "hello", from: carolAddr, pub: carolKey.pubHex, ts: ets }, evilKey.privHex);
  evil.send({ control: "hello", from: carolAddr, pub: carolKey.pubHex, ts: ets, sign: esign });
  const helloErr = await until(() => evil.ctrl.some((m) => m.control === "hello_error"));
  check("hello with a bad self-signature rejected (hello_error)", helloErr);
  const evilBefore = evil.got.length;
  alice.frame(carolAddr, "dock_push", 21);
  const carolGot21 = await until(() => carol.got.some((m) => m.header?.seq === 21 && m.header?.to === carolAddr));
  check("to:<pub> still reaches the real holder after a forged hello", carolGot21);
  check("impostor never bound \u2014 to:<pub> does not reach it", evil.got.length === evilBefore);
  const becomeCtrlBefore = evil.ctrl.length;
  evil.send({ control: "become", role: carolAddr });
  const becomeRefused = await until(() => evil.ctrl.slice(becomeCtrlBefore).some((m) => m.control === "error" && /identity-shaped/.test(String(m.error))));
  check("become <prepub> refused (identity-shaped role name)", becomeRefused);
  const evilBefore22 = evil.got.length;
  alice.frame(carolAddr, "dock_push", 22);
  const carolGot22 = await until(() => carol.got.some((m) => m.header?.seq === 22 && m.header?.to === carolAddr));
  check("to:<pub> still individuated after the refused become", carolGot22);
  check("shadow-subscriber got no copy", evil.got.length === evilBefore22);
  log("\n\u2014 individuation: to:<pub> is one runner, to:runner is all \u2014");
  const rk1 = await mint(), rk2 = await mint();
  const rp1 = prepubOf(rk1.pubHex), rp2 = prepubOf(rk2.pubHex);
  const run1 = browser(editorPort, "runner");
  const run2 = browser(editorPort, "runner");
  await Promise.all([run1.open, run2.open]);
  const rt1 = Date.now();
  run1.send({ control: "hello", from: rp1, pub: rk1.pubHex, ts: rt1, sign: await signHeader({ control: "hello", from: rp1, pub: rk1.pubHex, ts: rt1 }, rk1.privHex) });
  const rt2 = Date.now();
  run2.send({ control: "hello", from: rp2, pub: rk2.pubHex, ts: rt2, sign: await signHeader({ control: "hello", from: rp2, pub: rk2.pubHex, ts: rt2 }, rk2.privHex) });
  await until(() => run1.ctrl.some((m) => m.control === "hello_ok") && run2.ctrl.some((m) => m.control === "hello_ok"));
  const run2Before = run2.got.length;
  alice.frame(rp1, "rungo", 30);
  const indiv = await until(() => run1.got.some((m) => m.header?.seq === 30 && m.header?.to === rp1));
  check("to:<pubA> reaches runner A", indiv);
  await wait(120);
  check("to:<pubA> does NOT reach runner B (individuated \u2014 no double-run)", run2.got.length === run2Before);
  alice.frame("runner", "become_book", 31);
  const bcastA = await until(() => run1.got.some((m) => m.header?.seq === 31 && m.header?.to === "runner"));
  const bcastB = await until(() => run2.got.some((m) => m.header?.seq === 31 && m.header?.to === "runner"));
  check("to:runner broadcasts to runner A", bcastA);
  check("to:runner broadcasts to runner B", bcastB);
  log("\n\u2014 one delivery door: a two-socket tab receives each frame once \u2014");
  const dk = await mint();
  const dp = prepubOf(dk.pubHex);
  const station = browser(editorPort, dp);
  const channel = browser(editorPort, "runner");
  await Promise.all([station.open, channel.open]);
  for (const sock of [station, channel]) {
    const ts = Date.now();
    sock.send({ control: "hello", from: dp, pub: dk.pubHex, ts, sign: await signHeader({ control: "hello", from: dp, pub: dk.pubHex, ts }, dk.privHex) });
  }
  await until(() => station.ctrl.some((m) => m.control === "hello_ok") && channel.ctrl.some((m) => m.control === "hello_ok"));
  const chanBefore = channel.got.length;
  alice.frame(dp, "repli_page", 40);
  const onStation = await until(() => station.got.some((m) => m.header?.seq === 40));
  check("a music frame reaches the tab's STATION socket", onStation);
  await wait(120);
  check("\u2026and NOT its role channel (no phantom copy into w:Lies)", channel.got.length === chanBefore);
  check("\u2026exactly once on the station socket", station.got.filter((m) => m.header?.seq === 40).length === 1);
  station.ws.close();
  channel.ws.close();
  log("\n\u2014 who: batch presence probe \u2014");
  alice.send({ control: "who", addrs: [carolAddr], corr: "w0" });
  const whoRefused = await until(() => alice.ctrl.some((m) => m.control === "who_error" && m.corr === "w0"));
  check("who refused to a non-hello-bound asker (who_error)", whoRefused);
  carol.send({ control: "who", addrs: [rp1, rp2, carolAddr, "deadbeefdeadbeef", "ALICE"], corr: "w1" });
  const who1 = await until(() => carol.ctrl.some((m) => m.control === "who_ok" && m.corr === "w1"));
  check("who answers a hello-bound asker (who_ok)", who1);
  const w1 = carol.ctrl.find((m) => m.control === "who_ok" && m.corr === "w1");
  check("who: hello-bound runners read online", !!w1 && w1.online.includes(rp1) && w1.online.includes(rp2));
  check("who: the asker reads online to itself", !!w1 && w1.online.includes(carolAddr));
  check("who: an unknown addr reads offline", !!w1 && !w1.online.includes("deadbeefdeadbeef"));
  check("who: an ?addr=-only claim does NOT read online (verified binds only)", !!w1 && !w1.online.includes("ALICE"));
  check("who: asked count echoes the list", !!w1 && w1.asked === 5);
  const beforeRepeat = carol.ctrl.filter((m) => m.control === "who_ok").length;
  carol.send({ control: "who", addrs: [rp1], corr: "r1" });
  carol.send({ control: "who", addrs: [rp1], corr: "r2" });
  carol.send({ control: "who", addrs: [rp1], corr: "r3" });
  const allThree = await until(() => carol.ctrl.filter((m) => m.control === "who_ok").length >= beforeRepeat + 3);
  check("an unchanged who still ANSWERS every time (only the log is quiet)", allThree);
  check("and each reply carries its own corr", ["r1", "r2", "r3"].every((c) => carol.ctrl.some((m) => m.control === "who_ok" && m.corr === c)));
  run2.ws.close();
  await wait(200);
  carol.send({ control: "who", addrs: [rp1, rp2], corr: "w2" });
  const who2 = await until(() => carol.ctrl.some((m) => m.control === "who_ok" && m.corr === "w2"));
  const w2 = carol.ctrl.find((m) => m.control === "who_ok" && m.corr === "w2");
  check("who: a closed socket reads offline", who2 && !!w2 && !w2.online.includes(rp2));
  check("who: the still-open runner stays online", !!w2 && w2.online.includes(rp1));
  const ctrlBefore = bob.ctrl.length;
  bob.send({ control: "become", role: "editor" });
  const errored = await until(() => bob.ctrl.slice(ctrlBefore).some((m) => m.control === "error"));
  check("set-once role conflict is errorific", errored);
  const bobBefore = bob.got.length;
  alice.frame("NOBODY", "dock_push", 4);
  await wait(150);
  check("unknown addressee dropped (no spurious delivery)", bob.got.length === bobBefore);
  check("no loopback to sender ALICE", !alice.got.some((m) => m.header?.from === "ALICE"));
  check("no loopback to sender BOB", !bob.got.some((m) => m.header?.from === "BOB"));
  log("\n\u2014 routing tally (one line per addr+type per 10s) \u2014");
  const printed = [];
  const realLog = console.log;
  console.log = (...a) => {
    printed.push(a.join(" "));
    realLog(...a);
  };
  const tallyBefore = alice2.got.length;
  for (let i = 0; i < 12; i++) alice.frame("ALICE2", "repli_page", 900 + i);
  const allArrived = await until(() => alice2.got.length >= tallyBefore + 12);
  check("every tallied frame still DELIVERS (12/12)", allArrived);
  check("and none of them printed a per-frame routing line", !printed.some((l) => /→ ALICE2 repli_page/.test(l)));
  const dumped = await until(() => printed.some((l) => /📊 ALICE2 repli_page/.test(l)), 13e3);
  check("the 10s tally dump prints one line for ALICE2/repli_page", dumped);
  const row = printed.find((l) => /📊 ALICE2 repli_page/.test(l)) ?? "";
  check(`the tally counts all 12 (got: ${row.trim().slice(0, 80)})`, /×12\b/.test(row));
  check("and reports a byte total + lane", /local/.test(row) && /\d+(\.\d+)?(B|KB|MB)/.test(row));
  console.log = realLog;
  log("\n\u2014 r2r reconnect: simulating editor/staging restart (BOB stays put) \u2014");
  editor.close();
  editorSrv.close();
  const wentDown = await until(() => !runner.peerReady, 3e3);
  check("bridge drops when editor/staging restarts", wentDown);
  const editorSrv2 = createServer();
  await listenOn(editorSrv2, editorPort);
  const editor2 = attachRelay(editorSrv2);
  const alice3 = browser(editorPort, "ALICE");
  await alice3.open;
  alice3.send({ control: "become", role: "editor" });
  const reBridged = await until(() => runner.peerReady && editor2.peerReady, 2e4);
  check("runner auto-re-dials the r2r bridge (no browser reload, no manual restart)", reBridged);
  bob.frame("ALICE", "run_result", 7);
  const backAgain = await until(() => alice3.got.some((m) => m.header?.to === "ALICE" && m.header?.from === "BOB"), 3e3);
  check("cross-relay deliver resumes after reconnect (BOB\u2192ALICE)", backAgain);
  alice3.frame("BOB", "dock_push", 8);
  const fwdAgain = await until(() => bob.got.some((m) => m.header?.to === "BOB" && m.header?.from === "ALICE" && m.header?.seq === 8), 3e3);
  check("cross-relay deliver resumes after reconnect (ALICE\u2192BOB)", fwdAgain);
  editor2.close();
  runner.close();
  await wait(50);
  editorSrv2.close();
  runnerSrv.close();
  log(failures ? `
FAIL \u2014 ${failures} check(s) failed` : "\nPASS \u2014 relay routes");
  process.exit(failures ? 1 : 0);
}
main().catch((e) => {
  console.error("relay-test threw:", e);
  process.exit(1);
});

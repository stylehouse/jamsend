// relay_bridge.mjs — REACH THE REAL RELAY THROUGH THE DOCKER BRIDGE (2026-09-05, the owner's find).
//  This container's egress to djamsend.duckdns.org:9999 is blocked at the network layer (confirmed:
//   a direct `wss://djamsend.duckdns.org:9999/relay` connect times out — see [[remote-node-egress-walled]]).
//   But leproxy-caddy (the reverse proxy terminating that domain) is ALSO published on the docker0 bridge
//    at 172.17.0.1:9999 (`docker ps`: "0.0.0.0:9999->443/tcp"), and this container can reach that address
//     (it already reaches the daemon's own 172.17.0.1:9099 the same way).  So: keep the HOSTNAME the client
//      sends (both in the TLS SNI and the HTTP Host header — that's what caddy uses to pick the vhost and
//       what the cert's CN must match) and override ONLY the IP the socket actually connects to.  A real
//        `/etc/hosts` edit would do the same thing but needs root, which this container does not have; a
//         per-connection DNS override needs neither.
//  Node's `net.connect`/`tls.connect` (and everything built on them — `https.request`, the `ws` package)
//   accept a `lookup` option that defaults to `dns.lookup`; passing one BYPASSES real DNS for that call.
//    Monkeypatching the `dns` module's OWN `lookup` (both callback and promises forms) makes every caller
//     that does NOT supply its own `lookup` — which is every caller in runner_ask.mjs — inherit the override
//      for free.  Scoped to exactly one hostname; anything else resolves normally.
//  PROVEN, not guessed: `https://djamsend.duckdns.org:9999/` returns 200 with the real cert (CN=djamsend.
//   duckdns.org) through this route, and `wss://djamsend.duckdns.org:9999/relay` opens.
//
//  USAGE: node scripts/relay_bridge.mjs <runner_ask args...>
//    e.g. node scripts/relay_bridge.mjs runners --live
//         node scripts/relay_bridge.mjs ping --player=eed831f1977c4e81 --live
//   Always pass --live (RUNNER_URL below is a foreign host, per runner_ask's own rule) and set
//    RUNNER_URL=https://djamsend.duckdns.org:9999 in the environment (or edit the default below).
import dns from 'node:dns'
import { promises as dnsPromises } from 'node:dns'

const BRIDGE_HOST = 'djamsend.duckdns.org'
const BRIDGE_IP = process.env.RELAY_BRIDGE_IP || '172.17.0.1'

const origLookup = dns.lookup.bind(dns)
dns.lookup = (hostname, options, callback) => {
    if (typeof options === 'function') { callback = options; options = {} }
    if (hostname === BRIDGE_HOST) {
        if (options && options.all) return callback(null, [{ address: BRIDGE_IP, family: 4 }])
        return callback(null, BRIDGE_IP, 4)
    }
    return origLookup(hostname, options, callback)
}

const origLookupP = dnsPromises.lookup.bind(dnsPromises)
dnsPromises.lookup = async (hostname, options) => {
    if (hostname === BRIDGE_HOST) {
        return (options && options.all) ? [{ address: BRIDGE_IP, family: 4 }] : { address: BRIDGE_IP, family: 4 }
    }
    return origLookupP(hostname, options)
}

if (!process.env.RUNNER_URL) process.env.RUNNER_URL = `https://${BRIDGE_HOST}:9999`
console.error(`🌉 relay_bridge: ${BRIDGE_HOST} → ${BRIDGE_IP} (docker bridge) for this process only`)

await import('./runner_ask.mjs')

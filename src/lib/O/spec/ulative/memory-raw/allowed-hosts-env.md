---
name: allowed-hosts-env
description: "Vite allowedHosts comes from ALLOWED_HOSTS env (.env.local via compose env_file), NOT hardcoded; secure default localhost-only"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 2a47a269-1da9-4165-9d39-21bcea3120d2
---

`vite.config.ts` `server.allowedHosts` is **not hardcoded** — it reads
`process.env.ALLOWED_HOSTS` (comma-separated, trimmed). Default empty = **localhost-only**
(secure: an unexpected public Host header is refused). Don't re-hardcode domains there.

Wiring: `docker-compose.yml` app service has `env_file: [.env.local]` → injects
`ALLOWED_HOSTS` into the container's `process.env`. `.env.local` is gitignored (`.env.*`);
`.env.example` (committed) documents it. To add/phase out a public domain: edit the one line
in `.env.local`, then `docker compose up -d app` (env_file applies on **recreate**, not a
plain restart).

Read straight off `process.env`, NOT Vite's `loadEnv`, because **`/app/.env` is a directory**
(holds `secrets`) and loadEnv would trip on it.

SECURITY: a Vite *dev* server serves full source + the `@fs` resolver — never leave it on the
open internet without auth/allowlist at the reverse proxy (Caddy: `basic_auth` + `respond 444`
for scanner junk like `*xmlrpc.php*`/`*wp-includes*`). The duckdns exposure is being phased out.

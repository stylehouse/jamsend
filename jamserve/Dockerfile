# jamserve/Dockerfile — the always-on personal box: "a user's personal internet
#  infrastructure, music piracy only for now" (the owner, 2026-08-08).
#
# It runs scripts/daemon (Daemon_todo) headless: holds the collection, answers heists,
#  answers Invites, and keeps one peer on the network whose uptime is not somebody's
#   browser session.
#
# TWO THINGS IN HERE ARE LOAD-BEARING. Neither is decoration:
#
# 1. ffmpeg comes from apk, NOT from npm.  Daemon_todo §2.1's shim wants a BINARY to spawn
#     behind the WebCodecs seam (Ra.g:1352/1657 construct OfflineAudioContext unguarded, so a
#      daemon cannot carry a track past its preview window without one — §8.2).  The npm routes
#       are both wrong: `ffmpeg-static` ships a per-platform prebuilt as an OPTIONAL DEP, which
#        is exactly the musl/glibc failure that took the app down for hours on 2026-08-07, and
#         `@ffmpeg/ffmpeg` is the browser wasm build.  A system binary has no lockfile, no
#          optional deps and no opinion about libc.  Costs ~120MB; worth it.
#     It must live in the IMAGE, never bind-mounted from the host — a mounted binary is the same
#      libc trap wearing a different hat.
#
# 2. `npm ci`, and the compose file shadows /app/node_modules with an anonymous volume.
#     CLAUDE.md's big warning is that `app` (Alpine/musl) and `claude` (Debian/glibc) share ONE
#      /app/node_modules, because `volumes: - .:/app` mounts the host tree straight over whatever
#       the image built.  jamserve is a THIRD libc consumer, so without the anonymous-volume
#        shadow on the `jamserve` service in docker-compose.yml it would make that problem worse.
#     That shadow is STICKY, which is its own trap: `up` reuses the previous container's anonymous
#      volume rather than repopulating from a new image, so neither this npm ci nor the chown below
#       lands until you `up --renew-anon-volumes`.  It cost a crashloop on 2026-08-08.
#     `npm ci` (not `npm install`) so the pinned tree is what lands — the 2026-08-07 outage had
#      rollup drifting to 4.62.4 against a lockfile pinning 4.40.2, and that mismatch is what made
#       every SSR request 500 with `__SVELTEKIT_PATHS_BASE__ is not defined`.
#
# 3. It runs as uid 1000, not root.  MEASURED 2026-08-08, first boot: as root it wrote
#     `/music/.jamsend` mode 700 owned by root:root — inside the USER'S OWN music folder.  That
#      breaks the documented workflow in both directions: the browser (uid 1000, holding the FSA
#       grant) can no longer provision or read the account, and neither can you without sudo.
#      The dirs below must exist owned by node BEFORE the volumes attach, because an empty named
#       volume (and an anonymous one) inherits the ownership of the image directory it covers —
#        the same trick the `claude` service uses for /home/node/.claude in docker-compose.yml.
#      node:22-alpine already ships `node` at uid 1000, so no user needs creating.
#
# TODO (Daemon_todo §5.3, "Packaging"): this still boots vite in middleware mode, ~12s of
#  transform on every start, so a crash-looping jamserve recompiles from scratch each time.
#   A real deployment wants a build — which would also mean no node_modules at runtime at all,
#    and this whole file collapses to a binary plus ffmpeg.

FROM node:22-alpine

# the one system dependency — see (1) above.
RUN apk add --no-cache ffmpeg

WORKDIR /app

# Install against the LOCKFILE, into the image, for THIS platform (musl).  The compose file's
#  anonymous volume keeps this copy alive underneath the .:/app bind mount.
COPY package*.json ./
RUN npm ci

# The source is bind-mounted at runtime; this copy is only so the image is self-contained
#  enough to build and inspect without the mount.
COPY . .

# see (3) above.  node_modules is chowned because the anonymous volume inherits THIS ownership,
#  and vite in middleware mode writes its pre-bundle cache to node_modules/.vite/deps — as uid
#   1000 over a root-owned volume that is an EACCES at first transform, not at boot.
RUN mkdir -p /var/lib/jamserve /home/node/.cache \
    && chown -R node:node /var/lib/jamserve /home/node/.cache /app/node_modules
USER node

# Belt and braces: if someone ever drops the anonymous volume, fail loudly at boot rather than
#  silently running on the host's glibc tree.  `ldd` on a native .node reports "not found" for
#   the wrong libc; a musl image resolving a gnu binary is the tell CLAUDE.md documents.
CMD ["node", "scripts/daemon/run.mjs"]

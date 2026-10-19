// app_data_dir.ts — the app's private corner inside any share: the ONE spelling of `.jamsend`.
//  Everything this app keeps for itself on a person's disk lives under it — account/ and identities/ (keys),
//   berth/ (per-identity Wafts), wormhole/ (the app tree on a music folder), radiostock/ and friends (caches).
//  Two guards key on this exact segment: the relay's serve wall (Housing `rw_*` — never served over the wire)
//   and NodeWormholeNav's 0600/0700 modes.  Spell it anywhere else and that place's files stop being private.
//  The VALUE is on-disk format: changing it orphans every existing disk.  Dependency-free so the browser, the
//   ghosts (via IMPORT()) and the node daemon all read the same constant.
export const APP_DATA_DIR = '.jamsend'

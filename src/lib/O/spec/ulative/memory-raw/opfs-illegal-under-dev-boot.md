---
name: opfs-illegal-under-dev-boot
description: OPFS-github cloud forbidden under ?E=/?B= dev boots; FaceSucker share gate via H.c.disk_gated
metadata: 
  node_type: memory
  type: project
  originSessionId: e706066f-325c-4eae-adad-ee0bd28695ab
---

The OPFS-from-github backend (`mount_opfs_github_nav`, WormholeOpfs.svelte.ts) is a github-seeded **shadow disk** — legit only for a param-less Auto demo "out in the world". Under a dev boot (`?E=` editor / `?B=` runner, i.e. `H.c.boot_role` set) it's a **lie about the disk connection** and is now refused.

`DirectoryOpener` (Housing.svelte.ts ~1634): if `H.top_House().c.boot_role` is set and no real local share is open (`fsh.started && fsh.list`), it does NOT mount the cloud — it raises `H.top_House().c.disk_gated = true` and returns. The real-share success branch clears it (`disk_gated = false`). The sole way in is the enrolled `open_dir` watched-action (`requestDirectoryAccess` + `A.c.nav=null` + re-think); granting flips `fsh.started/list` so the next tick takes the success branch.

`Otro.svelte`: a fullscreen `FaceSucker` (altitude 77) shows while `disk_gated`. `disk_gated` lives on plain `.c` (not $state), so Otro samples it via a 400ms `disk_poll` $state interval (avoids House-reactivity guesswork — fine for a one-time gate). The gate's "open share" button reuses the `open_dir` action's `sc.fn` (found via `H.o({watched:'actions'})[0].o({action:1,role:'open_dir'})[0]`) so UI can't drift from the data layer.

Scope decision: **only role params E/B** forbid the cloud (boot_role is set only for those in Otro); `?A=`/`?W=` still allow OPFS. See [[creduler-runner-architecture]] — the runner's writes (cred snaps) now land on real disk, not the shadow. Related: [[host-commits-midsession]].

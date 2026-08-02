---
name: claude-crash-esbuild-zombies
description: Claude TUI hard-crash = PID exhaustion from esbuild zombies; FIXED via init:true in compose; diagnosis kept for recurrence
metadata:
  node_type: memory
  type: project
  originSessionId: 1dafee0d-6b03-4b07-89d6-b80c35375ed9
---

**FIXED** — `init: true` is now on the `claude` compose service (Docker injects tini as PID 1,
which reaps orphaned children). The crashes should not recur; they only would if the container is
recreated without `init`. Diagnosis kept below so the symptom is recognised, not misblamed on memory.

The crash signature: the Claude TUI hard-crashes — the ncurses frame freezes on screen, the shell
prompt re-emerges underneath. It is **PID exhaustion**, not RAM/CPU. Mechanism: every vite-node /
svelte-check / ghost-compile spawns a long-lived **esbuild** child; if the parent dies without
cleanly stopping it, esbuild is orphaned → re-parented to PID 1. The old PID 1 was `command: sleep
infinity`, which never calls `wait()` → permanent **zombies** that hold PID slots until the cgroup
`pids` cap (512) is hit → any new fork gets `EAGAIN` (`pthread_create: Resource temporarily
unavailable`) → node/Claude aborts mid-render. Self-reinforcing: each crashed compile leaks more.

**If it ever recurs:** check `cat /sys/fs/cgroup/pids.current` vs `pids.max` and count `Z`-state
procs before blaming memory; `docker compose up -d claude` recreates the container to clear existing
zombies (this kills the live Claude session — do it deliberately).

(A crashed session leaves NO `AskUserQuestion` tool_use on disk — the crash beats the transcript
write — so an unanswered-multichoice session is identified by its transcript ENDING abruptly with
no question persisted.)

---
name: localgen-browserless-compile
description: "scripts/LocalGen.spec.ts — compile a .g to its REAL src/lib/gen/.go with ZERO browser (ghost-compile can't: it only tickets a live editor); closes the headless edit→compile→run loop with CredRunner"
metadata: 
  node_type: memory
  type: project
  originSessionId: 65e20774-d6b8-435a-a4a1-7d69fb977e72
---

`npm run ghost-compile` does NOT compile locally — it sends a signed TICKET to a LIVE browser editor on :9091/:9092 (via the relay) and that editor compiles + writes the `.go` + HMRs it. So with **no editor connected it cannot refresh `src/lib/gen/**/*.go`** — it just times out reporting unconfirmed. (`scripts/ghost_compile.ts` header says this outright.)

**PREFERENCE (owner, 2026-07-01): try `ghost-compile` FIRST, LocalGen is the FALLBACK.** When a live editor is up, `npm run ghost-compile` is the path to use — it's the real commit path and HMRs into the live editor. Only drop to LocalGen when there's no editor (or the editor is wedged). Don't reach for "recompile headless" by default.

**The browserless substitute: `scripts/LocalGen.spec.ts`.** Boots the FlockCompile machine (Story_cli + a minimal editor wiring), runs each `.g` through the REAL in-app translator (`Lang_compile_source_state` → `Lang_compile_dock`), reads the generated module off the dock's `%Compile/%Output.source`, and writes the REAL `src/lib/` + `Lies_gen_path(path)` (`gen/N/Reliable.go` → `src/lib/gen/N/Reliable.go`). Output is **byte-identical to ghost-compile's** (verified: 4 unchanged `.g` → matching char counts).

```
GFILES="Ghost/N/Peeroleum.g Ghost/N/Tribunal.g" \
  node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts
CHECK=1 …    # compile only, DON'T write — diff vs the committed .go (a safety gate)
```

This + `CredRunner.spec.ts` (acquire-spine Books headless) = the **full edit→compile→run→witness loop with ZERO browser**. The only difference from ghost-compile: LocalGen writes disk but does NOT HMR into a *live* runner — fine for CredRunner, which re-acquires the gen on every boot. For a live :9091 runner you still need the editor path (or reload).

Key mechanics if it ever breaks: the compiled text lives at `dock.o({Compile:1})[0].o({Output:1})[0].sc.source` (full, unless `H.c.mungOutputstring` is set — it isn't in this boot). `Lies_gen_path` only maps `*/Ghost/*.{g,…GEN_ABLE}` → `gen/…`. See [[headless-creduler-runner]], [[creduler-runner-architecture]], [[ghost-compile-after-g-round]].

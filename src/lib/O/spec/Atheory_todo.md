# Atheory_todo.md — the next rebuild of Housing (that's just A**)

A capture doc, not yet a plan — the owner has reached for this three times in one session
 (2026-08-28), which is the tell it wants its own plot:

- *"we have random lists of .go to include somewhere too... we really need to rethink how code
   loads onto the base Housing, shall surely be Atheory (the next rebuild of Housing thats just
    A**)"*
- *"perhaps we should redo the toplevel? must be a ton of crap built up now huh? could be so much
   simpler and easier to moonwalk through these such transpirings?"* — said while reading a boot
    log of the world-1-destroy → world-2-mount churn at storyFinished.

## 0. What this is about

Two irritations, probably one rebuild:

1. **Code loading is random lists.**  Which `.go` ghosts mount is scattered hardcoded lists
    (LocalGen's GFILES default list is the compile-side twin of the same disease — a list you
     forget to be on is a silent absence).  Atheory would make loading DECLARED — the base
      Housing (`A**`) knowing what belongs on it, legibly, the way everything else in the world
       is legible matter.
2. **The toplevel has built-up crap.**  The boot walks worlds it then destroys (the
    world-1→world-2 remount at storyFinished; BigSoundland's un-buffered `cyto` derive + keyser
     remount is furniture balanced on that churn).  A stranger's cold boot runs a 1-step toc and
      leaves `step_n` stranded at 1 forever — the whole cold-boot disease (Solo_todo bombs) is
       toplevel sediment.  A simpler toplevel would make those seams walkable ("easier to
        moonwalk through these such transpirings").

## Not yet

No design here yet — this doc exists so the itch has an address.  When it starts: inventory the
 actual load lists (LocalGen defaults, boot ghost mounts, GhostList), inventory what the toplevel
  actually does between page-load and commission, and only then propose the A** shape.

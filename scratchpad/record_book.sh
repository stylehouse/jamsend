#!/usr/bin/env bash
# record_book.sh BOOK NSTEPS SWEARFILE — bootstrap a Plan, record live snaps, declare swears.
# Assumes the runner was reloaded (cache cleared) beforehand by the caller.
set -u
BOOK="$1"; N="$2"; SWEARS="$3"
DIR="wormhole/Story/$BOOK"; RA="node scripts/runner_ask.mjs"
mkdir -p "$DIR"
{ echo "story:$BOOK"; echo "  Styles"; echo "  Plan"; echo "  Opt"; echo "    For"
  echo "  step,dige:0000000000000000"
  for i in $(seq 2 "$N"); do echo "  step=$i,dige:0000000000000000"; done; } > "$DIR/toc.snap"
rung(){ timeout 120 $RA run "$BOOK" --watch 2>&1 | grep -oE '"phase":"(done|failed)"[^}]*"done":[0-9]*|"ok_pct":[0-9.]*' | tail -2 | tr '\n' ' '; echo; }
green(){ for k in 1 2 3; do r=$(rung); echo "$r" | grep -q '"ok_pct":1' && { echo "$r"; return; }; done; echo "$r"; }
echo "[$BOOK] advance: $(rung)"
echo "[$BOOK] accept: $($RA accept 2>&1 | grep -oE '"accepting":[0-9]*')"
echo "[$BOOK] green: $(green)"          # completed run → sworn shelf full
while IFS= read -r s; do [ -z "$s" ] && continue; $RA declare "$s" >/dev/null 2>&1; done < "$SWEARS"
echo "[$BOOK] $($RA assertions 2>&1 | head -1)"
echo "[$BOOK] toc Assertions: $(grep -cE 'Assertion:' "$DIR/toc.snap")  snaps: $(ls "$DIR"/[0-9]*.snap 2>/dev/null | wc -l)"
$RA release >/dev/null 2>&1

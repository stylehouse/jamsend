#!/bin/sh
# check.sh — the health check. Answers: is the fix holding, and is it stuttering NOW?
#
#   sh check.sh            # one 5s sample
#   sh check.sh --watch    # keep sampling
#   sh check.sh 10         # 10s sample
#
# 2026-09-17: the FIRST version of this gated "is it playing" on pw-top's batch
#  table (state letter + column position). That table lied twice — showing
#  QUANT=0/state idle while /proc/asound simultaneously showed a real, open,
#  non-closed hw_params. So the primary truth now comes straight from the
#  kernel (/proc/asound), which has been correct every single time:
#   period_size — the ALSA driver's actual negotiated buffer, in frames. This IS
#                 pipewire's "quantum" as seen by the hardware — no table to parse.
#   status:RUNNING — the kernel's own word that samples are actively clocking out
#                 right now (vs. open-but-paused).
# pw-top's ERR is kept as a SECOND, best-effort opinion (still useful when it
#  works), never the gate.
SECS=5; WATCH=""
for a in "$@"; do case "$a" in --watch) WATCH=1;; [0-9]*) SECS=$a;; esac; done

once() {
  MINQ=$(pw-metadata -n settings 2>/dev/null | awk -F"'" '/clock.min-quantum/{print $4}')
  FORCEQ=$(pw-metadata -n settings 2>/dev/null | awk -F"'" '/clock.force-quantum/{print $4}')
  bad=0
  found=""

  for hp in /proc/asound/card*/pcm*p/sub*/hw_params; do
    [ -f "$hp" ] || continue
    grep -q closed "$hp" 2>/dev/null && continue
    found=1
    dir=$(dirname "$hp")
    fmt=$(awk -F': ' '/^format/{print $2}' "$hp")
    rate=$(awk -F': ' '/^rate/{print $2; exit}' "$hp" | awk '{print $1}')
    period=$(awk -F': ' '/^period_size/{print $2}' "$hp" | awk '{print $1}')
    state=$(awk -F': ' '/^state/{print $2}' "$dir/status" 2>/dev/null)

    ms=$(awk -v p="$period" -v r="$rate" 'BEGIN{ if (r>0) printf "%.1f", p/r*1000; else print "?" }')
    printf 'hw       %s  state=%s  period=%s frames (%sms)\n' "$fmt @ ${rate}Hz" "${state:-?}" "$period" "$ms"

    if [ "$state" != "RUNNING" ]; then
      echo "!! PCM is open but not RUNNING ($state) — is it actually playing, or just paused?"; bad=1
    elif [ -n "$period" ]; then
      if [ -n "$FORCEQ" ] && [ "$FORCEQ" != "0" ] && [ "$period" -lt "$FORCEQ" ]; then
        echo "!! period $period is BELOW the forced quantum $FORCEQ — force-quantum conf not loaded. run setup.sh"; bad=1
      elif [ -n "$MINQ" ] && [ "$period" -lt "$MINQ" ]; then
        echo "!! period $period is BELOW the floor $MINQ — quantum conf not loaded, or something is overriding it. run setup.sh"; bad=1
      fi
    fi
  done
  [ -n "$found" ] || echo "card     idle right now (no open PCM) — play something and re-run"

  # pw-top ERR — best-effort second opinion; label it as such since its own
  #  table has been unreliable before. A real ERR climb here IS worth trusting;
  #  a flat/blank read here is NOT proof of health on its own.
  S1=$(pw-top -b -n 1 2>/dev/null | awk 'NR>1 && $2 ~ /^[0-9]+$/ {print $2, $9, $NF}')
  sleep "$SECS"
  S2=$(pw-top -b -n 1 2>/dev/null | awk 'NR>1 && $2 ~ /^[0-9]+$/ {print $2, $9, $NF}')
  grew=$(printf '%s\n%s\n' "$S1" "$S2" | awk '
    { if ($1 in e1) { d=$2-e1[$1]; if (d>0) printf "  %-40s +%d\n", $3, d } else e1[$1]=$2 }')
  if [ -n "$grew" ]; then
    echo "!! pw-top ERR climbed in the last ${SECS}s (best-effort — real if it says so):"; echo "$grew"; bad=1
  else
    echo "xruns    pw-top ERR did not climb in ${SECS}s (best-effort reading)"
  fi

  return $bad
}

if [ -n "$WATCH" ]; then
  while :; do echo "── $(date +%T)"; once; sleep 1; done
else
  once
fi

#!/bin/sh
# check.sh — the health check. Answers: is the fix holding, and is it stuttering NOW?
#
#   sh check.sh            # one 5s sample
#   sh check.sh --watch    # keep sampling
#   sh check.sh 10         # 10s sample
#
# Reads three truths, no guessing:
#   QUANT   — the driver's live buffer. Must be >= min-quantum. If a client has
#             pulled it below, the floor conf isn't loaded → run setup.sh.
#   ERR Δ   — xruns that happened DURING this sample (pw-top's ERR is cumulative,
#             so a big static number is history; only a GROWING one is a stutter).
#   hw      — what the soundcard is actually clocking (/proc/asound), not what
#             PipeWire claims. Only readable while audio plays.
# Exit 0 = healthy, 1 = something to look at. Scriptable.
SECS=5; WATCH=""
for a in "$@"; do case "$a" in --watch) WATCH=1;; [0-9]*) SECS=$a;; esac; done

# pw-top -b: fields 1-9 are fixed single tokens, so $3=QUANT $4=RATE $9=ERR, safe
sample() { pw-top -b -n 1 2>/dev/null | awk 'NR>1 && $2 ~ /^[0-9]+$/ {print $2, $3, $4, $9, $NF}'; }

once() {
  MINQ=$(pw-metadata -n settings 2>/dev/null | awk -F"'" '/clock.min-quantum/{print $4}')
  S1=$(sample); sleep "$SECS"; S2=$(sample)
  bad=0

  # driver quantum vs floor
  echo "$S2" | grep alsa_output | while read -r id q r err name; do
    printf 'card     QUANT=%s RATE=%s  (%.1f ms)\n' "$q" "$r" "$(echo "$q $r" | awk '{print $1/$2*1000}')"
  done
  Q=$(echo "$S2" | awk '/alsa_output/{print $2; exit}')
  if [ -n "$Q" ] && [ -n "$MINQ" ] && [ "$Q" -lt "$MINQ" ]; then
    echo "!! quantum $Q is BELOW the floor $MINQ — floor conf not loaded. run setup.sh"; bad=1
  elif [ -n "$Q" ] && [ "$Q" -lt 1024 ]; then
    echo "!! quantum $Q — something pulled it down (pavucontrol meters? low-latency app?)"; bad=1
  fi

  # xrun delta per node over the sample
  grew=$(printf '%s\n%s\n' "$S1" "$S2" | awk '
    { if ($1 in e1) { d=$4-e1[$1]; if (d>0) printf "  %-40s +%d\n", $5, d } else e1[$1]=$4 }')
  if [ -n "$grew" ]; then
    echo "!! xruns in the last ${SECS}s (these ARE the stutters):"; echo "$grew"; bad=1
  else
    echo "xruns    none in ${SECS}s"
  fi

  # hardware truth
  for hp in /proc/asound/card*/pcm*p/sub*/hw_params; do
    [ -f "$hp" ] && ! grep -q closed "$hp" 2>/dev/null || continue
    awk -F': ' '/^format|^rate/{printf "%s=%s ", $1, $2} END{print ""}' "$hp" | sed 's/^/hw       /'
  done
  return $bad
}

if [ -n "$WATCH" ]; then
  while :; do echo "── $(date +%T)"; once; done
else
  once
fi

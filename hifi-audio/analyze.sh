#!/bin/sh
# analyze.sh — read gap-catch.sh's logs, print a verdict instead of raw dumps.
#
#   sh analyze.sh           # reads ~/gap-catch/
#
# What it does:
#   1. finds every ERR (xrun) tick in pwtop.log, timestamped to the second
#   2. for each tick, shows the shared-IRQ-18 line from irq.log at that second
#      (a jump there is a HINT it's IRQ-line contention, never proof — the
#      count is shared between i801_smbus and snd_ice1712, Linux does not
#      split it — but a jump correlated with EVERY tick is a strong lead)
#   3. lists any candidate ~1Hz pollers found up front (env.txt)
#   4. flags kernel/pipewire warnings that landed in the same second as a tick
IN="$HOME/gap-catch"
[ -d "$IN" ] || { echo "no $IN — run gap-catch.sh first"; exit 1; }

echo "== candidate pollers (from env.txt) =="
awk '/--- candidate/,/--- user systemd/' "$IN/env.txt" | sed '1d;$d' | grep -v '^$' || echo "  (none found)"
echo

echo "== xrun ticks (ERR grew) with the shared-IRQ-18 count at that second =="
# pwtop.log lines: [ts] S ID QUANT RATE WAIT BUSY W/Q B/Q ERR FORMAT... NAME
#  ts adds ONE leading token, so id=$3 err=$10 name=$NF (unaffected by the shift)
awk '
  { ts=$1; gsub(/\[|\]/,"",ts); sub(/\.[0-9]+$/,"",ts)
    id=$3; err=$10; name=$NF
    if (id ~ /^[0-9]+$/) {
      if (id in last) { d = err-last[id]; if (d>0) print ts, name, "+"d }
      last[id]=err
    }
  }' "$IN/pwtop.log" > /tmp/ticks.$$

if [ ! -s /tmp/ticks.$$ ]; then
  echo "  no ERR growth recorded — either it stayed clean, or gap-catch.sh wasn't running when it stuttered"
else
  n=0
  while read -r ts name delta; do
    n=$((n+1)); [ $n -gt 40 ] && { echo "  ... (more, truncated)"; break; }
    irqline=$(grep "^$ts " "$IN/irq.log" | head -1)
    printf '  %s  %-30s %s   irq18: %s\n' "$ts" "$name" "$delta" "${irqline#* }"
  done < /tmp/ticks.$$
  echo
  echo "  total ticks: $(wc -l < /tmp/ticks.$$)"
fi
rm -f /tmp/ticks.$$

echo
echo "== irq-18 count: min/max/spread over the whole session =="
awk '{print $2}' "$IN/irq.log" 2>/dev/null | sort -n | awk '
  NR==1{min=$1} {max=$1; sum++} END{ if(sum) print "  min="min" max="max" (n="sum" samples)" }'

echo
echo "== kernel/pipewire lines mentioning xrun/underrun/error =="
grep -hiE 'xrun|underrun|overrun|error|suspend|resume' "$IN/kernel.log" "$IN/pw-journal.log" 2>/dev/null | sort -u | head -30

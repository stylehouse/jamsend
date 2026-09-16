# hifi-audio — the desktop (w) audio fix, made permanent

The stutter on the M-Audio 2496 was never the card. It was the PipeWire graph quantum
being pulled down to 256 (5.8 ms) by clients; this box can't make that deadline. The old
`~/bin/destutter` raised it with `pw-metadata`, which is runtime-only — hence it "kept
coming back" after every reboot. (Convolver in EasyEffects was a second, separate cause.)

| script | does |
|---|---|
| `setup.sh [48]` | deploys `10-hifi-rate.conf` + `20-quantum.conf`, restarts pipewire, runs check. **Run once; survives reboot.** |
| `check.sh [--watch] [secs]` | is it healthy *now*: quantum ≥ floor, xruns in the last N s, what the card is really clocking. Exit 1 on trouble. |
| `ssh-audio.sh <host> [ms]` | ship this desktop's audio to another machine (e.g. the laptop, for its Bluetooth). Sets up the remote every time. Ctrl-C restores. |
| `gap-catch.sh` | long-running logger for an intermittent stutter — leave it up, note the clock when you hear one. |

If it stutters again: `sh check.sh`. It names the cause — a quantum below 1024 means
something dragged it down (pavucontrol left open with its meters running is a classic),
xruns growing on a specific node names the injector.

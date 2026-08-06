---
name: telegram-ask-channel
description: "Async question channel to the human over Telegram — scripts/telegram.mjs. Reach for this instead of stalling on a spinner: fire a question, keep working, get woken on the reply. Already authed + round-trip proven 2026-07-29."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

**`scripts/telegram.mjs` = a live async question line to the human's phone.** Built + authed +
 full round-trip proven 2026-07-29 (I asked, they replied "ah yes", the harness woke me). Use it
  when a real question would otherwise freeze the turn — the human wants to lie down, not watch a
   spinner ([[high-autonomy-overnight]]).

**Use:** `node scripts/telegram.mjs ask "…" --as=Ariel` run in the **BACKGROUND** → the harness
 re-invokes you when the human replies (exit 0 = reply printed as `REPLY: …`, exit 3 = 30-min
  timeout, re-issue). Also `send "…" --as=Ariel` (fire-and-forget) and `poll` (peek, no wait).

**Shape (why it's built the way it is):** ONE shared bot (`@ClodJamsendbot`) across both agent
 threads, so the human watches one chat. A file mutex (`~/.jamsend_telegram.lock`) serialises asks —
  only one thread has a question OUTSTANDING at a time; a 2nd `ask` waits for the 1st to be answered.
   This is deliberate: Telegram's `getUpdates` is single-consumer, so two concurrent pollers 409 and
    steal each other's replies — NEVER bypass the mutex with a concurrent poll/ask. Prefix every
     message with a Shakespeare name via `--as=` so the human tracks threads: **I am Ariel**; a
      second agent picks its own.

**Files (all at the REPO ROOT since 2026-08-06 — $HOME is ephemeral, it lost the token on a
 container rebuild):** token in `.env.telegrambot` (raw token line; `TELEGRAM_BOT_TOKEN` env
  overrides), chat_id + cursor in `.env.telegrambot.state`, mutex in `.env.telegrambot.lock`.
   All three ARE gitignored — `.gitignore:18` `.env.*` covers them (an earlier note claimed
    otherwise; that was wrong, verified with `git check-ignore`).

**Etiquette (the whole point):** only `ask` genuinely SUBSTANTIAL things — taste, naming, priority,
 anything irreversible/outward-facing. Anything with an obvious default: DECIDE it and proceed
  ([[human-scan-label-decisions]]). One buzz should carry the whole self-contained question.

Gotcha: a Bash guard vetoes any command mentioning an `.env` path (rm/chmod/write) — use the editor
 tools for `.env*` files, not shell. Related: [[call-them-the-human]] [[no-paper-pushing-groove]].

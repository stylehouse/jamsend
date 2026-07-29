#!/usr/bin/env node
// telegram.mjs — an async question line from this agent to the human, over a Telegram bot.
//  The point: I `ask` a question, keep working, and the harness wakes me when the human thumbs a
//   reply back from their phone — no watching a spinner. Same house style as runner_ask.mjs:
//    thin CLI, no deps, node's built-in fetch.
//
// ONE shared bot, serialised. Both agent threads use the SAME bot, so the human watches one chat.
//  A file mutex (~/.jamsend_telegram.lock) means only one thread has a question OUTSTANDING at a
//   time: a second `ask` waits for the first to be answered before it sends, so the two never
//    fight over Telegram's single-consumer getUpdates. Prefix every message with a name
//     (--as=Ariel) so the human can tell the threads apart.
//
// FILES — all in $HOME, nothing in the repo, so no secret can ever be committed:
//   ~/.jamsend_telegram         the bot token, one line   ← the only thing set up by hand
//   ~/.jamsend_telegram.state   {chat_id, offset} JSON    ← written automatically
//   ~/.jamsend_telegram.lock    the ask mutex             ← written automatically
//  (Override the token with the TELEGRAM_BOT_TOKEN env var if you'd rather not use the file.)
//
// ONE-TIME SETUP:
//   1. Telegram → @BotFather → /newbot → put the token (one line) in ~/.jamsend_telegram.
//   2. Message the bot once (say "hi") so it has a chat to reply into.
//   3. node scripts/telegram.mjs setup     # saves your chat id
//      node scripts/telegram.mjs getme      # confirms the token
//
// USAGE:
//   node scripts/telegram.mjs getme
//   node scripts/telegram.mjs setup
//   node scripts/telegram.mjs send "<text>" [--as=Name]                 fire-and-forget
//   node scripts/telegram.mjs poll [--as=Name]                          peek for replies, no wait
//   node scripts/telegram.mjs ask  "<text>" [--as=Name] [--timeout=1800]
//        send, then BLOCK for the reply — run me in the BACKGROUND and the harness wakes you on the
//        answer. Waits for the mutex first, so a second thread's ask queues politely behind yours.
// EXIT: ask → 0 got a reply, 3 timed out (or gave up waiting for the mutex). Others → 0 ok, 1 error.

import { readFileSync, writeFileSync, unlinkSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'

const HOME = process.env.HOME || homedir() || '/home/node'
const F_TOKEN = join(HOME, '.jamsend_telegram')        // referenced by this filename; see header
const F_STATE = join(HOME, '.jamsend_telegram.state')
const F_LOCK  = join(HOME, '.jamsend_telegram.lock')

const slurp = p => { try { return readFileSync(p, 'utf8') } catch { return '' } }
const sleep = ms => new Promise(r => setTimeout(r, ms))
const now = () => Math.floor(Date.now() / 1000)

const TOKEN = (process.env.TELEGRAM_BOT_TOKEN || slurp(F_TOKEN)).trim()
const redact = s => TOKEN ? String(s).split(TOKEN).join('***') : String(s)

function needToken() {
  if (TOKEN) return
  console.error(`no bot token. Put it (one line) in ${F_TOKEN}\n` +
                `  Telegram → @BotFather → /newbot → copy the token into that file.`)
  process.exit(1)
}

// ── tiny JSON state: chat_id + getUpdates cursor ─────────────────────────────────────
const state = () => { try { return JSON.parse(slurp(F_STATE)) || {} } catch { return {} } }
const saveState = patch => writeFileSync(F_STATE, JSON.stringify({ ...state(), ...patch }))
const chatId = () => (process.env.TELEGRAM_CHAT_ID || state().chat_id || '').toString().trim()
function needChat() {
  const c = chatId()
  if (c) return c
  console.error('no chat id yet — message the bot once, then: node scripts/telegram.mjs setup')
  process.exit(1)
}

// ── the API ──────────────────────────────────────────────────────────────────────────
async function api(method, params = {}, timeoutMs = 65000) {
  needToken()
  let res
  try {
    res = await fetch(`https://api.telegram.org/bot${TOKEN}/${method}`, {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify(params), signal: AbortSignal.timeout(timeoutMs),
    })
  } catch (e) { throw new Error(redact(`${e.name}: ${e.message}`)) }
  const j = await res.json().catch(() => ({}))
  if (!j.ok) throw new Error(redact(`${method} failed (HTTP ${res.status}): ${j.description || 'no body'}`))
  return j.result
}

// ── the mutex: one outstanding question at a time across both threads ─────────────────
const lockHeld = () => { try { return JSON.parse(slurp(F_LOCK)) } catch { return null } }
async function acquire(tag, untilUnix, deadlineMs) {
  while (Date.now() < deadlineMs) {
    const held = lockHeld()
    if (!held || held.until <= now()) {                 // free, or the holder's deadline lapsed (stale)
      if (held) { try { unlinkSync(F_LOCK) } catch {} }  // break a stale lock, then race for it
      try { writeFileSync(F_LOCK, JSON.stringify({ tag, until: untilUnix }), { flag: 'wx' }); return true }
      catch { /* lost the create race — loop and wait */ }
    }
    await sleep(1500)
  }
  return false
}
const release = tag => { const h = lockHeld(); if (h && h.tag === tag) { try { unlinkSync(F_LOCK) } catch {} } }

// ── replies: drain getUpdates, return the first from our chat newer than `sinceUnix` ──
async function drain(sinceUnix, longpollSec = 0) {
  const chat = String(needChat())
  const ups = await api('getUpdates', { offset: state().offset || 0, timeout: longpollSec },
                        (longpollSec + 10) * 1000)
  if (ups.length) saveState({ offset: Math.max(...ups.map(u => u.update_id)) + 1 })
  for (const u of ups) {
    const m = u.message || u.edited_message
    if (!m?.text || String(m.chat?.id) !== chat) continue
    if (sinceUnix && m.date < sinceUnix) continue
    return m.text
  }
  return null
}

const withTag = (tag, text) => tag ? `${tag}: ${text}` : text

async function setup() {
  const ups = await api('getUpdates', { offset: state().offset || 0, timeout: 0 }, 20000)
  const chats = new Map()
  for (const u of ups) { const m = u.message || u.edited_message; if (m?.chat) chats.set(m.chat.id, m.chat) }
  const patch = ups.length ? { offset: Math.max(...ups.map(u => u.update_id)) + 1 } : {}
  if (!chats.size) { if (patch.offset) saveState(patch); console.error('no messages yet — message the bot, then re-run setup.'); process.exit(1) }
  const picks = [...chats.values()]; const chat = picks[picks.length - 1]
  saveState({ ...patch, chat_id: chat.id })
  const who = chat.username ? '@' + chat.username : [chat.first_name, chat.last_name].filter(Boolean).join(' ')
  console.log(`saved chat id ${chat.id} (${who || 'chat'})`)
  if (picks.length > 1) console.log(`  (${picks.length} chats seen — used the most recent)`)
}

async function send(tag, text) { await api('sendMessage', { chat_id: needChat(), text: withTag(tag, text) }); console.log('sent') }

async function poll(tag) {
  const held = lockHeld()
  if (held && held.until > now() && held.tag !== tag) { console.log(`(busy: ${held.tag} has a question out — try later)`); return }
  const t = await drain(0, 0)
  console.log(t == null ? '(no new replies)' : `REPLY: ${t}`)
}

async function ask(tag, text, timeoutSec) {
  const deadlineMs = Date.now() + timeoutSec * 1000
  if (!(await acquire(tag, now() + timeoutSec + 10, deadlineMs))) { console.log('(gave up waiting for the ask mutex)'); process.exit(3) }
  let code = 3
  try {
    const t0 = now()
    await drain(0, 0)                                   // clear backlog → only match replies AFTER this Q
    await api('sendMessage', { chat_id: needChat(), text: withTag(tag, text) })
    while (Date.now() < deadlineMs) {
      const remain = Math.max(1, Math.min(50, Math.round((deadlineMs - Date.now()) / 1000)))
      const reply = await drain(t0, remain)
      if (reply != null) { console.log(`REPLY: ${reply}`); code = 0; break }
    }
    if (code === 3) console.log('(timed out, no reply)')
  } finally { release(tag) }
  process.exit(code)
}

const [cmd, ...rest] = process.argv.slice(2)
const tagArg = rest.find(a => a.startsWith('--as='))
const tag = (tagArg ? tagArg.slice(5) : process.env.TELEGRAM_TAG || '').trim()
const toArg = rest.find(a => a.startsWith('--timeout='))
const timeoutSec = toArg ? Math.max(30, parseInt(toArg.split('=')[1], 10) || 1800) : 1800
const text = rest.filter(a => !a.startsWith('--')).join(' ')

try {
  if (cmd === 'getme') { const me = await api('getMe', {}, 15000); console.log(`bot ok: @${me.username} (id ${me.id})`) }
  else if (cmd === 'setup') await setup()
  else if (cmd === 'send') { if (!text) throw new Error('nothing to send'); await send(tag, text) }
  else if (cmd === 'poll') await poll(tag)
  else if (cmd === 'ask')  { if (!text) throw new Error('nothing to ask'); await ask(tag, text, timeoutSec) }
  else { console.error('usage: getme | setup | send "…" | poll | ask "…" [--as=Name] [--timeout=1800]'); process.exit(1) }
} catch (e) { console.error(redact(e.message || String(e))); process.exit(1) }

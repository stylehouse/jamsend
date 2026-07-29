#!/usr/bin/env node
// telegram.mjs — async question channel between this agent and the human.
//  So the human can go lie down: I `ask` a question, keep churning, and get woken when they reply.
//  Same spirit as runner_ask.mjs — a thin CLI over an API, no deps, node's built-in fetch.
//
// SECRETS live OUTSIDE the repo, in $HOME (never committed, never printed):
//   ~/.telegram_bot_token   the BotFather token   (env TELEGRAM_BOT_TOKEN overrides; chmod 600)
//   ~/.telegram_chat_id      the human's chat id   (env TELEGRAM_CHAT_ID overrides; written by `setup`)
//   ~/.telegram_offset       getUpdates cursor     (managed automatically)
//
// FIRST-TIME AUTH (the "auth you as a bot" dance):
//   1. Telegram → @BotFather → /newbot → copy the token.
//   2. Drop the token in place (run with the ! prefix so it lands in this container):
//        printf %s 'PASTE_TOKEN' > ~/.telegram_bot_token && chmod 600 ~/.telegram_bot_token
//   3. Message your new bot once (say "hi") so it has a chat to reply into.
//   4. node scripts/telegram.mjs setup     # discovers + saves your chat id
//      node scripts/telegram.mjs getme      # confirms the token
//
// USAGE:
//   node scripts/telegram.mjs getme                 liveness: prints the bot's @username
//   node scripts/telegram.mjs setup                 discover + save your chat id from recent messages
//   node scripts/telegram.mjs set-chat <id>         set the chat id by hand
//   node scripts/telegram.mjs send   "<text>"       fire-and-forget message
//   node scripts/telegram.mjs poll                  print any unread replies, don't wait
//   node scripts/telegram.mjs ask    "<text>" [--timeout=1800]
//                                                   send, then BLOCK (long-poll) until a reply — run me
//                                                   in the background and the harness wakes on the answer.
// EXIT: ask → 0 got a reply, 3 timed out. Others → 0 ok, 1 error.

import { readFileSync, writeFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join, dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const HOME = process.env.HOME || homedir() || '/home/node'
const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url))
const REPO = join(SCRIPT_DIR, '..')
// dotenv path — TELEGRAM_ENV_FILE (repo-relative or absolute) lets a 2nd agent point at its OWN
//  .env.telegrambot2 (also gitignored by .env.*); its bot state auto-separates below, so two
//   agents on two bots never collide on cursor or chat.
const F_ENV   = process.env.TELEGRAM_ENV_FILE ? resolve(REPO, process.env.TELEGRAM_ENV_FILE)
                                              : join(REPO, '.env.telegrambot')
const F_TOKEN = join(HOME, '.telegram_bot_token')          // legacy raw-token fallback

const slurp = p => { try { return readFileSync(p, 'utf8').trim() } catch { return '' } }
const dotenv = p => { // minimal KEY=value reader (strips quotes + trailing " # comment")
  const out = {}
  for (const raw of slurp(p).split('\n')) {
    const m = raw.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/)
    if (!m) continue
    let v = m[2].trim().replace(/\s+#.*$/, '').trim()
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1)
    out[m[1].toUpperCase()] = v
  }
  return out
}
const ENV = dotenv(F_ENV)

const TOKEN = (process.env.TELEGRAM_BOT_TOKEN || ENV.TELEGRAM_BOT_TOKEN || slurp(F_TOKEN)).trim()
// per-bot state, keyed by the non-secret numeric bot id, so multiple bots coexist without clashing
const BOTID = (TOKEN.split(':')[0] || 'default').replace(/[^0-9A-Za-z]/g, '')
const F_CHAT = join(HOME, `.telegram_chat_${BOTID}`)
const F_OFF  = join(HOME, `.telegram_offset_${BOTID}`)
const F_CHAT_LEGACY = join(HOME, '.telegram_chat_id')   // pre-keying fallback (primary bot)
const F_OFF_LEGACY  = join(HOME, '.telegram_offset')
const redact = s => TOKEN ? String(s).split(TOKEN).join('***') : String(s)

function needToken() {
  if (TOKEN) return
  console.error(`no bot token. Put TELEGRAM_BOT_TOKEN=... in ${F_ENV} (or set the env var).\n` +
                `  Telegram → @BotFather → /newbot → copy token, then:\n` +
                `  printf 'TELEGRAM_BOT_TOKEN=%s\\n' 'PASTE_TOKEN' > ${F_ENV} && chmod 600 ${F_ENV}`)
  process.exit(1)
}

async function api(method, params = {}, timeoutMs = 65000) {
  needToken()
  let res
  try {
    res = await fetch(`https://api.telegram.org/bot${TOKEN}/${method}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(params),
      signal: AbortSignal.timeout(timeoutMs),
    })
  } catch (e) { throw new Error(redact(`${e.name}: ${e.message}`)) }
  const j = await res.json().catch(() => ({}))
  if (!j.ok) throw new Error(redact(`${method} failed (HTTP ${res.status}): ${j.description || 'no body'}`))
  return j.result
}

const readOffset = () => { const n = parseInt(slurp(F_OFF) || slurp(F_OFF_LEGACY), 10); return Number.isFinite(n) ? n : 0 }
const bumpOffset = ups => {
  if (!ups?.length) return
  const hi = Math.max(...ups.map(u => u.update_id))
  writeFileSync(F_OFF, String(hi + 1))
}
const chatId = () => (process.env.TELEGRAM_CHAT_ID || ENV.TELEGRAM_CHAT_ID || slurp(F_CHAT) || slurp(F_CHAT_LEGACY)).trim()

function needChat() {
  const c = chatId()
  if (c) return c
  console.error(`no chat id. Message your bot once, then: node scripts/telegram.mjs setup`)
  process.exit(1)
}

async function getme() {
  const me = await api('getMe', {}, 15000)
  console.log(`bot ok: @${me.username} (${me.first_name}, id ${me.id})`)
}

async function setup() {
  const ups = await api('getUpdates', { offset: readOffset(), timeout: 0 }, 20000)
  const chats = new Map()
  for (const u of ups) { const m = u.message || u.edited_message; if (m?.chat) chats.set(m.chat.id, m.chat) }
  bumpOffset(ups)
  if (!chats.size) {
    console.error('no messages yet — open your bot in Telegram and send it anything, then re-run setup.')
    process.exit(1)
  }
  const picks = [...chats.values()]
  const chat = picks[picks.length - 1]
  writeFileSync(F_CHAT, String(chat.id))
  const who = chat.username ? '@' + chat.username : [chat.first_name, chat.last_name].filter(Boolean).join(' ')
  console.log(`saved chat id ${chat.id} (${who || 'chat'}) → ${F_CHAT}`)
  if (picks.length > 1) console.log(`  (${picks.length} chats seen; used the most recent — override with set-chat <id>)`)
}

async function send(text) {
  const chat = needChat()
  await api('sendMessage', { chat_id: chat, text })
  console.log('sent')
}

// drain + print any replies from our chat newer than `sinceUnix`; returns the first matching text or null
async function drain(sinceUnix, longpollSec = 0) {
  const chat = String(needChat())
  const ups = await api('getUpdates', { offset: readOffset(), timeout: longpollSec },
                        (longpollSec + 10) * 1000)
  bumpOffset(ups)
  for (const u of ups) {
    const m = u.message || u.edited_message
    if (!m?.text) continue
    if (String(m.chat?.id) !== chat) continue
    if (sinceUnix && m.date < sinceUnix) continue
    return m.text
  }
  return null
}

async function poll() {
  const t = await drain(0, 0)
  console.log(t == null ? '(no new replies)' : `REPLY: ${t}`)
}

async function ask(text, timeoutSec) {
  const now = Math.floor(Date.now() / 1000)
  // baseline: clear the backlog so we only match replies AFTER this question
  await drain(0, 0)
  await api('sendMessage', { chat_id: needChat(), text })
  const deadline = Date.now() + timeoutSec * 1000
  while (Date.now() < deadline) {
    const remain = Math.max(1, Math.min(50, Math.round((deadline - Date.now()) / 1000)))
    const reply = await drain(now, remain)
    if (reply != null) { console.log(`REPLY: ${reply}`); process.exit(0) }
  }
  console.log('(timed out, no reply)')
  process.exit(3)
}

const [cmd, ...rest] = process.argv.slice(2)
const timeoutArg = rest.find(a => a.startsWith('--timeout='))
const timeoutSec = timeoutArg ? parseInt(timeoutArg.split('=')[1], 10) : 1800
const text = rest.filter(a => !a.startsWith('--')).join(' ')

try {
  if (cmd === 'getme') await getme()
  else if (cmd === 'setup') await setup()
  else if (cmd === 'set-chat') { writeFileSync(F_CHAT, String(rest[0] || '').trim()); console.log(`chat id set → ${F_CHAT}`) }
  else if (cmd === 'send') { if (!text) throw new Error('nothing to send'); await send(text) }
  else if (cmd === 'poll') await poll()
  else if (cmd === 'ask') { if (!text) throw new Error('nothing to ask'); await ask(text, timeoutSec) }
  else { console.error('usage: getme | setup | set-chat <id> | send "…" | poll | ask "…" [--timeout=1800]'); process.exit(1) }
} catch (e) { console.error(redact(e.message || String(e))); process.exit(1) }

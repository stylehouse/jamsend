// Emojiconfirm — the SAS (short authentication string) brick for LinkDevice.
// Both bodies feed the SAME transcript (their two pubkeys + the sealed-channel
// salt, in a fixed order) through here and READ ALOUD the emoji row to a human.
// Matching rows ⇒ no MITM sat between them; a spliced transcript diverges.
// Pure + deterministic: sha256 of the transcript, folded to a fixed alphabet.
// No key material leaves — the emojis are a fingerprint, not a secret.

import { sha256, dehex } from '$lib/Y.svelte'

// 64 wide, visually distinct glyphs — one clean draw per 6 bits, no near-twins.
const SAS_ALPHABET = [
    '🐶', '🐱', '🦊', '🐻', '🐼', '🐨', '🦁', '🐯',
    '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🦉', '🦆',
    '🦅', '🦋', '🐝', '🐢', '🐙', '🦀', '🐬', '🐳',
    '🦖', '🌵', '🌲', '🍀', '🌸', '🌻', '🍁', '🍄',
    '🍎', '🍌', '🍒', '🍇', '🍉', '🍑', '🥕', '🌽',
    '🍞', '🧀', '🍕', '🍔', '🌮', '🍦', '🍩', '🍪',
    '⚽', '🏀', '🎸', '🎺', '🎻', '🥁', '🎨', '🎲',
    '🚗', '🚀', '⛵', '⚓', '💡', '🔑', '⭐', '🌙',
]

// Join the ordered parts into one transcript string. The order is the contract:
// both sides MUST agree on it (sorted pubkeys keeps it symmetric).
export function sas_transcript(parts: string[]): string {
    return parts.join('|')
}

// transcript -> `count` emojis. Reads whole bytes off the sha256 digest and
// masks to 6 bits, so two beacons agree iff their transcripts are byte-equal.
export async function sas_emojis(transcript: string, count = 6): Promise<string[]> {
    let hex = await sha256(transcript)
    let bytes = dehex(hex)
    let out: string[] = []
    for (let i = 0; i < count; i++) out.push(SAS_ALPHABET[bytes[i % bytes.length] & 63])
    return out
}

// Convenience: the spoken row as one spaced string.
export async function sas_row(transcript: string, count = 6): Promise<string> {
    return (await sas_emojis(transcript, count)).join(' ')
}

// Both sides confirm equality by comparing rows — never by comparing pubkeys
// directly (that is what a MITM would forge). Constant-shape string compare.
export function sas_agree(a: string, b: string): boolean {
    return a.length > 0 && a === b
}

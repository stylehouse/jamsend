// CpuLegs.svelte.ts — opt-in CPU-attribution experiment for the Lies+Lang UI panels.
//
// Cycles through a fixed list of "legs", each hiding a different panel Otro would normally
// mount from house.UIs (Otro.svelte's `{#each house.UIs.ob({UI:1})}` loop) — so a human
// watching an external CPU meter (OS Activity Monitor / browser Task Manager) can read one
// number per leg and attribute steady-state CPU to a specific panel by wall-clock alignment.
// The core House think-loop keeps running in every leg (this only stops PANELS from
// mounting) — a leg going quiet doesn't mean the belief loop is idle, only that that panel
// isn't drawing/holding decorations/animating on top of it. See Perf_todo.md §5 "the
// reactive fan-out" for why panel-mount cost is a distinct question from engine cost.
//
// Fully inert unless armed via ?cpu_legs=1 (or ?cpu_legs=<ms> for a custom per-leg
// duration) — never touches default boot. Console-logs every leg transition with a
// timestamp so a screen recording / CPU-log export can be lined up after the fact.
import { boot_param } from "$lib/boot"

export type CpuLeg = { key: string; label: string; hide: string[] }

// `hide` entries match the `UI` key panels register under via `uis.oai({UI:'<key>'}, ...)`
// (Cyto.svelte, Lang.svelte, Story.svelte, Lies.svelte, LiesLies.svelte/LiesRun.svelte).
export const CPU_LEGS: CpuLeg[] = [
    { key: 'baseline',     label: 'baseline — everything on',            hide: [] },
    { key: 'no-cyto',      label: 'Cyto graph hidden',                   hide: ['Cyto'] },
    { key: 'no-langui',    label: 'Lang editor (CodeMirror) hidden',     hide: ['Langui'] },
    { key: 'no-liesui',    label: 'Lies dock list hidden',               hide: ['Lies'] },
    { key: 'no-storui',    label: 'Story runner UI hidden',              hide: ['Story'] },
    { key: 'no-pantheate', label: 'Pantheate run previews hidden',       hide: ['Pantheate-include'] },
    { key: 'all-hidden',   label: 'ALL of the above hidden at once',     hide: ['Cyto', 'Langui', 'Lies', 'Story', 'Pantheate-include'] },
    { key: 'baseline-2',   label: 'baseline again — drift/sanity check', hide: [] },
]

const param = boot_param('cpu_legs')
export const CPU_LEGS_ARMED = param != null

const LEG_MS = (() => {
    const n = Number(param)
    return Number.isFinite(n) && n > 0 ? n : 45_000   // 45s/leg × 8 legs ≈ 6 min, full cycle
})()

let leg_i = $state(0)
let leg_started_at = $state(0)

export function cpu_leg_current(): CpuLeg { return CPU_LEGS[leg_i] }
export function cpu_leg_index(): number { return leg_i }
export function cpu_leg_ms(): number { return LEG_MS }
export function cpu_leg_started_at(): number { return leg_started_at }

// Called from Otro's `{#each}` for every registered UI — `ui_key` is `uiC.sc.UI`.
export function cpu_leg_hides(ui_key: string): boolean {
    return CPU_LEGS_ARMED && CPU_LEGS[leg_i].hide.includes(ui_key)
}

let timer: ReturnType<typeof setInterval> | null = null

function announce() {
    console.log(`[cpu-legs] leg ${leg_i + 1}/${CPU_LEGS.length} — ${CPU_LEGS[leg_i].label}  (${new Date().toLocaleTimeString()})`)
}

// Idempotent — safe to call from every CpuLegBanner instance's onMount (StrictMode-ish
// double-mount, HMR) without doubling the timer.
export function cpu_legs_start(): void {
    if (!CPU_LEGS_ARMED || timer) return
    leg_started_at = Date.now()
    announce()
    timer = setInterval(() => {
        leg_i = (leg_i + 1) % CPU_LEGS.length
        leg_started_at = Date.now()
        announce()
    }, LEG_MS)
}

// glass_kinds — the registry of FACES the glass can mount: a particle wearing sc.face:'<Kind>'
//  — or one whose mainkey the viewer imposes a face on (FACE_MAINKEYS, glass_faces.ts) —
//   gets the mapped Svelte component mounted in its node overlay (Cytui create_face_overlay),
//    earns a voronoi cell like a Stuffing does, and is molded into its cell by paint_final.
//  The FUNK_KINDS pattern (Funk/kinds.ts) worn by the glass: mainkey stays the particle's TYPE;
//   sc.face is a display request, never identity.  Props contract: { n: TheC, H: House } — the
//    live particle plus the House (imperative mount has no Svelte context; react off H.version).
//  Cyto.svelte must NEVER import this file (components need a DOM; the headless spine loads
//   Cyto without one) — the component-free half it needs lives in glass_faces.ts.
import RadioFace from './ui/RadioFace.svelte'
import StokerFace from './ui/StokerFace.svelte'
import TunerFace from './ui/TunerFace.svelte'
import CaperFace from './ui/CaperFace.svelte'
import HeistFace from './ui/HeistFace.svelte'
import HeistBarFace from './ui/HeistBarFace.svelte'
import HaulFace from './ui/HaulFace.svelte'
import PickFace from './ui/PickFace.svelte'
import DiagFace from './ui/DiagFace.svelte'
import ErrlogFace from './ui/ErrlogFace.svelte'
import TransferFace from './ui/TransferFace.svelte'
import SupervisorFace from './ui/SupervisorFace.svelte'
import DoorFace from './ui/DoorFace.svelte'
import RiffleFace from './ui/RiffleFace.svelte'
import RiffFace from './ui/RiffFace.svelte'
import ZineFace from './ui/ZineFace.svelte'
import LineupFace from './ui/LineupFace.svelte'
import ShuffleFace from './ui/ShuffleFace.svelte'
import CrateFace from './ui/CrateFace.svelte'
import UptimeFace from './ui/UptimeFace.svelte'
import BeatFace from './ui/BeatFace.svelte'
import TreeFace from './ui/TreeFace.svelte'
import LinkFace from './ui/LinkFace.svelte'

export const GLASS_KINDS: Record<string, any> = {
    Beat: BeatFace,       // the session HUD — beat N/7 + the live countdown for the wait we're in
    Uptime: UptimeFace,   // the live heartbeat — how long this tab's been alive, ticks every second
    Radio: RadioFace,     // the continuous listen — play/pause/skip, now-playing
    Stoker: StokerFace,   // the provisioning organ — watch the digs crank, poke a churn
    Tuner: TunerFace,     // the glass's dial — which crews of cells are shown
    Caper: CaperFace,     // the OPERATION — posed needs | soft wish → leads → take → the built pull
    Heist: HeistFace,     // ONE NAB OF AN ALBUM — the ⇊ keep cell: folder nodes, tweak genre, folds down on start
    HeistBar: HeistBarFace, // a NESTED heist's controls cell — genre · dest · all|none · ▶ start · ✕ · progress
    Pick: PickFace,       // one kept track chip in a nested keep — ✓/♪/⇊, click un-keeps
    Hauls: HaulFace,      // WHAT HEISTED — the albums that actually landed, newest first (reads the newlyadded ledger)
    Diag: DiagFace,       // the diagnostics toggle — reveals/hides beat·uptime·door; grabs attention when open
    Errlog: ErrlogFace,   // the Story error channel — calm ✓ green empty, RED w/ count+latest lines when a throw landed
    Supervisor: SupervisorFace, // the ONE sanity cell — quiet when healthy, loud with the worst thing when not
    Transfer: TransferFace,// the LIVE transfer HUD — jiggling rx/tx bars + per-track pull/serve progress + freed
    Door: DoorFace,       // who am I + who's with me — identity, landings, pulse liveness
    Link: LinkFace,       // the device-link ceremony (copy this account to a Cave) — its own takeover cell
    Riffle: RiffleFace,   // rifle a collection — the deck: crates, folders, deal/sweep
    Riff: RiffFace,       // one dealt card — a track (▶ tunes) or a folder (open descends)
    Zine: ZineFace,       // the pocket mag (Faves Berth) — its cards listed, ▶ auditions
    Lineup: LineupFace,   // the standing programme — up next (~20 deep), starve errors RED
    Shuffle: ShuffleFace, // the shuffle POOL — one pip per record in reach, lit = the dial can pick it
    Crate: CrateFace,     // a Musu home — the records spread out on the bed, ▶ auditions
    // the FACELESS face: draws whatever particle it is handed — mainkey, scalars, children, recursively.
    //  Every entry above knows what its thing MEANS and draws that; this one knows nothing and draws the
    //   C data itself, so a part of the tree nobody has designed a face for is still legible in the glass.
    Tree: TreeFace,
}
// HMR NOTE (2026-08-07): this file's only importer is Vytui.svelte, so it is hot-updatable ONLY while
//  Vytui stays self-accepting.  Vytui carried a `<script module>` block (a two-line debug serial) and
//   vite-plugin-svelte refuses HMR to any component with module-context state — which made Vytui a dead
//    end and this file a full-page reload on every edit, killing the player tabs' AudioContext.  Measured
//     both ways on the live pair: same one-line edit wiped the mirror crate before the fix, left it
//      standing (31 records, own shelf still climbing) after.  Don't reintroduce a module block here.

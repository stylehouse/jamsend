// flock bot — Cluster_spec §4.
//   Babysits ONE Chrome (via its Selenium droid) booted at the app as an
//    ?I=<cluster>-<n> idle runner. The tab auto-acquires the spine (Creduler),
//     binds to the relay, and idles awaiting %Rungo. The bot is a babysitter, not a
//      driver — the run authority is %Rungo over the relay, observed out-of-band via
//       scripts/runner_ask.mjs (which addresses runners by pub once the signed hello
//        ships — Cluster_spec §3.2). On a crash the bot rebuilds the session: a
//         graceful self-heal, since the runner's Idento persists in the mounted
//          profile and runs live in durable Storyrun records elsewhere, so the
//           reborn tab re-binds + re-announces and loses no work.
const { Builder } = require('selenium-webdriver')
const chrome = require('selenium-webdriver/chrome')

const seleniumUrl = process.env.SELENIUM_REMOTE_URL || 'http://localhost:4444/wd/hub'
const targetBase  = process.env.TARGET_BASE || 'http://host.docker.internal:9091'
const cluster     = process.env.CLUSTER || 'flock'
const runnerN     = process.env.RUNNER_N || '1'
const tag         = `${cluster}-${runnerN}`
// ?I=<tag> ALONE boots an idle runner on the grid (no ?B=) — the tag keys the forked
//  Idento (§3.1). &remoteWormhole=1 acquires disk access from a trusted editor via the
//   grant protocol (no VNC needed — the grant button is in the editor's Rundar rack).
const url         = `${targetBase}/?I=${encodeURIComponent(tag)}&remoteWormhole=1`
const HEARTBEAT_MS = 15 * 1000
let driver = null

async function initDriver() {
    const options = new chrome.Options()
    const display = process.env.DISPLAY || ':99.0'
    // No --user-data-dir: Chromium uses its default ~/.config/chromium, which lives in
    //  a named volume the droid mounts at /home/seluser/.config — that path already exists
    //   in the image owned by seluser, so Docker initialises the volume with the right
    //    ownership (no root-owned dir, no "cannot create default profile directory" error).
    //   Singleton lock cleanup (from an unclean exit) is handled by the prefs we inject:
    //    exit_type:Normal + exited_cleanly:true convinces Chrome it shut down cleanly.
    for (const a of [
        `--display=${display}`,
        '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
        '--disable-software-rasterizer', '--disable-features=VizDisplayCompositor',
        '--force-device-scale-factor=1', '--hide-crash-restore-bubble',
        '--use-fake-ui-for-media-stream',
    ]) options.addArguments(a)
    options.setUserPreferences({ exit_type: 'Normal', exited_cleanly: true,
        'profile.default_content_settings.popups': 0 })
    driver = await new Builder()
        .forBrowser('chrome').setChromeOptions(options).usingServer(seleniumUrl).build()
    await driver.get(url)
    console.log(`[${tag}] chrome up → ${url}`)
    return driver
}

async function alive() {
    // benign liveness probe: the tab still answers and the document is parsed.
    //  Real readiness (bound + idle awaiting %Rungo) is confirmed over the relay.
    const state = await driver.executeScript('return document.readyState')
    return state === 'complete' || state === 'interactive'
}

async function loop() {
    try {
        if (!driver) { await initDriver() }
        const ok = await alive()
        console.log(`[${tag}] ${new Date().toISOString()} ${ok ? 'LIVE' : 'NO-DOM'}`)
        if (!ok) throw new Error('document gone')
    } catch (e) {
        console.error(`[${tag}] self-heal:`, e.message)
        try { await driver.quit() } catch (e2) {}
        driver = null   // next tick rebuilds → reload re-binds, no work lost
    }
}

loop()
setInterval(loop, HEARTBEAT_MS)

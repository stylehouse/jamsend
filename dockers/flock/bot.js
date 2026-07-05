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
// /Otro is the toplevel that reads the role params (?E=/?B=/?I=) and stands up the
//  identity + runner machinery — the / route is the Mound app page and boots no role.
//   ?I=<tag> ALONE boots an idle runner on the grid (no ?B=); the tag keys the forked
//    Idento (§3.1) and — because it RESUMES from this bot's persistent profile — the
//     reborn tab keeps the SAME identity across a self-heal (a bare ?I=new would re-mint
//      every crash).  &remoteWormhole=1 acquires disk access from a trusted editor via the
//       grant protocol (no VNC needed — the grant button is in the editor's Rundar rack).
const url         = `${targetBase}/Otro?I=${encodeURIComponent(tag)}&remoteWormhole=1`
const HEARTBEAT_MS = 15 * 1000
let driver = null

async function initDriver() {
    const options = new chrome.Options()
    const display = process.env.DISPLAY || ':99.0'
    // --user-data-dir is EXPLICIT and persistent: a remote chromedriver given prefs but
    //  no user-data-dir mints its own throwaway temp profile — so identity would NOT
    //   survive a restart. We point it at /home/seluser/chrome-data, the seluser-owned
    //    dir the droid image creates and the rN-profile volume mounts onto (writable +
    //     persistent). A stale SingletonLock from an unclean exit is cleared droid-side by
    //      the chromium wrapper in docker-compose.yml (not here — the bot is a separate
    //       container and can't reach that volume). The prefs below only hush the bubble.
    for (const a of [
        `--display=${display}`,
        '--user-data-dir=/home/seluser/chrome-data',
        '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
        '--disable-software-rasterizer', '--disable-features=VizDisplayCompositor',
        '--force-device-scale-factor=1', '--hide-crash-restore-bubble',
        '--use-fake-ui-for-media-stream',
        // AudioContext starts RUNNING with no gesture — a headless runner can't be tapped, so
        //  without this every needAC Book wedges at 🎤 awaiting_audio.  (The droid's CHROME_FLAGS
        //   env is NOT consumed by selenium sessions — flags must ride here.)  The runner then
        //    advertises ac:1 and needAC dispatch prefers it.
        '--autoplay-policy=no-user-gesture-required',
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

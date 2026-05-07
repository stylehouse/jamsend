const puppeteer = require('puppeteer-core');
const net = require('net');

const SOCKET_PATH = '/tmp/jamsend-supervisor/chrome_launcher.sock';

// Config from environment — docker-compose injects these
const TARGET_URL = process.env.TARGET_URL;
const PORT_BASE  = parseInt(process.env.CHROME_DEBUG_PORT_BASE || '9222');

// Parse "public,private,tyrant" or "public,private:/stream,tyrant:/admin"
// → same structure as launcher.py; colon+path suffix is optional
const PROFILES = Object.fromEntries(
    (process.env.CHROME_PROFILES || '').split(',').map((entry, i) => {
        const [name, path = ''] = entry.trim().split(':');  // colon+path optional, e.g. 'private:/stream'
        return [name, { port: PORT_BASE + i, url: TARGET_URL + path }];
    })
);

const triggerRestart = (profileName) => {
    const client = net.createConnection({ path: SOCKET_PATH }, () => {
        client.write(`RESTART:${profileName}`);
        client.end();
    });
    client.on('error', (e) => console.error(`Socket error for ${profileName}:`, e.message));
};

const RESTART_COOLDOWN_MS = 25 * 1000;
const lastRestart = {};  // track when we last restarted each profile

async function checkProfile(name, config) {
    try {
        const browser = await puppeteer.connect({
            browserURL: `http://localhost:${config.port}`,
            protocolTimeout: 9 * 1000,
        });
        const pages = await browser.pages();
        if (pages.length === 0) throw new Error("No pages found");

        for (const page of pages) {
            try {
                await page.evaluate(() => true);  // throws if renderer crashed
            } catch (e) {
                // Crashed tab — close it and open a fresh one instead of restarting Chrome
                console.log(`Crashed tab in '${name}', recovering without full restart...`);
                await page.close().catch(() => {});
            }
        }
        await browser.disconnect();
    } catch (err) {
        const now = Date.now();
        const lastTime = lastRestart[name] || 0;
        if (now - lastTime < RESTART_COOLDOWN_MS) {
            console.log(`Heartbeat failed for '${name}' but in cooldown, skipping (${err.message})`);
            return;
        }
        console.log(`Check failed for '${name}': ${err.message} — signaling restart`);
        lastRestart[name] = now;
        triggerRestart(name);
    }
}

async function checkAll() {
    for (const [name, config] of Object.entries(PROFILES)) {
        await checkProfile(name, config);
    }
}
// now ish
setTimeout(checkAll, 3000);
// Check every 2 minutes
setInterval(checkAll, 2 * 60 * 1000);

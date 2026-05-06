// AI.
//   bot to scrape the droid every 10 minutes to count users online.
//   tally up how many UI:Pier are not disconnected out of a total
//   log that like logs/Droid-Piers/Piers-20260213/2220.jsons, if it changes.
const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const fs = require('fs');
const path = require('path');

const seleniumUrl = process.env.SELENIUM_REMOTE_URL || 'http://droid:4444/wd/hub';
const url = process.env.TARGET_URL;
const botName = process.env.BOT_NAME || 'unnamed';
const chromeProfileDir = process.env.CHROME_PROFILE_DIR || '/home/seluser/chrome-profile';
let lastState = "";
let driver = null;

// config per bot name - supervisor and tyrant are observers only
const configs = {
    public:     { shouldUnmute: true,countPiers: true },
    private:    { shouldUnmute: true,countPiers: true },
    supervisor: { shouldUnmute: false },
    tyrant:     { shouldUnmute: false },
};

function clearSingletonLocks() {
    // Chrome leaves Singleton* lock files behind on unclean exit,
    // preventing restart. Nuke them before starting.
    try {
        const files = fs.readdirSync(chromeProfileDir).filter(f => f.startsWith('Singleton'));
        for (const file of files) {
            fs.unlinkSync(path.join(chromeProfileDir, file));
            console.log(`[${botName}] Removed lock: ${file}`);
        }
    } catch (e) {
        // dir might not exist yet on first run, that's fine
    }
}
async function initDriver() {

    let options = new chrome.Options();
    // it tells the browser to appear on the VNC screen
    const displayNum = process.env.DISPLAY || ':99.0';
    options.addArguments(`--display=${displayNum}`);
    options.addArguments('--disable-gpu');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');
    options.addArguments('--disable-software-rasterizer');
    // --- STABILITY FLAGS ---
    options.addArguments('--disable-features=VizDisplayCompositor'); 
    options.addArguments('--force-device-scale-factor=1');
    // persist IndexedDB, is mounted in docker
    options.addArguments('--user-data-dir=/home/seluser/chrome-profile');
    options.addArguments('--profile-directory=Default');
    options.addArguments("--use-fake-ui-for-media-stream")
    options.addArguments(" --hide-crash-restore-bubble")
    options.addArguments("--disable-user-media-security=true")
    // < AI sludgey that these arguments are in compose CHROME_FLAGS as well
    // < likely AI lies:
    options.setUserPreferences({
        'profile.default_content_setting_values.file_system_write_access': 1, // 1 = Allow
        'profile.content_settings.exceptions.file_system_write_access.*.setting': 1,
        'profile.default_content_settings.popups': 0,
        'browser.enabled_labs_experiments': ["file-system-access-api-persistent-permissions"],
        'exit_type': 'Normal',
        'exited_cleanly': true
    });
    driver = await new Builder()
        .forBrowser('chrome')
        .setChromeOptions(options)
        .usingServer(seleniumUrl)
        .build();

    console.log(`[${botName}] Chrome started`);
    return driver;
}

async function tryUnmute(driver) {
    const config = configs[botName];
    if (!config?.shouldUnmute) return;
    
    try {
        await driver.wait(until.elementLocated(By.className('unmute-button')), 7 * 1000);
    } catch (e) {}

    try {
        const buttons = await driver.findElements(By.className('unmute-button'));
        if (buttons.length > 0) {
            await buttons[0].click();
            console.log(`[${botName}] Clicked unmute button`);
        } else {
            console.log(`[${botName}] No unmute button found`);
        }
    } catch (e) {
        console.warn(`[${botName}] Unmute click failed:`, e.message);
    }
}

// Returns pier stats, or null if no piers are present yet (nobody connected)
async function countPiers(driver) {
    const config = configs[botName];
    if (!config?.countPiers) return;

    try {
        await driver.wait(until.elementLocated(By.className('Pier_itself')), 16 * 1000);
    } catch (e) {
        // Timed out - no piers on the page yet, not an error
        console.log(`[${botName}] No piers found (not connected to anyone yet)`);
        return null;
    }

    const piers = await driver.findElements(By.className('Pier_itself'));
    let stats = {
        total: piers.length,
        connected: 0,
        details: []
    };

    for (let pier of piers) {
        // Check if this specific pier has a "discon" element inside it
        const disconElements = await pier.findElements(By.className('ohno'));
        const isDisconnected = disconElements.length > 0;

        if (!isDisconnected) stats.connected++;

        // Get the name/pub
        const name = await pier.findElement(By.className('title')).getText();
        stats.details.push({ name, status: isDisconnected ? 'offline' : 'online' });
    }

    return stats;
}

async function scrape() {
    try {
        if (!driver) {
            console.log(`[${botName}] Initializing driver...`);
            await initDriver();
        }

        console.log(`[${botName}] [${new Date().toLocaleTimeString()}] Refreshing...`);
        await driver.get(url);
        await tryUnmute(driver);

        const stats = await countPiers(driver);
        if (stats) {
            const { details, ...loggable } = stats;
            const currentState = JSON.stringify(loggable);

            if (currentState !== lastState) {
                saveLog(loggable);
                lastState = currentState;
            }
            console.log(`[${botName}] Checked: ${stats.connected}/${stats.total} connected`);
        }
    } catch (e) {
        console.error(`[${botName}] Scrape failed:`, e.message);
        try { await driver.quit(); } catch (e) {}
        driver = null;
    }
}

function saveLog(data) {
    const now = new Date();
    const dir = `./logs/Droid-${botName}/PiersList-${now.toISOString().split('T')[0].replace(/-/g, '')}`;
    const file = `${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}.json`;

    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, file), JSON.stringify(data, null, 2));
    console.log(`[${botName}] Log saved: ${file}`);
}

// Entry point
clearSingletonLocks();
scrape(); // Run once immediately
setInterval(scrape, 10 * 60 * 1000); // Then every 10 mins

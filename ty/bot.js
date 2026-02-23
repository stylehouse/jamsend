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
let lastState = "";

// config per bot name - supervisor and tyrant are observers only
const configs = {
    public:     { shouldUnmute: true },
    private:    { shouldUnmute: true },
    supervisor: { shouldUnmute: false },
    tyrant:     { shouldUnmute: false },
};

async function startBot() {
    // Chrome leaves Singleton* lock files behind on unclean exit,
    // preventing restart. Nuke them before starting.
    const profileDir = '/home/seluser/chrome-profile/Default';
    try {
        execSync(`rm -f ${profileDir}/Singleton*`);
        console.log(`[${botName}] Cleared Singleton locks`);
    } catch (e) {
        // dir might not exist yet, that's fine
    }
    
    let options = new chrome.Options();
    // it tells the browser to appear on the VNC screen
    options.addArguments('--display=:99.0');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');
    // persist IndexedDB, is mounted in docker
    options.addArguments('--user-data-dir=/home/seluser/chrome-profile');
    options.addArguments('--profile-directory=Default');

    const driver = await new Builder()
        .forBrowser('chrome')
        .setChromeOptions(options)
        .usingServer(seleniumUrl)
        .build();

    console.log(`[${botName}] Chrome started`);

    await scrape(driver);
    // Run every 10 minutes
    setInterval(() => scrape(driver), 10 * 60 * 1000);
}

async function tryUnmute(driver) {
    const config = configs[botName];
    if (!config?.shouldUnmute) return;

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

async function scrape(driver) {
    try {
        console.log(`[${botName}] [${new Date().toLocaleTimeString()}] Refreshing and Scrapping...`);

        await driver.get(url);
        console.log("got page")
        // Wait for the elements to load
        await driver.wait(until.elementLocated(By.className('Pier_itself')), 16 * 1000);

        await tryUnmute(driver);

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

        delete stats.details;
        const currentState = JSON.stringify(stats);
        
        if (currentState !== lastState) {
            saveLog(stats);
            lastState = currentState;
            console.log("doing")
        }
        console.log(`[${botName}] Checked: ${stats.connected}/${stats.total} connected`);

    } catch (e) {
        console.error(`[${botName}] Scrape failed:`, e.message);
    } finally {
        // await driver.quit();
    }
}

function saveLog(data) {
    const now = new Date();
    const dir = `./logs/Droid-PiersList/PiersList-${now.toISOString().split('T')[0].replace(/-/g, '')}`;
    const file = `${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}.json`;

    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, file), JSON.stringify(data, null, 2));
    console.log(`[${botName}] Log saved: ${file}`);
}

startBot();
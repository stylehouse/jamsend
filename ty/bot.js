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
let lastState = "";

async function startBot() {
    let options = new chrome.Options();
    // it tells the browser to appear on the VNC screen
    options.addArguments('--display=:99.0'); 
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');
    // persist IndexedDB, is mounted in docker
    options.addArguments('--user-data-dir=/home/seluser/chrome-profile');
    options.addArguments('--profile-directory=Default');

    let driver = await new Builder()
        .forBrowser('chrome')
        .setChromeOptions(options)
        .usingServer(seleniumUrl)
        .build();
    console.log("chrome started");


    while (true) {
        await scrape()
        // Wait 10 minutes before the next iteration
        await new Promise(resolve => setTimeout(resolve, 10 * 60 * 1000));
    }
}
async function scrape() {
    try {
        console.log(`[${new Date().toLocaleTimeString()}] Refreshing and Scrapping...`);

        await driver.get(url);
        console.log("got page")
        // Wait for the elements to load
        await driver.wait(until.elementLocated(By.className('Pier_itself')), 16 * 1000);

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
        console.log("checked")

    } catch (e) {
        console.error("Scrape failed:", e.message);
    } finally {
        // await driver.quit();
    }
}

function saveLog(data) {
    const now = new Date();
    const dir = `./logs/Droid-PiersList/PiersList-${now.toISOString().split('T')[0].replace(/-/g, '')}`;
    const file = `${now.getHours()}${now.getMinutes()}.json`;
    
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, file), JSON.stringify(data, null, 2));
    console.log(`Log saved: ${file}`);
}

// Run every 10 minutes
setInterval(scrape, 10 * 60 * 1000);
scrape(); // Run immediately on start
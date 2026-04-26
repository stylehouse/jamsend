const puppeteer = require('puppeteer-core');
const net = require('net');

const SOCKET_PATH = '/tmp/chrome_launcher.sock';
const triggerRestart = () => {
    const client = net.createConnection({ path: SOCKET_PATH }, () => {
        client.write('RESTART');
        client.end();
    });
    client.on('error', (e) => console.error("Socket error:", e.message));
};

async function check() {
    try {
        const browser = await puppeteer.connect({ browserURL: 'http://host.docker.internal:9222' });
        const pages = await browser.pages();
        // If the renderer crashed, pages will be empty or throw
        if (pages.length === 0) throw new Error("No pages found");
        await browser.disconnect();
    } catch (err) {
        console.log("Heartbeat failed, signaling restart...");
        triggerRestart();
    }
}

// Initial trigger to start Chrome on boot
triggerRestart();
// Check every 10 seconds
setInterval(check, 10000);
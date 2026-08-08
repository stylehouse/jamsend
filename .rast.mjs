// rasterise a standalone SVG so I can actually LOOK at the glass (THE PIN's law A:
//  "pixels or it didn't land" — a coordinate dump is not a look).
import { chromium } from 'playwright'
import { readFileSync } from 'fs'
const [,, inp, outp, bg] = process.argv
const svg = readFileSync(inp, 'utf8')
const b = await chromium.launch()
const p = await b.newPage({ viewport: { width: 900, height: 520 }, deviceScaleFactor: 2 })
await p.setContent(`<body style="margin:0;background:${bg || '#16161c'}">${svg}</body>`)
await p.waitForTimeout(400)
await p.screenshot({ path: outp })
await b.close()
console.log('wrote', outp)

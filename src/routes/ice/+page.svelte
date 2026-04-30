<script>
    import { onMount, tick } from 'svelte'

    // ── Config (edit these or override in the UI) ─────────────────────────────
    let host       = 'jamsend.duckdns.org'
    let turnsPort  = 5349
    let turnPort   = 3478
    let username   = 'jamsend'
    let credential = 'Eiru7gahneeD2che'

    // ── State ─────────────────────────────────────────────────────────────────
    let running   = false
    let log       = []   // { t, level, text }
    let suites    = []   // completed suite results

    const TIMEOUT_MS = 20_000

    // ── Logging ───────────────────────────────────────────────────────────────
    let t0
    function ts() { return ((performance.now() - t0) / 1000).toFixed(3) }

    function emit(text, level = 'info') {
        log = [...log, { t: ts(), level, text }]
    }

    // ── Core ICE probe ────────────────────────────────────────────────────────
    /**
     * Opens a single RTCPeerConnection with the given iceServers list,
     * logs every raw candidate event, and resolves with a summary.
     *
     * Returns { result, candidates, gatheringStates, durationMs }
     */
    function probeIce(label, iceServers) {
        return new Promise((resolve) => {
            const start        = performance.now()
            const candidates   = []
            const gatherStates = []
            let   settled      = false
            let   timer

            emit(`▶ ${label}`, 'section')
            emit(`  iceServers: ${JSON.stringify(iceServers)}`, 'debug')

            const pc = new RTCPeerConnection({ iceServers })

            function finish(result) {
                if (settled) return
                settled = true
                clearTimeout(timer)
                const durationMs = Math.round(performance.now() - start)
                try { pc.close() } catch {}
                const relayFound = candidates.some(c => c.type === 'relay')
                emit(
                    `  ↳ ${result} in ${durationMs}ms | relay:${relayFound} | total candidates:${candidates.length}`,
                    result === 'relay-found' ? 'ok' : 'fail'
                )
                resolve({ result, candidates, gatherStates, durationMs })
            }

            // Log every candidate verbatim — this is the primary diagnostic output
            pc.onicecandidate = (e) => {
                if (!e.candidate) {
                    emit('  candidate: (null — end of candidates signal)', 'debug')
                    return
                }
                const c = e.candidate
                candidates.push(c)
                emit(`  candidate [${c.type}] ${c.candidate}`, c.type === 'relay' ? 'ok' : 'info')
                if (c.type === 'relay') finish('relay-found')
            }

            pc.onicegatheringstatechange = () => {
                const s = pc.iceGatheringState
                gatherStates.push(s)
                emit(`  gatheringState → ${s}`, s === 'complete' ? 'warn' : 'debug')
                if (s === 'complete') finish('gathering-complete-no-relay')
            }

            pc.oniceconnectionstatechange = () => {
                emit(`  iceConnectionState → ${pc.iceConnectionState}`, 'debug')
            }

            // Timeout safety net (browser may stall without completing)
            timer = setTimeout(() => finish('timeout'), TIMEOUT_MS)

            // A data channel + offer is required to trigger ICE gathering
            pc.createDataChannel('diag')
            pc.createOffer()
                .then(o => pc.setLocalDescription(o))
                .catch(err => {
                    emit(`  createOffer error: ${err}`, 'fail')
                    finish('offer-error')
                })
        })
    }

    // ── TCP reachability probe via fetch (best-effort — CORS will block body) ─
    async function probeTcp(host, port) {
        emit(`  TCP probe → ${host}:${port} (fetch trick — expect network error or CORS, not silence)`, 'debug')
        const start = performance.now()
        try {
            // fetch will at minimum complete the TCP handshake before failing on CORS
            await fetch(`https://${host}:${port}/`, { mode: 'no-cors', signal: AbortSignal.timeout(6000) })
            emit(`  TCP ${host}:${port} → response received (port open)`, 'ok')
        } catch (e) {
            const ms = Math.round(performance.now() - start)
            if (e.name === 'AbortError' || ms < 200) {
                // Immediate failure = RST or port closed, not a timeout
                emit(`  TCP ${host}:${port} → FAILED in ${ms}ms — port likely closed/filtered`, 'fail')
            } else {
                // Slow failure = TLS or CORS error after real TCP connection — port is open
                emit(`  TCP ${host}:${port} → error after ${ms}ms (${e.name}) — port reachable`, 'ok')
            }
        }
    }

    // ── Test suites ───────────────────────────────────────────────────────────
    /**
     * Each suite tests a different hypothesis. Run them all in sequence so
     * log output stays readable.
     */
    async function runAll() {
        running = true
        log     = []
        suites  = []
        t0      = performance.now()

        emit('═══ TURNS DIAGNOSTIC ════════════════════════════════════════════', 'section')
        emit(`host:${host}  turns:${turnsPort}  turn:${turnPort}  user:${username}`, 'debug')
        emit('', 'info')

        // ── 0. TCP reachability ───────────────────────────────────────────────
        emit('── 0. TCP REACHABILITY ──────────────────────────────────────────', 'section')
        await probeTcp(host, turnsPort)   // 5349 must be open for TURNS/TLS
        await probeTcp(host, turnPort)    // 3478 baseline comparison
        emit('', 'info')

        // ── 1. TURNS alone (the failing case) ────────────────────────────────
        emit('── 1. TURNS ALONE (turns: scheme) ─────────────────────────────', 'section')
        // Hypothesis: does isolation cause the browser to skip relay candidates?
        // Answer: no — browsers should gather relay from TURNS even in isolation.
        // If this returns "gathering-complete-no-relay" immediately, the TCP connection
        // to port 5349 is likely failing silently.
        const r1 = await probeIce('TURNS alone', [
            { urls: `turns:${host}:${turnsPort}`, username, credential }
        ])
        suites.push({ label: 'TURNS alone (turns: scheme)', ...r1 })
        emit('', 'info')

        // ── 2. TURNS with ?transport=tcp explicit ─────────────────────────────
        emit('── 2. TURNS + ?transport=tcp explicit ─────────────────────────', 'section')
        // Some browsers require the transport hint even for turns: (which implies TCP)
        const r2 = await probeIce('TURNS ?transport=tcp', [
            { urls: `turns:${host}:${turnsPort}?transport=tcp`, username, credential }
        ])
        suites.push({ label: 'TURNS + ?transport=tcp', ...r2 })
        emit('', 'info')

        // ── 3. TURN over TLS via turn: scheme (Chrome supports this) ──────────
        emit('── 3. turn: with ?transport=tls ───────────────────────────────', 'section')
        // Some Chromium builds interpret turn:host:5349?transport=tls as TURNS.
        // Worth trying if turns: scheme parsing is the bug.
        const r3 = await probeIce('turn: ?transport=tls', [
            { urls: `turn:${host}:${turnsPort}?transport=tls`, username, credential }
        ])
        suites.push({ label: 'turn: ?transport=tls on port 5349', ...r3 })
        emit('', 'info')

        // ── 4. TURNS alongside STUN + plain TURN ─────────────────────────────
        emit('── 4. TURNS + STUN + TURN combined ───────────────────────────', 'section')
        // Original production config — does having other servers present change anything?
        // (It should not affect TURNS relay gathering, but rules out ordering issues.)
        const r4 = await probeIce('Full combined config', [
            { urls: `stun:${host}:${turnPort}` },
            { urls: `turns:${host}:${turnsPort}`, username, credential },
            { urls: `turn:${host}:${turnPort}`,  username, credential },
        ])
        suites.push({ label: 'TURNS + STUN + TURN combined', ...r4 })
        emit('', 'info')

        // ── 5. Plain TURN baseline (should always work) ───────────────────────
        emit('── 5. PLAIN TURN BASELINE ──────────────────────────────────────', 'section')
        const r5 = await probeIce('TURN alone (baseline)', [
            { urls: `turn:${host}:${turnPort}`, username, credential }
        ])
        suites.push({ label: 'TURN alone (UDP baseline)', ...r5 })

        emit('', 'info')
        emit('═══ DONE ════════════════════════════════════════════════════════', 'section')

        running = false
        await tick()
        document.getElementById('log-end')?.scrollIntoView({ behavior: 'smooth' })
    }

    // ── Level → colour class ──────────────────────────────────────────────────
    const cls = {
        section: 'c-section',
        debug:   'c-dim',
        info:    'c-info',
        ok:      'c-ok',
        warn:    'c-warn',
        fail:    'c-fail',
    }
</script>

<style>
    @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;600&display=swap');

    :global(body) {
        margin: 0;
        background: #0a0c0f;
        color: #c9d1d9;
        font-family: 'IBM Plex Sans', sans-serif;
    }

    .page {
        min-height: 100vh;
        padding: 2rem;
        max-width: 960px;
        margin: 0 auto;
    }

    h1 {
        font-family: 'IBM Plex Mono', monospace;
        font-size: 1.1rem;
        font-weight: 600;
        color: #58a6ff;
        letter-spacing: .08em;
        text-transform: uppercase;
        margin: 0 0 .25rem;
    }
    .subtitle {
        font-size: .8rem;
        color: #6e7681;
        margin: 0 0 2rem;
        font-family: 'IBM Plex Mono', monospace;
    }

    /* ── Config grid ── */
    .config {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
        gap: .75rem;
        margin-bottom: 1.5rem;
    }
    label {
        display: flex;
        flex-direction: column;
        gap: .25rem;
        font-family: 'IBM Plex Mono', monospace;
        font-size: .7rem;
        color: #6e7681;
        text-transform: uppercase;
        letter-spacing: .06em;
    }
    input {
        background: #161b22;
        border: 1px solid #30363d;
        border-radius: 4px;
        color: #e6edf3;
        font-family: 'IBM Plex Mono', monospace;
        font-size: .85rem;
        padding: .4rem .6rem;
        outline: none;
        transition: border-color .15s;
    }
    input:focus { border-color: #58a6ff; }

    /* ── Run button ── */
    button.run {
        display: inline-flex;
        align-items: center;
        gap: .5rem;
        background: #1f6feb;
        color: #fff;
        border: none;
        border-radius: 6px;
        font-family: 'IBM Plex Mono', monospace;
        font-size: .85rem;
        font-weight: 600;
        padding: .55rem 1.4rem;
        cursor: pointer;
        transition: background .15s, opacity .15s;
        margin-bottom: 1.5rem;
    }
    button.run:disabled { opacity: .45; cursor: not-allowed; }
    button.run:not(:disabled):hover { background: #388bfd; }

    .spinner {
        width: 14px; height: 14px;
        border: 2px solid rgba(255,255,255,.3);
        border-top-color: #fff;
        border-radius: 50%;
        animation: spin .7s linear infinite;
        display: inline-block;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* ── Summary cards ── */
    .summary {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
        gap: .75rem;
        margin-bottom: 1.5rem;
    }
    .card {
        background: #161b22;
        border: 1px solid #30363d;
        border-radius: 6px;
        padding: .75rem 1rem;
        font-family: 'IBM Plex Mono', monospace;
        font-size: .75rem;
    }
    .card.ok   { border-left: 3px solid #3fb950; }
    .card.fail { border-left: 3px solid #f85149; }
    .card .card-label { color: #8b949e; margin-bottom: .25rem; }
    .card .card-result { font-weight: 600; font-size: .85rem; }
    .card.ok   .card-result { color: #3fb950; }
    .card.fail .card-result { color: #f85149; }
    .card .card-meta { color: #6e7681; margin-top: .15rem; }

    /* ── Log terminal ── */
    .terminal {
        background: #0d1117;
        border: 1px solid #30363d;
        border-radius: 6px;
        padding: 1rem 1.25rem;
        font-family: 'IBM Plex Mono', monospace;
        font-size: .78rem;
        line-height: 1.7;
        max-height: 600px;
        overflow-y: auto;
        white-space: pre-wrap;
        word-break: break-all;
    }
    .terminal:empty::before {
        content: '// Click "Run diagnostics" to begin';
        color: #3d444d;
    }

    .log-line { display: flex; gap: .75rem; }
    .log-t    { color: #3d444d; flex-shrink: 0; user-select: none; }

    .c-section { color: #79c0ff; font-weight: 600; }
    .c-dim     { color: #6e7681; }
    .c-info    { color: #c9d1d9; }
    .c-ok      { color: #3fb950; }
    .c-warn    { color: #d29922; }
    .c-fail    { color: #f85149; font-weight: 600; }

    /* ── Hints box ── */
    .hints {
        margin-top: 1.5rem;
        background: #161b22;
        border: 1px solid #30363d;
        border-left: 3px solid #d29922;
        border-radius: 6px;
        padding: .75rem 1rem;
        font-size: .8rem;
        line-height: 1.8;
        color: #8b949e;
    }
    .hints strong { color: #e6edf3; }
    .hints code {
        background: #0d1117;
        padding: .1em .35em;
        border-radius: 3px;
        font-family: 'IBM Plex Mono', monospace;
        font-size: .9em;
        color: #79c0ff;
    }
</style>

<div class="page">
    <h1>🔬 TURNS / ICE Diagnostic</h1>
    <p class="subtitle">raw candidate events · gathering state transitions · tcp reachability</p>

    <!-- Config -->
    <div class="config">
        <label>Host <input bind:value={host} /></label>
        <label>TURNS port <input bind:value={turnsPort} type="number" /></label>
        <label>TURN port  <input bind:value={turnPort}  type="number" /></label>
        <label>Username   <input bind:value={username} /></label>
        <label>Credential <input bind:value={credential} type="password" /></label>
    </div>

    <button class="run" on:click={runAll} disabled={running}>
        {#if running}<span class="spinner"></span> Running…{:else}▶ Run diagnostics{/if}
    </button>

    <!-- Summary cards (shown after run) -->
    {#if suites.length}
        <div class="summary">
            {#each suites as s}
                {@const ok = s.result === 'relay-found'}
                <div class="card" class:ok class:fail={!ok}>
                    <div class="card-label">{s.label}</div>
                    <div class="card-result">{s.result}</div>
                    <div class="card-meta">{s.durationMs}ms · {s.candidates.length} candidates</div>
                </div>
            {/each}
        </div>
    {/if}

    <!-- Raw log terminal -->
    <div class="terminal">
        {#each log as line}
            <div class="log-line">
                <span class="log-t">{line.t}</span>
                <span class={cls[line.level] ?? 'c-info'}>{line.text}</span>
            </div>
        {/each}
        <div id="log-end"></div>
    </div>

    <!-- Interpretation hints (always visible) -->
    <div class="hints">
        <strong>Reading the output</strong><br>
        <strong>relay-found immediately</strong> → working ✓<br>
        <strong>gathering-complete-no-relay fast (&lt;2s)</strong> → browser never connected to port 5349;
        check <code>sudo ufw allow 5349/tcp</code> and <code>sudo ufw allow 5349/udp</code> on the jump server.<br>
        <strong>timeout (20s)</strong> → TCP reached coturn but TLS/TURN auth failed;
        check cert chain, coturn logs (<code>docker logs coturn</code>), and that <code>tls-cert-file</code> / <code>tls-pkey-file</code> point to valid files.<br>
        <strong>turn: ?transport=tls works but turns: doesn't</strong> → browser-specific URL scheme parsing bug;
        use <code>turn:host:5349?transport=tls</code> in production config instead of <code>turns:</code>.<br>
        <strong>TCP probe fails on 5349 but succeeds on 3478</strong> → firewall is the culprit, not coturn config.
    </div>
</div>

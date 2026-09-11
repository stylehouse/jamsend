// wafts_everything.mjs — AUTHOR the area Wafts + Waft:Everything from one validated source.
//  Why a script and not hand-edited toc.snaps: every Doc path and every Point,method is checked
//   against the tree before anything is written (16 stale references fell out of the first pass),
//    and a rename anywhere is one re-run away from a map that still resolves.
//  Usage: node scripts/wafts_everything.mjs        (writes wormhole/Ghost/*/toc.snap + wormhole/Everything/toc.snap)
//  The editor keeps these Wafts open and saves them back on a version bump — reload it after a run.
//  Policy for what goes in lives in Waft:Everything itself (What:the policy).
import fs from 'node:fs'
import path from 'node:path'
const ROOT = path.resolve(new URL('..', import.meta.url).pathname)
const W = []
const P = (m, d) => `Point:${m}|${d}`

W.push(['Ghost/Net/Easy', 'the wire — one spine and its carriers — the relay in the middle — the cluster channel the editor and its runners ride',
 ['PereStaple','PereProof','PereTyrant','PereReborn','PereComplain','Peregrination','RepliUpsert','RepliSplit','RepliShadow','ParkCull','RaBreach','PeeringLive','Sounditron'], [
 ['What:the spine', 'Peeroleum — an envelope with a seq and an ack — a Pier per peer with an outbox and an inbox — every frame books an unemit served under the beliefs mutex',
  'Doc:Ghost/N/Peeroleum.g',
  P('Peeroleum_send', 'outbound — allocate seq — book the emit — hand to the carrier'),
  P('Peeroleum_deliver', 'inbound gate — timing dose — calls deliver_do'),
  P('Peeroleum_deliver_do', 'route by header — ack ping pulse fast paths — book the unemit — pier-less roads'),
  P('req_unemit', 'the inbox worker — dispatch a booked frame to its handler — ack or fault'),
  P('Peeroleum_take_ack', 'an ack retires an emit — hello and trust acked here too'),
  P('Peeroleum_on', 'register an app handler for a frame type on this world'),
  P('Peeroleum_route', 'header.to → Peering + Pier'),
  P('Peeroleum_bound_inbox', 'the cap — shed and whittle so an inbox never grows without bound')],
 ['What:the handshake', 'say and hear — hello then trust — a Ud is the pre-trust gate on the inbox',
  'Doc:Ghost/N/Peeroleum.g',
  P('say_hello', 'first word to a Pier — once — seq from Pier_next_seq'), P('hear_hello', 'verify the pubkey matches the Pier — reply hello — mint the Ud'),
  P('say_trust', 'the second word — trust everything v1'), P('hear_trust', 'accept trust — the Pier is ready'),
  P('Peeroleum_peer_ready', 'handshake complete? — gates app frames'), P('Peeroleum_reset_handshake', 'a reborn peer — drop protocol outbox inbox faulty and start over')],
 ['What:the carriers', 'Tribunal — the real websocket to the relay with auto-reconnect and backoff — mock and webrtc beside it',
  'Doc:Ghost/N/Tribunal.g',
  P('Socket_real', 'the websocket carrier — dial reconnect bulk lane control frames hello_ok fan-out'),
  P('Socket', 'the mock carrier — loopback for Books'),
  P('Tribunal_activate_websocket', 'stamp the active transport on the world'),
  P('Tribunal_fall_to_websocket', 'webrtc failed — fall back'),
  P('Tribunal_redial', 'a Peering whose socket died — when to try again'),
  'Doc:src/lib/server/relay.ts',
  P('attachRelay', 'the relay — locals map — bind by addr role or hello — r2r bridge to the other dev server'),
  P('deliverLocal', 'own-door rule — a socket that dialled or declared the address is the door'),
  P('handleHello', 'signed identity bind — the seat arbiter — want and grant'),
  P('routeFromBrowser', 'deliver local else forward once over the bridge'),
  P('dialEditor', 'the runner relay dials the editor relay — one peerLink — last dialer wins'),
  'Doc:src/lib/p2p/pinned_stable/Tribunal.go', 'Doc:src/lib/p2p/pinned_stable/Peeroleum.go'],
 ['What:the healing floor', 'Reliable — inbound sequencing and retransmit — the lossy partner is the adversary the floor is proven against',
  'Doc:Ghost/N/Reliable.g',
  P('inseq_admit', 'in-order admission — buffer the gap — release what is ready'), P('retx_due', 'which emits to resend and which are dead'),
  P('retx_delay', 'backoff per attempt'), P('make_lossy_partner', 'a carrier that drops and reorders on purpose'),
  'Doc:Ghost/N/Peeroleum.g', P('Peeroleum_retx_sweep', 'the resend clock over every outbox'), P('Peeroleum_liveness_sweep', 'no inbound for dead ms → mark the Pier silent')],
 ['What:admission', 'Tyrant — trust and policy-gated admission on the floor',
  'Doc:Ghost/N/Tyrant.g', P('req_admit', 'is this Pier admitted under policy'), P('req_policy', 'the standing policy req'), P('say_vouch', 'vouch for a peer'), P('hear_vouch', 'take a vouch'), P('Tyrant_grant', 'mint the grant admission rides on')],
 ['What:presence', 'who is online — one batch who probe per round instead of a pulse per friend',
  'Doc:Ghost/N/Presence.g', P('Presence_arm', 'install the who_ok hook before the socket can answer'), P('Presence_ask', 'send the who batch'), P('Presence_take', 'land the answer — online offline'), P('Presence_online', 'is this addr live right now'), P('Presence_ask_roster', 'ask about everyone we know')],
 ['What:replication', 'Repli — a C** subtree becomes wire lines and back — offer a Record then deal its Stream page by page — the want and the park',
  'Doc:Ghost/N/Repli.g',
  P('Repli_lines_of', 'a subtree as wire lines'), P('Repli_fragment', 'cut a record into sendable fragments'), P('Repli_pack_chunks', 'chunks into a page'), P('Repli_unpack_page', 'a page back into chunk particles'),
  P('Repli_page_ready', 'the sender says a page is there'), P('Repli_recv_page', 'a page lands — cid gate — attach'), P('Repli_recv_parked', 'the want waits for a record that is not here yet'),
  P('Repli_serve_miss', 'a want for something we do not hold — say so'), P('Repli_open_awaitbuf', 'a receiver buffer per pull'), P('Repli_awaitbuf_do', 'the pull loop — re-ask every wanted offset'),
  P('Repli_meter', 'the coalesced transfer meter — bytes and pace'), P('Repli_rto', 'retransmit timeout from the smoothed rtt'), P('Repli_arm', 'arm the protocol on a world each beat')],
 ['What:the cluster channel', 'Lies rides the same spine — become binds a role and a signed hello binds an identity — the keepalive and the hello latch',
  'Doc:src/lib/O/LiesLies.svelte', 'Doc:src/lib/O/LiesRun.svelte', P('req_Rundown', 'the runner — a rungo lands and the Book runs'), P('Pantheate', 'where a run lands — the include is mounted'),
  'Doc:src/lib/p2p/cluster_trust.ts', 'Doc:scripts/runner_ask.mjs', 'Doc:scripts/relay-test.ts'],
 ['What:the tests', 'Doc:Ghost/Story/PeerTesting.g', P('Run_A_PereStaple', 'the canonical spine over loopback'), P('Run_A_PereProof', 'proven delivery'), P('Run_A_PereReborn', 'the reconnect epoch'), 'Doc:Ghost/Story/Sounditron.g'],
 ['What:the spec', 'Doc:src/lib/O/spec/Peeroleum_spec.md', 'Doc:src/lib/O/spec/Wire_spec.md', 'Doc:src/lib/O/spec/Repli_design.md', 'Doc:src/lib/O/spec/Cluster_spec.md', 'Doc:src/lib/O/spec/Social_demarcation_todo.md', 'Doc:src/lib/O/spec/Backpressure_todo.md', 'Doc:src/lib/O/spec/Presence_todo.md', 'Doc:src/lib/O/spec/Network_procedures_todo.md', 'Doc:src/lib/O/spec/Networky_directions_todo.md'],
]])

W.push(['Ghost/Swarm/Easy', 'the social layer — one soul many bodies — crew by grant — the door the reach the ferry — what survives a reload',
 ['SwarmStaple','SwarmWire','SwarmSteal','SwarmInvite','SwarmDoor','SwarmGot','SwarmPolicy','SwarmShare','SwarmChain','SwarmBlotter','SwarmSpoof','SwarmDisk','SwarmCohort','SwarmFerry','EmojiConfirm','SwarmBody','SwarmCharter','SwarmGossip','SwarmPost','SwarmServe','SwarmSpread','SwarmReboot','SwarmHelm','Swarmation','InvSeal','InvFerry','InvWalk'], [
 ['What:the soul', 'one signing key is who you are — bodies wear their own keys — the prepub is the routing face',
  'Doc:Ghost/S/Swarm.g', P('Swarm_identity', 'the active identity particle'), P('Swarm_keys', 'mint or load the keypair'), P('Swarm_soul', 'the soul key behind every body'), P('Swarm_body_key', 'this body — its own key-derived name'), P('Swarm_live_self', 'who we are right now on the wire'), P('Swarm_address', 'the address we stand at')],
 ['What:the crew', 'membership is a Grant — the Charter is display and recovery only — a Cave carries the soul key and a Captain wields it',
  'Doc:Ghost/S/Swarm.g', P('Swarm_crew', 'the /Crew shelf — membership'), P('Swarm_crew_grant', 'mint a crew grant'), P('Swarm_crew_join', 'take a grant — join'), P('Swarm_crew_leave', 'leave — the grant retires'), P('Swarm_captain_here', 'is the Captain this body'), P('Swarm_charter_wire', 'the Charter as a frame'), P('Swarm_charter_gossip', 'the Charter crosses on hi')],
 ['What:the invite', 'a token or a printed blotter — the Idzeug — a ReInvite chain where the tip grants',
  'Doc:Ghost/S/Swarm.g', P('Swarm_token', 'mint the invite token'), P('Swarm_token_parse', 'read one back'), P('Swarm_iz_claim', 'claim an Idzeug — once'), P('Swarm_iz_spent', 'was it spent'), P('Swarm_iz_issuer', 'who issued it'), P('Swarm_chain_root_ok', 'the chain root verifies'), P('Swarm_invite_note', 'what the invite says about itself'),
  'Doc:src/lib/O/Funk/Emojiconfirm.ts', 'Doc:src/lib/O/ui/InvitePanel.svelte', 'Doc:src/lib/O/ui/InviteYourself.svelte'],
 ['What:the door', 'first contact — hello then seal — a rebuff and its forgiveness — the station socket at the bare prepub',
  'Doc:Ghost/S/Swarm.g', P('Swarm_station_up', 'stand the station socket — the hello and the arbiter adopt hook'), P('Swarm_deliver', 'the swarm frame dispatcher'), P('Swarm_seal', 'seal a Pier — the ceremony completes'), P('Swarm_rebuff', 'refuse and say why'), P('Swarm_rebuff_forgive', 'let a rebuffed peer knock again'), P('Swarm_hi_one', 'greet one peer'), P('Swarm_heard_hi', 'a greeting landed'), P('Swarm_pier_live', 'is this Pier live'), P('Swarm_pier_granted', 'is this Pier granted'),
  'Doc:src/lib/O/ui/DoorFace.svelte', 'Doc:src/lib/O/ui/SwarmStandup.svelte'],
 ['What:reach', 'the Want middleware — a Reach books an intent and pumps it until the far side serves or refuses',
  'Doc:Ghost/S/Swarm.g', P('Swarm_reach_book', 'book a Reach'), P('Swarm_reach_pump', 'the beat — dispatch what is due'), P('Swarm_reach_dispatch', 'send one'), P('Swarm_reach_serve', 'the far side serves'), P('Swarm_reach_settle', 'settle on receipt'), P('Swarm_reach_report', 'the state of every Reach')],
 ['What:the ferry', 'LinkDevice — the soul crosses to a second body with a secret and a serial — cancel and reheal',
  'Doc:Ghost/S/Swarm.g', P('req_Ferry_soul', 'the soul side of the ceremony'), P('req_Ferry_cave', 'the cave side'), P('Swarm_ferry_ask', 'ask to be ferried'), P('Swarm_ferry_secret', 'the shared secret'), P('Swarm_ferry_done', 'the crossing completes'), P('Swarm_ferry_cancel', 'abort'), P('Swarm_ferry_reheal', 'resume a broken crossing'),
  'Doc:src/lib/O/ui/LinkDevice.svelte', 'Doc:src/lib/O/ui/LinkFace.svelte'],
 ['What:bodies and siblings', 'many bodies of one soul — the primary — sibling delivery needs no Pier',
  'Doc:Ghost/S/Swarm.g', P('Swarm_body_roster', 'the bodies we know of ourselves'), P('Swarm_body_primary', 'which body is primary'), P('Swarm_body_pick', 'pick a body for a job'), P('Swarm_sibling_send', 'send to a sibling body'), P('Swarm_is_sibling', 'same soul?'), P('Swarm_take_role', 'a body takes a role'),
  'Doc:Ghost/N/Peeroleum.g', P('Peeroleum_same_soul', 'a frame from our own soul — no Pier needed'), P('Peeroleum_crew_road', 'a frame from a crew mate — the crew road')],
 ['What:gossip', 'the pulse — what music I have got — suggest and boast — the roster crosses on hi',
  'Doc:Ghost/S/Swarm.g', P('Swarm_pulse_all', 'the heartbeat to every Pier'), P('Swarm_gossip_music', 'tell friends what we hold'), P('Swarm_ive_got', 'the ive_got fact'), P('Swarm_suggest', 'suggest a track'), P('Swarm_suggest_got', 'a suggestion landed'), P('Swarm_roster_gossip', 'the roster crosses'), P('Swarm_music_census', 'count what is reachable')],
 ['What:the stash', 'what survives a reload — piers izzes chainroots crew pools heard radio reaches — a phone has no folder so this is its only home',
  'Doc:Ghost/S/Swarm.g', P('Swarm_restash_all', 'write every durable shelf'), P('Swarm_piers_rehydrate', 'piers back from the stash'), P('Swarm_crew_rehydrate', 'crew back'), P('Swarm_heard_rehydrate', 'the Heard Mag back'), P('Swarm_pools_rehydrate', 'pools back'), P('Swarm_radio_rehydrate', 'radio state back'), P('Swarm_account_settle', 'the account snap settles'), P('Swarm_protocol', 'which mainkeys cross the wire — the skips')],
 ['What:theft and home', 'a stolen name — steal back — rehome and reinstate — the cohort vessel',
  'Doc:Ghost/S/Swarm.g', P('Swarm_note_theft', 'someone else holds our name'), P('Swarm_steal_back', 'take it back'), P('Swarm_rehome', 'the address changed — redial'), P('Swarm_reinstate', 'stand at the bare name again'), P('Swarm_cohort_vessel', 'which tab of ours carries the cohort'), P('Swarm_next_suffix', 'the _N collision fallback')],
 ['What:the tests', 'Doc:Ghost/Story/SwarmTesting.g', 'Doc:Ghost/Story/InvSeal.g', 'Doc:Ghost/Story/InvFerry.g', 'Doc:Ghost/Story/InvWalk.g'],
 ['What:the spec', 'Doc:src/lib/O/spec/Swarm_spec.md', 'Doc:src/lib/O/spec/Crew_todo.md', 'Doc:src/lib/O/spec/Reach_todo.md', 'Doc:src/lib/O/spec/Portability_todo.md', 'Doc:src/lib/O/spec/Statehome_todo.md', 'Doc:src/lib/O/spec/Identity_persist_todo.md', 'Doc:src/lib/O/spec/Swarm_compact_invite_todo.md', 'Doc:src/lib/O/spec/Sharing_design.md', 'Doc:src/lib/O/spec/Trust_todo.md'],
]])

W.push(['Ghost/Music/Ality', 'the music pipeline — rastock racast raterm — stock a track then cast it then play it at the terminal — the radio dials and the pool keeps what played',
 ['MusuStaple','MusuStream','MusuStock','MusuLive','MusuWear','MusuSkip','MusuCrowd','MusuSignal','MusuGlide','MusuTune','MusuRadio','MusuMix','MusuMesh','MusuCue','MusuEdge','MusuPier','MusuConceal','MusuBounce','MusuReplica','MusuReco','MusuRaStream','MusuRaChase','MusuRaStock','MusuRaTerm','MusuOgg','MusuLossy','MusuPress','MusuQuarter','MusuNeGrind','MusuPoolFill','MusuPoolRadio','MusuPoolRandom','MusuPoolBytes','MusuGenerateTestsMusic'], [
 ['What:the stock pass', 'Ra — needles LUFS then a baked gain then Opus segments cut into chunk particles — the preview is the tail of the song and the head run is separate',
  'Doc:Ghost/M/Ra.g', P('Ra_gain_for', 'loudness → gain'), P('Ra_bake', 'apply the gain to pcm'), P('Ra_encode_feed', 'pcm into the opus encoder'), P('Ra_chunk_cut', 'segments into chunk particles'), P('Ra_chunk_mint', 'one chunk particle — seq bytes cid'), P('Ra_preview_offset', 'where the preview cuts — 30 to 70 percent in'), P('Ra_head_whole', 'is the head run complete'), P('Ra_record_from', 'a Record from a file'),
  'Doc:Ghost/M/Orig.g', P('Orig_ogg_mux', 'chunks back into an ogg file'), P('Orig_ogg_parse', 'an ogg file into packets')],
 ['What:the homes', 'Mine Theirs the shop the bay and the pool — records live once per shelf and a Card refers',
  'Doc:Ghost/M/Ra.g', P('Ra_home_self', 'my shelf'), P('Ra_home_them', 'a friend shelf'), P('Ra_home_pool', 'the pool shelf'), P('Ra_home_shelf', 'any shelf by name'), P('Ra_library', 'the Library under a home'), P('Ra_rec_find', 'a Record by id'), P('Ra_recs', 'every Record on a shelf'), P('Ra_mag_page', 'a page of a Mag')],
 ['What:the pool', 'SoundPooling — the dial already chooses so the pool keeps what played — consent budget caps and the quarter goal',
  'Doc:Ghost/M/Ra.g', P('Ra_pool_define', 'a pool — who owns it'), P('Ra_pool_stock', 'what the pool holds'), P('Ra_pool_consent', 'who consented to pool'), P('Ra_pool_budget', 'bytes allowed'), P('Ra_pool_census', 'count the pool'), P('Ra_quarter_goal', 'the quarter — how much each source should give'), P('Ra_pool_fill_book', 'book a fill'), P('Ra_pool_fill_homes', 'where a fill comes from and lands'), P('Ra_pool_fill_verdict', 'did the fill land'),
  'Doc:src/lib/O/ui/PoolFace.svelte'],
 ['What:the terminal', 'the listener end — pcm admission and the fly — the spool and the stream open — the dial picks the next',
  'Doc:Ghost/M/Ra.g', P('Ra_pcm_admit', 'may this chunk decode now'), P('Ra_pcm_sweep', 'drop pcm we are past'), P('Ra_term_spool', 'the playback spool'), P('Ra_term_stream_open', 'open a stream at the terminal'), P('Ra_dial_next', 'pick the next track'), P('Ra_page_hole', 'a missing chunk in a page — re-ask page-wide'), P('Ra_clock_arm', 'the pull clock')],
 ['What:the radio', 'Radio — ensure toggle skip and like — sources and the dial — the lineup — the head run decoded ahead',
  'Doc:Ghost/M/Radio.g', P('Radio_ensure', 'the radio particle'), P('Radio_toggle', 'play pause'), P('Radio_skip', 'next'), P('Radio_like', 'the heart — love toggles the Heard take'), P('Radio_sources', 'where music can come from'), P('Radio_source_next', 'rotate the source'), P('Radio_dial_remote', 'dial a friend'), P('Radio_dial_pool', 'dial the pool'), P('Radio_lineup_fill', 'fill the lineup'), P('Radio_playable', 'can this card play now'), P('Radio_hbase', 'prepend the head run'), P('Radio_dec_open', 'open the decoder'),
  'Doc:src/lib/O/ui/RadioFace.svelte', 'Doc:src/lib/O/ui/LineupFace.svelte', 'Doc:src/lib/O/ui/TunerFace.svelte'],
 ['What:the stoker and the riffle', 'what warms the next play — churn preheat cull — a card dealt from a shelf',
  'Doc:Ghost/M/Radio.g', P('Stoker_ensure', 'the stoker particle'), P('Stoker_churn', 'the beat'), P('Stoker_preheat', 'warm the next'), P('Stoker_cull', 'drop the cold'), P('Stoker_mag_draw', 'draw from a Mag'), P('Riffle_ensure', 'the riffle'), P('Riffle_deal_shelf', 'deal a card off a shelf'), P('Riffle_deal_deep', 'deal from deep'),
  'Doc:src/lib/O/ui/StokerFace.svelte', 'Doc:src/lib/O/ui/RiffleFace.svelte'],
 ['What:the machine', 'Radiola — the cursor models the streaming spine was first proven on — streamability keep-ahead wear and the live edge',
  'Doc:Ghost/M/Radiola.g', P('req_streamability', 'enough ahead to play'), P('Radiola_keep_ahead', 'how far ahead to stock'), P('req_restock', 'make more'), P('req_reap', 'wear out the old'), P('Glide_decide', 'live-edge rate slew'), P('LiveEdge_decide', 'the safe margin off the frontier')],
 ['What:the audio engine', 'Sound — synth silence measure and the starving live-stream pump — real muted Web Audio',
  'Doc:Ghost/M/Sound.g', P('Sound_synth', 'synth pcm'), P('Sound_measure', 'measure entropy of pcm'), P('Sound_radiostock', 'the stock pump'), P('Sound_stock_chunk', 'one chunk to the graph'), P('Sound_panic', 'stop everything'), 'Doc:src/lib/O/Funk/Sound.svelte'],
 ['What:the crate', 'digging a music collection — meta from a name or a path — the transcode and the radiostock override',
  'Doc:Ghost/M/Crate.g', P('Crate_nav', 'the nav over the collection'), P('Crate_radiostock', 'stock from the crate'), P('Crate_meta_from_path', 'artist title from a path'), P('Crate_transcode_release', 'let a transcode go'), P('Crate_pile_draw', 'draw from the pile'), 'Doc:src/lib/O/ui/CrateFace.svelte'],
 ['What:the mixer and the mesh', 'beat detection beatmatch crossfade and the DJ cue — the sync that sees itself',
  'Doc:Ghost/M/Mixer.g', P('Mix_tempo', 'beats per minute'), P('Mix_beatmatch', 'align two decks'), P('Mix_crossfade', 'fade between'), P('Mix_align', 'phase align'),
  'Doc:Ghost/M/Mesh.g', P('Mesh_route', 'cheapest route'), P('Mesh_broadcast_stretch', 'multicast stretch'),
  'Doc:Ghost/M/Booth.g', P('Tune_of', 'a tune key'), P('Booth_bans', 'what the booth bans')],
 ['What:the tests', 'Doc:Ghost/Story/MusuTesting.g', 'Doc:Ghost/Story/RaTesting.g'],
 ['What:the spec', 'Doc:src/lib/O/spec/Radio_todo.md', 'Doc:src/lib/O/spec/Radio_circuit_todo.md', 'Doc:src/lib/O/spec/SoundPooling_todo.md', 'Doc:src/lib/O/spec/Radio_spec.md', 'Doc:src/lib/O/spec/Radio_design.md', 'Doc:src/lib/O/spec/Radio_lowlevel.md', 'Doc:src/lib/O/spec/Radio_multicast_todo.md', 'Doc:src/lib/O/spec/Backpressure_todo.md'],
]])

W.push(['Ghost/Music/Cave', 'the collection — heist original bytes into the Cave — the keep chooses — the Heard Mag is the ledger of love — a phone hands its loves to the laptop',
 ['MusuHeist','MusuHeard','MusuHandoff','MusuBerth','MusuVend','MusuDoor','MusuCursor','MusuHeal','MusuResume','MusuRename','MusuRecast','MusuStanding','MusuFreeze','MusuReap','MusuSoft','MusuBay','MusuBreach','MusuMag','MusuBuddy','MusuSteward','MusuSmuggle','Heistation','Siphonation'], [
 ['What:the heist', 'Heist — ORIGINAL file bytes move straight into the collection — a job a filing a body',
  'Doc:Ghost/M/Heist.g', P('Heist_job', 'one heist — what to pull and where'), P('Heist_body_new', 'a body to receive bytes'), P('Heist_has_body', 'is the whole body here'), P('Heist_filing_for', 'where a track files'), P('Heist_manifest', 'what a heist will take'), P('Heist_release_rec', 'let a record go'), P('Heist_xfer_breach', 'bytes that do not hash — refused'),
  'Doc:src/lib/O/ui/HeistFace.svelte', 'Doc:src/lib/O/ui/HeistBarFace.svelte', 'Doc:src/lib/O/Funk/HeistSetup.svelte'],
 ['What:the keep', 'what we choose to take — picks genre lofi dirs — the memo — pause resume and the haul',
  'Doc:Ghost/M/Heist.g', P('Heist_keep_id', 'the keep id'), P('Heist_keep_remember', 'remember the keep'), P('Heist_keep_pick_toggle', 'pick or unpick'), P('Heist_keep_set_genre', 'a genre filter'), P('Heist_keep_pause', 'pause'), P('Heist_keep_resume', 'resume'), P('Heist_keep_commit', 'commit the choices'), P('Heist_haul_rows', 'the haul — what is coming'), P('Heist_keep_gist', 'one line about the keep'),
  'Doc:src/lib/O/ui/HaulFace.svelte', 'Doc:src/lib/O/ui/PickFace.svelte'],
 ['What:the rummage', 'soft heist — words and leads — a wish hardens into a pull',
  'Doc:Ghost/M/Heist.g', P('Heist_wish', 'a wish for music'), P('Heist_soft', 'soft search'), P('Heist_words', 'the words of a wish'), P('Heist_match', 'does a record match'), P('Heist_leads', 'where to look'), P('Heist_rummage_recs', 'rummage a shelf'), P('Heist_rummage_wire', 'rummage over the wire'), P('Heist_blag_folder', 'take a whole folder')],
 ['What:the berth', 'the magazine on disk — parts and the fold — Musica the zine — a cursor names a spot and heals across a rename',
  'Doc:Ghost/M/Heist.g', P('Berth_dir', 'where a berth lives'), P('Berth_fold', 'fold parts'), P('Musica_zine_ensure', 'the zine'), P('Musica_cards', 'cards of the zine'), P('Musica_rename', 'rename with a redirect'), P('Cursor_make', 'a cursor into a magazine'), P('Cursor_resolve', 'find the spot'), P('Cursor_heal', 'heal across a rename'), 'Doc:src/lib/O/ui/ZineFace.svelte'],
 ['What:the heard', 'the Heard Mag is the ledger — a Card per track per pub — love takes and unlove unwants — verdicts and the unseen mark',
  'Doc:Ghost/M/Heard.g', P('Heard_mag', 'the Mag per pub'), P('Heard_card', 'the Card per track'), P('Heard_take', 'love — take it'), P('Heard_unwant', 'unlove — drop the ask keep the listing'), P('Heard_taken', 'is it loved'), P('Heard_verdict', 'what happened to the take'), P('Heard_notice', 'mark unseen on arrival'), P('Heard_unseen', 'how many unseen'), P('Heard_gc', 'the clock that forgets'), P('Heard_clone_beat', 'copy verdicts across')],
 ['What:the hand road', 'a phone hands its loved tracks to the laptop — land got and wake',
  'Doc:Ghost/M/Heard.g', P('Heard_hand_targets', 'who to hand to'), P('Heard_hand_land', 'a hand lands'), P('Heard_hand_got', 'the laptop says got'), P('Heard_hand_wake', 're-offer'), P('Heard_tip', 'tip a card over')],
 ['What:the siphon', 'tags and playlists over the collection',
  'Doc:Ghost/M/Siphon.g', P('Siphon_tags', 'the tag set'), P('Siphon_tag_apply', 'tag a track'), P('Siphon_playlist', 'a playlist from tags'), P('Siphon_home', 'where siphons live')],
 ['What:the tests', 'Doc:Ghost/Story/HeistTesting.g', 'Doc:Ghost/Story/BerthTesting.g', 'Doc:Ghost/Story/SiphonTesting.g'],
 ['What:the spec', 'Doc:src/lib/O/spec/Heist_todo.md', 'Doc:src/lib/O/spec/Heist_design.md', 'Doc:src/lib/O/spec/Mag_todo.md', 'Doc:src/lib/O/spec/Mag_design.md', 'Doc:src/lib/O/spec/Siphon_todo.md', 'Doc:src/lib/O/spec/Fallen_out_of_mind_todo.md', 'Doc:src/lib/O/spec/Radio_circuit_todo.md'],
]])

W.push(['Ghost/Vis/Visua', 'the visual — the crush that gangs leaves — the glass that cuts cells from the model — what a Book looks like while it runs',
 ['VoroMitosis','VoroScape','VoroRadio','VoroClinic','VoroTest','VytoStaple','VytoCell','VytoMitosis','VytoTandem','VytoFreeze','VytoSeek','VytoCrest','VytoFold','VytoBunch','VytoFoam','VytoBreathe','VytoNest','VytoMemo','VytoNeed','VytoDepth','VytoOrchestra'], [
 ['What:the crush', 'Voro — the census that gangs loose leaves behind a representative — the model and its facts',
  'Doc:Ghost/V/Voro.g', P('Voro_crush_scan', 'scan the worlds'), P('Voro_crush_pass', 'one pass — escalate a level'), P('Voro_crushable', 'may this gang'), P('Voro_crush_clear', 'undo'), P('Voro_model', 'the model of a family'), P('Voro_model_family', 'one family'), P('Voro_gang_fold', 'fold a gang behind a representative')],
 ['What:the stuffing', 'Vtuff — what a cell says about itself — title rows member rows and the bamboo',
  'Doc:Ghost/V/Voro.g', P('Vtuff_build', 'build the stuffing'), P('Vtuff_name', 'a name for a cell'), P('Vtuff_title_row', 'the title row'), P('Vtuff_member_rows', 'the members'), P('Vtuff_bamboo', 'the bamboo axis')],
 ['What:the glass', 'Vyto — the power-diagram foam cut and sprung from the model with no cytoscape — a board is commissioned beside a run',
  'Doc:Ghost/V/Vyto.g', P('Vyto_board', 'the board particle'), P('e_Vyto_commission', 'commission a glass beside a run'), P('Vyto_watch', 'watch a world'), P('Vyto_decommission', 'take it down'), P('Vyto_stir', 'the stir — re-cut'), P('Vyto_scan', 'scan the model'), P('Vyto_fold', 'fold the least dominant family'), P('Vyto_distil', 'distil rows to cells')],
 ['What:the solve', 'seats and sizes — express solves the seats and calm pins one — relate and importance',
  'Doc:Ghost/V/Vyto.g', P('Vyto_solve', 'solve the seats'), P('Vyto_express', 'express sizes'), P('Vyto_relate', 'kin attraction'), P('Vyto_importance', 'graph-global importance'), P('Vyto_need_of', 'what a widget needs'), P('Vyto_slope', 'the slope'), P('Vyto_mesh', 'the mesh'),
  'Doc:src/lib/O/vyto_foam.ts', 'Doc:src/lib/O/vyto_seat.ts', 'Doc:src/lib/O/vyto_geometry.ts', 'Doc:src/lib/O/vyto_gauge.ts'],
 ['What:attention', 'focus attend release — the pointer enters and the calm yields — the spool and the seek',
  'Doc:Ghost/V/Vyto.g', P('Vyto_focus', 'focus a cell'), P('Vyto_attend', 'attend'), P('Vyto_release', 'release'), P('Vyto_pointer_enter', 'the pointer arrives'), P('Vyto_calm_yield', 'calm yields to motion'), P('Vyto_spool_cull', 'cull the spool to its cap'), P('Vyto_seek_to', 'seek to a moment'),
  'Doc:src/lib/O/vyto_focus.ts', 'Doc:src/lib/O/vyto_pane.ts'],
 ['What:the render', 'Vytui paints the glass — Cyto and Cytui are the older force layout — Matstyle is the auto swatch',
  'Doc:src/lib/O/Vytui.svelte', 'Doc:src/lib/O/Cyto.svelte', P('cyto_scan', 'walk the particles into nodes'), P('cytyle_classify', 'skip invisible compound'), P('cyto_update_wave', 'the animation wave'),
  'Doc:src/lib/O/Cytui.svelte', 'Doc:src/lib/O/Matstyle.svelte', P('matstyle_for', 'a swatch for a mainkey'), P('matstyle_apply', 'apply'), 'Doc:src/lib/O/glass_faces.ts', 'Doc:src/lib/O/glass_kinds.ts', 'Doc:src/lib/V/BigShapeland.svelte', 'Doc:scripts/runner_shot.mjs', 'Doc:scripts/runner_eye.mjs'],
 ['What:the tests', 'Doc:Ghost/Story/VoroTesting.g', P('VoroMitosis_seed', 'a flora that divides'), P('VoroScape_library', 'a library scape'), 'Doc:Ghost/V/VytoTesting.g', P('VytoStaple_seed', 'the glass beside a run'), P('VytoCell_seed', 'dosed cogs into cells'), P('VytoMitosis_found', 'grow and go extinct'), P('VytoTandem_found', 'two watchers one gear'), P('VytoFreeze_stand', 'freeze on a failed run'), P('VytoSeek_stand', 'seek a step pip')],
 ['What:the spec', 'Doc:src/lib/O/spec/Glassbeast_todo.md', 'Doc:src/lib/O/spec/Vyto_spec.md', 'Doc:src/lib/O/spec/Vyto_todo.md', 'Doc:src/lib/O/spec/Vyto_sizing_todo.md', 'Doc:src/lib/O/spec/Vyto_perf_todo.md', 'Doc:src/lib/O/spec/Cellsizing_todo.md', 'Doc:src/lib/O/spec/Voro_todo.md', 'Doc:src/lib/O/spec/Voro_vtuffing.md', 'Doc:src/lib/O/spec/Voro_svg_stuffing.md', 'Doc:src/lib/O/spec/Lens_posable_TODO.md', 'Doc:src/lib/O/spec/Waft_styling_todo.md'],
]])

W.push(['Ghost/Land/Wordland', 'the land — the bet turned on the code itself — what the code says what it does and who asks',
 ['AtlasStaple','ElectrodeStaple','LagoonStaple','Hackarium','Educarium'], [
 ['What:what the code says', 'Atlas keeps the compiler Map for every doc headless — the corpus rostered in full on a runner',
  'Doc:Ghost/L/Atlas.g', P('Atlas', 'the ghost'), P('Atlas_plan', 'the plan — roster and census'), P('Atlas_nav', 'the nav it reads through'), P('Atlas_db', 'the map store'),
  'Doc:src/lib/server/dige.ts', 'Doc:src/lib/O/lang/compile.ts'],
 ['What:what the code does', 'Electrode taps both ends of every ghost call and reduces on demand to a Flow',
  'Doc:Ghost/L/Electrode.g', P('Electrode_arm', 'arm the tap'), P('Electrode_mark', 'one call marked'), P('Electrode_reduce', 'reduce to Method and Flow'), P('Electrode_top', 'the busiest'), P('Electrode_hangs', 'calls that never returned'), P('Electrode_film', 'the film strip')],
 ['What:the reader', 'Lagoon asks and Atlas keeps — seek callers defs families mentions rot — the errands off the Aside',
  'Doc:Ghost/L/Lagoon.g', P('Lagoon_seek', 'find a name'), P('Lagoon_callers', 'who calls it'), P('Lagoon_defs', 'where it is defined'), P('Lagoon_families', 'the name families'), P('Lagoon_mentions', 'prose mentions'), P('Lagoon_prose_rot', 'comments gone stale'), P('Lagoon_lint', 'the lint'), P('Lagoon_errands', 'the Aside read back newest first'), P('Lagoon_figurines', 'distinct-caller size')],
 ['What:the rooms', 'BigWordland is the room — the Hackarium the Clerkdesk the Educarium',
  'Doc:src/lib/L/BigWordland.svelte', 'Doc:src/lib/L/Hackarium.svelte', 'Doc:src/lib/L/Clerkdesk.svelte', 'Doc:src/lib/L/Educarium.svelte', 'Doc:src/lib/L/Lagui.svelte', 'Doc:src/lib/L/testing.ts'],
 ['What:the tests', 'Doc:Ghost/L/AtlasTesting.g', 'Doc:Ghost/L/ElectrodeTesting.g', 'Doc:Ghost/L/LagoonTesting.g'],
 ['What:the spec', 'Doc:src/lib/O/spec/Wordland_todo.md', 'Doc:src/lib/O/spec/Lagoon_todo.md', 'Doc:src/lib/O/spec/Electrode_todo.md', 'Doc:src/lib/O/spec/Stemdex_todo.md', 'Doc:src/lib/O/spec/Stemdex_spec.md', 'Doc:src/lib/O/spec/Clerkdesk_todo.md', 'Doc:src/lib/O/spec/Docindex_todo.md', 'Doc:src/lib/O/spec/Meaningfold_todo.md'],
]])

W.push(['Ghost/Lake/Easy', 'the foundation — particles in a House — the req machine — the Story that proves — the Lies pipeline that compiles and runs — the language of Wafts',
 ['LakeSurfer','LakeNets','LakeFlush','LakeTiles','LakeSurprise','LakeLocate','LakeFunk','LakeKeep','LakeLango','LakeWaftMap','LakeSearch','LakeTtlilt','PortPlan','PortPlanet','PortPlant','PortPain','StuffFlipping','StuffResolving','LeafFarm','LeafJuggle','Diffmatication','Editron','Interesting','MundaneStation','MundaneStaying','ReactiveWaft','Snapmigrating','Snaptesting','TextInca','Understandication','Understandity','Understandium','Engage','WaftMapPacked','ErrChannel','RehealSmoke','Nestcut','GhoghoDrone','BootGateNoFSA'], [
 ['What:the particle', 'everything is a C — the mainkey is what a thing IS — sc snaps and c is runtime only — o finds i creates oai finds-or-creates',
  'Doc:src/lib/data/Stuff.svelte.ts', P('o', 'find children matching sc'), P('i', 'create a child'), P('oai', 'find or create'), P('oa', 'boolean probe'), P('r', 'async replace — never read after a bare r'), P('drop', 'detach a child'), P('bump', 'version up — watchers react'), P('resolve', 'pair a particle across past and future'),
  'Doc:src/lib/O/Text.svelte', P('enWaft', 'encode a Waft tree'), P('deWaft', 'decode one'), P('enLine', 'one line'), P('deL', 'one line back'), P('make_diff', 'the snap diff'), P('spay_classify_line', 'what a diff line means — graft blown mung'),
  'Doc:src/lib/O/spec/NOTATION.md', 'Doc:src/lib/O/spec/Cstructures_todo.md'],
 ['What:the House', 'the container hierarchy — Mundo actors and worlds — the beliefs mutex — the Wormhole park',
  'Doc:src/lib/O/Housing.svelte.ts', P('beliefs', 'one tick under the mutex'), P('main', 'wake a tick'), P('post_do', 'run later under the mutex'), P('eatfunc', 'a ghost deposits its methods on H'), P('i_elvisto', 'the deferred cross-ghost call'), P('subHouse', 'a nested House'), P('top_House', 'walk up to Mundo'), P('Wormhole', 'the disk actor'), P('Wormhole_park', 'park an op — timeout retry generation'), P('read_file', 'read through the nav'), P('write_file', 'write through the nav'),
  'Doc:src/lib/O/Ghost.svelte', 'Doc:src/lib/O/Auto.svelte', P('auto_reset_story', 'tear down and re-post a Book'), P('Clustation_ensure_identity', 'the ?I= identity'), P('Cred_assertion_gaps', 'sworn sentences the run did not say'),
  'Doc:src/lib/O/MountNav.svelte.ts', 'Doc:src/lib/O/WormholeOpfs.svelte.ts', 'Doc:src/lib/O/RemoteWormholeNav.svelte.ts'],
 ['What:the req machine', 'Hovercraft — a stack of requirements at maz levels — a ttlilt bows out — eternal and permanent — the EntropyArrest',
  'Doc:src/lib/O/Hovercraft.svelte', P('reqyoncile', 'ensure a req exists at its level'), P('i_req_ttlilt', 'arm a wait — bow out — come back'), P('Runstepped', 'a step of runnable work'), P('whittle_N', 'keep the last N children'), P('The_EntropyArrest', 'the arrest — spay and forgive'), P('entropy_diagnose', 'why the snap churns'),
  'Doc:src/lib/O/spec/Hovercraft.design.md', 'Doc:src/lib/O/spec/Coding_guide.md', 'Doc:src/lib/O/spec/EntropyArrest.md'],
 ['What:the Story', 'the test runner — a Book of steps — snap diff and dige — sworn assertions — the Supervisor watches a run',
  'Doc:src/lib/O/Story.svelte', P('story_drive', 'drive the steps'), P('story_snap', 'snap the world between steps'), P('story_swear', 'swear a sentence — an oath the Book must say'), P('story_harvest_sworn', 'gather oaths to the Assertioning shelf'), P('story_save', 'write the fixture'), P('story_analysis', 'the verdict'), P('The_step_dige', 'the change-sensitivity digest'), P('e_story_accept', 'accept a step as the new fixture'),
  'Doc:src/lib/O/Storui.svelte', 'Doc:Ghost/O/Supervisor.g', P('Supervisor', 'the ghost'), P('Supervisor_beat', 'the beat'), P('Supervisor_watch', 'watch a runner'), P('Supervisor_verdict', 'the verdict on a run'), P('Supervisor_summary', 'one line'),
  'Doc:src/lib/O/Funk/CreduFunk.svelte', 'Doc:src/lib/O/Funk/Storying.svelte', 'Doc:scripts/story_accept.mjs'],
 ['What:the compile pipeline', 'Lies — Store Cortex Codebit Rundown — the dock compiles to a .go and a runner runs it',
  'Doc:src/lib/O/Lies.svelte', P('Lies_resolve_locator', 'Waft:x/What:y — the loose locator'), P('Lies_focus_waft', 'which Waft is in focus'), P('e_Lies_open_Waft', 'open a Waft'), P('e_Lies_ghost_pick', 'jump if open else today Aside'), P('e_Lies_want', 'a want lands'),
  'Doc:src/lib/O/LiesStore.svelte', P('req_Store', 'the IO pump'), P('LiesStore_read', 'read'), P('LiesStore_write', 'write'), P('LiesStore_listing', 'list a dir'), P('Lies_waft_save', 'persist a Waft'), P('Lies_spawn_aside_waft', 'today Aside'),
  'Doc:src/lib/O/LiesCortex.svelte', P('req_Cortex', 'the compile foreman'), P('req_Codebit', 'one per dock — owns the generated write'),
  'Doc:src/lib/O/LiesRun.svelte', P('req_Rundown', 'the runner'), 'Doc:src/lib/O/LiesFunk.svelte', 'Doc:src/lib/O/LiesKeep.svelte', P('Lies_keep_reopen', 'reopen every Waft in the ledger at boot'), P('Lies_keep_note', 'a Waft was found'), P('Lies_keep_resume_waft', 'the last Waft focused'),
  'Doc:src/lib/O/LiesCurse.svelte', 'Doc:src/lib/O/Liesui.svelte'],
 ['What:the language', 'Lang — the .g grammar — Waft What Doc Point — the minimap folds around engaged Points',
  'Doc:src/lib/O/Lang.svelte', P('Lang_open_dock', 'open a dock'), P('Lang_build_mapules', 'the minimap rows'), P('e_Lang_goto_point', 'go to a Point'), P('req_Languish', 'the dock req'),
  'Doc:src/lib/O/LangCompiling.svelte', P('Lang_compile', 'compile a .g'), P('Lang_compile_dock', 'compile the mounted dock'),
  'Doc:src/lib/O/LangHold.svelte', P('LE_arm', 'the understanding'), P('LE_push', 'push the working Seem back'), P('LE_pull', 'pull'), P('req_understanding', 'the checkout'),
  'Doc:src/lib/O/LangPoint.svelte', 'Doc:src/lib/O/LangWhatwhere.svelte', 'Doc:src/lib/O/Langui.svelte', 'Doc:src/lib/O/lang/lang.ts', 'Doc:src/lib/O/spec/stho_primer.md'],
 ['What:the faces', 'the Waft body and its Funkcions — the Searchbar the Aside the Keep',
  'Doc:src/lib/O/ui/Waft.svelte', 'Doc:src/lib/O/ui/NaviCado.svelte', 'Doc:src/lib/O/ui/Searchbar.svelte', 'Doc:src/lib/O/Funk/DocGhostList.svelte', 'Doc:src/lib/O/Funk/DocWaftMap.svelte', 'Doc:src/lib/O/Funk/Shelver.svelte', 'Doc:src/lib/O/Editron.svelte', 'Doc:src/lib/O/Otro.svelte'],
 ['What:the spec', 'Doc:src/lib/O/spec/Homethink_todo.md', 'Doc:src/lib/O/spec/Story_future.md', 'Doc:src/lib/O/spec/Story_hygiene_todo.md', 'Doc:src/lib/O/spec/Seen_split_todo.md', 'Doc:src/lib/O/spec/Editron.md', 'Doc:src/lib/O/spec/Supervisor_todo.md', 'Doc:src/lib/O/spec/Keeping_spec.md', 'Doc:src/lib/O/spec/Interest.md', 'Doc:src/lib/O/spec/Loose_ends_todo.md', 'Doc:src/lib/O/spec/Everything_todo.md'],
]])

// ── Waft:Everything — the front door.  Each area What carries FromWhat:Waft:<key> (the locator
//  Lies_resolve_locator reads) and the area's own front-door docs so there is something to click today.
W.push(['Everything', 'READ THIS FIRST — one Waft per area of the program lists its main functions with keywords — this Waft locates them all — the policy is the last What', [], [
 ['What:the wire', 'Ghost/Net/Easy — Peeroleum Tribunal Reliable Tyrant Presence Repli — the relay — the cluster channel', 'FromWhat:Waft:Ghost/Net/Easy',
  'Doc:Ghost/N/Peeroleum.g', 'Doc:src/lib/server/relay.ts', 'Doc:src/lib/O/spec/Peeroleum_spec.md'],
 ['What:the swarm', 'Ghost/Swarm/Easy — soul crew invite door reach ferry bodies gossip stash theft', 'FromWhat:Waft:Ghost/Swarm/Easy',
  'Doc:Ghost/S/Swarm.g', 'Doc:src/lib/O/spec/Swarm_spec.md', 'Doc:src/lib/O/spec/Crew_todo.md'],
 ['What:the music', 'Ghost/Music/Ality — Ra Radio Radiola Sound Crate Orig Mixer Mesh — stock cast term — the pool', 'FromWhat:Waft:Ghost/Music/Ality',
  'Doc:Ghost/M/Ra.g', 'Doc:Ghost/M/Radio.g', 'Doc:src/lib/O/spec/Radio_todo.md'],
 ['What:the cave', 'Ghost/Music/Cave — Heist Heard Siphon — the keep the Mag the hand road', 'FromWhat:Waft:Ghost/Music/Cave',
  'Doc:Ghost/M/Heist.g', 'Doc:Ghost/M/Heard.g', 'Doc:src/lib/O/spec/Heist_todo.md'],
 ['What:the visual', 'Ghost/Vis/Visua — Voro Vyto Vytui Cyto Matstyle — crush glass solve attention', 'FromWhat:Waft:Ghost/Vis/Visua',
  'Doc:Ghost/V/Vyto.g', 'Doc:src/lib/O/Vytui.svelte', 'Doc:src/lib/O/spec/Glassbeast_todo.md'],
 ['What:the land', 'Ghost/Land/Wordland — Atlas Electrode Lagoon — BigWordland Hackarium Clerkdesk', 'FromWhat:Waft:Ghost/Land/Wordland',
  'Doc:Ghost/L/Lagoon.g', 'Doc:src/lib/L/BigWordland.svelte', 'Doc:src/lib/O/spec/Wordland_todo.md'],
 ['What:the foundation', 'Ghost/Lake/Easy — the particle the House the req machine the Story Lies Lang the faces', 'FromWhat:Waft:Ghost/Lake/Easy',
  'Doc:src/lib/data/Stuff.svelte.ts', 'Doc:src/lib/O/Housing.svelte.ts', 'Doc:src/lib/O/Hovercraft.svelte', 'Doc:src/lib/O/spec/Coding_guide.md'],
 ['What:the Books', 'Credence — every Book grouped by What with a desc naming what the group tests — run one from its Storying', 'FromWhat:Waft:Credence',
  'Doc:src/lib/O/Funk/CreduFunk.svelte', 'Doc:scripts/runner_ask.mjs', 'Doc:scripts/story_accept.mjs'],
 ['What:the shelves', 'GhostList lists the repo — Keep remembers what you had open — Aside/YMD is where errands land — Look and Ting are session-only',
  'Doc:src/lib/O/Funk/DocGhostList.svelte', 'Doc:src/lib/O/LiesKeep.svelte', 'Doc:src/lib/O/LiesStore.svelte', 'Doc:src/lib/O/spec/Keeping_spec.md', 'Doc:src/lib/O/spec/Clerkdesk_todo.md'],
 ['What:the policy', 'how this map is kept — each rule is one What below with the rule as its desc',
  ['What:one Waft per area', 'a ghost lives in ONE area Waft — a Doc may be cited from another area only under a What that says why'],
  ['What:Points are the main functions', 'a Point method is an entry the reader should know — with keywords as its desc — not every def — the code is the full list'],
  ['What:no commas in a desc', 'the peel parser splits on commas — use an em-dash'],
  ['What:Books live in CreduFunk', 'an area Waft lists its FIXTURED Books under Funkcion:CreduFunk so they run from there — Credence stays the full index'],
  ['What:the spec What is last', 'specs and todos sit under What:the spec at the tail — a _todo opens with §0 what to get on with next — only the human promotes a doc to _spec'],
  ['What:rebalance when an area splits', 'when a Waft passes about 150 lines or two stories live in it — split it and add the new Waft here'],
  ['What:stale names are bugs', 'a Doc path or Point that no longer resolves is a mint bug — scripts/wafts_everything.mjs validates every one before writing — re-run it after a rename'],
  ['What:new sessions read this Waft first', 'then the area Waft for the work at hand — then its _todo §0']],
]])

// ── validate + emit ──
const defs = new Map()
const defsOf = (p) => {
  if (!defs.has(p)) {
    const s = fs.readFileSync(ROOT + '/' + p, 'utf8')
    const set = new Set()
    for (const m of s.matchAll(/^\s*(?:export\s+)?(?:async\s+)?(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*\(/gm)) set.add(m[1])
    for (const m of s.matchAll(/^\s*(?:export\s+)?(?:const|let)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=/gm)) set.add(m[1])
    defs.set(p, set)
  }
  return defs.get(p)
}
let bad = 0
const out = []
for (const [name, wdesc, books, tree] of W) {
  const lines = [`Waft:${name}${wdesc ? ',desc:' + wdesc : ''}`]
  if (books.length) lines.push(`  Funkcion:CreduFunk`)
  for (const b of books) {
    if (!fs.existsSync(`${ROOT}/wormhole/Story/${b}`)) { console.log(`✗ ${name}: no Book ${b}`); bad++ }
    lines.push(`    Funkcion:Storying,of_Book:${b}`)
  }
  const emit = (node, depth) => {
    const pad = '  '.repeat(depth)
    let lastDoc = null
    const [head, ...rest] = node
    const desc = (typeof rest[0] === 'string' && !/^(Doc:|Point:|FromWhat:)/.test(rest[0])) ? rest.shift() : null
    const from = (typeof rest[0] === 'string' && rest[0].startsWith('FromWhat:')) ? rest.shift().slice(9) : null
    if (/,/.test(desc || '') || /,/.test(head)) { console.log(`✗ ${name}: comma in ${head}`); bad++ }
    lines.push(`${pad}${head}${desc ? ',desc:' + desc : ''}${from ? ',FromWhat:' + from : ''}`)
    for (const c of rest) {
      if (Array.isArray(c)) { emit(c, depth + 1); continue }
      if (c.startsWith('Doc:')) {
        lastDoc = c.slice(4)
        if (!fs.existsSync(ROOT + '/' + lastDoc)) { console.log(`✗ ${name}: missing ${lastDoc}`); bad++ }
        lines.push(`${pad}  ${c}`)
      } else if (c.startsWith('Point:')) {
        const [m, d] = c.slice(6).split('|')
        if (!lastDoc || !defsOf(lastDoc).has(m)) { console.log(`✗ ${name}: ${lastDoc} has no def ${m}`); bad++ }
        if (/,/.test(d || '')) { console.log(`✗ ${name}: comma in desc of ${m}`); bad++ }
        lines.push(`${pad}  Point,method:${m}${d ? ',desc:' + d : ''}`)
      }
    }
  }
  for (const w of tree) emit(w, 1)
  out.push([name, lines.join('\n') + '\n'])
}
if (bad) { console.log(`${bad} problem(s) — nothing written`); process.exit(1) }
for (const [name, text] of out) {
  const dir = `${ROOT}/wormhole/${name}`
  fs.mkdirSync(dir, { recursive: true })
  fs.writeFileSync(`${dir}/toc.snap`, text)
  console.log(`✓ wormhole/${name}/toc.snap  ${text.split('\n').length - 1} lines`)
}

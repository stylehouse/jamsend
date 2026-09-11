# Sweep report — 2026-09-11 (sweep 18:46→21:00, re-runs 21:03→21:32, runner e747cbed6a9ca919)

162 fixtured Books; 7 skipped by rule; 155 ran.

| class | n |
|---|---|
| green (ok:true, caveat:0) | 87 |
| caveat-only (ok:true, caveat>0) | 21 |
| known (a) L-ghost not loaded | 3 |
| known (b) see:lies row — needs human re-swear | 17 |
| flake (red/never-started in sweep, green or caveat-only on re-run) | 11 |
| unexplained red (stays red on 2 re-runs) | 16 |

Sweep caveats
- Tree moved under the sweep: owner committed 1881f9f0 (12:35), 46fb2164 (13:30), 5778eec6 (18:58) and is editing Vyto.g/Swarm.g uncommitted; HMR reloads land on the runner.
- Another client used the SAME runner mid-sweep: the state lines for MusuMag, MusuOgg (run.book=Ghost/V/Vyto.g), Peregrination (Ghost/N/Peeroleum), SwarmChain (VytoDepth), SwarmCharter (VytoOrchestra), SwarmCohort (VytoNest) reported someone else's run. All six were re-run clean; SwarmChain/SwarmCohort/Peregrination are green.
- 12 never-starts in the sweep (8 wedged at phase `begun`, 2 outcome:null/run:null, 2 empty replies). All re-run.
- No `wormhole/Story/*/NNN.snap` fixture is modified in the working tree; the 409 modified wormhole files are runner-written toc.snap TimeSpool samples.
- /music inside this container holds only `.jamsend` (mount state), yet the streaming Musu family is green, so not a factor here.

## Non-green Books

known (a): AtlasStaple, ElectrodeStaple, LagoonStaple — L ghost loads on demand gaps.
known (b): Diffmatication (never-started in sweep; re-run = usual b red), Educarium, Engage, Hackarium, Interesting, LakeFlush, LakeFunk, LakeKeep, LakeLango, LakeLocate, LakeNets, LakeSearch, LakeSurfer, LakeSurprise, LakeTiles (begun-wedge in sweep; re-run = usual b red), LakeTtlilt, LakeWaftMap.
caveat-only: MusuBay(1) MusuCrowd(5) MusuFreeze(1) MusuLive(5) MusuReco(7) MusuSignal(1) MusuStanding(1) MusuStaple(5) MusuStock(5) MusuStream(5) PereComplain(1) PereReborn(7) PereStaple(19) PereTyrant(1) Snaptesting(1) SwarmDoor(1) SwarmGot(2) SwarmShare(8) TextInca(1) VoroMitosis(10) VytoMemo(3).
flake: SwarmBlotter (null→green), MusuBerth (empty→green), PortPlant (begun→green), RepliShadow (begun→green), VoroTest (begun→green), SwarmCharter (begun-wedge twice, green 3rd run), PereProof (empty→caveat 29/33), MusuWear (begun→caveat 5/5), MusuPier (0.67→caveat 3/6), PeeringLive (0.83→caveat 6/6), SwarmWire (red 0.83 w/ gap→caveat 1/5).

unexplained red (persistent; first failing step, reading, fixture age):
- MusuHandoff — step 4, 0.5. New scalar `unseen:1` on the handed Card; `unseen` stamp entered Heard.g in TODAY's commit 1881f9f0. Fixture 09-05. Intended change → re-swear, else a regression of 1881f9f0.
- MusuRaChase — step 1, 0/56. New scalar `now=1751990010` on w:. Clock pin added to the drive in ca0e4fb4 (09-09); fixture 07-11. Stale fixture, every step differs.
- MusuRaStream — step 1, 0/40. Same as MusuRaChase (`now=1751980010`); fixture 07-08.
- VytoOrchestra — step 2, 0.13. Changed scalar: `Stray:moth,loose` / `Stray:lint,loose` (mint gained `loose:1` in ca0e4fb4); fixture 08-09. Stale fixture.
- SwarmSpread — all 5 steps green; red only by assertion gaps: toc.snap declares the 5 pre-re-author (adopt road) sentences, the drive (re-authored 09-03) swears different ones. Needs human re-declare.
- Peeringinst — step 1, 0/2. Got world is hollow (6 lines vs 91): no Peering/Pier minted, no mo:main. Fixture 06-07, contains `mo:main` + `{"see":…}` rows → ancient, almost certainly long-red.
- PortPain — step 1, 0/2. The FIXTURE is a PortPlan snap (`H:PortPlan,Run` / `w:PortPlan` / `De:sort` / `De:yay`) — mis-recorded fixture, June 06-07. Not a regression.
- ReactiveWaft — step 1, 0/6. New rows (imount/form Waft:test1/2, UI:ReactiveInline), logger n=8→12, mo:main gone. Fixture 06-10. Stale.
- MundaneStaying — step 1, 0/3. Pure child re-order: `req:one_shot,…,finished` now serialises AFTER `self,round=2` instead of before; content identical. Fixture 06-18.
- RepliSplit — step 4, 0.6. One new row `Spin,of:a,times:1` under the ledger + gap "two spins of different tracks stayed two". Fixture 08-05.
- VytoNeed — step 3, 0.5. Timing: got snapped at round=3 with `req:floor_wait` + ttlilt still armed; fixture is round=4, floor_wait finished + see row. Reproduced 3×, so a settle-round shift, not noise. Fixture 08-12.
- VoroScape — step 2, 0.17. Two new rows: `What:the-spot,start_at=3,end_at=6` > `What:cymbal,…`. Fixture 07-13.
- VoroClinic — step 2, 0.11. Changed scalars: every Track gained year/live/remaster; Se:scape gains `trait:live ×2,regions:3`; Family gains order_by/axis; new Loud rows. Fixture 07-11.
- MusuOgg — step 2, 0.17. Changed scalars only: all `Stream,seq:16..29` cids differ (head/preskip identical, count identical) — opus chunk hashes changed. Fixture 09-04.
- MusuMag — step 2, 0.1. New subtrees `Crew,soul:…` (mate/Key) under each body + `path:` gained `testsounds/` prefix; both landed 09-05/06, fixture 09-04. Stale fixture.
- MusuBuddy — step 8, 0.78 (steps 8–9 red, 10–11 never reached: run exceeds the 240s watch). New rows `parked_want,id:02cf…,stream:opus,from_idx:16..26` (11 of them), rounds 23→20, ~12 `req:unemit,…repli_page` rows missing. Fixture 09-05 (already has Crew+testsounds). Behavioural difference in the buddy pull, worth a human look.

## Diff excerpts (fixture `<`, got `>`; mung annotations stripped; files in scratchpad as <Book>_got.snap / <Book>.diff)

MusuHandoff 004
```
48c48
<               Card,id:t1,pub:dj,take:1,at:1788500030,title:Cosmic C,artist:DJ Oscillo,handed:Laptop
>               Card,id:t1,pub:dj,take:1,at:1788500030,title:Cosmic C,artist:DJ Oscillo,handed:Laptop,unseen:1
```
MusuRaChase 001 (MusuRaStream identical shape)
```
5c5
<       w:MusuRaChase
>       w:MusuRaChase,now=1751990010
```
VytoOrchestra 002
```
15,16c15,16
<         Stray:moth
<         Stray:lint
>         Stray:moth,loose
>         Stray:lint,loose
```
Peeringinst 001 (91 → 6 lines)
```
6,9d5
<         scheme:Peering
<           lematch,class:Peering
<         scheme:Pier
<           lematch,class:Pier
11,91d6
<         Peering,name:testPeering
<         Pier,name:alice,pantsathonia=4
<         Pier,name:bob
<         {"see":"Peering: testPeering awaiting concretion..."}
…
<     mo:main,interval=3.6
< Snap:cytowave
```
PortPain 001
```
2,3c2,3
<   H:PortPlan,Run
<     A:PortPlan
>   H:PortPain,Run
>     A:PortPain
5c5
<       w:PortPlan
>       w:PortPain
7,10d6
<         De:sort
<           req:wait,time=123
<         De:yay,maz=2
<     mo:main,interval=3.6
```
ReactiveWaft 001
```
12c12,14
<         logger,n=8
>         logger,n=12
>           imount,Waft:test1,inA
>           imount,Waft:test2,inA
15a18,19
>           form,Waft:test1,open=0
>           form,Waft:test2,open=0
21d24
<     mo:main,interval=3.6
27a31
>       UI:ReactiveInline
```
MundaneStaying 001
```
6d5
<         req:one_shot,ttl=600,timer=400,finished
7a7
>         req:one_shot,ttl=600,timer=400,finished
```
RepliSplit 004
```
19a20
>           Spin,of:a,times:1
```
VytoNeed 003
```
4c4
<       self,round=4
>       self,round=3
11,12c11,13
<         req:floor_wait,finished
<         see:the wide label cell grew to hold its measured content — the need floor is honored
>         req:floor_wait
>           ttlilt
>     ttlilt,of_w:VytoNeed
```
VoroScape 002
```
9a10,11
>             What:the-spot,start_at=3,end_at=6
>               What:cymbal,start_at=4,end_at=5
```
VoroClinic 002
```
9,12c9,12
<           Track,title:a1
<           Track,title:a2
>           Track,title:a1,year:2007
>           Track,title:a2,year:2019,live
28,29c28,31
<         Se:scape,grasped:3,born:0,died:0,loudest:Artist · Alpha,regions:1
<         Family:Artist,n:2,kind:pane,from:Alpha,to:Beta
>         Se:scape,grasped:3,born:0,died:0,loudest:Artist · Alpha,trait:live ×2,regions:3
>         Family:Artist,n:2,kind:pane,order_by:year,axis:num,from:Beta,to:Alpha
>           Loud:live,share:1
>           Loud:remaster
```
MusuOgg 002 (23 lines each side, cids only)
```
33,55c33,55
<                   Stream,seq:16,head,preskip=312,cid:ed207f22…
<                   Stream,seq:17,cid:941c70d9…
>                   Stream,seq:16,head,preskip=312,cid:5915b833…
>                   Stream,seq:17,cid:217ee52d…
```
MusuMag 002
```
4c4
<       self,round=6
>       self,round=5
10a11,13
>             Crew,soul:d70f253a…
>               mate:d70f253aa325f68b,role:Captain,pub:d70f253a…
>               Key,pub:d70f253a…
<                 Record,id:d71294dbbcd7b726,…,path:DJ Oscillo - Cosmic C.wav,…
>                 Record,id:d71294dbbcd7b726,…,path:testsounds/DJ Oscillo - Cosmic C.wav,…
```
MusuBuddy 008
```
4c4
<       self,round=23
>       self,round=20
58a59,69
>             parked_want,id:02cfcb9c15affeaf,stream:opus,from_idx:16
>             parked_want,id:02cfcb9c15affeaf,stream:opus,from_idx:18
…  (11 parked_want rows, from_idx 16..36)
<               req:unemit,seq=44,type:repli_lines,…,finished
<               req:unemit,seq=45,type:repli_page,…,finished
…  (~12 unemit rows present only in the fixture)
```

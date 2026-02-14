<script lang="ts">
    import { onMount } from "svelte";
    import { throttle } from "$lib/Y";
    import Pirate from "./Pirate.svelte";
    import { _C } from "$lib/data/Stuff.svelte";

    import cytoscape from "cytoscape";
    // these are apparently the best at either hierarchical
    import dagre from "cytoscape-dagre";
    //   or force-directed, compound graphs
    //    and "fairly rich set of constraint types" https://github.com/iVis-at-Bilkent/cytoscape.js-fcose
    import fcose from "cytoscape-fcose";
    // and everything, interactively
    import cola from "cytoscape-cola";
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte";
    import ShareButton from "$lib/p2p/ui/ShareButton.svelte";
    import type { RadioModus } from "$lib/mostly/Modus.svelte.ts";
    import ActionButtons from "$lib/p2p/ui/ActionButtons.svelte";
    let layeng = fcose;
    let layeng_name = "fcose";
    cytoscape.use(layeng);
    

    //#endregion
    //#region GraphStyles
    let GraphStyles = [
        {
            selector: "node",
            style: {
                width: "50",
                height: "50",
                // all node labels (name) are scaled
                "font-size": (ele) => {
                    let name = ele.data('name')
                    if (name == 'null') return "18"
                    let len = name.length
                    let size = Math.max(22,36 - len) * 0.8
                    // console.log(`Had text: ${len} -> ${size}: ${name}`)
                    return size
                },
                "font-weight": "bold",
                label: `data(name)`,
                "text-valign": "center",
                "text-wrap": "wrap",
                "text-max-width": "140",
                "background-color": "gold",
                color: "#6f3bf5",
            },
        },

        
        // < going?
        {
            selector: 'node[class="ayethree"]',
            style: {
                width: "70",
                height: "290",
                "background-color": "chocolate",
            },
        },
        {
            selector: 'node[class="ayetwo"]',
            style: {
                width: "70",
                height: "50",
                "background-color": "goldenrod",
            },
        },



        {
            selector: "node:selected",
            style: {
                "background-color": "darkred",
                color: "white",
                "border-color": "darkred",
                "line-color": "#0e76ba",
                "target-arrow-color": "#0e76ba",
            },
        },
        {
            selector: ":parent",
            style: {
                "text-valign": "top",
                "text-halign": "center",
            },
        },

        {
            selector: "edge",
            style: {
                "curve-style": "bezier",
                "control-point-step-size": 40,
                color: "darkred",
                "text-background-color": "#003355",
                "text-background-opacity": "1",
                "text-background-padding": "1",
                width: "6",
                // "line-color": "darkred",
                //'font-weight': 'bold'
                "line-color": "gold",
                "target-arrow-color": "gold",
                "target-arrow-shape": "triangle",
            },
        },


        {
            selector: 'node[class="blob"]',
            style: {
                height: "90",
                width: "120",
                color: "black",
                "background-color": "#b394ff",
            },
        },
        // any other directory level
        // < why does node.ayefour not match? move everything to i_cla?
        {
            selector: 'node[class="ayefour"]',
            style: {
                "width": "133",
                height: "70",
                color: "pink",
                "text-rotation": "9deg",
                "line-color": "lightblue",
                "background-color": "darkblue",
                "border-color": "black",
            },
        },
        {
            selector: 'node.tilted',
            style: {
                "text-rotation": "26deg",
            },
        },
        {
            selector: 'node[class="collection"]',
            style: {
                width: "70",
                height: "90",
                "background-color": "black",
                color: "lightblue",
                "border-color": "orange",
                "border-width": "3",
            },
        },



        // the Playing pointer
        {
            selector: 'node[class="anno"]',
            style: {
                "width": "90",
                "color": "hsl(0, 29%, 45%)",
                "border-width": "0",
                "background-opacity": "0.1",
            },
        },
        {
            selector: 'edge[class="anno"]',
            style: {
                "color": "hsl(0, 29%, 45%)",
                "line-color": "hsl(0, 29%, 45%)",
                "target-arrow-color": "hsl(0, 29%, 45%)",
                "width":"1em"
            },
        },
        // and what its pointing to (the sun)
        {
            selector: 'node.nowplaying',
            style: {
                "width": "90",
                "color": "black",
                "border-color": "orange",
                "border-width": "6em",
                "z-index": -206,
            },
        },
        // the %nowSnaking route also leading there
        {
            selector: 'edge[class="outward"]',
            style: {
                // "line-color": "gold",
                "width":"1em",
                "opacity":"0.5",
            },
        },

        // wilting in time
        {selector: 'node.slightood',
        style: {"background-blacken":"0.5"}},
        {selector: 'node.quiteood',
        style: {"background-blacken":"0.7"}},





        {
            selector: 'edge[class="along"]',
            style: {
                color: "lightblue",
            },
        },
        {
            selector: "edge[label]",
            style: {
                content: `data(label)`,
            },
        },
        {
            selector: "edge.label",
            style: {
                "line-color": "white",
                "target-arrow-color": "orange",
            },
        },
    ];

    //#endregion
    //#region dealing

    let { VJ, M }:{M:RadioModus} = $props();
    let P = M.F.P
    let w = VJ.sc.VJ;
    // < put interface on M?
    let node_edger = {};
    M.node_edger = node_edger;
    M.i_elvis(w, "IamyourUI", { A: w, node_edger, thingsing: "L" });


    function get_layout_options() {
        // name = dagre|fcose|circle|grid etc
        let name = layeng_name;

        // all the constraints merged into a tree as per fcose doc / API
        let concon = node_edger.constraints_config || {}

        return {
            name,
            ...concon,
            animate: 1,
            animationDuration: 2,
            nodeSeparation: 375,
            nodeDimensionsIncludeLabels: true,
            randomize: false,

            // other options, may affect things
            //  eg cytoscape.js-klay / README / API
            // dagre
            rankDir: "TB",
            // klay
            aspectRatio: 1.3,
            avoidOverlap: 1,
        };
    }

    let ele = null;
    let cy = null;
    onMount(() => {
        cy = node_edger.cy = cytoscape({
            container: ele,
            style: GraphStyles,
        });
        cy.freshie = true
        cy.on("select", "node", () => selection_changed());
        // let graph = test_graph();
        // load_graph(graph);
        layout();
    });
    let lay;
    let relayout = throttle(() => layout(),200)
    function layout() {
        lay?.stop(); 
        lay = cy.layout({
            ...get_layout_options(),
        });
        run_layout();
    }
    function run_layout(them?) {
        // < different subsets of the graph
        them ||= lay;
        try {
            them.run();
        } catch (er) {
            console.error(er);
        }
    }

    //#endregion
    //#region dealing

    function test_graph() {
        return {
            nodes: [
                { id: "n4", name: "inner", parent: "n37" },
                { id: "n35", name: "rere", parent: "n38" },
                { id: "n37", name: "med", class: "ayefour", parent: "n38" },
                { id: "n38", name: "out", class: "ayefour" },
            ],
            edges: [
                { id: "e0", source: "n35", target: "n37", label: "yad" },
                { id: "e1", source: "n35", target: "n38", label: "yad" },
            ],
        };
    }

    function load_graph(graph) {
        // < causes a loop somewhere that freezes devtools
        // graph = test_graph()
        console.log("load_graph");
        cy.add(
            graph.nodes.map(function (node) {
                return {
                    group: "nodes",
                    id: node.id,
                    data: { ...node },
                };
            }),
        );
        cy.add(
            graph.edges.map(function (edge) {
                return {
                    group: "edges",
                    id: edge.id,
                    data: { ...edge },
                };
            }),
        );
    }

    let constraints_memo = ''
    node_edger.reset_constraints = () => {
        node_edger.constraints_config = {}
        constraints_memo = ''
    }
    node_edger.constraints = (concon) => {
        let memo = JSON.stringify(concon)
        // console.log(`Got concon`)
        if (memo == constraints_memo) return
        constraints_memo = memo
        // console.log(`Changed concon: ${memo}`)
        // setTimeout(() => {
            node_edger.constraints_config = concon
            relayout()
        // },111)
    }
    node_edger.add = (N) => {
        if (!N.length) return
        cy.add(N);
        on_graph_change();
    };
    node_edger.remove = (N) => {
        if (!N.length) return
        for (let c of N) {
            cy.getElementById(c.id).remove()
        }
        on_graph_change();
    };
    let on_graph_change = throttle(() => {
        if (!lay || 1) layout();
        run_layout();
    }, 100);

    //#endregion



    //#region UI
    // we:
    let mem = M.imem("heisting")
    let uimem = mem.further('UI')

    
    
    // persists
    let quit_fullscreen = $state(uimem.get('quit_fullscreen') ?? false)
    let toggle_fullscreen = () => {
        quit_fullscreen = !quit_fullscreen
        uimem.set('quit_fullscreen',quit_fullscreen)
    }

    let artist = $state()
    let title = $state()
    let enid = $state() // ticket back, to nab -> heist
    node_edger.titles = (c) => {
        [{artist,title,enid}] = [c];
    }

    let heist = $state()
    let YES = () => {
        if (enid) {
            M.i_elvis(w, "nab_this", {enid})
            // < do we need this nudge
            setTimeout(() => {
                M.i_elvis(w, "nab_this", {enid})
            },133)
        }
    }
    node_edger.enheist = (hi) => {
        heist = hi
    }
    node_edger.deheist = () => {
        node_edger.set_resumable_heist(null)
        if (heist) heist.c.abandon_piracy()
    }
    let NO = () => {
        let he = heist?.o()[0]
        let planning_heist = he && he.sc.cv <3
        if (planning_heist) {
            node_edger.deheist()
        }
        else {
            M.turn_knob()
        }
    }

    // savable
    onMount(() => {
    })
    let on_jamming_commenced = () => {
        // fullscreen interface ready to receive this thing
        // < nah shouldn't cancel a heist once it's @5
        let heice = mem.get('resumable_heist')
        // node_edger.set_resumable_heist(null)
        heice && M.i_elvis(w, 'resume_heist', {heice})
    }
    node_edger.set_resumable_heist = (heice) => {
        mem.set('resumable_heist',heice)
    }





    let jamming = $state()
    node_edger.jamming = (whether) => {
        jamming = whether
    }
    // stick this down so Pier can reconnect without leaving fullscreen
    // < to switch which Pier is facesucking, raterming. Engage needs to.
    let ever_jamming = $state(false)
    $effect(() => {
        if (jamming && !ever_jamming) {
            ever_jamming = true
            on_jamming_commenced()
            setTimeout(() => {
                // < first thing we play reliably inaudible?
                M.turn_knob()
            },800)
        }
    })
    // F:Trusting, always there, also throws up fullscreening on load
    //  depending also on similar !quit_fullscreen
    //   shows them induction text while atop us
    
    //   processes idzeug maybe
    //   and lets you select which peer to listen to, if multiple...
    //   and jumps out of the way just as the stream comes in
    //   
    // < once jamming, or
    let fullscreen = $derived(ever_jamming && !quit_fullscreen)
    onMount(() => {
        M.F.P.some_feature_is_nearly_ready = true
    })
    $effect(() => {
        if (jamming) {
            // we are now ready for F:Trusting to reveal us
            M.F.P.some_feature_is_ready = true
        }
    })


    function selection_changed() {
        return
        let eles = cy.$("node:selected");
        if (!eles[0]) {
            heist = null
        }
        else {
            M.i_elvis(w, "eles_selection", {eles})
        }
    }
    
    let share_act = $derived(P.needs_share_open_action)
    // gets set only once so they can dismiss it and continue
    let no_share = () => {
        P.needs_share_open_action = false
    }
</script>

<button onclick={() => layout()}>layout</button>
<button onclick={() => run_layout()}>...</button>
<button onclick={() => cy.fit()}>fit()</button>


<FaceSucker altitude={22} {fullscreen}>
    {#snippet content()}
        <div class="relief">
            <div class="wall"></div>
            
            <div class="graph" 
                class:graphtightly={!fullscreen} 
                bind:this={ele}
            ></div>

            <div class='uiing'>
                {#if jamming}
                    <div class='controls'>
                        <button onclick={() => YES()} class='big'
                            disabled={heist && true}
                            >yeah</button>
                        {#if title}
                            <span class='np'>{artist} - {title}</span>
                        {/if}
                        <span>
                            <button onclick={() => NO()} class='big'
                                >nah</button>
                        </span>
                    </div>
                {/if}
                {#if heist}
                    <div class='heisting'>
                        <Pirate {M} {mem} {heist} {w}></Pirate>
                    </div>
                {/if}
            </div>
            
            <div class='uiing bottom'>
                <div class='controls'>
                    <span>
                        <button onclick={() => toggle_fullscreen()}
                            class={!quit_fullscreen ? 'small' : ''}>fullscreen</button>
                    </span>


                    <span>
                        {#if share_act}
                            <span class="navicom" title="
                            Access to (some part of) your filesystem is required to share.
                            ">
                                <span class="arow" style="font-size:1.8em;">
                                    please
                                    <ActionButtons actions={[share_act]} />
                                    to share back
                                </span>
                                <button onclick={() => no_share()}
                                    style="margin:2em;"
                                    >nah</button>
                            </span>
                        {/if}
                        <ShareButton {P} />
                        <a href="https://github.com/stylehouse/jamsend" target="#" style="font-size:1.8em;">README</a>
                    </span>
                </div>
            </div>
        </div>
    {/snippet}
</FaceSucker>

<style>
    .navicom {
        border: 2px solid blue;
        border-radius:2em;
        margin: 0.5em;
        padding: 0.5em;
    }
    div.relief {
        background:#b394ff;
        width:100%;
        height: 100%;

    }
    div.wall {
        background:url('seapiano.webp');
        background-size:cover;
        mix-blend-mode: multiply;
        opacity: 0.7;
        width:100%;
        height: 100%;
        position:absolute;
        pointer-events:none;
    }
    .np {
        font-size:2em;
    }
    button.big {
        font-size:2.6em;
        background:#1a4e2e;
    }
    button.small {
        font-size:0.75em;
        opacity:0.05;
    }
    .contain {
        position:relative;
        width: 100%;
        height: 100%;
    }
    .hoist.jamming {
        position:fixed;
        top:0;
        left:0;
        z-index:20000;
        width: 100%;
        height: 100%;
    }
        /* width: calc(100% + 2em);
        height: calc(100% + 0);
        border: 1em solid greenyellow;
        border-radius:2em; */
    .graph {
        width: 100%;
        top:6%;
        height: 94%;
        min-height: 50em;
        min-width: 40em;
        color: #b394ff;
    }
    .graphtightly {
        height: calc(min(60vw, 60vh));
        min-height: 6em;
    }
    .uiing {
        width: 100%;
        position:absolute;
        top:0;
        left:0;
        display: flex;
        flex-direction: column;
        background: black;
    }
    .bottom {
        top:initial;
        bottom:0;
    }
    .uiing button {
        padding:0.7em;
    }
    .controls {
        display: flex;
        align-items: center;
        width: 100%;
    }

    .controls > span:last-of-type {
        margin-left: auto;
        display: flex;
        align-items: center;
        gap: 0.5em;
    }

    .heisting {
        position:relative;
    }


</style>

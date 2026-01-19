<script lang="ts">
    import cytoscape from "cytoscape";
    // these are apparently the best at either hierarchical
    import dagre from "cytoscape-dagre";
    //   or force-directed, compound graphs
    //    and "fairly rich set of constraint types" https://github.com/iVis-at-Bilkent/cytoscape.js-fcose
    import fcose from "cytoscape-fcose";
    // and everything, interactively
    import cola from "cytoscape-cola";
    import { onMount } from "svelte";
    import { throttle } from "$lib/Y";
    import { keyser, objectify } from "$lib/data/Stuff.svelte";
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

                // "text-wrap": "none",
                // shape: "rectangle",
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
        // and what its pointing to
        {
            selector: 'node.nowplaying',
            style: {
                "width": "90",
                "color": "black",
                "border-color": "orange",
                "border-width": "6em",
                "background-opacity": "0.1",
                "background":"none",
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

        {
            selector: "node[data.dir]",
            style: {
                shape: "ellipse",
                width: "8em",
                "background-color": "pink",
            },
        },
        {
            selector: "node[data.texty]",
            style: {
                width: (ele) => (ele.data("data.texty") ?? 2) * 0.5 + 1 + "em",
                "text-wrap": "none",
                shape: "rectangle",
                color: "lightblue",
                "line-color": "lightblue",
                "background-color": "darkblue",
                "border-color": "gray",
            },
        },
    ];

    //#endregion
    //#region dealing

    let { VJ, M } = $props();
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
    //#region heist
    let artist = $state()
    let title = $state()
    let enid = $state() // ticket back, to nab -> heist
    node_edger.titles = (c) => {
        [{artist,title,enid}] = [c];
    }
    // < fullscreen cyto, banners if true
    let jamming = $state()
    node_edger.jamming = (whether) => {
        jamming = whether
    }

    let heist = $state()
    function selection_changed() {
        let eles = cy.$("node:selected");
        if (!eles[0]) {
            heist = null
        }
        else {
            M.i_elvis(w, "eles_selection", {eles})
        }
    }
    node_edger.enheist = (hi) => {
        heist = hi
    }
    
</script>

<button onclick={() => layout()}>layout</button>
<button onclick={() => run_layout()}>...</button>
<button onclick={() => cy.fit()}>fit()</button>

<h3>Cytoscape {jamming && 'jamming'} {title}</h3>

<div class="hoist" class:jamming={jamming}>
    <div class="contain" class:jamming={jamming}>
        <div class="graph" bind:this={ele}></div>

        <div class='banner' class:jamming={jamming}>
            <div class='scroll-text'>{artist}</div>
        </div>
        <div class='banner right' class:jamming={jamming}>
            <div class='scroll-text'>{title}</div>
        </div>
    </div>
</div>
{#if heist}
    <h3>heist: ${objectify(heist)}</h3>
{/if}

<style>
    .contain {
        position:relative;
        width: calc(100% - 2em);
        height: calc(100% - 2em);
        border: 1em solid greenyellow;
        border-radius:2em;
    }
    .hoist.jamming {
        position:fixed;
        top:-1em;
        left:-1em;
        z-index:20000;
        width: 100%;
        height: calc(100% + 2em);
    }
    .graph {
        width: 100%;
        height: 100%;
        min-height: 50em;
        min-width: 40em;
        background: black;
        color: #b394ff;
    }
    .banner {
        position:relative;
        top:0;
        left:0;
        width:10vw;
        height:100%;
        background-color:rgba(43, 33, 109,0.8);
        border-radius:2em;
        margin:-0.7em;
        line-height:5vw;
        overflow:hidden;
    }
    .banner.jamming {
        position: fixed;
        z-index: 10;
        background-color: rgba(43, 33, 109, 0.95);
    }
    .banner.right {
        left:initial;
        right:0em;
    }



    .scroll-text {
        position: absolute;
        font-size: 9vw;
        font-weight: 900;
        white-space: nowrap;
        color: gold;
        text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.7);
        letter-spacing: -0.02em;
    }
    .banner .scroll-text {
        transform-origin: left top;
        transform: rotate(-90deg) translateX(-100%);
        left: 3vw;
        animation: scroll-down 15s linear infinite;
    }
    .banner.right .scroll-text {
        transform-origin: right top;
        transform: rotate(90deg) translateX(100%);
        right: 3vw;
        animation: scroll-up 15s linear infinite;
    }
    @keyframes scroll-down {
        0% {
            top: -20%;
        }
        100% {
            top: 120%;
        }
    }
    @keyframes scroll-up {
        0% {
            top: 120%;
        }
        100% {
            top: -20%;
        }
    }
</style>

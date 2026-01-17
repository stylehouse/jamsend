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
    import { keyser } from "$lib/data/Stuff.svelte";
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
                "font-size": "18",
                "font-weight": "bold",
                label: `data(name)`,
                "text-valign": "center",
                "text-wrap": "wrap",
                "text-max-width": "140",
                "background-color": "gold",
                "border-color": "orange",
                "border-width": "3",
                color: "darkred",
            },
        },
        {
            selector: 'node[class="blob"]',
            style: {
                height: "70",
                width: "120",
                "background-color": "black",
            },
        },
        {
            selector: 'node[class="collection"]',
            style: {
                width: "70",
                height: "90",
                "background-color": "black",
            },
        },

        {
            selector: 'node[class="ayefour"]',
            style: {
                width: "90",
                height: "70",
                "background-color": "saddlebrown",
            },
        },
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
                width: "3",
                "target-arrow-shape": "triangle",
                "line-color": "darkred",
                //'font-weight': 'bold'
            },
        },
        {
            selector: 'edge[class="along"]',
            style: {
                color: "lightblue",
                "line-color": "gold",
                "target-arrow-color": "gold",
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
        {
            selector: 'edge[class="texty"]',
            style: {
                "line-color": "#33f",
            },
        },
        {
            selector: 'edge[class="textybroke"]',
            style: {
                "line-color": "#66e",
            },
        },
        {
            selector: 'edge[class="outward"]',
            style: {
                "line-color": "#842",
                "width":"2em"
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

    function selection_changed() {
        window.eles = cy.$("node:selected");
        console.log(`cytoscape selected nodes:`, window.eles);
    }

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
    node_edger.constraints = (concon) => {
        let memo = JSON.stringify(concon)
        console.log(`Got concon`)
        if (memo == constraints_memo) return
        constraints_memo = memo
        console.log(`Changed concon: ${memo}`)
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
</script>

<button onclick={() => layout()}>layout</button>
<button onclick={() => run_layout()}>...</button>
<button onclick={() => cy.fit()}>fit()</button>

<h3>Cytoscape</h3>

<div class="graph" bind:this={ele}></div>

<style>
    .graph {
        width: 100%;
        height: 100%;
        min-height: 50em;
        min-width: 40em;
        background: hsl(0, 29%, 45%)
    }
</style>

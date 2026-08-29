<script lang="ts">
	const schemes = [
		{
			file: 'residual_ink.svg',
			name: 'Residual Ink',
			caption: 'Ink density is proportional to surprise — the unexpected parts of the tree soak darkest.'
		},
		{
			file: 'staff.svg',
			name: 'Musical Staff',
			caption: 'The tree laid out as notation on a staff — particles as notes, depth as pitch.'
		},
		{
			file: 'mesh_weave.svg',
			name: 'Mesh Atom-Weave',
			caption: 'Particles as atoms woven into a mesh — edges are the sc/c bonds between them.'
		},
		{
			file: 'tree_nest.svg',
			name: 'Tree Blob-Nesting',
			caption: 'Containment drawn literally — each particle a blob nested inside its holder.'
		}
	];
</script>

<svelte:head>
	<title>C** rendering art</title>
</svelte:head>

<div class="gallery">
	<header>
		<h1>C** rendering art</h1>
		<p>
			Four renditions of the <em>same</em> universal C** data — one particle tree, four ways of
			seeing it. Each scheme keeps the identical structure and re-answers only the question of how
			it should look.
		</p>
	</header>

	<div class="grid">
		{#each schemes as s (s.file)}
			<figure class="card">
				<div class="frame">
					<img src={'/art/' + s.file} alt={s.name} loading="lazy" />
				</div>
				<figcaption>
					<h2>{s.name}</h2>
					<p>{s.caption}</p>
				</figcaption>
			</figure>
		{/each}
	</div>
</div>

<style>
	.gallery {
		min-height: 100vh;
		background: #0e0f13;
		color: #d8dae2;
		font-family:
			system-ui,
			-apple-system,
			'Segoe UI',
			sans-serif;
		padding: 2.5rem 2rem 4rem;
		box-sizing: border-box;
	}

	header {
		max-width: 60rem;
		margin: 0 auto 2.5rem;
	}

	h1 {
		margin: 0 0 0.5rem;
		font-size: 1.7rem;
		font-weight: 650;
		letter-spacing: 0.01em;
		color: #f0f1f5;
	}

	header p {
		margin: 0;
		color: #9a9eae;
		line-height: 1.55;
		max-width: 46rem;
	}

	.grid {
		max-width: 60rem;
		margin: 0 auto;
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(24rem, 1fr));
		gap: 1.5rem;
	}

	.card {
		margin: 0;
		background: #16181f;
		border: 1px solid #262a35;
		border-radius: 10px;
		overflow: hidden;
		display: flex;
		flex-direction: column;
	}

	.frame {
		background: #1c1f28;
		border-bottom: 1px solid #262a35;
		display: flex;
		align-items: center;
		justify-content: center;
		min-height: 18rem;
		padding: 1rem;
	}

	.frame img {
		max-width: 100%;
		max-height: 24rem;
		display: block;
	}

	figcaption {
		padding: 0.9rem 1.1rem 1.1rem;
	}

	h2 {
		margin: 0 0 0.3rem;
		font-size: 1.05rem;
		font-weight: 600;
		color: #e8eaf0;
	}

	figcaption p {
		margin: 0;
		font-size: 0.88rem;
		line-height: 1.45;
		color: #8f93a3;
	}
</style>

<!---
	Starter home page: replace before production.

	This development/first-run landing page surfaces environment details
	(Wheels version, engine, datasource, environment) and links to the dev
	tools. It renders because config/routes.cfm still points the root route at
	the Main controller. Replace it with a real homepage before you deploy so
	those details are not exposed to anonymous visitors.

	Lives in cli/lucli/templates/app/ so it ships with `wheels new` and is
	reviewable in the repository — not as an inline string in the CLI.
--->
<style>
	/* Scoped to this page so it cannot leak into the app's own styles. */
	.wheels-starter {
		--ws-border: #d4d4d5;
		--ws-muted: rgba(0, 0, 0, .62);
		--ws-note-bg: #f4f6f8;
		max-width: 46rem;
		margin: 0 auto;
		padding: 3rem 1.25rem 4rem;
	}
	@media (prefers-color-scheme: dark) {
		.wheels-starter {
			--ws-border: #3f3f46;
			--ws-muted: rgba(255, 255, 255, .68);
			--ws-note-bg: #27272a;
		}
	}
	.wheels-starter-brand {
		display: flex;
		align-items: center;
		margin: 0 0 1.75rem;
	}
	.wheels-starter-brand img {
		display: block;
		height: 26px;
		width: auto;
	}
	.wheels-starter h1 { margin: 0 0 .85rem; }
	.wheels-starter h2 { margin: 2.5rem 0 1rem; }
	.wheels-starter-note {
		margin: 1.75rem 0;
		padding: 1rem 1.15rem;
		border: 1px solid var(--ws-border);
		border-radius: .4rem;
		background: var(--ws-note-bg);
	}
	.wheels-starter-note p { margin: 0; }
	.wheels-starter-details {
		display: grid;
		grid-template-columns: auto 1fr;
		gap: .45rem 1.75rem;
		margin: 0;
	}
	.wheels-starter-details dt { font-weight: 700; }
	.wheels-starter-details dd { margin: 0; }
	.wheels-starter-cards {
		display: grid;
		/* Exactly two cards, so a fixed pair of columns reads better than
		   auto-fit, which would leave a ragged gap at wide widths. */
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: .85rem;
		margin: 0 0 2.5rem;
	}
	@media (max-width: 34rem) {
		.wheels-starter-cards { grid-template-columns: 1fr; }
	}
	/* :visited/:hover are listed explicitly — simple.css styles a:visited, and
	   a pseudo-class selector outranks a bare class, which otherwise leaves one
	   already-visited card a different colour from its siblings. */
	.wheels-starter-card,
	.wheels-starter-card:visited,
	.wheels-starter-card:hover,
	.wheels-starter-card:focus {
		display: block;
		padding: .9rem 1.05rem;
		border: 1px solid var(--ws-border);
		border-radius: .4rem;
		color: inherit;
		text-decoration: none;
	}
	.wheels-starter-card:hover { border-color: #4183c4; }
	.wheels-starter-card strong { display: block; color: inherit; }
	.wheels-starter-card span {
		display: block;
		margin-top: .2rem;
		font-size: .9rem;
		color: var(--ws-muted);
	}
	.wheels-starter-footer {
		margin: 0;
		color: var(--ws-muted);
		font-size: .9rem;
	}
</style>

<div class="wheels-starter">
	<p class="wheels-starter-brand">
		<!--- Official Wheels wordmark. Two files: the default reads on light
		     backgrounds, the inverse reads on dark ones — same artwork, so the
		     <picture> swap cannot shift layout. --->
		<picture>
			<source srcset="/images/wheels-logo-inverse.png" media="(prefers-color-scheme: dark)">
			<img src="/images/wheels-logo.png" alt="Wheels" width="1492" height="178">
		</picture>
	</p>

	<h1>Welcome to {{appName}}</h1>

	<p>Your application booted and is serving requests. Here is what it is connected to, and where to go next.</p>

	<div class="wheels-starter-note">
		<p>
			<strong>This is the starter page, not a real homepage.</strong>
			It is showing because <code>config/routes.cfm</code> still points the root route at the
			<code>Main</code> controller, and it prints your environment and datasource names.
			Replace it with a real action before you deploy.
		</p>
	</div>

	<h2>The details</h2>
	<cfoutput>
		<dl class="wheels-starter-details">
			<dt>Wheels</dt>
			<dd>#get("version")#</dd>
			<dt>Engine</dt>
			<dd>#application.wheels.serverName# #application.wheels.serverVersion#</dd>
			<dt>Datasource</dt>
			<dd>#application.wheels.dataSourceName#</dd>
			<dt>Environment</dt>
			<dd>#get("environment")#</dd>
		</dl>
	</cfoutput>

	<h2>Next steps</h2>
	<div class="wheels-starter-cards">
		<!--- Both open in a new tab: they are documentation, and a reader who
		     follows one should not lose the app they are working in.
		     rel="noopener" stops the opened page reaching back through
		     window.opener. --->
		<a class="wheels-starter-card" href="/wheels/guides" target="_blank" rel="noopener">
			<strong>Guides</strong>
			<span>Learn Wheels end to end</span>
		</a>
		<a class="wheels-starter-card" href="/wheels/api" target="_blank" rel="noopener">
			<strong>API docs</strong>
			<span>Every helper, searchable</span>
		</a>
	</div>

	<p class="wheels-starter-footer">
		This page lives at <code>app/views/main/index.cfm</code>; routing is in <code>config/routes.cfm</code>.
		Run <code>wheels g scaffold Post title content:text</code> to generate a real resource.
	</p>
</div>

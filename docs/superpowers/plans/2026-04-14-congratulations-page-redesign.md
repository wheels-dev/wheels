# Congratulations Page Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static congratulations page with a modern dashboard showing runtime info, CLI detection with install instructions, quick-start action cards, and v4.0 feature highlights.

**Architecture:** Single-file rewrite of `vendor/wheels/public/views/congratulations.cfm`. All styling uses existing `--w-*` CSS custom properties from the Catppuccin theme in `_header.cfm`. No new files, no new dependencies.

**Tech Stack:** CFML (cfm template), CSS Grid, vanilla JavaScript (~10 lines for tab switching)

**Spec:** `docs/superpowers/specs/2026-04-14-congratulations-page-redesign.md`

**Mockup:** `.superpowers/brainstorm/78539-1776200777/content/hero-layout-v3.html`

---

### Task 1: Rewrite congratulations.cfm

**Files:**
- Modify: `vendor/wheels/public/views/congratulations.cfm` (full rewrite, lines 1-63)

The current file is 63 lines. The new version replaces everything between the `_header.cfm` and `_footer.cfm` includes.

**Key CFML references the template needs:**
- `get("version")` — returns version string like `"4.0.0"`
- `application.$wheels.serverName` — `"Lucee"`, `"Adobe ColdFusion"`, or `"BoxLang"`
- `application.$wheels.serverVersion` — e.g. `"7.0.1.65"`
- `application.wheels.dataSourceName` — datasource name string
- `get("environment")` — `"development"`, `"production"`, etc.
- `server.os.name` — OS detection for CLI install tab pre-selection
- `FileExists(ExpandPath("/cli/lucli/Module.cfc"))` — CLI detection
- `pageHeader()` is available from `helpers.cfm` but we are NOT using it (the hero replaces it)

- [ ] **Step 1: Write the new congratulations.cfm**

Replace the entire contents of `vendor/wheels/public/views/congratulations.cfm` with:

```cfm
<!--- cfformat-ignore-start --->
<cfinclude template="../layout/_header.cfm">
<cfscript>
	// Runtime info
	local.wheelsVersion = get("version");
	local.engineName = application.$wheels.serverName;
	local.engineVersion = ListFirst(application.$wheels.serverVersion, ".");
	if (ListLen(application.$wheels.serverVersion, ".") > 1) {
		local.engineVersion &= "." & ListGetAt(application.$wheels.serverVersion, 2, ".");
	}
	local.dbName = application.wheels.dataSourceName;
	local.environment = get("environment");

	// CLI detection
	local.hasCLI = FileExists(ExpandPath("/cli/lucli/Module.cfc"));

	// OS detection for install tab pre-selection
	local.osName = server.os.name;
	local.isMac = FindNoCase("Mac", local.osName) || FindNoCase("Darwin", local.osName);
	local.isWindows = FindNoCase("Windows", local.osName);
	// Default to Linux if neither Mac nor Windows
</cfscript>
<cfoutput>
<style>
	/* Congratulations page scoped styles */
	.wheels-hero {
		text-align: center;
		padding: 48px 0 40px;
		border-bottom: 1px solid var(--w-border);
		margin-bottom: 36px;
	}
	.wheels-hero-brand {
		font-size: 14px;
		letter-spacing: 6px;
		text-transform: uppercase;
		color: var(--w-text-subtle);
		margin-bottom: 8px;
	}
	.wheels-hero-version {
		font-size: 48px;
		font-weight: 700;
		color: var(--w-accent);
		margin-bottom: 16px;
	}
	.wheels-hero-check {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		background: rgba(166,227,161,0.1);
		border: 1px solid rgba(166,227,161,0.25);
		color: var(--w-green);
		padding: 6px 16px;
		border-radius: 20px;
		font-size: 14px;
		margin-bottom: 20px;
	}
	.wheels-hero-env {
		display: flex;
		justify-content: center;
		gap: 24px;
		color: var(--w-text-muted);
		font-size: 14px;
	}
	.wheels-hero-env span {
		display: flex;
		align-items: center;
		gap: 6px;
	}
	.wheels-env-dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		display: inline-block;
	}
	/* CLI install banner */
	.wheels-cli-banner {
		background: rgba(249,226,175,0.08);
		border: 1px solid rgba(249,226,175,0.25);
		border-radius: 8px;
		padding: 20px 24px;
		margin-bottom: 36px;
	}
	.wheels-cli-banner-header {
		display: flex;
		align-items: center;
		gap: 10px;
		margin-bottom: 12px;
	}
	.wheels-cli-banner-header svg {
		color: var(--w-yellow);
		flex-shrink: 0;
	}
	.wheels-cli-banner-header h3 {
		font-size: 15px;
		font-weight: 600;
		color: var(--w-yellow);
		margin: 0;
	}
	.wheels-cli-banner p {
		font-size: 13px;
		color: var(--w-text-muted);
		margin-bottom: 14px;
	}
	.wheels-cli-tabs {
		display: flex;
		gap: 0;
	}
	.wheels-cli-tab {
		padding: 7px 16px;
		font-size: 13px;
		color: var(--w-text-subtle);
		background: transparent;
		border: 1px solid var(--w-border);
		border-bottom: none;
		cursor: pointer;
		border-radius: 6px 6px 0 0;
		transition: color 0.15s, background 0.15s;
	}
	.wheels-cli-tab.active {
		color: var(--w-text);
		background: var(--w-bg-surface);
	}
	.wheels-cli-tab:not(.active):hover {
		color: var(--w-text-muted);
		background: rgba(49,50,68,0.4);
	}
	.wheels-cli-cmd {
		background: var(--w-bg-surface);
		border: 1px solid var(--w-border);
		border-radius: 0 6px 6px 6px;
		padding: 12px 16px;
		font-family: 'SF Mono', Menlo, Consolas, monospace;
		font-size: 13px;
		color: var(--w-teal);
	}
	.wheels-cli-cmd .prompt {
		color: var(--w-text-subtle);
		margin-right: 8px;
	}
	.wheels-cli-ok {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 8px;
		padding: 10px 0;
		margin-bottom: 24px;
		font-size: 13px;
		color: var(--w-text-subtle);
	}
	.wheels-cli-ok svg {
		color: var(--w-green);
	}
	/* Action cards */
	.wheels-actions {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 16px;
		margin-bottom: 40px;
	}
	.wheels-action-card {
		background: var(--w-bg-overlay);
		border: 1px solid var(--w-border);
		border-radius: 8px;
		padding: 20px;
		text-align: center;
		transition: border-color 0.15s;
	}
	.wheels-action-card:hover {
		border-color: var(--w-accent);
	}
	.wheels-action-icon {
		margin-bottom: 10px;
		color: var(--w-accent);
	}
	.wheels-action-card h3 {
		font-size: 15px;
		font-weight: 600;
		color: var(--w-text);
		margin-bottom: 4px;
	}
	.wheels-action-card p {
		font-size: 13px;
		color: var(--w-text-muted);
		margin-bottom: 12px;
	}
	.wheels-action-cmd {
		background: var(--w-bg-surface);
		border: 1px solid var(--w-border);
		border-radius: 4px;
		padding: 6px 10px;
		font-family: 'SF Mono', Menlo, Consolas, monospace;
		font-size: 12px;
		color: var(--w-teal);
		display: inline-block;
	}
	/* Feature grid */
	.wheels-features-label {
		font-size: 12px;
		letter-spacing: 3px;
		text-transform: uppercase;
		color: var(--w-text-subtle);
		margin-bottom: 16px;
	}
	.wheels-features {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 12px;
		margin-bottom: 40px;
	}
	.wheels-feature {
		background: var(--w-bg-surface);
		border: 1px solid var(--w-border);
		border-radius: 6px;
		padding: 16px;
	}
	.wheels-feature h4 {
		font-size: 14px;
		font-weight: 600;
		color: var(--w-text);
		margin-bottom: 4px;
	}
	.wheels-feature p {
		font-size: 12px;
		color: var(--w-text-muted);
		line-height: 1.5;
	}
	.wheels-feature-tag {
		display: inline-block;
		font-size: 10px;
		text-transform: uppercase;
		letter-spacing: 1px;
		padding: 2px 6px;
		border-radius: 3px;
		margin-bottom: 8px;
		font-weight: 600;
	}
	.wheels-tag-new {
		background: rgba(166,227,161,0.15);
		color: var(--w-green);
	}
	.wheels-tag-upgraded {
		background: rgba(137,180,250,0.15);
		color: var(--w-accent);
	}
	/* Footer */
	.wheels-congrats-footer {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding-top: 24px;
		border-top: 1px solid var(--w-border);
	}
	.wheels-congrats-footer-links {
		display: flex;
		gap: 20px;
	}
	.wheels-congrats-footer-links a {
		font-size: 14px;
	}
	.wheels-congrats-footer-route {
		font-size: 13px;
		color: var(--w-text-subtle);
	}
</style>

<div class="ui container">

	<!--- ── Hero ── --->
	<div class="wheels-hero">
		<div class="wheels-hero-brand">W H E E L S</div>
		<div class="wheels-hero-version">#local.wheelsVersion#</div>
		<div class="wheels-hero-check">
			<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0zm3.78 4.97a.75.75 0 0 0-1.06 0L7 8.69 5.28 6.97a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.06 0l4.25-4.25a.75.75 0 0 0 0-1.06z"/></svg>
			Running successfully
		</div>
		<div class="wheels-hero-env">
			<span><span class="wheels-env-dot" style="background:var(--w-green)"></span> #local.engineName# #local.engineVersion#</span>
			<span><span class="wheels-env-dot" style="background:var(--w-accent)"></span> #local.dbName#</span>
			<span><span class="wheels-env-dot" style="background:var(--w-yellow)"></span> #local.environment#</span>
		</div>
	</div>

	<!--- ── CLI Detection ── --->
	<cfif local.hasCLI>
		<div class="wheels-cli-ok">
			<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0zm3.78 4.97a.75.75 0 0 0-1.06 0L7 8.69 5.28 6.97a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.06 0l4.25-4.25a.75.75 0 0 0 0-1.06z"/></svg>
			Wheels CLI detected
		</div>
	<cfelse>
		<div class="wheels-cli-banner">
			<div class="wheels-cli-banner-header">
				<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>
				<h3>Install the Wheels CLI</h3>
			</div>
			<p>The Wheels CLI gives you generators, migrations, testing, and a local dev server. The commands below require it.</p>
			<div class="wheels-cli-tabs">
				<button class="wheels-cli-tab<cfif local.isMac> active</cfif>" onclick="wheelsCliTab(this,'brew install wheels-dev/tap/wheels','$')">macOS</button>
				<button class="wheels-cli-tab<cfif !local.isMac && !local.isWindows> active</cfif>" onclick="wheelsCliTab(this,'brew install wheels-dev/tap/wheels','$')">Linux</button>
				<button class="wheels-cli-tab<cfif local.isWindows> active</cfif>" onclick="wheelsCliTab(this,'choco install wheels','>')">Windows</button>
			</div>
			<div class="wheels-cli-cmd">
				<span class="prompt"><cfif local.isWindows>><cfelse>$</cfif></span>
				<span id="wheels-cli-install-cmd"><cfif local.isWindows>choco install wheels<cfelse>brew install wheels-dev/tap/wheels</cfif></span>
			</div>
		</div>
	</cfif>

	<!--- ── Action Cards ── --->
	<div class="wheels-actions">
		<div class="wheels-action-card">
			<div class="wheels-action-icon">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>
			</div>
			<h3>Generate a Scaffold</h3>
			<p>Create your first model, controller, and views</p>
			<div class="wheels-action-cmd">wheels g scaffold Post title content:text</div>
		</div>
		<div class="wheels-action-card">
			<div class="wheels-action-icon">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/></svg>
			</div>
			<h3>Migrate Database</h3>
			<p>Run pending migrations to set up your schema</p>
			<div class="wheels-action-cmd">wheels dbmigrate latest</div>
		</div>
		<div class="wheels-action-card">
			<div class="wheels-action-icon">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
			</div>
			<h3>Run Tests</h3>
			<p>Verify your installation is working correctly</p>
			<div class="wheels-action-cmd">wheels test run</div>
		</div>
	</div>

	<!--- ── Feature Grid ── --->
	<div class="wheels-features-label">What's New in 4.0</div>
	<div class="wheels-features">
		<div class="wheels-feature">
			<span class="wheels-feature-tag wheels-tag-new">New</span>
			<h4>Package System</h4>
			<p>First-party modules in vendor/ replace legacy plugins</p>
		</div>
		<div class="wheels-feature">
			<span class="wheels-feature-tag wheels-tag-new">New</span>
			<h4>Middleware</h4>
			<p>CORS, CSP, rate limiting, security headers</p>
		</div>
		<div class="wheels-feature">
			<span class="wheels-feature-tag wheels-tag-new">New</span>
			<h4>DI Container</h4>
			<p>Dependency injection with request scoping</p>
		</div>
		<div class="wheels-feature">
			<span class="wheels-feature-tag wheels-tag-new">New</span>
			<h4>Query Builder</h4>
			<p>Fluent, injection-safe chainable queries</p>
		</div>
		<div class="wheels-feature">
			<span class="wheels-feature-tag wheels-tag-new">New</span>
			<h4>Background Jobs</h4>
			<p>Async processing with retries and backoff</p>
		</div>
		<div class="wheels-feature">
			<span class="wheels-feature-tag wheels-tag-upgraded">Upgraded</span>
			<h4>Wheels CLI</h4>
			<p>Zero-Docker local dev, generators, and console</p>
		</div>
	</div>

	<!--- ── Footer ── --->
	<div class="wheels-congrats-footer">
		<div class="wheels-congrats-footer-links">
			<a href="https://wheels.dev" target="_blank">Documentation</a>
			<a href="https://github.com/wheels-dev/wheels/discussions" target="_blank">Community</a>
			<a href="https://github.com/wheels-dev/wheels" target="_blank">GitHub</a>
		</div>
		<div class="wheels-congrats-footer-route">
			Change this page &rarr; <code>config/routes.cfm</code>
		</div>
	</div>

</div>

<script>
function wheelsCliTab(el, cmd, prompt) {
	var tabs = el.parentElement.querySelectorAll('.wheels-cli-tab');
	for (var i = 0; i < tabs.length; i++) { tabs[i].className = 'wheels-cli-tab'; }
	el.className = 'wheels-cli-tab active';
	document.getElementById('wheels-cli-install-cmd').textContent = cmd;
	el.parentElement.nextElementSibling.querySelector('.prompt').textContent = prompt;
}
</script>
</cfoutput>

<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->
```

- [ ] **Step 2: Verify the page renders**

Start the server if not running, then load the congratulations page:

```bash
curl -s "http://localhost:8080/?reload=true&password=wheels" > /dev/null
curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/"
```

Expected: HTTP 200. Open in browser to visually verify:
- Hero shows version, engine, database, environment
- CLI banner or CLI-detected line displays correctly
- Three action cards render in a row
- Six feature tiles render in a 3x2 grid
- Footer links and route hint display

- [ ] **Step 3: Commit**

```bash
git add vendor/wheels/public/views/congratulations.cfm
git commit -m "feat(view): redesign congratulations page for v4.0

Replace static welcome text with dashboard-style page showing runtime
info, CLI detection with install instructions, quick-start action
cards, and v4.0 feature highlights."
```

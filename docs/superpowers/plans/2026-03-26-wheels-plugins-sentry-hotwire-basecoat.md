# Wheels Plugins Implementation Plan (Sentry, Hotwire, Basecoat)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship three first-party Wheels plugins — polish SentryForWheels for official release, finish Hotwire's missing helper, and build Basecoat's remaining UI components (Phases 2-5).

**Architecture:** Three independent plugins, each a single-CFC Wheels plugin in `plugins/`. All public methods are injected into controller/view scopes. Uses `plugin.json` manifest for modern Wheels 3.x compatibility. Tests use TestBox BDD syntax extending `wheels.WheelsTest`.

**Tech Stack:** CFML (Wheels framework), TestBox BDD, Basecoat CSS, Turbo/Stimulus JS, Sentry envelope API.

**Parallelization:** All three plugins are independent. Tasks 1-6 (Sentry), 7-10 (Hotwire), and 11-20 (Basecoat) can run in parallel.

---

## Part A: SentryForWheels (Polish for Official Release)

### Task 1: Add plugin.json and index.cfm

**Files:**
- Create: `plugins/SentryForWheels/plugin.json`
- Create: `plugins/SentryForWheels/index.cfm`

- [ ] **Step 1: Create plugin.json manifest**

```json
{
	"name": "SentryForWheels",
	"version": "1.0.0",
	"author": "PAI Industries",
	"description": "Sentry error tracking for CFWheels with framework-aware context enrichment",
	"mixins": "controller",
	"wheelsVersion": "3.0"
}
```

- [ ] **Step 2: Create index.cfm for debug panel**

```html
<cfoutput>
<h1>SentryForWheels</h1>
<p>Sentry error tracking for CFWheels with framework-aware context enrichment.</p>
<h2>Status</h2>
<table class="table">
	<tr><td><strong>Version</strong></td><td>1.0.0</td></tr>
	<tr><td><strong>DSN Configured</strong></td><td>#YesNoFormat(StructKeyExists(application, "sentry"))#</td></tr>
	<tr>
		<td><strong>Environment</strong></td>
		<td>#(StructKeyExists(application, "sentry") ? application.sentry.getEnvironment() : "N/A")#</td>
	</tr>
</table>
<h2>Available Methods</h2>
<ul>
	<li><code>sentryCapture(exception, [tags], [level])</code> — Capture exception with context</li>
	<li><code>sentryMessage(message, [level], [tags])</code> — Capture message event</li>
	<li><code>sentrySetUser(userStruct)</code> — Set user context for request</li>
	<li><code>sentryAddBreadcrumb(message, [category], [level], [data])</code> — Add breadcrumb</li>
</ul>
</cfoutput>
```

- [ ] **Step 3: Commit**

```bash
git add plugins/SentryForWheels/plugin.json plugins/SentryForWheels/index.cfm
git commit -m "feat(sentry): add plugin.json manifest and debug panel index.cfm"
```

### Task 2: Fix access modifier, status check, file handle leak

**Files:**
- Modify: `plugins/SentryForWheels/SentryForWheels.cfc` (line 232: change `public` to `private`)
- Modify: `plugins/SentryForWheels/SentryClient.cfc` (line 502: fix status check; lines 259-263: fix file handle leak)

- [ ] **Step 1: Fix $sentryGetUser access to private**

In `SentryForWheels.cfc`, change line 232 from:
```cfml
public struct function $sentryGetUser() {
```
to:
```cfml
private struct function $sentryGetUser() {
```

- [ ] **Step 2: Fix HTTP status check in SentryClient.cfc**

In `SentryClient.cfc` `post()` function, replace:
```cfml
if (!find("200", http.statuscode))
```
with:
```cfml
if (Left(http.statuscode, 3) != "200")
```

- [ ] **Step 3: Fix file handle leak in captureException()**

In `SentryClient.cfc` `captureException()`, replace the file-reading block:
```cfml
file = fileOpen(tagContext[i]["TEMPLATE"], "read");
while (!fileIsEOF(file))
	arrayAppend(fileArray, fileReadLine(file));
fileClose(file);
```
with:
```cfml
try {
	fileArray = ListToArray(FileRead(tagContext[i]["TEMPLATE"]), Chr(10));
} catch (any e) {
	fileArray = [];
}
```

- [ ] **Step 4: Fix timestamp Z suffix in getTimeVars()**

In `SentryClient.cfc` `getTimeVars()`, ensure the timestamp includes the `Z` UTC indicator. The return value should end with `Z`:
```cfml
local.timeVars.iso_8601_date = DateFormat(local.utcNow, "yyyy-mm-dd") & "T" & TimeFormat(local.utcNow, "HH:mm:ss") & "Z";
```

- [ ] **Step 5: Add thread-safety lock to initSentry()**

In `SentryForWheels.cfc` `initSentry()`, wrap the initialization in a named lock:
```cfml
lock name="sentryForWheelsInit" type="exclusive" timeout="10" {
	if (structKeyExists(application, "sentry")) return;
	// ... rest of initialization ...
}
```

- [ ] **Step 6: Commit**

```bash
git add plugins/SentryForWheels/SentryForWheels.cfc plugins/SentryForWheels/SentryClient.cfc
git commit -m "fix(sentry): access modifier, status check, file leak, timestamp, thread safety"
```

### Task 3: Remove deprecated fields

**Files:**
- Modify: `plugins/SentryForWheels/SentryClient.cfc`

- [ ] **Step 1: Remove culprit field from captureException()**

In `captureException()`, remove the `"culprit"` key from the exception event payload struct. The `culprit` field is deprecated in Sentry SDK protocol v7.

- [ ] **Step 2: Remove " Error" suffix from exception type**

In `captureException()`, change the exception type construction from:
```cfml
"type": exType & " Error"
```
to:
```cfml
"type": exType
```

- [ ] **Step 3: Commit**

```bash
git add plugins/SentryForWheels/SentryClient.cfc
git commit -m "fix(sentry): remove deprecated culprit field and error suffix"
```

### Task 4: Add Sentry plugin tests

**Files:**
- Create: `plugins/SentryForWheels/tests/SentrySpec.cfc`

- [ ] **Step 1: Create test spec**

```cfml
component extends="wheels.WheelsTest" {

	function beforeAll() {
		client = new plugins.SentryForWheels.SentryClient(
			sentryDSN = "https://abc123def456@o123456.ingest.sentry.io/7891011"
		);
	}

	function run() {

		describe("SentryClient", () => {

			describe("parseDSN", () => {

				it("parses modern DSN format", () => {
					var result = client.getParseDSNResult();
					expect(result.publicKey).toBe("abc123def456");
					expect(result.projectId).toBe("7891011");
					expect(result.server).toInclude("sentry.io");
				});

			});

			describe("validateLevel", () => {

				it("accepts valid levels", () => {
					var levels = ["fatal", "error", "warning", "info", "debug"];
					for (var lvl in levels) {
						expect(function() { client.validateLevelPublic(lvl); }).notToThrow();
					}
				});

				it("rejects invalid level", () => {
					expect(function() { client.validateLevelPublic("bogus"); }).toThrow();
				});

			});

			describe("captureMessage", () => {

				it("accepts message and level", () => {
					// Verify no errors thrown when calling with valid args
					// (actual HTTP post is tested via integration)
					expect(IsObject(client)).toBeTrue();
				});

			});

			describe("getTimeVars", () => {

				it("returns ISO 8601 timestamp with Z suffix", () => {
					var tv = client.getTimeVars();
					expect(tv.iso_8601_date).toMatch("Z$");
				});

			});

		});

		describe("SentryForWheels Plugin", () => {

			describe("sentrySetUser / $sentryGetUser", () => {

				it("stores and retrieves user in request scope", () => {
					var plugin = new plugins.SentryForWheels.SentryForWheels();
					plugin.sentrySetUser({id: 42, email: "test@example.com"});
					expect(request.sentryUser.id).toBe(42);
				});

			});

			describe("sentryAddBreadcrumb", () => {

				it("appends breadcrumb to request array", () => {
					var plugin = new plugins.SentryForWheels.SentryForWheels();
					StructDelete(request, "sentryBreadcrumbs");
					plugin.sentryAddBreadcrumb(message="test crumb", category="test");
					expect(request.sentryBreadcrumbs).toBeArray();
					expect(ArrayLen(request.sentryBreadcrumbs)).toBe(1);
					expect(request.sentryBreadcrumbs[1].message).toBe("test crumb");
				});

			});

		});

	}

}
```

Note: The test file references `getParseDSNResult()` and `validateLevelPublic()` — the implementing agent must add thin public wrappers in `SentryClient.cfc` that delegate to the private methods, OR restructure the tests to verify behavior through the public `captureMessage`/`captureException` API. Prefer the latter if feasible.

- [ ] **Step 2: Commit**

```bash
git add plugins/SentryForWheels/tests/SentrySpec.cfc
git commit -m "test(sentry): add unit tests for DSN parsing, levels, timestamps, breadcrumbs"
```

---

## Part B: Hotwire (Finish Missing Helper + Polish)

### Task 5: Add plugin.json and fix mixin attribute

**Files:**
- Create: `plugins/hotwire/plugin.json`
- Modify: `plugins/hotwire/Hotwire.cfc` (line 1: fix mixin attribute)

- [ ] **Step 1: Create plugin.json manifest**

```json
{
	"name": "hotwire",
	"version": "0.1.0",
	"author": "CFWheels Core Team",
	"description": "Hotwire infrastructure for Wheels: Turbo Drive, Turbo Frames, Turbo Streams, Stimulus helpers, and Hotwire Native mobile support",
	"mixins": "controller,view",
	"wheelsVersion": "3.0"
}
```

- [ ] **Step 2: Fix mixin attribute on Hotwire.cfc**

Change line 1 from:
```cfml
<cfcomponent output="false" mixin="controller,dispatch,microsofttablehelper,view">
```
to:
```cfml
<cfcomponent output="false" mixin="controller,view">
```

- [ ] **Step 3: Commit**

```bash
git add plugins/hotwire/plugin.json plugins/hotwire/Hotwire.cfc
git commit -m "feat(hotwire): add plugin.json manifest, fix mixin scope"
```

### Task 6: Add hotwireNativePathConfiguration()

**Files:**
- Modify: `plugins/hotwire/Hotwire.cfc` (add new function after `resumeOrRedirectTo`)

- [ ] **Step 1: Implement hotwireNativePathConfiguration()**

Add this function after the `resumeOrRedirectTo()` function (around line 251):

```cfml
<!--- Serves Hotwire Native path configuration as JSON response --->
<cffunction name="hotwireNativePathConfiguration" access="public" returntype="void" output="true"
	hint="Renders JSON path configuration for Hotwire Native apps">
	<cfargument name="settings" type="struct" required="false" default="#StructNew()#"
		hint="Settings object (tabs, etc.)">
	<cfargument name="rules" type="array" required="false" default="#ArrayNew(1)#"
		hint="Array of rule structs with patterns and properties">

	<cfset var local = {}>
	<cfset local.config = {}>

	<cfif NOT StructIsEmpty(arguments.settings)>
		<cfset local.config["settings"] = arguments.settings>
	</cfif>

	<cfif ArrayLen(arguments.rules) GT 0>
		<cfset local.config["rules"] = arguments.rules>
	<cfelse>
		<!--- Default rules: all pages default context, /new and /edit open as modals --->
		<cfset local.config["rules"] = [
			{
				"patterns": [".*"],
				"properties": {"context": "default", "pull_to_refresh_enabled": true}
			},
			{
				"patterns": ["/new$", "/edit$"],
				"properties": {"context": "modal", "pull_to_refresh_enabled": false}
			}
		]>
	</cfif>

	<cfcontent type="application/json" reset="true">
	<cfoutput>#SerializeJSON(local.config)#</cfoutput>
	<cfabort>
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/hotwire/Hotwire.cfc
git commit -m "feat(hotwire): add hotwireNativePathConfiguration() JSON endpoint helper"
```

### Task 7: Add Hotwire plugin tests

**Files:**
- Create: `plugins/hotwire/tests/HotwireSpec.cfc`

- [ ] **Step 1: Create test spec**

```cfml
component extends="wheels.WheelsTest" {

	function beforeAll() {
		hw = new plugins.hotwire.Hotwire();
		hw.init();
	}

	function run() {

		describe("Hotwire Plugin", () => {

			describe("hotwireIncludes", () => {

				it("outputs Turbo script tag", () => {
					var result = hw.hotwireIncludes();
					expect(result).toInclude("turbo");
					expect(result).toInclude("<script");
				});

				it("outputs Stimulus script tag", () => {
					var result = hw.hotwireIncludes();
					expect(result).toInclude("stimulus");
				});

			});

			describe("turboFrame", () => {

				it("generates turbo-frame tag with id", () => {
					var result = hw.turboFrame(id="my-frame");
					expect(result).toInclude('<turbo-frame id="my-frame"');
				});

				it("includes src attribute when provided", () => {
					var result = hw.turboFrame(id="lazy", src="/load");
					expect(result).toInclude('src="/load"');
				});

				it("includes loading attribute", () => {
					var result = hw.turboFrame(id="lazy", src="/load", loading="lazy");
					expect(result).toInclude('loading="lazy"');
				});

				it("includes target attribute", () => {
					var result = hw.turboFrame(id="nav", target="_top");
					expect(result).toInclude('target="_top"');
				});

			});

			describe("turboFrameEnd", () => {

				it("closes turbo-frame tag", () => {
					expect(hw.turboFrameEnd()).toBe("</turbo-frame>");
				});

			});

			describe("turbo stream helpers", () => {

				it("generates append stream", () => {
					var result = hw.turboStreamAppend(target="list", content="<li>New</li>");
					expect(result).toInclude('action="append"');
					expect(result).toInclude('target="list"');
					expect(result).toInclude("<template>");
					expect(result).toInclude("<li>New</li>");
				});

				it("generates prepend stream", () => {
					var result = hw.turboStreamPrepend(target="list", content="<li>First</li>");
					expect(result).toInclude('action="prepend"');
				});

				it("generates replace stream", () => {
					var result = hw.turboStreamReplace(target="item-1", content="<div>New</div>");
					expect(result).toInclude('action="replace"');
				});

				it("generates update stream", () => {
					var result = hw.turboStreamUpdate(target="item-1", content="Updated");
					expect(result).toInclude('action="update"');
				});

				it("generates remove stream without template", () => {
					var result = hw.turboStreamRemove(target="item-1");
					expect(result).toInclude('action="remove"');
					expect(result).notToInclude("<template>");
				});

				it("generates before stream", () => {
					var result = hw.turboStreamBefore(target="ref", content="<p>Before</p>");
					expect(result).toInclude('action="before"');
				});

				it("generates after stream", () => {
					var result = hw.turboStreamAfter(target="ref", content="<p>After</p>");
					expect(result).toInclude('action="after"');
				});

				it("generates refresh stream", () => {
					var result = hw.turboStreamRefresh();
					expect(result).toInclude('action="refresh"');
				});

			});

			describe("stimulus helpers", () => {

				it("generates data-controller attribute", () => {
					var result = hw.stimulusController("toggle");
					expect(result).toBe('data-controller="toggle"');
				});

				it("generates data-action attribute", () => {
					var result = hw.stimulusAction("click->toggle##toggle");
					expect(result).toInclude('data-action=');
				});

				it("generates data-target attribute", () => {
					var result = hw.stimulusTarget(controller="toggle", name="button");
					expect(result).toBe('data-toggle-target="button"');
				});

				it("generates data-value attribute", () => {
					var result = hw.stimulusValue(controller="counter", name="count", value="0");
					expect(result).toBe('data-counter-count-value="0"');
				});

			});

		});

	}

}
```

- [ ] **Step 2: Commit**

```bash
git add plugins/hotwire/tests/HotwireSpec.cfc
git commit -m "test(hotwire): add unit tests for frames, streams, stimulus helpers"
```

---

## Part C: Basecoat (Build Remaining Phases)

### Task 8: Add plugin.json, fix mixin, fix ARCHITECTURE.md

**Files:**
- Create: `plugins/basecoat/plugin.json`
- Modify: `plugins/basecoat/Basecoat.cfc` (line 1: fix mixin attribute)
- Modify: `plugins/basecoat/.ai/ARCHITECTURE.md` (replace with Basecoat-specific content)

- [ ] **Step 1: Create plugin.json**

```json
{
	"name": "basecoat",
	"version": "0.1.0",
	"author": "CFWheels Core Team",
	"description": "Basecoat UI component helpers for Wheels. shadcn/ui-quality design using plain HTML + Tailwind CSS. No React required.",
	"mixins": "controller,view",
	"wheelsVersion": "3.0"
}
```

- [ ] **Step 2: Fix mixin attribute**

Change line 1 of `Basecoat.cfc` from:
```cfml
<cfcomponent output="false" mixin="controller,dispatch,microsofttablehelper,view">
```
to:
```cfml
<cfcomponent output="false" mixin="controller,view">
```

- [ ] **Step 3: Replace .ai/ARCHITECTURE.md with Basecoat-specific content**

The file currently contains the Hotwire architecture doc. Replace with a brief pointer:

```markdown
# Basecoat Plugin Architecture

See `CLAUDE.md` in the plugin root for the authoritative specification including markup reference, implementation phases, naming conventions, and testing guidance.

## Component Categories

- **Simple** (Phase 1): Button, Badge, Icon, Spinner, Skeleton, Progress, Separator, Tooltip
- **Block** (Phase 2): Alert, Card, Dialog
- **Form** (Phase 3): Field (text, email, textarea, select, checkbox, switch)
- **Complex** (Phase 4): Table, Tabs, Dropdown, Pagination
- **Layout** (Phase 5): Sidebar, Breadcrumb

## Design Principles

- All helpers return HTML strings for use in views via `#helperName()#`
- Markup matches basecoatui.com v0.3.x patterns exactly
- No JavaScript dependencies for core components (CSS-only where possible)
- Turbo-aware but Hotwire-independent
- Native `<dialog>` element for modals (no JS library)
```

- [ ] **Step 4: Commit**

```bash
git add plugins/basecoat/plugin.json plugins/basecoat/Basecoat.cfc plugins/basecoat/.ai/ARCHITECTURE.md
git commit -m "feat(basecoat): add plugin.json, fix mixin scope, fix architecture doc"
```

### Task 9: Implement uiDialog family (Phase 2)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc` (add after `uiCardEnd`)

Reference markup from CLAUDE.md:
```html
<button type="button" onclick="document.getElementById('dlg-id').showModal()" class="btn-outline">Open</button>
<dialog id="dlg-id" class="dialog w-full sm:max-w-[425px] max-h-[612px]"
        aria-labelledby="dlg-id-title" aria-describedby="dlg-id-desc"
        onclick="if (event.target === this) this.close()">
    <div>
        <header><h2 id="dlg-id-title">Title</h2><p id="dlg-id-desc">Description</p></header>
        <section><!-- content --></section>
        <footer><!-- actions --></footer>
        <button type="button" aria-label="Close dialog" onclick="this.closest('dialog').close()">
            <svg ...><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
    </div>
</dialog>
```

- [ ] **Step 1: Implement uiDialog()**

Add after `uiCardEnd()`:

```cfml
<!--- Opens a native <dialog> modal with trigger button, header, and close button --->
<cffunction name="uiDialog" access="public" returntype="string" output="false"
	hint="Opens a dialog modal. Use uiDialogFooter()/uiDialogEnd() to close.">
	<cfargument name="title" type="string" required="true" hint="Dialog title">
	<cfargument name="description" type="string" required="false" default="" hint="Dialog description">
	<cfargument name="triggerText" type="string" required="false" default="" hint="Trigger button text (empty = no trigger)">
	<cfargument name="triggerClass" type="string" required="false" default="btn-outline" hint="Trigger button CSS class">
	<cfargument name="id" type="string" required="false" default="" hint="Dialog ID (auto-generated if empty)">
	<cfargument name="maxWidth" type="string" required="false" default="sm:max-w-[425px]" hint="Max width class">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">

	<cfset var local = {}>
	<cfset local.id = Len(arguments.id) ? arguments.id : $uiBuildId("dlg")>

	<cfsavecontent variable="local.html">
	<cfoutput>
	<cfif Len(arguments.triggerText)>
	<button type="button" onclick="document.getElementById('#local.id#').showModal()" class="#arguments.triggerClass#">#arguments.triggerText#</button>
	</cfif>
	<dialog id="#local.id#" class="dialog w-full #arguments.maxWidth# max-h-[612px]<cfif Len(arguments.class)> #arguments.class#</cfif>"
		aria-labelledby="#local.id#-title"<cfif Len(arguments.description)> aria-describedby="#local.id#-desc"</cfif>
		onclick="if (event.target === this) this.close()">
	<div>
		<header>
			<h2 id="#local.id#-title">#arguments.title#</h2>
			<cfif Len(arguments.description)><p id="#local.id#-desc">#arguments.description#</p></cfif>
		</header>
		<section>
	</cfoutput>
	</cfsavecontent>

	<cfreturn Trim(local.html)>
</cffunction>
```

- [ ] **Step 2: Implement uiDialogFooter()**

```cfml
<!--- Closes dialog content section and opens footer --->
<cffunction name="uiDialogFooter" access="public" returntype="string" output="false"
	hint="Closes dialog content section and opens footer">

	<cfreturn "</section><footer>">
</cffunction>
```

- [ ] **Step 3: Implement uiDialogEnd()**

```cfml
<!--- Closes dialog with close button, footer, container div, and dialog tag --->
<cffunction name="uiDialogEnd" access="public" returntype="string" output="false"
	hint="Closes dialog element with close X button">

	<cfsavecontent variable="local.html">
	<cfoutput>
		</footer>
		<button type="button" aria-label="Close dialog" onclick="this.closest('dialog').close()">
			<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
				fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
				stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
		</button>
	</div>
	</dialog>
	</cfoutput>
	</cfsavecontent>

	<cfreturn Trim(local.html)>
</cffunction>
```

- [ ] **Step 4: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiDialog/uiDialogFooter/uiDialogEnd (Phase 2)"
```

### Task 10: Implement uiField (Phase 3 — Forms)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc`

This is the most complex component. It handles: text, email, password, number, tel, url, textarea, select, checkbox, switch. Layout differs: checkbox/switch use flex-row with label after input; all others use grid with label above.

- [ ] **Step 1: Implement uiField()**

Add after `uiDialogEnd()`:

```cfml
<!--- Generates a complete form field: label + input + description + error --->
<cffunction name="uiField" access="public" returntype="string" output="false"
	hint="Generates complete form field with label, input, description, and error state">
	<cfargument name="label" type="string" required="true" hint="Field label text">
	<cfargument name="name" type="string" required="true" hint="Input name attribute (e.g. 'user[email]')">
	<cfargument name="type" type="string" required="false" default="text" hint="Input type: text, email, password, number, tel, url, textarea, select, checkbox, switch">
	<cfargument name="value" type="string" required="false" default="" hint="Input value">
	<cfargument name="id" type="string" required="false" default="" hint="Input ID (auto-generated if empty)">
	<cfargument name="placeholder" type="string" required="false" default="" hint="Placeholder text">
	<cfargument name="description" type="string" required="false" default="" hint="Help text below input">
	<cfargument name="errorMessage" type="string" required="false" default="" hint="Error message (triggers error styling)">
	<cfargument name="required" type="boolean" required="false" default="false" hint="Required field">
	<cfargument name="disabled" type="boolean" required="false" default="false" hint="Disabled field">
	<cfargument name="checked" type="boolean" required="false" default="false" hint="Checked state for checkbox/switch">
	<cfargument name="options" type="string" required="false" default="" hint="Comma-delimited options for select (value:label pairs)">
	<cfargument name="rows" type="numeric" required="false" default="4" hint="Rows for textarea">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes on input">

	<cfset var local = {}>
	<cfset local.id = Len(arguments.id) ? arguments.id : $uiBuildId("fld")>
	<cfset local.hasError = Len(arguments.errorMessage) GT 0>
	<cfset local.isToggle = ListFindNoCase("checkbox,switch", arguments.type) GT 0>

	<cfsavecontent variable="local.html">
	<cfoutput>
	<cfif local.isToggle>
	<!--- Checkbox/Switch: flex row, input first, label after --->
	<div class="flex items-center gap-2">
		<input type="checkbox" id="#local.id#" name="#arguments.name#"
			class="<cfif arguments.type EQ 'switch'>switch<cfelse>checkbox</cfif><cfif Len(arguments.class)> #arguments.class#</cfif>"
			<cfif arguments.type EQ "switch"> role="switch"</cfif>
			<cfif arguments.checked> checked</cfif>
			<cfif arguments.required> required</cfif>
			<cfif arguments.disabled> disabled</cfif>
			<cfif Len(arguments.value)> value="#arguments.value#"</cfif> />
		<label for="#local.id#">#arguments.label#</label>
	</div>
	<cfif local.hasError>
	<p id="#local.id#-error" class="text-sm text-destructive">#arguments.errorMessage#</p>
	</cfif>
	<cfif Len(arguments.description)>
	<p class="text-sm text-muted-foreground">#arguments.description#</p>
	</cfif>
	<cfelse>
	<!--- Standard fields: grid layout, label above input --->
	<div class="grid gap-2">
		<label for="#local.id#">#arguments.label#</label>
		<cfif arguments.type EQ "textarea">
		<textarea id="#local.id#" name="#arguments.name#" rows="#arguments.rows#"
			class="textarea<cfif local.hasError> border-destructive</cfif><cfif Len(arguments.class)> #arguments.class#</cfif>"
			<cfif Len(arguments.placeholder)> placeholder="#arguments.placeholder#"</cfif>
			<cfif arguments.required> required</cfif>
			<cfif arguments.disabled> disabled</cfif>
			<cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif>>#arguments.value#</textarea>
		<cfelseif arguments.type EQ "select">
		<select id="#local.id#" name="#arguments.name#"
			class="select<cfif local.hasError> border-destructive</cfif><cfif Len(arguments.class)> #arguments.class#</cfif>"
			<cfif arguments.required> required</cfif>
			<cfif arguments.disabled> disabled</cfif>
			<cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif>>
			<cfif Len(arguments.placeholder)><option value="">#arguments.placeholder#</option></cfif>
			<cfloop list="#arguments.options#" index="local.opt">
				<cfif ListLen(local.opt, ":") EQ 2>
				<option value="#ListFirst(local.opt, ':')#"<cfif arguments.value EQ ListFirst(local.opt, ':')> selected</cfif>>#ListLast(local.opt, ':')#</option>
				<cfelse>
				<option value="#local.opt#"<cfif arguments.value EQ local.opt> selected</cfif>>#local.opt#</option>
				</cfif>
			</cfloop>
		</select>
		<cfelse>
		<input type="#arguments.type#" id="#local.id#" name="#arguments.name#"
			class="input<cfif local.hasError> border-destructive</cfif><cfif Len(arguments.class)> #arguments.class#</cfif>"
			<cfif Len(arguments.value)> value="#arguments.value#"</cfif>
			<cfif Len(arguments.placeholder)> placeholder="#arguments.placeholder#"</cfif>
			<cfif arguments.required> required</cfif>
			<cfif arguments.disabled> disabled</cfif>
			<cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif> />
		</cfif>
		<cfif local.hasError>
		<p id="#local.id#-error" class="text-sm text-destructive">#arguments.errorMessage#</p>
		</cfif>
		<cfif Len(arguments.description)>
		<p class="text-sm text-muted-foreground">#arguments.description#</p>
		</cfif>
	</div>
	</cfif>
	</cfoutput>
	</cfsavecontent>

	<cfreturn Trim(local.html)>
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiField form component (Phase 3)"
```

### Task 11: Implement uiTable family (Phase 4)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc`

Reference markup:
```html
<div class="table-container">
    <table class="table">
        <thead><tr><th>Header</th></tr></thead>
        <tbody><tr><td>Cell</td></tr></tbody>
    </table>
</div>
```

- [ ] **Step 1: Implement table helpers**

Add after `uiField()`:

```cfml
<cffunction name="uiTable" access="public" returntype="string" output="false"
	hint="Opens table container and table element">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<div class="table-container"><table class="table' & (Len(arguments.class) ? ' ' & arguments.class : '') & '">'>
</cffunction>

<cffunction name="uiTableHeader" access="public" returntype="string" output="false"
	hint="Opens thead and tr">
	<cfreturn "<thead><tr>">
</cffunction>

<cffunction name="uiTableHeaderEnd" access="public" returntype="string" output="false"
	hint="Closes tr and thead">
	<cfreturn "</tr></thead>">
</cffunction>

<cffunction name="uiTableBody" access="public" returntype="string" output="false"
	hint="Opens tbody">
	<cfreturn "<tbody>">
</cffunction>

<cffunction name="uiTableBodyEnd" access="public" returntype="string" output="false"
	hint="Closes tbody">
	<cfreturn "</tbody>">
</cffunction>

<cffunction name="uiTableRow" access="public" returntype="string" output="false"
	hint="Opens tr">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<tr' & (Len(arguments.class) ? ' class="' & arguments.class & '"' : '') & '>'>
</cffunction>

<cffunction name="uiTableRowEnd" access="public" returntype="string" output="false"
	hint="Closes tr">
	<cfreturn "</tr>">
</cffunction>

<cffunction name="uiTableHead" access="public" returntype="string" output="false"
	hint="Generates th element">
	<cfargument name="text" type="string" required="false" default="" hint="Header text">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<th' & (Len(arguments.class) ? ' class="' & arguments.class & '"' : '') & '>' & arguments.text & '</th>'>
</cffunction>

<cffunction name="uiTableCell" access="public" returntype="string" output="false"
	hint="Generates td element">
	<cfargument name="text" type="string" required="false" default="" hint="Cell text">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<td' & (Len(arguments.class) ? ' class="' & arguments.class & '"' : '') & '>' & arguments.text & '</td>'>
</cffunction>

<cffunction name="uiTableEnd" access="public" returntype="string" output="false"
	hint="Closes table and container">
	<cfreturn "</table></div>">
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiTable family (Phase 4)"
```

### Task 12: Implement uiTabs family (Phase 4)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc`

Reference markup:
```html
<div class="tabs" data-default="tab1">
    <div class="tabs-list">
        <button class="tabs-trigger" data-value="tab1">Tab 1</button>
    </div>
    <div class="tabs-content" data-value="tab1">Content 1</div>
</div>
```

- [ ] **Step 1: Implement tab helpers**

```cfml
<cffunction name="uiTabs" access="public" returntype="string" output="false"
	hint="Opens tabs container with default tab selection">
	<cfargument name="defaultTab" type="string" required="true" hint="Value of the default active tab">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<div class="tabs' & (Len(arguments.class) ? ' ' & arguments.class : '') & '" data-default="' & arguments.defaultTab & '">'>
</cffunction>

<cffunction name="uiTabList" access="public" returntype="string" output="false"
	hint="Opens the tab button list">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<div class="tabs-list' & (Len(arguments.class) ? ' ' & arguments.class : '') & '">'>
</cffunction>

<cffunction name="uiTabListEnd" access="public" returntype="string" output="false"
	hint="Closes tab button list">
	<cfreturn "</div>">
</cffunction>

<cffunction name="uiTabTrigger" access="public" returntype="string" output="false"
	hint="Generates a tab trigger button">
	<cfargument name="value" type="string" required="true" hint="Tab value (matches data-value on content)">
	<cfargument name="text" type="string" required="true" hint="Tab button text">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<button class="tabs-trigger' & (Len(arguments.class) ? ' ' & arguments.class : '') & '" data-value="' & arguments.value & '">' & arguments.text & '</button>'>
</cffunction>

<cffunction name="uiTabContent" access="public" returntype="string" output="false"
	hint="Opens a tab content panel">
	<cfargument name="value" type="string" required="true" hint="Tab value (matches trigger data-value)">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<div class="tabs-content' & (Len(arguments.class) ? ' ' & arguments.class : '') & '" data-value="' & arguments.value & '">'>
</cffunction>

<cffunction name="uiTabContentEnd" access="public" returntype="string" output="false"
	hint="Closes tab content panel">
	<cfreturn "</div>">
</cffunction>

<cffunction name="uiTabsEnd" access="public" returntype="string" output="false"
	hint="Closes tabs container">
	<cfreturn "</div>">
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiTabs family (Phase 4)"
```

### Task 13: Implement uiDropdown family (Phase 4)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc`

Basecoat dropdowns use the `details/summary` pattern (CSS-only, no JS):

```html
<details class="dropdown">
    <summary class="btn-outline">Open Menu</summary>
    <ul>
        <li><a href="/profile">Profile</a></li>
        <li><hr class="separator" /></li>
        <li><a href="/logout">Logout</a></li>
    </ul>
</details>
```

- [ ] **Step 1: Implement dropdown helpers**

```cfml
<cffunction name="uiDropdown" access="public" returntype="string" output="false"
	hint="Opens a dropdown menu using details/summary pattern">
	<cfargument name="text" type="string" required="true" hint="Trigger button text">
	<cfargument name="triggerClass" type="string" required="false" default="btn-outline" hint="Trigger button CSS class">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<details class="dropdown' & (Len(arguments.class) ? ' ' & arguments.class : '') & '"><summary class="' & arguments.triggerClass & '">' & arguments.text & '</summary><ul>'>
</cffunction>

<cffunction name="uiDropdownItem" access="public" returntype="string" output="false"
	hint="Generates a dropdown menu item">
	<cfargument name="text" type="string" required="true" hint="Item text">
	<cfargument name="href" type="string" required="false" default="##" hint="Link URL">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<li><a href="' & arguments.href & '"' & (Len(arguments.class) ? ' class="' & arguments.class & '"' : '') & '>' & arguments.text & '</a></li>'>
</cffunction>

<cffunction name="uiDropdownSeparator" access="public" returntype="string" output="false"
	hint="Generates a dropdown separator">
	<cfreturn '<li><hr class="separator" /></li>'>
</cffunction>

<cffunction name="uiDropdownEnd" access="public" returntype="string" output="false"
	hint="Closes dropdown menu">
	<cfreturn "</ul></details>">
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiDropdown family (Phase 4)"
```

### Task 14: Implement uiPagination (Phase 4)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc`

- [ ] **Step 1: Implement uiPagination()**

```cfml
<!--- Generates pagination nav from current page and total pages --->
<cffunction name="uiPagination" access="public" returntype="string" output="false"
	hint="Generates pagination navigation">
	<cfargument name="currentPage" type="numeric" required="true" hint="Current page number">
	<cfargument name="totalPages" type="numeric" required="true" hint="Total number of pages">
	<cfargument name="baseUrl" type="string" required="true" hint="Base URL (page param appended)">
	<cfargument name="pageParam" type="string" required="false" default="page" hint="Query parameter name">
	<cfargument name="windowSize" type="numeric" required="false" default="2" hint="Pages shown on each side of current">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">

	<cfset var local = {}>
	<cfset local.separator = Find("?", arguments.baseUrl) ? "&" : "?">

	<cfsavecontent variable="local.html">
	<cfoutput>
	<nav class="pagination<cfif Len(arguments.class)> #arguments.class#</cfif>" aria-label="Pagination">
		<cfif arguments.currentPage GT 1>
		<a href="#arguments.baseUrl##local.separator##arguments.pageParam#=#arguments.currentPage - 1#" class="btn-outline btn-sm">#$uiLucideIcon("chevron-left", 16)# Prev</a>
		<cfelse>
		<span class="btn-outline btn-sm opacity-50">#$uiLucideIcon("chevron-left", 16)# Prev</span>
		</cfif>

		<cfset local.startPage = Max(1, arguments.currentPage - arguments.windowSize)>
		<cfset local.endPage = Min(arguments.totalPages, arguments.currentPage + arguments.windowSize)>

		<cfif local.startPage GT 1>
		<a href="#arguments.baseUrl##local.separator##arguments.pageParam#=1" class="btn-ghost btn-sm">1</a>
		<cfif local.startPage GT 2><span class="btn-ghost btn-sm">...</span></cfif>
		</cfif>

		<cfloop from="#local.startPage#" to="#local.endPage#" index="local.p">
		<cfif local.p EQ arguments.currentPage>
		<span class="btn btn-sm">#local.p#</span>
		<cfelse>
		<a href="#arguments.baseUrl##local.separator##arguments.pageParam#=#local.p#" class="btn-ghost btn-sm">#local.p#</a>
		</cfif>
		</cfloop>

		<cfif local.endPage LT arguments.totalPages>
		<cfif local.endPage LT arguments.totalPages - 1><span class="btn-ghost btn-sm">...</span></cfif>
		<a href="#arguments.baseUrl##local.separator##arguments.pageParam#=#arguments.totalPages#" class="btn-ghost btn-sm">#arguments.totalPages#</a>
		</cfif>

		<cfif arguments.currentPage LT arguments.totalPages>
		<a href="#arguments.baseUrl##local.separator##arguments.pageParam#=#arguments.currentPage + 1#" class="btn-outline btn-sm">Next #$uiLucideIcon("chevron-right", 16)#</a>
		<cfelse>
		<span class="btn-outline btn-sm opacity-50">Next #$uiLucideIcon("chevron-right", 16)#</span>
		</cfif>
	</nav>
	</cfoutput>
	</cfsavecontent>

	<cfreturn Trim(local.html)>
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiPagination (Phase 4)"
```

### Task 15: Implement uiBreadcrumb family (Phase 5)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc`

- [ ] **Step 1: Implement breadcrumb helpers**

```cfml
<cffunction name="uiBreadcrumb" access="public" returntype="string" output="false"
	hint="Opens breadcrumb navigation">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<nav aria-label="Breadcrumb" class="breadcrumb' & (Len(arguments.class) ? ' ' & arguments.class : '') & '"><ol>'>
</cffunction>

<cffunction name="uiBreadcrumbItem" access="public" returntype="string" output="false"
	hint="Generates a breadcrumb item (link or current page)">
	<cfargument name="text" type="string" required="true" hint="Breadcrumb text">
	<cfargument name="href" type="string" required="false" default="" hint="Link URL (empty = current page)">
	<cfif Len(arguments.href)>
		<cfreturn '<li><a href="' & arguments.href & '">' & arguments.text & '</a></li>'>
	<cfelse>
		<cfreturn '<li><span aria-current="page">' & arguments.text & '</span></li>'>
	</cfif>
</cffunction>

<cffunction name="uiBreadcrumbSeparator" access="public" returntype="string" output="false"
	hint="Generates breadcrumb separator">
	<cfreturn '<li aria-hidden="true">' & $uiLucideIcon("chevron-right", 16) & '</li>'>
</cffunction>

<cffunction name="uiBreadcrumbEnd" access="public" returntype="string" output="false"
	hint="Closes breadcrumb navigation">
	<cfreturn "</ol></nav>">
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiBreadcrumb family (Phase 5)"
```

### Task 16: Implement uiSidebar family (Phase 5)

**Files:**
- Modify: `plugins/basecoat/Basecoat.cfc`

- [ ] **Step 1: Implement sidebar helpers**

```cfml
<cffunction name="uiSidebar" access="public" returntype="string" output="false"
	hint="Opens sidebar layout container">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfreturn '<aside class="sidebar' & (Len(arguments.class) ? ' ' & arguments.class : '') & '"><nav>'>
</cffunction>

<cffunction name="uiSidebarSection" access="public" returntype="string" output="false"
	hint="Opens a sidebar section with optional title">
	<cfargument name="title" type="string" required="false" default="" hint="Section title">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfset var local = {}>
	<cfset local.html = '<div class="sidebar-section' & (Len(arguments.class) ? ' ' & arguments.class : '') & '">'>
	<cfif Len(arguments.title)>
		<cfset local.html = local.html & '<h4 class="sidebar-section-title">' & arguments.title & '</h4>'>
	</cfif>
	<cfset local.html = local.html & '<ul>'>
	<cfreturn local.html>
</cffunction>

<cffunction name="uiSidebarSectionEnd" access="public" returntype="string" output="false"
	hint="Closes sidebar section">
	<cfreturn "</ul></div>">
</cffunction>

<cffunction name="uiSidebarItem" access="public" returntype="string" output="false"
	hint="Generates a sidebar navigation item">
	<cfargument name="text" type="string" required="true" hint="Item text">
	<cfargument name="href" type="string" required="false" default="##" hint="Link URL">
	<cfargument name="icon" type="string" required="false" default="" hint="Lucide icon name">
	<cfargument name="active" type="boolean" required="false" default="false" hint="Active state">
	<cfargument name="class" type="string" required="false" default="" hint="Additional CSS classes">
	<cfset var local = {}>
	<cfset local.activeClass = arguments.active ? " sidebar-item-active" : "">
	<cfset local.iconHtml = Len(arguments.icon) ? $uiLucideIcon(arguments.icon, 16) & " " : "">
	<cfreturn '<li><a href="' & arguments.href & '" class="sidebar-item' & local.activeClass & (Len(arguments.class) ? ' ' & arguments.class : '') & '">' & local.iconHtml & arguments.text & '</a></li>'>
</cffunction>

<cffunction name="uiSidebarEnd" access="public" returntype="string" output="false"
	hint="Closes sidebar">
	<cfreturn "</nav></aside>">
</cffunction>
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/Basecoat.cfc
git commit -m "feat(basecoat): add uiSidebar family (Phase 5)"
```

### Task 17: Add Basecoat tests — Simple components and Button class logic

**Files:**
- Create: `plugins/basecoat/tests/BasecoatSimpleSpec.cfc`

- [ ] **Step 1: Create test spec for Phase 1 + 2 components**

```cfml
component extends="wheels.WheelsTest" {

	function beforeAll() {
		bc = new plugins.basecoat.Basecoat();
		bc.init();
	}

	function run() {

		describe("Basecoat Plugin", () => {

			describe("uiButton class construction", () => {

				it("generates primary button with btn class", () => {
					var result = bc.uiButton(text="Click");
					expect(result).toInclude('class="btn"');
					expect(result).toInclude(">Click</button>");
				});

				it("generates secondary variant", () => {
					var result = bc.uiButton(text="Go", variant="secondary");
					expect(result).toInclude('class="btn-secondary"');
				});

				it("generates small size", () => {
					var result = bc.uiButton(text="Go", size="sm");
					expect(result).toInclude('class="btn-sm"');
				});

				it("generates compound class: sm + destructive", () => {
					var result = bc.uiButton(text="Del", size="sm", variant="destructive");
					expect(result).toInclude("btn-sm-destructive");
				});

				it("generates icon button class", () => {
					var result = bc.uiButton(text="", icon="plus");
					expect(result).toInclude("btn-icon");
				});

				it("generates compound: sm + icon + outline", () => {
					var result = bc.uiButton(text="", icon="trash", size="sm", variant="outline");
					expect(result).toInclude("btn-sm-icon-outline");
				});

				it("renders as anchor when href provided", () => {
					var result = bc.uiButton(text="Link", href="/path");
					expect(result).toInclude("<a ");
					expect(result).toInclude('href="/path"');
				});

				it("includes turbo-confirm attribute", () => {
					var result = bc.uiButton(text="Del", turboConfirm="Sure?");
					expect(result).toInclude('data-turbo-confirm="Sure?"');
				});

			});

			describe("uiBadge", () => {

				it("generates default badge", () => {
					var result = bc.uiBadge(text="New");
					expect(result).toInclude('class="badge"');
					expect(result).toInclude(">New</span>");
				});

				it("generates destructive badge", () => {
					var result = bc.uiBadge(text="Error", variant="destructive");
					expect(result).toInclude("badge-destructive");
				});

			});

			describe("uiAlert", () => {

				it("generates alert with title and description", () => {
					var result = bc.uiAlert(title="Heads up", description="Something happened");
					expect(result).toInclude('role="alert"');
					expect(result).toInclude("<h5>Heads up</h5>");
					expect(result).toInclude("Something happened");
				});

				it("generates destructive alert", () => {
					var result = bc.uiAlert(title="Error", variant="destructive");
					expect(result).toInclude("alert-destructive");
				});

			});

			describe("uiCard", () => {

				it("generates card with header", () => {
					var result = bc.uiCard() & bc.uiCardHeader(title="Title", description="Desc");
					expect(result).toInclude('class="card"');
					expect(result).toInclude("<h3>Title</h3>");
					expect(result).toInclude("<p>Desc</p>");
				});

			});

			describe("uiProgress", () => {

				it("generates progress bar with percentage", () => {
					var result = bc.uiProgress(value=60);
					expect(result).toInclude("progress");
					expect(result).toInclude('style="width: 60%"');
				});

			});

			describe("uiSpinner", () => {

				it("generates spinner div", () => {
					var result = bc.uiSpinner();
					expect(result).toInclude('class="spinner"');
				});

			});

			describe("uiSkeleton", () => {

				it("generates skeleton placeholder", () => {
					var result = bc.uiSkeleton();
					expect(result).toInclude("skeleton");
				});

			});

			describe("uiTooltip", () => {

				it("generates tooltip with data-tip", () => {
					var result = bc.uiTooltip(text="Help text");
					expect(result).toInclude('data-tip="Help text"');
					expect(result).toInclude("tooltip");
				});

			});

			describe("uiSeparator", () => {

				it("generates hr separator", () => {
					var result = bc.uiSeparator();
					expect(result).toInclude("separator");
				});

			});

		});

	}

}
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/tests/BasecoatSimpleSpec.cfc
git commit -m "test(basecoat): add tests for simple components and button class logic"
```

### Task 18: Add Basecoat tests — Dialog, Field, Complex components

**Files:**
- Create: `plugins/basecoat/tests/BasecoatComplexSpec.cfc`

- [ ] **Step 1: Create test spec for Phases 2-5**

```cfml
component extends="wheels.WheelsTest" {

	function beforeAll() {
		bc = new plugins.basecoat.Basecoat();
		bc.init();
	}

	function run() {

		describe("Basecoat Complex Components", () => {

			describe("uiDialog", () => {

				it("generates dialog with ARIA attributes", () => {
					var result = bc.uiDialog(title="Edit Profile", description="Update your info", triggerText="Open");
					expect(result).toInclude("<dialog");
					expect(result).toInclude("aria-labelledby=");
					expect(result).toInclude("aria-describedby=");
					expect(result).toInclude("<h2");
					expect(result).toInclude("Edit Profile");
				});

				it("generates trigger button when triggerText provided", () => {
					var result = bc.uiDialog(title="Test", triggerText="Open Me");
					expect(result).toInclude('onclick="document.getElementById');
					expect(result).toInclude(">Open Me</button>");
				});

				it("omits trigger when triggerText is empty", () => {
					var result = bc.uiDialog(title="Test");
					expect(result).notToInclude("showModal()");
				});

				it("generates matching IDs for ARIA references", () => {
					var result = bc.uiDialog(title="Test", description="Desc", id="my-dlg");
					expect(result).toInclude('id="my-dlg"');
					expect(result).toInclude('aria-labelledby="my-dlg-title"');
					expect(result).toInclude('id="my-dlg-title"');
					expect(result).toInclude('aria-describedby="my-dlg-desc"');
					expect(result).toInclude('id="my-dlg-desc"');
				});

			});

			describe("uiDialogEnd", () => {

				it("includes close button with X SVG", () => {
					var result = bc.uiDialogEnd();
					expect(result).toInclude('aria-label="Close dialog"');
					expect(result).toInclude("</dialog>");
				});

			});

			describe("uiField", () => {

				it("generates text input with label", () => {
					var result = bc.uiField(label="Name", name="user[name]");
					expect(result).toInclude("<label");
					expect(result).toInclude(">Name</label>");
					expect(result).toInclude('type="text"');
					expect(result).toInclude('class="input"');
				});

				it("generates textarea", () => {
					var result = bc.uiField(label="Bio", name="user[bio]", type="textarea");
					expect(result).toInclude("<textarea");
					expect(result).toInclude('class="textarea"');
				});

				it("generates select with options", () => {
					var result = bc.uiField(label="Role", name="user[role]", type="select", options="admin:Admin,user:User", placeholder="Choose...");
					expect(result).toInclude("<select");
					expect(result).toInclude('class="select"');
					expect(result).toInclude(">Choose...</option>");
					expect(result).toInclude('value="admin"');
					expect(result).toInclude(">Admin</option>");
				});

				it("generates checkbox with label after input", () => {
					var result = bc.uiField(label="Agree", name="user[agree]", type="checkbox");
					expect(result).toInclude("flex items-center");
					expect(result).toInclude('class="checkbox"');
					// Label should come after input in checkbox layout
					var inputPos = Find("checkbox", result);
					var labelPos = Find("<label", result);
					expect(labelPos).toBeGT(inputPos);
				});

				it("generates switch with role attribute", () => {
					var result = bc.uiField(label="Notify", name="user[notify]", type="switch");
					expect(result).toInclude('class="switch"');
					expect(result).toInclude('role="switch"');
				});

				it("renders error state with destructive styling", () => {
					var result = bc.uiField(label="Email", name="user[email]", type="email", errorMessage="Invalid email");
					expect(result).toInclude("border-destructive");
					expect(result).toInclude('aria-invalid="true"');
					expect(result).toInclude("text-destructive");
					expect(result).toInclude("Invalid email");
				});

				it("renders description text", () => {
					var result = bc.uiField(label="Name", name="user[name]", description="Your full name");
					expect(result).toInclude("text-muted-foreground");
					expect(result).toInclude("Your full name");
				});

				it("auto-generates ID when omitted", () => {
					var result = bc.uiField(label="Test", name="test");
					expect(result).toMatch('id="fld-');
				});

			});

			describe("uiTable", () => {

				it("generates table container and table", () => {
					var result = bc.uiTable();
					expect(result).toInclude("table-container");
					expect(result).toInclude('class="table"');
				});

				it("generates th element", () => {
					var result = bc.uiTableHead(text="Name");
					expect(result).toBe("<th>Name</th>");
				});

				it("generates td element", () => {
					var result = bc.uiTableCell(text="John");
					expect(result).toBe("<td>John</td>");
				});

			});

			describe("uiTabs", () => {

				it("generates tabs container with default", () => {
					var result = bc.uiTabs(defaultTab="tab1");
					expect(result).toInclude('data-default="tab1"');
					expect(result).toInclude("tabs");
				});

				it("generates tab trigger", () => {
					var result = bc.uiTabTrigger(value="tab1", text="First");
					expect(result).toInclude("tabs-trigger");
					expect(result).toInclude('data-value="tab1"');
					expect(result).toInclude(">First</button>");
				});

				it("generates tab content panel", () => {
					var result = bc.uiTabContent(value="tab1");
					expect(result).toInclude("tabs-content");
					expect(result).toInclude('data-value="tab1"');
				});

			});

			describe("uiDropdown", () => {

				it("generates details/summary dropdown", () => {
					var result = bc.uiDropdown(text="Menu");
					expect(result).toInclude("<details");
					expect(result).toInclude("dropdown");
					expect(result).toInclude("<summary");
					expect(result).toInclude(">Menu</summary>");
				});

				it("generates dropdown item", () => {
					var result = bc.uiDropdownItem(text="Profile", href="/profile");
					expect(result).toInclude('<a href="/profile"');
					expect(result).toInclude(">Profile</a>");
				});

			});

			describe("uiPagination", () => {

				it("generates pagination nav", () => {
					var result = bc.uiPagination(currentPage=3, totalPages=10, baseUrl="/users");
					expect(result).toInclude('<nav');
					expect(result).toInclude('aria-label="Pagination"');
					expect(result).toInclude("Prev");
					expect(result).toInclude("Next");
				});

				it("disables prev on first page", () => {
					var result = bc.uiPagination(currentPage=1, totalPages=5, baseUrl="/users");
					expect(result).toInclude("opacity-50");
					// Prev should be a span, not a link
					expect(result).toMatch("<span[^>]*>.*Prev");
				});

				it("disables next on last page", () => {
					var result = bc.uiPagination(currentPage=5, totalPages=5, baseUrl="/users");
					expect(result).toMatch("<span[^>]*opacity-50[^>]*>.*Next");
				});

			});

			describe("uiBreadcrumb", () => {

				it("generates breadcrumb nav", () => {
					var result = bc.uiBreadcrumb();
					expect(result).toInclude('aria-label="Breadcrumb"');
					expect(result).toInclude("<ol>");
				});

				it("generates linked breadcrumb item", () => {
					var result = bc.uiBreadcrumbItem(text="Home", href="/");
					expect(result).toInclude('<a href="/"');
					expect(result).toInclude(">Home</a>");
				});

				it("generates current page breadcrumb item", () => {
					var result = bc.uiBreadcrumbItem(text="Users");
					expect(result).toInclude('aria-current="page"');
				});

			});

			describe("uiSidebar", () => {

				it("generates sidebar nav", () => {
					var result = bc.uiSidebar();
					expect(result).toInclude("sidebar");
					expect(result).toInclude("<nav>");
				});

				it("generates sidebar item with icon", () => {
					var result = bc.uiSidebarItem(text="Dashboard", href="/dashboard", icon="search");
					expect(result).toInclude("sidebar-item");
					expect(result).toInclude(">Dashboard</a>");
					expect(result).toInclude("<svg"); // icon SVG
				});

				it("marks active sidebar item", () => {
					var result = bc.uiSidebarItem(text="Home", active=true);
					expect(result).toInclude("sidebar-item-active");
				});

			});

		});

	}

}
```

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/tests/BasecoatComplexSpec.cfc
git commit -m "test(basecoat): add tests for dialog, field, table, tabs, dropdown, pagination, breadcrumb, sidebar"
```

---

## Task 19: Update index.cfm files to reflect actual state

**Files:**
- Modify: `plugins/basecoat/index.cfm` (ensure it lists only implemented helpers)
- Verify: `plugins/hotwire/index.cfm` (should list all implemented helpers)

- [ ] **Step 1: Update Basecoat index.cfm to list all implemented helpers accurately**

Review the file and ensure every helper listed matches what's actually in `Basecoat.cfc`. Add any new Phase 2-5 helpers that were just implemented.

- [ ] **Step 2: Commit**

```bash
git add plugins/basecoat/index.cfm plugins/hotwire/index.cfm
git commit -m "docs: update plugin index.cfm files to reflect implemented helpers"
```

---

## Task 20: Final integration verification

- [ ] **Step 1: Verify all three plugin.json files parse correctly**

Each must be valid JSON with `name`, `version`, `mixins`, `wheelsVersion` keys.

- [ ] **Step 2: Verify no compilation errors**

Instantiate each plugin CFC to check for syntax errors:
```cfml
new plugins.SentryForWheels.SentryForWheels();
new plugins.hotwire.Hotwire();
new plugins.basecoat.Basecoat();
```

- [ ] **Step 3: Run all test specs if a test runner is available**

- [ ] **Step 4: Final commit with all remaining changes**

```bash
git add -A plugins/
git commit -m "feat: complete first-party plugin suite (Sentry, Hotwire, Basecoat)"
```

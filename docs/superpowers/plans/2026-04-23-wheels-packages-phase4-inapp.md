# wheels-packages Phase 4 In-App Browse Registry — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Browse registry" section to the in-app `/wheels/packages` page so developers see all installable packages from `wheels-dev/wheels-packages` alongside their installed ones, with a copy-to-clipboard CLI install command per package.

**Architecture:** Reuse the CLI's `cli.lucli.services.packages.Registry` directly from Wheels core. Add one convenience method (`listAll()`) that returns enriched manifest summaries. Add one seam on `vendor/wheels/Public.cfc` (`$loadRegistryPackages()`) that handles memoization, production gating, and error capture — keeping the `.cfm` view thin and untestable-in-isolation logic out of the view. Extend `packagelist.cfm` to render the new section, marking rows that are already installed.

**Tech Stack:** CFML (Lucee + Adobe CF), WheelsTest BDD, existing `FakeHttpClient` + `ManifestCache` test doubles.

**Spec:** `docs/superpowers/specs/2026-04-23-wheels-packages-phase4-ui-design.md` (see "Revision" note — this plan covers Component 1 only; the wheels.dev Astro work is deferred).

**Issue:** [#2271](https://github.com/wheels-dev/wheels/issues/2271). This PR does **not** close #2271 — it remains open for the deferred wheels.dev work.

---

## File structure

**Files created:**
- `vendor/wheels/tests/specs/packages/RegistryListAllSpec.cfc` — spec for new `listAll()` method
- `vendor/wheels/tests/specs/packages/LoadRegistryPackagesSpec.cfc` — spec for new `$loadRegistryPackages()` method on Public.cfc

**Files modified:**
- `cli/lucli/services/packages/Registry.cfc` — add `listAll()` public method
- `vendor/wheels/Public.cfc` — add `$loadRegistryPackages()` private helper
- `vendor/wheels/public/views/packagelist.cfm` — add "Browse registry" section below existing installed-packages table
- `CHANGELOG.md` — add entry under "Unreleased" or appropriate heading

**Rationale for shape:**
- `listAll()` on `Registry.cfc` (not a new class) — it's a trivial wrapper composing two existing methods. A new class would be over-abstraction.
- `$loadRegistryPackages()` on `Public.cfc` (not a view helper) — Public.cfc already owns `$blockInProduction()` and handler logic; adding a peer is consistent. View-level try/catch would bake untestable logic into the `.cfm`.
- No new `vendor/wheels/global/packages.cfm` (as the spec initially proposed) — over-scoped for a 20-line helper.

---

## Task 1: Add `listAll()` to Registry.cfc (TDD)

**Files:**
- Modify: `cli/lucli/services/packages/Registry.cfc`
- Create: `cli/lucli/tests/specs/packages/RegistryListAllSpec.cfc`

**Shape of `listAll()`:**
- Returns: `array` of structs, each with keys `name`, `description`, `tags` (array), `latestVersion` (string), `homepage` (string — may be empty)
- Calls `listPackageNames()`, then `fetchManifest(name)` for each, extracts latest version from `manifest.versions[-1].version`
- Manifests ordered append-only per the registry's `CONTRIBUTING.md` — the last entry is the latest
- Silently skips any package whose manifest fetch throws `Wheels.Packages.RegistryMalformed` (still logs via regular Wheels logging), so one bad manifest doesn't break the whole list
- Propagates `Wheels.Packages.RegistryUnavailable` from `listPackageNames()` — that's a fatal condition for this call

### Steps

- [ ] **Step 1.1: Write failing test for happy path**

Create `cli/lucli/tests/specs/packages/RegistryListAllSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Registry.listAll", () => {

			var $freshCache = () => {
				var root = GetTempDirectory() & "wheels-registry-" & CreateUUID() & "/";
				return new cli.lucli.services.packages.ManifestCache(root = root);
			};

			var $manifest = (name, versions = [{version: "1.0.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "y"}]) => {
				return SerializeJSON({
					name: name,
					description: name & " description",
					homepage: "https://github.com/wheels-dev/" & name,
					tags: ["utility"],
					source: {type: "github", repo: "wheels-dev/" & name},
					versions: versions
				});
			};

			var $contentsBody = SerializeJSON([
				{name: "wheels-sentry",  type: "dir"},
				{name: "wheels-hotwire", type: "dir"},
				{name: "README.md",      type: "file"}
			]);

			it("returns enriched summaries for every package in the registry", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = $freshCache(), registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 200, body: $contentsBody}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-sentry/manifest.json",
					{status: 200, body: $manifest("wheels-sentry")}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-hotwire/manifest.json",
					{status: 200, body: $manifest("wheels-hotwire", [
						{version: "1.0.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "y"},
						{version: "1.1.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "y"}
					])}
				);

				var result = r.listAll();

				expect(ArrayLen(result)).toBe(2);
				expect(result[1].name).toBe("wheels-hotwire");     // sorted
				expect(result[1].latestVersion).toBe("1.1.0");     // last version entry wins
				expect(result[1].homepage).toBe("https://github.com/wheels-dev/wheels-hotwire");
				expect(result[1].tags).toBe(["utility"]);
				expect(result[2].name).toBe("wheels-sentry");
				expect(result[2].latestVersion).toBe("1.0.0");
			});

		});
	}
}
```

- [ ] **Step 1.2: Run test, verify it fails**

Run (from repo root):
```bash
bash tools/test-local.sh packages
```

Expected: failure on `RegistryListAllSpec` with "listAll is not a function" (or method-not-found). All other specs still pass. If any other spec fails, stop and investigate — do not proceed.

- [ ] **Step 1.3: Implement `listAll()` in Registry.cfc**

Add after `fetchManifest()` (roughly line 106) in `cli/lucli/services/packages/Registry.cfc`:

```cfml
	/**
	 * Returns enriched summaries for every package in the registry.
	 * One HTTP call for the index, one per package for its manifest
	 * (all cached 24h). Skips packages whose manifest fails to parse;
	 * propagates a registry-wide unavailability error.
	 */
	public array function listAll() {
		local.names = listPackageNames();
		local.out = [];
		for (local.name in local.names) {
			try {
				local.m = fetchManifest(local.name);
			} catch (Wheels.Packages.RegistryMalformed e) {
				continue;
			}
			local.latest = local.m.versions[ArrayLen(local.m.versions)];
			ArrayAppend(local.out, {
				name:          local.m.name,
				description:   local.m.description ?: "",
				tags:          IsArray(local.m.tags ?: "") ? local.m.tags : [],
				homepage:      local.m.homepage ?: "",
				latestVersion: local.latest.version
			});
		}
		return local.out;
	}
```

- [ ] **Step 1.4: Run test, verify it passes**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: all package specs pass, including the new one.

- [ ] **Step 1.5: Add test for malformed manifest skip**

Append inside the `describe("Registry.listAll", ...)` block in `RegistryListAllSpec.cfc`, after the first `it`:

```cfml
			it("skips a package whose manifest is malformed and continues", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = $freshCache(), registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 200, body: $contentsBody}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-sentry/manifest.json",
					{status: 200, body: "{""description"": ""no name key""}"}  // malformed — missing required 'name'
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-hotwire/manifest.json",
					{status: 200, body: $manifest("wheels-hotwire")}
				);

				var result = r.listAll();
				expect(ArrayLen(result)).toBe(1);
				expect(result[1].name).toBe("wheels-hotwire");
			});
```

- [ ] **Step 1.6: Run test, verify the new case passes**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: both specs in `RegistryListAllSpec` pass.

- [ ] **Step 1.7: Add test for propagation of unavailability error**

Append inside the same `describe` block:

```cfml
			it("propagates Wheels.Packages.RegistryUnavailable from listPackageNames", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = $freshCache(), registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 503, body: "service unavailable"}
				);

				var thrown = "";
				try {
					r.listAll();
				} catch (Wheels.Packages.RegistryUnavailable e) {
					thrown = e.type;
				}
				expect(thrown).toBe("Wheels.Packages.RegistryUnavailable");
			});
```

- [ ] **Step 1.8: Run full test suite**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: all three `listAll` specs pass. Total package specs should be previous count + 3.

- [ ] **Step 1.9: Commit**

```bash
git add cli/lucli/services/packages/Registry.cfc cli/lucli/tests/specs/packages/RegistryListAllSpec.cfc
git commit -m "feat(cli): add Registry.listAll() returning enriched package summaries"
```

---

## Task 2: Add `$loadRegistryPackages()` to Public.cfc (TDD)

**Files:**
- Modify: `vendor/wheels/Public.cfc`
- Create: `vendor/wheels/tests/specs/packages/LoadRegistryPackagesSpec.cfc`

**Shape of `$loadRegistryPackages()`:**
- Returns: `struct` with keys `packages` (array from `Registry.listAll()`), `error` (string — empty on success)
- Short-circuits to `{packages: [], error: ""}` when `application.wheels.environment == "production"` (defense-in-depth; the handler is already `$blockInProduction()`-gated)
- Memoizes a `Registry` instance in `application.wheels.$packageRegistry` on first call
- Try/catches all exceptions from `listAll()`; captures the error message into `error` and returns empty `packages`
- Accepts an optional `registry` argument for dependency injection in tests

### Steps

- [ ] **Step 2.1: Write failing test — production env short-circuit**

Create `vendor/wheels/tests/specs/packages/LoadRegistryPackagesSpec.cfc`:

```cfml
component extends="wheels.WheelsTest" {

	function run() {
		describe("Public.\$loadRegistryPackages", () => {

			var $newPublic = () => {
				return new wheels.Public();
			};

			// Minimal fake registry that returns canned data or throws.
			var $fakeRegistry = (packages = [], throwType = "", throwMessage = "") => {
				return CreateObject("component", "wheels.tests._assets.packages.FakeRegistry").init(
					packages = packages,
					throwType = throwType,
					throwMessage = throwMessage
				);
			};

			// Swap application.wheels.environment for the duration of a callback.
			var $withEnv = (env, fn) => {
				var prior = application.wheels.environment ?: "development";
				application.wheels.environment = env;
				try { fn(); }
				finally { application.wheels.environment = prior; }
			};

			it("returns empty packages and no error when environment is production", () => {
				$withEnv("production", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(
						registry = $fakeRegistry(packages = [{name: "should-not-appear"}])
					);
					expect(result.packages).toBe([]);
					expect(result.error).toBe("");
				});
			});

		});
	}
}
```

Also create the supporting fake at `vendor/wheels/tests/_assets/packages/FakeRegistry.cfc`:

```cfml
component {

	public FakeRegistry function init(
		array packages = [],
		string throwType = "",
		string throwMessage = ""
	) {
		variables.packages = arguments.packages;
		variables.throwType = arguments.throwType;
		variables.throwMessage = arguments.throwMessage;
		return this;
	}

	public array function listAll() {
		if (Len(variables.throwType)) {
			Throw(type = variables.throwType, message = variables.throwMessage);
		}
		return variables.packages;
	}
}
```

- [ ] **Step 2.2: Run test, verify it fails**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: failure in `LoadRegistryPackagesSpec` with "$loadRegistryPackages is not a function" or similar. The fake fixture class should load without error (if not, path/prefix is wrong — fix before proceeding).

- [ ] **Step 2.3: Implement `$loadRegistryPackages()` on Public.cfc**

Insert in `vendor/wheels/Public.cfc` near the other `$`-prefixed helpers (after `$blockInProduction()`, before `function index()`):

```cfml
	/**
	 * Returns a struct { packages: [...], error: "" } populated from the
	 * wheels-packages registry. Short-circuits in production (defense in
	 * depth — the handler is already $blockInProduction()-gated). Captures
	 * any registry error into the `error` field so the view can render a
	 * friendly banner instead of a stack trace.
	 *
	 * The optional `registry` argument is for tests; normal callers pass
	 * nothing and get a memoized application-scope Registry instance.
	 */
	public struct function $loadRegistryPackages(any registry = "") {
		if ($shouldBlockInProduction()) {
			return {packages: [], error: ""};
		}
		local.reg = IsObject(arguments.registry) ? arguments.registry : $getRegistryClient();
		try {
			return {packages: local.reg.listAll(), error: ""};
		} catch (any e) {
			return {packages: [], error: "Registry lookup failed: " & e.message};
		}
	}

	/**
	 * Lazy, app-scope memo of the CLI's Registry component.
	 */
	private any function $getRegistryClient() {
		if (!StructKeyExists(application.wheels, "$packageRegistry")) {
			application.wheels.$packageRegistry = new cli.lucli.services.packages.Registry();
		}
		return application.wheels.$packageRegistry;
	}
```

- [ ] **Step 2.4: Run test, verify production short-circuit passes**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: the one `it` block in `LoadRegistryPackagesSpec` passes.

- [ ] **Step 2.5: Add test — happy path in development**

Append inside the `describe` block in `LoadRegistryPackagesSpec.cfc`:

```cfml
			it("returns packages from the registry in development", () => {
				$withEnv("development", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(
						registry = $fakeRegistry(packages = [
							{name: "wheels-sentry",  description: "x", tags: [], homepage: "", latestVersion: "1.0.0"}
						])
					);
					expect(ArrayLen(result.packages)).toBe(1);
					expect(result.packages[1].name).toBe("wheels-sentry");
					expect(result.error).toBe("");
				});
			});
```

- [ ] **Step 2.6: Run test, verify happy path passes**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: both `it` blocks pass.

- [ ] **Step 2.7: Add test — registry error captured, not thrown**

Append inside the same `describe` block:

```cfml
			it("captures registry errors into the error field without throwing", () => {
				$withEnv("development", () => {
					var pub = $newPublic();
					var result = pub.$loadRegistryPackages(
						registry = $fakeRegistry(
							throwType = "Wheels.Packages.RegistryUnavailable",
							throwMessage = "GitHub returned 503"
						)
					);
					expect(result.packages).toBe([]);
					expect(result.error contains "GitHub returned 503").toBeTrue();
				});
			});
```

- [ ] **Step 2.8: Run test, verify error path passes**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: all three `LoadRegistryPackagesSpec` blocks pass.

- [ ] **Step 2.9: Commit**

```bash
git add vendor/wheels/Public.cfc \
        vendor/wheels/tests/specs/packages/LoadRegistryPackagesSpec.cfc \
        vendor/wheels/tests/_assets/packages/FakeRegistry.cfc
git commit -m "feat(view): add \$loadRegistryPackages helper for in-app browse UI"
```

---

## Task 3: Extend `packagelist.cfm` with "Browse registry" section

**Files:**
- Modify: `vendor/wheels/public/views/packagelist.cfm`

No unit test for the view — the logic is extracted into `$loadRegistryPackages()` (Task 2). This task is pure presentation; verified manually in Task 4.

### Steps

- [ ] **Step 3.1: Extend the cfscript block at the top of `packagelist.cfm`**

After line 39 (closing `</cfscript>` block of the JSON response) — actually line 40 is `</cfscript>`, so open a new block just before the `<cfinclude>` at line 41. Replace lines 40–41 with:

```cfml
// Load registry packages for the "Browse registry" section.
// Short-circuits in production via $loadRegistryPackages.
registryResult = application.$wheels.public.$loadRegistryPackages();
registryPackages = registryResult.packages;
registryError = registryResult.error;

// Build a set of installed package keys (lowercased) for quick
// lookup when rendering the "✓ Installed" badge on registry rows.
installedKeys = {};
for (local.key in packageMeta) {
	installedKeys[LCase(local.key)] = true;
}
</cfscript>
<cfinclude template="../layout/_header.cfm">
```

(Open the existing `<cfscript>` that ends on line 39 — the JSON-response block — and append these lines before the closing tag, so they run regardless of `format`. Or wrap them in their own new `<cfscript>` block directly below line 39. Either is fine; preserve the abort-on-JSON-format behavior above.)

- [ ] **Step 3.2: Append the "Browse registry" section to the `packagelist.cfm` body**

After the existing closing `</div>` of the installed-packages container (before line 103's closing `</cfoutput>`), insert:

```cfml
	<div class="ui container" style="margin-top: 3em;">
		<h2 class="ui header">
			Browse registry
			<div class="sub header">
				Packages available at
				<a href="https://wheels.dev/packages" target="_blank" rel="noopener">wheels.dev/packages</a>.
				Install with the CLI.
			</div>
		</h2>

		<cfif Len(registryError)>
			<div class="ui warning message">
				<div class="header">Registry unavailable</div>
				<p>#HTMLEditFormat(registryError)#</p>
			</div>
		<cfelseif ArrayLen(registryPackages) EQ 0>
			<div class="ui message">
				<p>No packages found in the registry.</p>
			</div>
		<cfelse>
			<table class="ui celled striped table">
				<thead>
					<tr>
						<th>Name</th>
						<th>Description</th>
						<th>Latest</th>
						<th>Install</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#registryPackages#" index="local.rp">
						<cfset local.rpKey = LCase(local.rp.name)>
						<cfset local.isInstalled = StructKeyExists(installedKeys, local.rpKey)>
						<tr>
							<td>
								<strong>#HTMLEditFormat(local.rp.name)#</strong>
								<cfif Len(local.rp.homepage)>
									<br><a href="#HTMLEditFormat(local.rp.homepage)#" target="_blank" rel="noopener" class="ui small grey text">homepage</a>
								</cfif>
							</td>
							<td>#HTMLEditFormat(local.rp.description)#</td>
							<td>#HTMLEditFormat(local.rp.latestVersion)#</td>
							<td>
								<cfif local.isInstalled>
									<span class="ui label"><i class="check icon"></i> Installed</span>
								<cfelse>
									<code id="install-#HTMLEditFormat(local.rpKey)#">wheels packages install #HTMLEditFormat(local.rp.name)#</code>
									<button type="button"
										class="ui tiny button"
										onclick="navigator.clipboard.writeText(document.getElementById('install-#HTMLEditFormat(local.rpKey)#').innerText)">
										Copy
									</button>
								</cfif>
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfif>
	</div>
```

**Critical formatting notes:**
- `##` in CSS selectors / id references — CFML requires `##` to emit literal `#`. The view uses `#HTMLEditFormat(local.rpKey)#` interpolation inside the id so `##` is not needed here, but double-check Lucee 7 + Adobe 2023 both render the element ids correctly before merging.
- `rel="noopener"` on all external links.
- No inline event handlers besides the simple `onclick` for clipboard — consistent with the rest of this view.

- [ ] **Step 3.3: Verify CFML syntax by running the existing view spec**

Run:
```bash
bash tools/test-local.sh packages
```

Expected: all previously-passing specs still pass. The view isn't directly spec'd, but any syntax error in `packagelist.cfm` crashes the CFML compiler when the Public component is instantiated at app start — which will cause unrelated specs to fail. If you see spec failures that reference `packagelist.cfm` or `Public.cfc`, fix the syntax before proceeding.

- [ ] **Step 3.4: Commit**

```bash
git add vendor/wheels/public/views/packagelist.cfm
git commit -m "feat(view): add browse-registry section to /wheels/packages"
```

---

## Task 4: Manual verification against the live registry

Not a code step; an end-to-end smoke test before the PR is opened.

### Steps

- [ ] **Step 4.1: Start a local Wheels dev server**

```bash
lucli server run --port=8080
```

Wait for "Server started on port 8080".

- [ ] **Step 4.2: Force a reload so Public.cfc picks up the new methods**

```bash
curl -s "http://localhost:8080/?reload=true&password=wheels" > /dev/null
```

- [ ] **Step 4.3: Load the packages page in a browser (or curl)**

Browser: `http://localhost:8080/wheels/packages`
Or:
```bash
curl -s "http://localhost:8080/wheels/packages" | head -200
```

Expected:
- Page renders without a 500 error
- Original "Installed packages" table still appears (likely empty in a fresh dev app)
- New "Browse registry" section appears below
- Section lists the 4 live registry packages: `wheels-basecoat`, `wheels-hotwire`, `wheels-legacy-adapter`, `wheels-sentry`
- Each has a `wheels packages install <name>` snippet and a Copy button
- No row shows an "Installed" badge (fresh app has no vendor packages beyond `wheels/` itself, which the registry doesn't include)

If the registry is unavailable (offline, rate-limited), expect the yellow "Registry unavailable" banner with the error message — not a 500.

- [ ] **Step 4.4: Install one package with the CLI, reload, verify the "Installed" badge**

```bash
wheels packages install wheels-sentry
curl -s "http://localhost:8080/?reload=true&password=wheels" > /dev/null
```

Reload the browser on `/wheels/packages`.

Expected: the `wheels-sentry` row in the Browse registry table now shows `✓ Installed` instead of the install snippet; the installed-packages table above it has a new `wheels-sentry` entry.

- [ ] **Step 4.5: Remove the package to leave the worktree clean**

```bash
wheels packages remove wheels-sentry --yes
curl -s "http://localhost:8080/?reload=true&password=wheels" > /dev/null
```

- [ ] **Step 4.6: Verify production gating**

Temporarily flip the env. In `config/environment.cfm`, change the environment to `"production"` for a single reload:

```cfml
// Temporary: for manual verification only. Revert after.
set(environment = "production");
```

```bash
curl -s "http://localhost:8080/?reload=true&password=wheels" > /dev/null
curl -si "http://localhost:8080/wheels/packages" | head -20
```

Expected: HTTP 404 response (`$blockInProduction()` on the handler fires before the view runs). If it returns a 200 and renders the page, stop and investigate — the gate is broken.

Revert `config/environment.cfm` and reload once more.

```bash
git checkout config/environment.cfm
curl -s "http://localhost:8080/?reload=true&password=wheels" > /dev/null
```

---

## Task 5: Update CHANGELOG and open PR

### Steps

- [ ] **Step 5.1: Add CHANGELOG entry**

Open `CHANGELOG.md` and add a line under the "Unreleased" (or current working) section. Match the style of existing entries:

```markdown
- feat(view): `/wheels/packages` now shows a "Browse registry" section listing packages available from `wheels-dev/wheels-packages`, with copy-to-clipboard install commands. Dev/testing only — production is 404-gated. (#2271, partial — wheels.dev side deferred)
```

- [ ] **Step 5.2: Commit CHANGELOG**

```bash
git add CHANGELOG.md
git commit -m "docs(docs): note in-app browse-registry section for #2271"
```

- [ ] **Step 5.3: Push branch and open PR against `develop`**

```bash
git push -u origin claude/fervent-brahmagupta-c9a826
gh pr create --base develop --title "feat(view): add browse-registry section to /wheels/packages (#2271 partial)" --body "$(cat <<'EOF'
## Summary
- Adds a "Browse registry" section to `/wheels/packages` that lists installable packages from `wheels-dev/wheels-packages`
- Reuses the CLI's `Registry` component — same data source as `wheels packages list`
- Dev/testing only; `Public.cfc`'s `\$blockInProduction()` gate plus a view-level env check keep this off production servers
- No install-via-browser action; each row shows a copy-to-clipboard `wheels packages install <name>` snippet
- Rows matching an installed package show a `✓ Installed` badge instead

## Scope
This is the in-app half of #2271. The `wheels.dev/packages` Astro static-site work is deferred — see the Revision note in `docs/superpowers/specs/2026-04-23-wheels-packages-phase4-ui-design.md`. #2271 stays open.

## Test plan
- [ ] Package specs pass locally: `bash tools/test-local.sh packages`
- [ ] Full core test suite passes: `bash tools/test-local.sh`
- [ ] Manual: `/wheels/packages` renders registry list in dev
- [ ] Manual: `/wheels/packages` returns 404 in production
- [ ] Manual: installing a package via CLI then reloading shows the `✓ Installed` badge
EOF
)"
```

- [ ] **Step 5.4: Wait for CI green (code tier)**

Per `CLAUDE.local.md`: this is a code-tier PR (touches `vendor/`, `cli/`). Wait for the **full** check suite to pass — not just required checks. Treat `pending`/`queued`/`in_progress` as "not done." Treat `fail`/`cancelled` as a stop.

Poll with:
```bash
gh pr checks
```

When all checks are `pass`, merge with:
```bash
gh pr merge --squash --delete-branch
```

Report the merge commit SHA and confirm branch deletion.

---

## Self-review notes (executed during plan writing)

- **Spec coverage check:** Every Component-1 requirement in the spec is covered by Tasks 1–3. Component 2/3 are out of scope per the Revision note — spec updated to reflect that.
- **Placeholder scan:** No TBDs, no "handle errors appropriately," every code block is complete.
- **Type consistency:** `listAll()` returns `{name, description, tags, latestVersion, homepage}`; `$loadRegistryPackages()` consumes that shape; the view reads those exact keys.
- **Deviation from spec:** Spec proposed a new `vendor/wheels/global/packages.cfm` file for the helper. Plan puts the helper on `Public.cfc` instead — simpler, matches the pattern of the other `$`-prefixed helpers in that file, no new file needed. Spec diagram/architecture otherwise matches the plan.
- **Deviation from spec:** Spec originally proposed an `isStale()` flag on the registry client. Plan drops it — the in-app page can show either a success or a warning banner; there's no meaningful third "stale cache" state to surface in the UI. Less code, same UX.

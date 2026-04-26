component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Doctor Service", () => {

			it("reports HEALTHY for a valid project", () => {
				var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("HEALTHY");
				expect(arrayLen(results.issues)).toBe(0);
			});

			it("reports CRITICAL when a required directory is missing", () => {
				// Remove app/controllers
				if (directoryExists(tempRoot & "/app/controllers")) {
					directoryDelete(tempRoot & "/app/controllers", true);
				}

				var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("CRITICAL");
				expect(arrayLen(results.issues)).toBeGT(0);

				var issueText = arrayToList(results.issues, " ");
				expect(issueText).toInclude("app/controllers");

				// Restore for subsequent tests
				directoryCreate(tempRoot & "/app/controllers", true);
			});

			it("reports WARNING when a recommended directory is missing", () => {
				// Remove tests/specs if it exists
				var specsDir = tempRoot & "/tests/specs";
				var existed = directoryExists(specsDir);
				if (existed) {
					directoryDelete(specsDir, true);
				}

				var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				// Should not be CRITICAL (no required dirs missing)
				expect(results.status).notToBe("CRITICAL");
				expect(arrayLen(results.warnings)).toBeGT(0);

				// Restore
				if (existed) {
					directoryCreate(specsDir, true);
				}
			});

			it("reports CRITICAL when a required file is missing", () => {
				var routesPath = tempRoot & "/config/routes.cfm";
				var routesContent = "";
				if (fileExists(routesPath)) {
					routesContent = fileRead(routesPath);
					fileDelete(routesPath);
				}

				var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("CRITICAL");

				// Restore
				if (len(routesContent)) {
					fileWrite(routesPath, routesContent);
				}
			});

			it("warns when config routes.cfm has minimal content", () => {
				var routesPath = tempRoot & "/config/routes.cfm";
				var original = fileRead(routesPath);
				fileWrite(routesPath, "// "); // less than 10 chars of content

				var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				var warningText = arrayToList(results.warnings, " ");
				expect(warningText).toInclude("routes.cfm");

				fileWrite(routesPath, original);
			});

			it("generates recommendations based on issues", () => {
				// Remove tests to trigger recommendation
				var specsDir = tempRoot & "/tests/specs";
				var existed = directoryExists(specsDir);
				if (existed) {
					directoryDelete(specsDir, true);
				}

				var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(arrayLen(results.recommendations)).toBeGT(0);

				if (existed) {
					directoryCreate(specsDir, true);
				}
			});

			it("passes write permission check on writable directory", () => {
				var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				var passedText = arrayToList(results.passed, " ");
				expect(passedText).toInclude("Write permission");
			});

			describe("CLI install freshness (##2223)", () => {

				it("is silent when no installedModuleRoot is provided", () => {
					var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
					var results = doctor.runChecks();
					var combined = arrayToList(results.warnings, " ") & " " & arrayToList(results.passed, " ");
					expect(combined).notToInclude("Installed CLI module");
				});

				it("is silent when projectRoot is not a wheels source checkout", () => {
					// tempRoot has no cli/lucli/Module.cfc — should not trigger the check
					var fakeInstalled = getTempDirectory() & "wheels-install-" & createUUID();
					directoryCreate(fakeInstalled, true);
					fileWrite(fakeInstalled & "/Module.cfc", "component { }");

					var doctor = new modules.wheels.services.Doctor(
						projectRoot = tempRoot,
						installedModuleRoot = fakeInstalled
					);
					var results = doctor.runChecks();
					var combined = arrayToList(results.warnings, " ") & " " & arrayToList(results.passed, " ");
					expect(combined).notToInclude("Installed CLI module");

					directoryDelete(fakeInstalled, true);
				});

				it("warns when installed Module.cfc diverges from checkout", () => {
					var checkout = makeFakeCheckout("component { /* checkout version */ }");
					var installed = getTempDirectory() & "wheels-install-" & createUUID();
					directoryCreate(installed, true);
					fileWrite(installed & "/Module.cfc", "component { /* stale installed version */ }");

					var doctor = new modules.wheels.services.Doctor(
						projectRoot = checkout,
						installedModuleRoot = installed
					);
					var results = doctor.runChecks();

					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).toInclude("Installed CLI module");
					expect(warningText).toInclude("diverges");

					var recText = arrayToList(results.recommendations, " ");
					expect(recText).toInclude("ln -s");

					directoryDelete(checkout, true);
					directoryDelete(installed, true);
				});

				it("passes when installed Module.cfc matches checkout bytes", () => {
					var src = "component { /* identical bytes */ }";
					var checkout = makeFakeCheckout(src);
					var installed = getTempDirectory() & "wheels-install-" & createUUID();
					directoryCreate(installed, true);
					fileWrite(installed & "/Module.cfc", src);

					var doctor = new modules.wheels.services.Doctor(
						projectRoot = checkout,
						installedModuleRoot = installed
					);
					var results = doctor.runChecks();

					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).notToInclude("Installed CLI module");

					var passedText = arrayToList(results.passed, " ");
					expect(passedText).toInclude("matches source checkout");

					directoryDelete(checkout, true);
					directoryDelete(installed, true);
				});

				it("skips when installedModuleRoot is the checkout's own cli/lucli/", () => {
					var checkout = makeFakeCheckout("component { }");
					var selfInstalled = checkout & "/cli/lucli";

					var doctor = new modules.wheels.services.Doctor(
						projectRoot = checkout,
						installedModuleRoot = selfInstalled
					);
					var results = doctor.runChecks();

					var combined = arrayToList(results.warnings, " ") & " " & arrayToList(results.passed, " ");
					expect(combined).notToInclude("Installed CLI module");

					directoryDelete(checkout, true);
				});

				it("passes when installed module is a symlink", () => {
					var checkout = makeFakeCheckout("component { /* target */ }");
					var installedParent = getTempDirectory() & "wheels-install-" & createUUID();
					directoryCreate(installedParent, true);
					var installed = installedParent & "/wheels";

					var linkCreated = tryCreateSymlink(installed, checkout & "/cli/lucli");
					if (!linkCreated) {
						// Symlink unsupported on this FS — skip the assertion
						directoryDelete(checkout, true);
						directoryDelete(installedParent, true);
						return;
					}

					var doctor = new modules.wheels.services.Doctor(
						projectRoot = checkout,
						installedModuleRoot = installed
					);
					var results = doctor.runChecks();

					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).notToInclude("Installed CLI module");

					var passedText = arrayToList(results.passed, " ");
					expect(passedText).toInclude("symlink");

					// Delete symlink first, then dirs
					try { fileDelete(installed); } catch (any e) {}
					directoryDelete(installedParent, true);
					directoryDelete(checkout, true);
				});

			});

			describe("framework source bundling", () => {

				it("is silent when no installedModuleRoot is provided (dev checkout)", () => {
					var doctor = new modules.wheels.services.Doctor(projectRoot = tempRoot);
					var results = doctor.runChecks();
					var combined = arrayToList(results.issues, " ") & " " & arrayToList(results.passed, " ");
					expect(combined).notToInclude("framework source");
				});

				it("passes when vendor/wheels/ exists at projectRoot", () => {
					var checkout = makeFakeCheckout("component { }");
					var installed = getTempDirectory() & "wheels-install-" & createUUID();
					directoryCreate(installed, true);
					fileWrite(installed & "/Module.cfc", "component { }");

					var doctor = new modules.wheels.services.Doctor(
						projectRoot = checkout,
						installedModuleRoot = installed
					);
					var results = doctor.runChecks();

					var passedText = arrayToList(results.passed, " ");
					expect(passedText).toInclude("Wheels framework source available");

					var issueText = arrayToList(results.issues, " ");
					expect(issueText).notToInclude("framework source (vendor/wheels/) not found");

					directoryDelete(checkout, true);
					directoryDelete(installed, true);
				});

				it("flags CRITICAL when framework source is missing everywhere", () => {
					var fakeInstalled = getTempDirectory() & "wheels-install-" & createUUID();
					directoryCreate(fakeInstalled, true);
					fileWrite(fakeInstalled & "/Module.cfc", "component { }");

					var doctor = new modules.wheels.services.Doctor(
						projectRoot = tempRoot,
						installedModuleRoot = fakeInstalled
					);
					var results = doctor.runChecks();

					var issueText = arrayToList(results.issues, " ");
					expect(issueText).toInclude("framework source (vendor/wheels/) not found");
					expect(results.status).toBe("CRITICAL");

					var recText = arrayToList(results.recommendations, " ");
					expect(recText).toInclude("WHEELS_FRAMEWORK_PATH");
					expect(recText).notToInclude("Run 'wheels new' to scaffold");

					directoryDelete(fakeInstalled, true);
				});

			});

			describe("checkMixinCollisions", () => {

				it("reports passed when no packages/plugins exist", () => {
					var root = makeProjectRoot();
					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();
					expect(arrayLen(results.mixinCollisions)).toBe(0);
					var combined = arrayToList(results.warnings, " ");
					expect(combined).notToInclude("mixin collision");
					directoryDelete(root, true);
				});

				it("reports passed when two packages provide non-overlapping methods", () => {
					var root = makeProjectRoot();
					makePackage(root, "pkgA", "controller", "$helperA", []);
					makePackage(root, "pkgB", "controller", "$helperB", []);

					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();

					expect(arrayLen(results.mixinCollisions)).toBe(0);
					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).notToInclude("mixin collision");
					var passedText = arrayToList(results.passed, " ");
					expect(passedText).toInclude("No static mixin collisions");
					directoryDelete(root, true);
				});

				it("emits summary in warnings and detail in mixinCollisions when packages collide", () => {
					var root = makeProjectRoot();
					makePackage(root, "pkgA", "controller", "$shared", []);
					makePackage(root, "pkgB", "controller", "$shared", []);

					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();

					// Default output: count summary only, no inline detail
					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).toInclude("mixin collision(s) detected");
					expect(warningText).toInclude("--verbose");
					expect(warningText).notToInclude("$shared");

					// Verbose-dump data on the results struct
					expect(arrayLen(results.mixinCollisions)).toBe(1);
					var c = results.mixinCollisions[1];
					expect(c.method).toBe("$shared");
					expect(c.target).toBe("controller");
					// directoryList() iteration order isn't guaranteed across filesystems,
					// so assert both packages are present without fixing which came first.
					var participants = [c.firstName, c.secondName];
					arraySort(participants, "textnocase");
					expect(participants[1]).toBe("pkgA");
					expect(participants[2]).toBe("pkgB");
					expect(c.firstSource).toBe("package");
					expect(c.secondSource).toBe("package");
					directoryDelete(root, true);
				});

				it("suppresses warning and detail when overriding package declares provides.overrides", () => {
					var root = makeProjectRoot();
					makePackage(root, "pkgA", "controller", "$shared", []);
					makePackage(root, "pkgB", "controller", "$shared", ["$shared"]);

					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();

					expect(arrayLen(results.mixinCollisions)).toBe(0);
					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).notToInclude("mixin collision");
					directoryDelete(root, true);
				});

				// ── Regression: issue ##2260 blind spots ────────────

				it("honors per-method mixin attribute over manifest target (issue ##2260)", () => {
					// Both packages declare provides.mixins = "controller" but the
					// method itself declares `mixin="model"`. The static scan must
					// report the collision on `model`, not `controller`.
					var root = makeProjectRoot();
					makePackageWithSource(
						root = root,
						name = "pkgA",
						manifestTarget = "controller",
						cfcBody = 'public string function $shared() mixin="model" { return "a"; }'
					);
					makePackageWithSource(
						root = root,
						name = "pkgB",
						manifestTarget = "controller",
						cfcBody = 'public string function $shared() mixin="model" { return "b"; }'
					);

					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();

					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).toInclude("Mixin collision");
					expect(warningText).toInclude("$shared");
					expect(warningText).toInclude("'model'");
					expect(warningText).notToInclude("'controller'");
					directoryDelete(root, true);
				});

				it("treats per-method mixin=none as an opt-out (issue ##2260)", () => {
					// Manifest says "controller" but the method opts out; the
					// scanner must not report a controller-level collision.
					var root = makeProjectRoot();
					makePackageWithSource(
						root = root,
						name = "pkgA",
						manifestTarget = "controller",
						cfcBody = 'public string function $shared() mixin="none" { return "a"; }'
					);
					makePackageWithSource(
						root = root,
						name = "pkgB",
						manifestTarget = "controller",
						cfcBody = 'public string function $shared() { return "b"; }'
					);

					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();

					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).notToInclude("Mixin collision");
					directoryDelete(root, true);
				});

				it("follows in-package extends chain for inherited methods (issue ##2260)", () => {
					// Each package's main CFC extends a same-package Base CFC
					// that defines the shared method. Old scanner would miss it.
					var root = makeProjectRoot();
					makePackageWithExtendsChain(root, "pkgA", "controller", "$inherited");
					makePackageWithExtendsChain(root, "pkgB", "controller", "$inherited");

					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();

					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).toInclude("Mixin collision");
					expect(warningText).toInclude("$inherited");
					directoryDelete(root, true);
				});

				it("ignores function-like text inside block comments (issue ##2260)", () => {
					// pkgA's real method is $real; its docblock MENTIONS $ghost.
					// pkgB only declares $real. If the scanner picked up $ghost
					// it would still collide on $real (so false positives for
					// $ghost wouldn't change the count here) — but the warning
					// text must not mention $ghost.
					var root = makeProjectRoot();
					makePackageWithSource(
						root = root,
						name = "pkgA",
						manifestTarget = "controller",
						cfcBody = '/** @deprecated use function $ghost() instead */
							public string function $real() { return "a"; }'
					);
					makePackageWithSource(
						root = root,
						name = "pkgB",
						manifestTarget = "controller",
						cfcBody = 'public string function $real() { return "b"; }'
					);

					var doctor = new modules.wheels.services.Doctor(projectRoot = root);
					var results = doctor.runChecks();

					var warningText = arrayToList(results.warnings, " ");
					expect(warningText).toInclude("Mixin collision");
					expect(warningText).toInclude("$real");
					expect(warningText).notToInclude("$ghost");
					directoryDelete(root, true);
				});

			});

		});

	}

	// ── Mixin collision spec helpers ─────────────────────────

	private string function makeProjectRoot() {
		var root = getTempDirectory() & "wheels-collision-" & createUUID();
		directoryCreate(root & "/vendor", true);
		directoryCreate(root & "/config", true);
		directoryCreate(root & "/app", true);
		directoryCreate(root & "/app/controllers", true);
		directoryCreate(root & "/app/models", true);
		directoryCreate(root & "/app/views", true);
		directoryCreate(root & "/public", true);
		fileWrite(root & "/config/routes.cfm", "mapper().wildcard().end();");
		fileWrite(root & "/config/settings.cfm", "set(dataSourceName='test');");
		return root;
	}

	private void function makePackage(
		required string root,
		required string name,
		required string target,
		required string methodName,
		required array overrides
	) {
		var pkgDir = arguments.root & "/vendor/" & arguments.name;
		directoryCreate(pkgDir, true);
		var manifest = {
			"name": "wheels-" & arguments.name,
			"version": "1.0.0",
			"provides": {"mixins": arguments.target}
		};
		if (arrayLen(arguments.overrides)) {
			manifest.provides.overrides = arguments.overrides;
		}
		fileWrite(pkgDir & "/package.json", serializeJSON(manifest));
		fileWrite(
			pkgDir & "/" & arguments.name & ".cfc",
			'component { public any function init() { return this; } public string function ' & arguments.methodName & '() { return "x"; } }'
		);
	}

	/**
	 * Creates a package with a hand-written CFC body so specs can exercise
	 * the full function-signature parser (per-method `mixin` attributes,
	 * docblocks, etc.) — unlike makePackage() which hard-codes the body.
	 */
	private void function makePackageWithSource(
		required string root,
		required string name,
		required string manifestTarget,
		required string cfcBody
	) {
		var pkgDir = arguments.root & "/vendor/" & arguments.name;
		directoryCreate(pkgDir, true);
		var manifest = {
			"name": "wheels-" & arguments.name,
			"version": "1.0.0",
			"provides": {"mixins": arguments.manifestTarget}
		};
		fileWrite(pkgDir & "/package.json", serializeJSON(manifest));
		fileWrite(
			pkgDir & "/" & arguments.name & ".cfc",
			'component {
				public any function init() { return this; }
				' & arguments.cfcBody & '
			}'
		);
	}

	/**
	 * Creates a two-CFC package: the main CFC extends a Base CFC in the
	 * same directory. The shared method lives on Base, so the static
	 * scanner must follow extends to see it.
	 */
	private void function makePackageWithExtendsChain(
		required string root,
		required string name,
		required string manifestTarget,
		required string methodName
	) {
		var pkgDir = arguments.root & "/vendor/" & arguments.name;
		directoryCreate(pkgDir, true);
		var manifest = {
			"name": "wheels-" & arguments.name,
			"version": "1.0.0",
			"provides": {"mixins": arguments.manifestTarget}
		};
		fileWrite(pkgDir & "/package.json", serializeJSON(manifest));
		fileWrite(
			pkgDir & "/Base.cfc",
			'component {
				public any function init() { return this; }
				public string function ' & arguments.methodName & '() { return "inherited"; }
			}'
		);
		fileWrite(
			pkgDir & "/" & arguments.name & ".cfc",
			'component extends="Base" {
				public any function init() { super.init(); return this; }
			}'
		);
	}

	// ── Spec helpers ─────────────────────────────────────────

	private string function makeFakeCheckout(required string moduleContent) {
		var root = getTempDirectory() & "wheels-checkout-" & createUUID();
		directoryCreate(root & "/cli/lucli", true);
		directoryCreate(root & "/vendor/wheels", true);
		fileWrite(root & "/cli/lucli/Module.cfc", arguments.moduleContent);
		return root;
	}

	private boolean function tryCreateSymlink(required string link, required string target) {
		try {
			var Paths = createObject("java", "java.nio.file.Paths");
			var Files = createObject("java", "java.nio.file.Files");
			var linkPath = Paths.get(javacast("string", arguments.link), javacast("string[]", []));
			var targetPath = Paths.get(javacast("string", arguments.target), javacast("string[]", []));
			Files.createSymbolicLink(linkPath, targetPath, javacast("java.nio.file.attribute.FileAttribute[]", []));
			return true;
		} catch (any e) {
			return false;
		}
	}

}

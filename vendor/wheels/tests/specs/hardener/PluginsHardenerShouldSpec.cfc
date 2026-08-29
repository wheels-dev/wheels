/**
 * Hardener SHOULDs S1–S15 (plugins / package loader).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 *
 * Public defaults stay true (CoS lock): overwritePlugins,
 * loadIncompatiblePlugins, deletePluginDirectories.
 *
 * Escalations (no silent public default/API flips):
 *   S3 omitted wheelsVersion on packages stays fail-open (existing compat).
 *   S3 runtime 0.0.0 / @build.version@ skip stays (local unstamped checkouts).
 *   S9 plugin mixin last-wins stays (pluginsModernSpec documents it).
 *   S15 default mixin target stays "global" (detect+warn only).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("CoS lock: plugin public defaults stay true", () => {

			it("keeps overwritePlugins true", () => {
				expect(application.wheels.overwritePlugins).toBeTrue();
			});

			it("keeps loadIncompatiblePlugins true", () => {
				expect(application.wheels.loadIncompatiblePlugins).toBeTrue();
			});

			it("keeps deletePluginDirectories true", () => {
				expect(application.wheels.deletePluginDirectories).toBeTrue();
			});

		});

		describe("S1 PackageLoader mixin collisions warn and last-wins", () => {

			it("last package wins the mixin and provides.overrides only acknowledges", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_collision"),
					componentPrefix = "wheels.tests._assets.packages_collision"
				);
				var collisions = loader.getMixinCollisions();
				expect(ArrayLen(collisions)).toBeGTE(1);

				var lastShared = "";
				var acknowledgedOverride = false;
				for (var c in collisions) {
					if (c.method == "$sharedHelper" && c.target == "controller") {
						lastShared = c.secondProvider;
						if (c.secondProvider == "mixincolOverride") {
							expect(c.acknowledged).toBeTrue();
							acknowledgedOverride = true;
						}
					}
				}
				expect(Len(lastShared)).toBeGT(0);
				expect(acknowledgedOverride).toBeTrue();

				var mixins = loader.getMixins();
				expect(mixins.controller).toHaveKey("$sharedHelper");
				var fn = mixins.controller["$sharedHelper"];
				expect(fn()).toBe("from-" & lastShared);
			});

			it("records an unacknowledged collision when overrides is absent", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_collision"),
					componentPrefix = "wheels.tests._assets.packages_collision"
				);
				var foundUnacked = false;
				for (var c in loader.getMixinCollisions()) {
					if (c.method == "$sharedHelper" && !c.acknowledged) {
						foundUnacked = true;
					}
				}
				expect(foundUnacked).toBeTrue();
			});

		});

		describe("S2 lazy getPackage instantiates once under a lock", () => {

			it("wraps $instantiateLazyPackage in a named lock", () => {
				var src = FileRead(ExpandPath("/wheels/PackageLoader.cfc"));
				var start = FindNoCase("function $instantiateLazyPackage", src);
				expect(start).toBeGT(0);
				var body = Mid(src, start, 2500);
				expect(FindNoCase("lock ", body) GT 0 || FindNoCase("cflock", body) GT 0).toBeTrue(
					"$instantiateLazyPackage must take a named lock so two getPackage calls cannot double register/boot"
				);
			});

			it("getPackage twice on a lazy ServiceProvider does not double-register", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_lazy_sp_solo"),
					componentPrefix = "wheels.tests._assets.packages_lazy_sp_solo"
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();
				loader.$invokeServiceProviderRegister(fakeContainer);
				loader.$invokeServiceProviderBoot({});

				var first = loader.getPackage("solounhinted");
				var second = loader.getPackage("solounhinted");
				expect(first.registerCalled).toBeTrue();
				expect(second.registerCalled).toBeTrue();
				expect(first.bootCalled).toBeTrue();
			});

		});

		describe("S3 wheelsVersion * and 0.0.0 fail closed", () => {

			it("does not load a package whose wheelsVersion is *", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_hardener_starzero"),
					componentPrefix = "wheels.tests._assets.packages_hardener_starzero",
					wheelsVersion = "4.0.0"
				);
				expect(loader.getPackages()).notToHaveKey("starversion");
				expect(loader.getPackageMeta()).notToHaveKey("starversion");
			});

			it("does not load a package whose wheelsVersion is 0.0.0", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_hardener_starzero"),
					componentPrefix = "wheels.tests._assets.packages_hardener_starzero",
					wheelsVersion = "4.0.0"
				);
				expect(loader.getPackages()).notToHaveKey("zeroversion");
				expect(loader.getPackageMeta()).notToHaveKey("zeroversion");
			});

			it("plugin * compat fails closed even when loadIncompatible is true", () => {
				var pm = CreateObject("component", "wheels.Plugins");
				expect(pm.$shouldLoadPlugin("*", "4.0.0", true)).toBeFalse();
				expect(pm.$shouldLoadPlugin("0.0.0", "4.0.0", true)).toBeFalse();
				expect(pm.$shouldLoadPlugin("1.0", "4.0.0", true)).toBeTrue();
			});

			it("does not load a plugin whose this.version is * when loadIncompatiblePlugins is true", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_starcompat";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_starcompat",
					deletePluginDirectories = false,
					overwritePlugins = true,
					loadIncompatiblePlugins = true,
					wheelsVersion = "4.0.0"
				};
				try {
					var pluginObj = $pluginObj(config);
					expect(pluginObj.getPlugins()).notToHaveKey("StarCompatPlugin");
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

			it("does not load a plugin whose this.version is 0.0.0 when loadIncompatiblePlugins is true", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_zerocompat";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_zerocompat",
					deletePluginDirectories = false,
					overwritePlugins = true,
					loadIncompatiblePlugins = true,
					wheelsVersion = "4.0.0"
				};
				try {
					var pluginObj = $pluginObj(config);
					expect(pluginObj.getPlugins()).notToHaveKey("ZeroCompatPlugin");
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

		});

		describe("S4 plural mapping realpath stays inside the package", () => {

			beforeEach(() => {
				symlinkRoot = ExpandPath("/wheels/tests/_assets/packages_hardener_symlink_runtime");
				$resetDir(symlinkRoot);
			});

			afterEach(() => {
				$resetDir(symlinkRoot);
			});

			it("rejects a mappings path that is a symlink out of the package tree", () => {

				// RustCFML is JVM-free: the zip/symlink fixtures are built with
				// java.util.zip / java.nio.file, which the engine cannot run.
				// The pure-CFML classifier contract is covered elsewhere in this file.
				if (g.$engineAdapter().isRustCFML()) {
					return;
				}
				var pkgDir = symlinkRoot & "/symlinkescape";
				DirectoryCreate(pkgDir);
				var outside = symlinkRoot & "/outside-target";
				DirectoryCreate(outside);
				FileWrite(outside & "/pwned.txt", "escaped");
				$createSymlink(outside, pkgDir & "/link");
				$writePackageFiles(
					pkgDir,
					"symlinkescape",
					{"name" = "wheels-symlinkescape", "version" = "1.0.0", "mappings" = {"escape.out" = "link"}}
				);

				var loader = new wheels.PackageLoader(
					vendorPath = symlinkRoot,
					componentPrefix = "wheels.tests._assets.packages_hardener_symlink_runtime"
				);
				expect(loader.getPackageMappings()).notToHaveKey("escape.out");
				var found = false;
				for (var failed in loader.getFailedPackages()) {
					if (failed.name == "symlinkescape") {
						found = true;
					}
				}
				expect(found).toBeTrue();
			});

		});

		describe("S5 middleware component must be package-local", () => {

			it("does not register a middleware component outside the package", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_hardener_rawmw"),
					componentPrefix = "wheels.tests._assets.packages_hardener_rawmw"
				);
				expect(ArrayLen(loader.getPackageMiddleware())).toBe(0);
				expect(loader.getPackages()).notToHaveKey("rawmw");
				var found = false;
				for (var failed in loader.getFailedPackages()) {
					if (failed.name == "rawmw") {
						found = true;
					}
				}
				expect(found).toBeTrue();
			});

			it("accepts a bare identifier and rejects a foreign dotted path", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_lazy_sp_solo"),
					componentPrefix = "wheels.tests._assets.packages_lazy_sp_solo"
				);
				expect(loader.$isLocalMiddlewareComponent("solounhinted", "LocalMw")).toBeTrue();
				expect(loader.$isLocalMiddlewareComponent("solounhinted", "wheels.Dispatch")).toBeFalse();
				expect(loader.$isLocalMiddlewareComponent("solounhinted", "wheels.tests._assets.middleware.TestMiddlewareA")).toBeFalse();
			});

		});

		describe("S6 dotted package dirName is not a CreateObject path", () => {

			it("does not load a package whose directory name contains a dot", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_hardener_dotted"),
					componentPrefix = "wheels.tests._assets.packages_hardener_dotted"
				);
				expect(loader.getPackages()).notToHaveKey("evil.nested");
				expect(loader.getPackageMeta()).notToHaveKey("evil.nested");
				var found = false;
				for (var failed in loader.getFailedPackages()) {
					if (failed.name == "evil.nested") {
						found = true;
					}
				}
				expect(found).toBeTrue();
			});

			it("rejects dir names with dots slashes or spaces", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_lazy_sp_solo"),
					componentPrefix = "wheels.tests._assets.packages_lazy_sp_solo"
				);
				expect(loader.$isSafePackageDirName("solounhinted")).toBeTrue();
				expect(loader.$isSafePackageDirName("wheels-sentry")).toBeTrue();
				expect(loader.$isSafePackageDirName("evil.nested")).toBeFalse();
				expect(loader.$isSafePackageDirName("../escape")).toBeFalse();
				expect(loader.$isSafePackageDirName("has space")).toBeFalse();
			});

		});

		describe("S7 failed boot() unwinds Injector bindings", () => {

			it("drops a service registered before boot() threw", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_hardener_bootresidue"),
					componentPrefix = "wheels.tests._assets.packages_hardener_bootresidue"
				);
				var container = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.TrackingContainer"
				).init();

				loader.$invokeServiceProviderRegister(container);
				expect(container.containsInstance("hardenerBootResidue")).toBeTrue();

				loader.$invokeServiceProviderBoot({});

				expect(container.containsInstance("hardenerBootResidue")).toBeFalse();
				expect(loader.getPackages()).notToHaveKey("bootresidue");
			});

		});

		describe("S8 getters return copies not live registries", () => {

			it("mutating getMixins does not change the loader registry", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_collision"),
					componentPrefix = "wheels.tests._assets.packages_collision"
				);
				var mixins = loader.getMixins();
				mixins.controller["$hardenerInjected"] = "pwned";
				var fresh = loader.getMixins();
				expect(fresh.controller).notToHaveKey("$hardenerInjected");
			});

			it("mutating getPackages does not add a key to the loader registry", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_collision"),
					componentPrefix = "wheels.tests._assets.packages_collision"
				);
				var pkgs = loader.getPackages();
				pkgs["$hardenerInjected"] = true;
				var fresh = loader.getPackages();
				expect(fresh).notToHaveKey("$hardenerInjected");
			});

			it("mutating Plugins getMixins does not change the live mixin registry", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					var mixins = pluginObj.getMixins();
					expect(mixins).toHaveKey("controller");
					mixins.controller["$hardenerInjected"] = "pwned";
					var fresh = pluginObj.getMixins();
					expect(fresh.controller).notToHaveKey("$hardenerInjected");
					expect(fresh.controller).toHaveKey("$CollidingMethod");
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

			it("mutating Plugins getMethodProviders does not change the live provider map", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					var providers = pluginObj.getMethodProviders();
					providers["$hardenerInjected"] = {pwned = true};
					if (StructKeyExists(providers, "controller") && IsStruct(providers.controller)) {
						providers.controller["$hardenerInjected"] = "pwned";
					}
					var fresh = pluginObj.getMethodProviders();
					expect(fresh).notToHaveKey("$hardenerInjected");
					if (StructKeyExists(fresh, "controller") && IsStruct(fresh.controller)) {
						expect(fresh.controller).notToHaveKey("$hardenerInjected");
					}
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

			it("mutating Plugins getPlugins does not add a key to the live plugin registry", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					var plugins = pluginObj.getPlugins();
					expect(StructCount(plugins)).toBeGT(0);
					plugins["$hardenerInjected"] = {pwned = true};
					var fresh = pluginObj.getPlugins();
					expect(fresh).notToHaveKey("$hardenerInjected");
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

		});

		describe("S9 plugin mixin collisions are detected then last-wins", () => {

			it("records the collision and the later plugin method wins", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/collision";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/collision",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					var collisions = pluginObj.getMixinCollisions();
					expect(ArrayLen(collisions)).toBeGT(0);
					var fn = pluginObj.getMixins().controller["$CollidingMethod"];
					expect(fn()).toBe("FromPluginB");
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

		});

		describe("S10 silent degrade: bad manifest, lifecycle, init isolation", () => {

			it("does not load a plugin whose plugin.json is invalid", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/manifest";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/manifest",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					expect(pluginObj.getPlugins()).notToHaveKey("TestBadManifestPlugin");
					expect(pluginObj.getPluginMeta()).notToHaveKey("TestBadManifestPlugin");
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

			it("unloads a plugin whose onPluginLoad throws and still loads the sibling", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				StructDelete(application, "$wheelstestLifecycleLog");
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/lifecyclefailing";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/lifecyclefailing",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					expect(pluginObj.getPlugins()).notToHaveKey("TestLifecycleFailingA");
					expect(pluginObj.getPlugins()).toHaveKey("TestLifecycleWorkingB");
					expect(ArrayFind(application.$wheelstestLifecycleLog, "B:onPluginLoad")).toBeGT(0);
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
					StructDelete(application, "$wheelstestLifecycleLog");
				}
			});

			it("isolates a throwing init() so the sibling plugin still loads", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_initthrow";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_initthrow",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					expect(pluginObj.getPlugins()).notToHaveKey("InitThrowPlugin");
					expect(pluginObj.getPlugins()).toHaveKey("SiblingOkPlugin");
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
			});

		});

		describe("S11 onPluginLoad / onPluginActivate cannot plant application keys via the hook context", () => {

			it("does not sync attacker keys onto application after onPluginLoad", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				StructDelete(application, "hardenerPluginPwned");
				if (StructKeyExists(application.wheels, "hardenerPluginPwned")) {
					StructDelete(application.wheels, "hardenerPluginPwned");
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_mutateapp";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_mutateapp",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					$pluginObj(config);
					expect(StructKeyExists(application, "hardenerPluginPwned")).toBeFalse();
					expect(StructKeyExists(application.wheels, "hardenerPluginPwned")).toBeFalse();
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
					StructDelete(application, "hardenerPluginPwned");
					if (StructKeyExists(application.wheels, "hardenerPluginPwned")) {
						StructDelete(application.wheels, "hardenerPluginPwned");
					}
				}
			});

			it("does not let onPluginActivate plant keys on the live application", () => {
				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				StructDelete(application, "hardenerActivatePwned");
				if (StructKeyExists(application.wheels, "hardenerActivatePwned")) {
					StructDelete(application.wheels, "hardenerActivatePwned");
				}
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_mutateapp";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_mutateapp",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true
				};
				try {
					var pluginObj = $pluginObj(config);
					pluginObj.$invokeOnPluginActivate();
					expect(StructKeyExists(application, "hardenerActivatePwned")).toBeFalse();
					expect(StructKeyExists(application.wheels, "hardenerActivatePwned")).toBeFalse();
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
					StructDelete(application, "hardenerActivatePwned");
					if (StructKeyExists(application.wheels, "hardenerActivatePwned")) {
						StructDelete(application.wheels, "hardenerActivatePwned");
					}
				}
			});

		});

		describe("S12 deletePluginDirectories deletes orphan folders", () => {

			beforeEach(() => {
				deleteRoot = ExpandPath("/wheels/tests/_assets/plugins/hardener_delete_runtime");
				$resetDir(deleteRoot);
			});

			afterEach(() => {
				$resetDir(deleteRoot);
			});

			it("deletes a folder that has no corresponding zip when the default is true", () => {
				var orphan = deleteRoot & "/orphanplugin";
				DirectoryCreate(orphan);
				FileWrite(orphan & "/Orphanplugin.cfc", "component { function init() { this.version = ""99.9.9""; return this; } }");

				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_delete_runtime";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_delete_runtime",
					deletePluginDirectories = true,
					overwritePlugins = true,
					loadIncompatiblePlugins = true,
					wheelsVersion = "4.0.0"
				};
				try {
					$pluginObj(config);
				} catch (any e) {
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
				expect(DirectoryExists(orphan)).toBeFalse();
			});

			it("keeps a folder that has a matching zip", () => {

				// RustCFML is JVM-free: the zip/symlink fixtures are built with
				// java.util.zip / java.nio.file, which the engine cannot run.
				// The pure-CFML classifier contract is covered elsewhere in this file.
				if (g.$engineAdapter().isRustCFML()) {
					return;
				}
				var kept = deleteRoot & "/keptplugin";
				DirectoryCreate(kept);
				FileWrite(kept & "/Keptplugin.cfc", "component { function init() { this.version = ""99.9.9""; return this; } }");
				$writeZipWithEntries(deleteRoot & "/Keptplugin-1.0.zip", {"Keptplugin.cfc" = "component { function init() { this.version = ""99.9.9""; return this; } }"});

				var originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_delete_runtime";
				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_delete_runtime",
					deletePluginDirectories = true,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsVersion = "4.0.0"
				};
				try {
					$pluginObj(config);
				} catch (any e) {
				} finally {
					application.wheels.pluginComponentPath = originalPluginComponentPath;
				}
				expect(DirectoryExists(kept)).toBeTrue();
			});

		});

		describe("S13 XSS residual: javascript homepage and unescaped list fields", () => {

			it("admin views reject javascript: homepages and encode list fields", () => {
				var views = [
					ExpandPath("/wheels/public/views/pluginentry.cfm"),
					ExpandPath("/wheels/public/views/packageentry.cfm"),
					ExpandPath("/wheels/public/views/packagelist.cfm"),
					ExpandPath("/wheels/public/views/plugins.cfm")
				];
				for (var path in views) {
					var src = FileRead(path);
					expect(FindNoCase("javascript:", src)).toBe(0);
					expect(FindNoCase("EncodeForHTML(", src) GT 0).toBeTrue(
						GetFileFromPath(path) & " must encode user-controlled fields with EncodeForHTML"
					);
				}
			});

			it("only emits http(s) homepage hrefs", () => {
				var src = FileRead(ExpandPath("/wheels/public/views/pluginentry.cfm"))
					& FileRead(ExpandPath("/wheels/public/views/packageentry.cfm"));
				expect(FindNoCase("REFindNoCase(""^https?://""", src) GT 0 || FindNoCase("REFindNoCase('^https?://'", src) GT 0).toBeTrue(
					"plugin/package entry views must allowlist http(s) homepage URLs"
				);
			});

		});

		describe("S14 entry views do not cfinclude package or plugin index.cfm", () => {

			it("pluginentry.cfm does not include /plugins/.../index.cfm", () => {
				var src = FileRead(ExpandPath("/wheels/public/views/pluginentry.cfm"));
				expect(REFindNoCase("plugins/.+index\.cfm", src)).toBe(0);
			});

			it("packageentry.cfm does not include /vendor/.../index.cfm", () => {
				var src = FileRead(ExpandPath("/wheels/public/views/packageentry.cfm"));
				expect(FindNoCase("pkgIndexPath", src)).toBe(0);
				expect(REFindNoCase("vendor/.+index\.cfm", src)).toBe(0);
			});

		});

		describe("S15 implicit global mixin default is detected not flipped", () => {

			it("still defaults an undeclared plugin mixin target to global", () => {
				var pm = CreateObject("component", "wheels.Plugins");
				expect(pm.$defaultMixinTarget()).toBe("global");
			});

			it("$resolveMixinTarget warns via $usesImplicitGlobalMixin when neither CFC nor manifest declares a target", () => {
				var pm = CreateObject("component", "wheels.Plugins");
				expect(pm.$usesImplicitGlobalMixin({}, {})).toBeTrue();
				expect(pm.$usesImplicitGlobalMixin({mixin = "controller"}, {})).toBeFalse();
				expect(pm.$usesImplicitGlobalMixin({}, {mixins = "model"})).toBeFalse();
			});

		});

	}

	function $pluginObj(required struct config) {
		return g.$createObjectFromRoot(argumentCollection = arguments.config);
	}

	public void function $resetDir(required string path) {
		if (DirectoryExists(arguments.path)) {
			DirectoryDelete(arguments.path, true);
		}
		DirectoryCreate(arguments.path);
	}

	public void function $writeZipWithEntries(required string zipPath, required struct entries) {
		var fos = CreateObject("java", "java.io.FileOutputStream").init(arguments.zipPath);
		var zos = CreateObject("java", "java.util.zip.ZipOutputStream").init(fos);
		for (var name in arguments.entries) {
			var entry = CreateObject("java", "java.util.zip.ZipEntry").init(name);
			zos.putNextEntry(entry);
			var bytes = CreateObject("java", "java.lang.String").init(arguments.entries[name]).getBytes("UTF-8");
			zos.write(bytes);
			zos.closeEntry();
		}
		zos.close();
	}

	public void function $writePackageFiles(required string pkgDir, required string cfcName, required struct manifest) {
		var payload = IsBinary(SerializeJSON(arguments.manifest))
			? SerializeJSON(arguments.manifest)
			: SerializeJSON(arguments.manifest);
		var jsonBytes = CreateObject("java", "java.lang.String").init(payload).getBytes("UTF-8");
		FileWrite(arguments.pkgDir & "/package.json", jsonBytes);
		var cfc = "component { public any function init() { this.version = ""1.0.0""; return this; } }";
		FileWrite(arguments.pkgDir & "/" & arguments.cfcName & ".cfc", CharsetDecode(cfc, "utf-8"));
	}

	public void function $createSymlink(required string target, required string linkPath) {
		var Files = CreateObject("java", "java.nio.file.Files");
		var Paths = CreateObject("java", "java.nio.file.Paths");
		var link = Paths.get(arguments.linkPath, []);
		var dest = Paths.get(arguments.target, []);
		if (Files.exists(link, [])) {
			Files.delete(link);
		}
		Files.createSymbolicLink(link, dest, []);
	}

}

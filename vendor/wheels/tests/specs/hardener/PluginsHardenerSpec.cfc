/**
 * Hardener BLOCKERs B1–B4 (plugins / package loader).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 *
 * Public defaults stay true (CoS lock): overwritePlugins,
 * loadIncompatiblePlugins, deletePluginDirectories. Fixes are fail-closed
 * containment / detection under those defaults.
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

		describe("B1 zip slip: unzip stays inside destination", () => {

			beforeEach(() => {
				slipRoot = ExpandPath("/wheels/tests/_assets/plugins/hardener_zipslip_runtime");
				$resetDir(slipRoot);
				destDir = slipRoot & "/dest";
				DirectoryCreate(destDir);
				zipPath = slipRoot & "/Slip-1.0.zip";
				escapedSibling = slipRoot & "/escaped-sibling.txt";
				escapedPluginTree = ExpandPath("/wheels/tests/_assets/plugins/hardener-b1-pwned.txt");
			});

			afterEach(() => {
				$resetDir(slipRoot);
				if (FileExists(escapedPluginTree)) {
					FileDelete(escapedPluginTree);
				}
			});

			it("classifies traversal and absolute entries as escaping", () => {
				expect(g.$zipEntryEscapesDestination(destDir, "../escaped-sibling.txt")).toBeTrue();
				expect(g.$zipEntryEscapesDestination(destDir, "../../hardener-b1-pwned.txt")).toBeTrue();
				expect(g.$zipEntryEscapesDestination(destDir, "/tmp/abs-escaped.txt")).toBeTrue();
				expect(g.$zipEntryEscapesDestination(destDir, "safe.txt")).toBeFalse();
				expect(g.$zipEntryEscapesDestination(destDir, "nested/safe.txt")).toBeFalse();
			});

			it("does not write a ../ zip entry outside the unzip destination", () => {
				$writeZipWithEntries(zipPath, {
					"../escaped-sibling.txt" = "pwned-sibling",
					"safe.txt" = "contained"
				});

				try {
					g.$zip(action = "unzip", destination = destDir, file = zipPath, overwrite = true);
				} catch (any e) {
					// fail-closed throw is allowed; the escaped file must not land
				}

				expect(FileExists(escapedSibling)).toBeFalse();
			});

			it("does not write a ../../ zip entry into the plugins tree", () => {
				$writeZipWithEntries(zipPath, {
					"../../hardener-b1-pwned.txt" = "pwned-tree",
					"safe.txt" = "contained"
				});

				try {
					g.$zip(action = "unzip", destination = destDir, file = zipPath, overwrite = true);
				} catch (any e) {
				}

				expect(FileExists(escapedPluginTree)).toBeFalse();
			});

			it("does not extract a zip-slip plugin archive when overwritePlugins is true", () => {
				originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_zipslip_runtime";

				$writeZipWithEntries(zipPath, {
					"../escaped-sibling.txt" = "pwned-extract",
					"../../hardener-b1-pwned.txt" = "pwned-tree"
				});

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_zipslip_runtime",
					deletePluginDirectories = true,
					overwritePlugins = true,
					loadIncompatiblePlugins = true
				};

				try {
					$pluginObj(config);
				} catch (any e) {
					// extract must fail closed without leaving escaped files
				}

				application.wheels.pluginComponentPath = originalPluginComponentPath;

				expect(FileExists(escapedSibling)).toBeFalse();
				expect(FileExists(escapedPluginTree)).toBeFalse();
			});

			it("rejects an absolute zip entry path", () => {
				var absEscape = slipRoot & "/abs-escaped.txt";
				if (FileExists(absEscape)) {
					FileDelete(absEscape);
				}
				var absEntry = {};
				absEntry[Replace(absEscape, "\", "/", "all")] = "pwned-abs";
				$writeZipWithEntries(zipPath, absEntry);

				try {
					g.$zip(action = "unzip", destination = destDir, file = zipPath, overwrite = true);
				} catch (any e) {
				}

				expect(FileExists(absEscape)).toBeFalse();
			});

		});

		describe("B2 version gate: empty compat fails closed", () => {

			it("empty compat fails closed even when loadIncompatible is true", () => {
				var pm = CreateObject("component", "wheels.Plugins");
				expect(pm.$shouldLoadPlugin("", "4.0.0", true)).toBeFalse();
				expect(pm.$shouldLoadPlugin("   ", "4.0.0", true)).toBeFalse();
				expect(pm.$shouldLoadPlugin("1.0", "4.0.0", true)).toBeTrue();
				expect(pm.$shouldLoadPlugin("1.0", "4.0.0", false)).toBeFalse();
				expect(pm.$shouldLoadPlugin("4.0.0", "4.0.0", false)).toBeTrue();
			});

			it("does not load a plugin with empty compatibility when loadIncompatiblePlugins is true", () => {
				originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/hardener_emptycompat";

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/hardener_emptycompat",
					deletePluginDirectories = true,
					overwritePlugins = true,
					loadIncompatiblePlugins = true,
					wheelsVersion = "4.0.0"
				};
				var pluginObj = $pluginObj(config);
				var plugins = pluginObj.getPlugins();

				application.wheels.pluginComponentPath = originalPluginComponentPath;

				expect(plugins).notToHaveKey("EmptyCompatPlugin");
			});

			it("still loads a declared mismatch when loadIncompatiblePlugins is true", () => {
				originalPluginComponentPath = application.wheels.pluginComponentPath;
				application.wheels.pluginComponentPath = "/wheels/tests/_assets/plugins/standard";

				var config = {
					path = "wheels",
					fileName = "Plugins",
					method = "$init",
					pluginPath = "/wheels/tests/_assets/plugins/standard",
					deletePluginDirectories = false,
					overwritePlugins = false,
					loadIncompatiblePlugins = true,
					wheelsVersion = "99.9.9"
				};
				var pluginObj = $pluginObj(config);
				var plugins = pluginObj.getPlugins();

				application.wheels.pluginComponentPath = originalPluginComponentPath;

				expect(plugins).toHaveKey("TestIncompatableVersion");
			});

			it("does not load a package whose wheelsVersion is an empty string", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = ExpandPath("/wheels/tests/_assets/packages_hardener_emptycompat"),
					componentPrefix = "wheels.tests._assets.packages_hardener_emptycompat",
					wheelsVersion = "4.0.0"
				);

				expect(loader.getPackages()).notToHaveKey("emptycompat");
				expect(loader.getPackageMeta()).notToHaveKey("emptycompat");

				var foundEmpty = false;
				for (var failed in loader.getFailedPackages()) {
					if (failed.name == "emptycompat") {
						foundEmpty = true;
					}
				}
				expect(foundEmpty).toBeTrue();
			});

		});

		describe("B3 duplicate package manifest name is not last-wins", () => {

			it("fails both packages that declare the same manifest name", () => {
				var graph = new wheels.ModuleGraph();
				var manifests = {
					"pkgFirst" = {name = "wheels-dup", version = "1.0.0"},
					"pkgSecond" = {name = "wheels-dup", version = "2.0.0"}
				};
				var result = graph.resolve(manifests);

				expect(ArrayFind(result.loadOrder, "pkgFirst")).toBe(0);
				expect(ArrayFind(result.loadOrder, "pkgSecond")).toBe(0);

				var foundDup = false;
				for (var err in result.errors) {
					if (FindNoCase("duplicate", err.message) && FindNoCase("wheels-dup", err.message)) {
						foundDup = true;
					}
				}
				expect(foundDup).toBeTrue();
			});

			it("does not resolve requires against a collided name", () => {
				var graph = new wheels.ModuleGraph();
				var manifests = {
					"pkgFirst" = {name = "wheels-dup", version = "1.0.0"},
					"pkgSecond" = {name = "wheels-dup", version = "2.0.0"},
					"pkgConsumer" = {
						name = "wheels-consumer",
						version = "1.0.0",
						requires = {"wheels-dup" = "*"}
					}
				};
				var result = graph.resolve(manifests);

				expect(ArrayFind(result.loadOrder, "pkgConsumer")).toBe(0);
				expect(ArrayFind(result.loadOrder, "pkgFirst")).toBe(0);
				expect(ArrayFind(result.loadOrder, "pkgSecond")).toBe(0);
			});

		});

		describe("B4 solo unhinted lazy ServiceProvider still boots", () => {

			beforeEach(() => {
				soloPath = ExpandPath("/wheels/tests/_assets/packages_lazy_sp_solo");
				soloPrefix = "wheels.tests._assets.packages_lazy_sp_solo";
			});

			it("reports ServiceProvider work when the only package is an unhinted lazy provider", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = soloPath,
					componentPrefix = soloPrefix
				);

				expect(loader.getPackages()).notToHaveKey("solounhinted");
				expect(loader.$hasServiceProviderWork()).toBeTrue();
			});

			it("invokes register() and boot() on a solo unhinted lazy ServiceProvider", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = soloPath,
					componentPrefix = soloPrefix
				);
				var fakeContainer = CreateObject(
					"component",
					"wheels.tests._assets.plugins.serviceprovider.FakeContainer"
				).init();

				loader.$invokeServiceProviderRegister(fakeContainer);
				loader.$invokeServiceProviderBoot({});

				var pkgs = loader.getPackages();
				expect(pkgs).toHaveKey("solounhinted");
				expect(pkgs.solounhinted.registerCalled).toBeTrue();
				expect(pkgs.solounhinted.bootCalled).toBeTrue();
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

}

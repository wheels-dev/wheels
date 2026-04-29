/**
 * Regression coverage for GH #2326 (F8) — fresh `wheels new` apps fail to
 * resolve `org.sqlite.JDBC` because Lucee 7's stock Express distribution
 * doesn't ship the SQLite driver. BundleStager is what `wheels start`
 * delegates to before booting Lucee; it stages the patched JAR into every
 * Lucee Express install's lib/ext/ so the Tomcat classpath can resolve it.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.stager = new cli.lucli.services.BundleStager();
	}

	private string function makeTempProject(required string appCfmContent) {
		var root = getTempDirectory() & "wheels-bundlestager-#createUUID()#";
		directoryCreate(root, true);
		directoryCreate(root & "/config", true);
		fileWrite(root & "/config/app.cfm", arguments.appCfmContent);
		return root;
	}

	private string function makeTempBundleJar() {
		var jar = getTempDirectory() & "wheels-bundle-src-#createUUID()#.jar";
		fileWrite(jar, "fake jar content");
		return jar;
	}

	private string function makeTempExpressRoot(required array versions) {
		var root = getTempDirectory() & "wheels-express-#createUUID()#";
		directoryCreate(root, true);
		for (var v in arguments.versions) {
			directoryCreate(root & "/" & v & "/lib/ext", true);
		}
		return root;
	}

	private string function makeTempServersRoot(required array serverNames) {
		var root = getTempDirectory() & "wheels-servers-#createUUID()#";
		directoryCreate(root, true);
		for (var s in arguments.serverNames) {
			directoryCreate(root & "/" & s & "/lucee-server/bundles", true);
		}
		return root;
	}

	function run() {
		describe("BundleStager.projectUsesSqliteDatasource", () => {

			it("returns true when app.cfm references the jdbc:sqlite: URL prefix (current format, post-##2304)", () => {
				var p = makeTempProject('<cfscript>
					this.datasources["app"] = {
						class: "org.sqlite.JDBC",
						connectionString: "jdbc:sqlite:" & expandPath("../db/app.sqlite")
					};
				</cfscript>');
				try {
					expect(variables.stager.projectUsesSqliteDatasource(p)).toBeTrue();
				} finally {
					directoryDelete(p, true);
				}
			});

			it("returns true when app.cfm references the OSGi bundleName hint (legacy format)", () => {
				var p = makeTempProject('<cfscript>
					this.datasources["app"] = {
						class: "org.sqlite.JDBC",
						bundleName: "org.xerial.sqlite-jdbc",
						connectionString: "jdbc:sqlite:" & expandPath("../db/app.sqlite")
					};
				</cfscript>');
				try {
					expect(variables.stager.projectUsesSqliteDatasource(p)).toBeTrue();
				} finally {
					directoryDelete(p, true);
				}
			});

			it("returns false for non-SQLite datasources (regression — don't stage for postgres/mysql apps)", () => {
				var p = makeTempProject('<cfscript>
					this.datasources["app"] = {
						class: "org.postgresql.Driver",
						connectionString: "jdbc:postgresql://localhost:5432/app"
					};
				</cfscript>');
				try {
					expect(variables.stager.projectUsesSqliteDatasource(p)).toBeFalse();
				} finally {
					directoryDelete(p, true);
				}
			});

			it("returns false when projectRoot is empty", () => {
				expect(variables.stager.projectUsesSqliteDatasource("")).toBeFalse();
			});

			it("returns false when config/app.cfm is missing", () => {
				var root = getTempDirectory() & "wheels-bundlestager-empty-#createUUID()#";
				directoryCreate(root, true);
				try {
					expect(variables.stager.projectUsesSqliteDatasource(root)).toBeFalse();
				} finally {
					directoryDelete(root, true);
				}
			});
		});

		describe("BundleStager.stageIntoLibExt", () => {

			it("copies the bundle JAR into every Lucee version's lib/ext/", () => {
				var jar = makeTempBundleJar();
				var express = makeTempExpressRoot(["7.0.0.395", "6.2.2.91"]);
				try {
					var r = variables.stager.stageIntoLibExt(jar, express, "sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(2);
					expect(arrayLen(r.skipped)).toBe(0);
					expect(arrayLen(r.failed)).toBe(0);
					expect(fileExists(express & "/7.0.0.395/lib/ext/sqlite-jdbc-3.49.1.0.jar")).toBeTrue();
					expect(fileExists(express & "/6.2.2.91/lib/ext/sqlite-jdbc-3.49.1.0.jar")).toBeTrue();
				} finally {
					fileDelete(jar);
					directoryDelete(express, true);
				}
			});

			it("is idempotent — already-staged JARs report as 'skipped' (no overwrite)", () => {
				var jar = makeTempBundleJar();
				var express = makeTempExpressRoot(["7.0.0.395"]);
				try {
					variables.stager.stageIntoLibExt(jar, express, "sqlite-jdbc-3.49.1.0.jar");
					var r2 = variables.stager.stageIntoLibExt(jar, express, "sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r2.staged)).toBe(0);
					expect(arrayLen(r2.skipped)).toBe(1);
					expect(arrayLen(r2.failed)).toBe(0);
				} finally {
					fileDelete(jar);
					directoryDelete(express, true);
				}
			});

			it("returns empty result when expressRoot is missing (no Lucee installed yet)", () => {
				var jar = makeTempBundleJar();
				try {
					var r = variables.stager.stageIntoLibExt(jar, "/nonexistent/path", "sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(0);
				} finally {
					fileDelete(jar);
				}
			});

			it("returns empty result when bundleSrc is missing (dev checkout without baked-in JAR)", () => {
				var express = makeTempExpressRoot(["7.0.0.395"]);
				try {
					var r = variables.stager.stageIntoLibExt("/nonexistent.jar", express, "sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(0);
					expect(arrayLen(r.skipped)).toBe(0);
				} finally {
					directoryDelete(express, true);
				}
			});

			it("skips Express versions that don't have a lib/ext/ directory", () => {
				var jar = makeTempBundleJar();
				var express = getTempDirectory() & "wheels-express-partial-#createUUID()#";
				directoryCreate(express, true);
				directoryCreate(express & "/7.0.0.395/lib/ext", true);
				directoryCreate(express & "/broken-version", true); // no lib/ext
				try {
					var r = variables.stager.stageIntoLibExt(jar, express, "sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(1);
					expect(fileExists(express & "/7.0.0.395/lib/ext/sqlite-jdbc-3.49.1.0.jar")).toBeTrue();
				} finally {
					fileDelete(jar);
					directoryDelete(express, true);
				}
			});
		});

		describe("BundleStager.stageIntoServerBundles", () => {

			it("copies the bundle JAR into every server's lucee-server/bundles/", () => {
				var jar = makeTempBundleJar();
				var servers = makeTempServersRoot(["blog", "another-app"]);
				try {
					var r = variables.stager.stageIntoServerBundles(jar, servers, "org.xerial.sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(2);
					expect(arrayLen(r.skipped)).toBe(0);
					expect(arrayLen(r.failed)).toBe(0);
					expect(fileExists(servers & "/blog/lucee-server/bundles/org.xerial.sqlite-jdbc-3.49.1.0.jar")).toBeTrue();
					expect(fileExists(servers & "/another-app/lucee-server/bundles/org.xerial.sqlite-jdbc-3.49.1.0.jar")).toBeTrue();
				} finally {
					fileDelete(jar);
					directoryDelete(servers, true);
				}
			});

			it("is idempotent — already-staged JARs report as 'skipped' (no overwrite)", () => {
				var jar = makeTempBundleJar();
				var servers = makeTempServersRoot(["blog"]);
				try {
					variables.stager.stageIntoServerBundles(jar, servers, "org.xerial.sqlite-jdbc-3.49.1.0.jar");
					var r2 = variables.stager.stageIntoServerBundles(jar, servers, "org.xerial.sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r2.staged)).toBe(0);
					expect(arrayLen(r2.skipped)).toBe(1);
					expect(arrayLen(r2.failed)).toBe(0);
				} finally {
					fileDelete(jar);
					directoryDelete(servers, true);
				}
			});

			it("returns empty result when serversRoot is missing (no servers started yet)", () => {
				var jar = makeTempBundleJar();
				try {
					var r = variables.stager.stageIntoServerBundles(jar, "/nonexistent/path", "org.xerial.sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(0);
					expect(arrayLen(r.skipped)).toBe(0);
				} finally {
					fileDelete(jar);
				}
			});

			it("returns empty result when bundleSrc is missing", () => {
				var servers = makeTempServersRoot(["blog"]);
				try {
					var r = variables.stager.stageIntoServerBundles("/nonexistent.jar", servers, "org.xerial.sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(0);
				} finally {
					directoryDelete(servers, true);
				}
			});

			it("skips server entries that don't have a lucee-server/bundles/ directory yet", () => {
				var jar = makeTempBundleJar();
				var servers = getTempDirectory() & "wheels-servers-partial-#createUUID()#";
				directoryCreate(servers, true);
				directoryCreate(servers & "/blog/lucee-server/bundles", true);
				directoryCreate(servers & "/half-built", true); // no lucee-server/bundles
				try {
					var r = variables.stager.stageIntoServerBundles(jar, servers, "org.xerial.sqlite-jdbc-3.49.1.0.jar");
					expect(arrayLen(r.staged)).toBe(1);
					expect(fileExists(servers & "/blog/lucee-server/bundles/org.xerial.sqlite-jdbc-3.49.1.0.jar")).toBeTrue();
				} finally {
					fileDelete(jar);
					directoryDelete(servers, true);
				}
			});
		});
	}
}

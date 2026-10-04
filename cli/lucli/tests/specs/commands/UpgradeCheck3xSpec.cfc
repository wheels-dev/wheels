/**
 * #3939: `wheels upgrade check` on 3.x-era apps. It reads 3.0 GA's version
 * (no version in vendor/wheels/box.json), reports each finding once, still
 * finds 3.x leftovers after the framework swap, raises the CSRF key only
 * for cookie-store apps, and never tells a RocketUnit suite to switch base
 * classes before its tests are converted.
 *
 * Runs the real `upgrade check --format=json` against small temp apps.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.workDir = getTempDirectory() & "upgrade-check-3x-" & createUUID();
		directoryCreate(variables.workDir, true);
	}

	function afterAll() {
		if (directoryExists(variables.workDir)) directoryDelete(variables.workDir, true);
	}

	/** A minimal app: vendor/wheels, config/, tests/. `files` maps relative path → content. */
	private string function $app(required struct files) {
		var root = variables.workDir & "/app-" & createUUID();
		directoryCreate(root & "/vendor/wheels/events", true);
		directoryCreate(root & "/config", true);
		directoryCreate(root & "/tests", true);
		for (var rel in arguments.files) {
			var path = root & "/" & rel;
			var dir = getDirectoryFromPath(path);
			if (!directoryExists(dir)) directoryCreate(dir, true);
			fileWrite(path, arguments.files[rel]);
		}
		return root;
	}

	/** The parsed JSON report of `wheels upgrade check --to=<target> --format=json`. */
	private struct function $check(required string root, string target = "4.1.2") {
		var m = new cli.lucli.Module(cwd = arguments.root);
		prepareMock(m);
		m.$("out");
		try {
			m.upgrade(arg1 = "check", to = arguments.target, format = "json");
		} catch (Wheels.UpgradeCheckFailed e) {
			// Breaking findings exit non-zero after the report is printed.
		}
		for (var call in m.$callLog().out) {
			if (isJSON(call[1])) return deserializeJSON(call[1]);
		}
		return {};
	}

	private array function $descriptions(required array findings) {
		var out = [];
		for (var f in arguments.findings) arrayAppend(out, f.description);
		return out;
	}

	/** The matches of the breaking finding whose description starts with `prefix`; [] when there is none. */
	private array function $matchesFor(required struct report, required string prefix) {
		for (var f in arguments.report.breaking ?: []) {
			if (left(f.description, len(arguments.prefix)) == arguments.prefix) return f.matches;
		}
		return [];
	}

	private string function $allText(required struct report) {
		return serializeJSON([report.breaking ?: [], report.advisories ?: []]);
	}

	/** 3.0 GA: version only in events/onapplicationstart.cfc, box.json without one. */
	private struct function $wheels30() {
		return {
			"vendor/wheels/box.json": serializeJSON({devDependencies: {testbox: "^6.2.1+400"}}),
			"vendor/wheels/events/onapplicationstart.cfc": "component {#chr(10)#	function $init() {#chr(10)#		application.$wheels.version = ""3.0.0"";#chr(10)#	}#chr(10)#}"
		};
	}

	function run() {

		describe("upgrade check: current version of a 3.0 GA app", () => {

			it("reads 3.0.0 from the framework when box.json has no version", () => {
				var report = $check($app($wheels30()));
				expect(report.currentVersion).toBe("3.0.0");
			});

			it("reports a 3.x test base class once, not twice", () => {
				var files = $wheels30();
				files["tests/RocketUnit/Test.cfc"] = 'component extends="wheels.Test" {}';
				var report = $check($app(files));
				var all = arrayToList($descriptions(report.breaking), "|") & "|" & arrayToList($descriptions(report.advisories), "|");
				expect(listLen(all, "|")).toBe(arrayLen(listToArray(all, "|")));
				var hits = 0;
				for (var d in listToArray(all, "|")) if (findNoCase("RocketUnit", d)) hits++;
				expect(hits).toBe(1);
			});
		});

		describe("upgrade check after the framework swap", () => {

			it("still finds 3.x leftovers in a 4.x app", () => {
				var files = {
					"vendor/wheels/wheels.json": serializeJSON({name: "wheels-core", version: "4.1.2"}),
					"tests/specs/OldSpec.cfc": 'component extends="wheels.Testbox" {}',
					"app/controllers/Legacy.cfc": "component { function x() { renderPage(); } }"
				};
				var report = $check($app(files));
				var text = $allText(report);
				expect(text).toInclude("renderPage");
				expect(text).toInclude("wheels.Testbox");
			});

			it("reports nothing breaking for a stock 4.x app (plugins/ placeholder, deprecated helpers)", () => {
				var files = {
					"vendor/wheels/wheels.json": serializeJSON({name: "wheels-core", version: "4.1.2"}),
					"plugins/README.md": "Legacy plugins live here.",
					"plugins/.gitkeep": "",
					"app/views/posts/index.cfm": "##paginationLinks()##"
				};
				expect($check($app(files)).breaking).toBeEmpty();
			});

			it("doesn't raise 3-to-4 default changes for an app already on 4.x", () => {
				var files = {
					"vendor/wheels/wheels.json": serializeJSON({name: "wheels-core", version: "4.1.2"}),
					"config/settings.cfm": "set(allowEnvironmentSwitchViaUrl=true);"
				};
				expect($allText($check($app(files)))).notToInclude("allowEnvironmentSwitchViaUrl");
			});
		});

		describe("upgrade check: WireBox references in a 3.x app", () => {

			it("flags the WireBox bootstrap in public/Application.cfc", () => {
				var files = $wheels30();
				files["public/Application.cfc"] = 'component {#chr(10)#	function onApplicationStart() {#chr(10)#		application.wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");#chr(10)#	}#chr(10)#}';
				var matches = $matchesFor($check($app(files)), "Direct WireBox references");
				expect(matches).toBe(["public/Application.cfc:3"]);
			});

			it("skips a package that box.json installs under app/", () => {
				var files = $wheels30();
				files["box.json"] = serializeJSON({dependencies: {logbox: "^7.0.0"}, installPaths: {logbox: "app/lib/logbox/"}});
				files["app/lib/logbox/system/BaseProxy.cfc"] = "component { function x() { return application.wirebox; } }";
				expect($matchesFor($check($app(files)), "Direct WireBox references")).toBeEmpty();
			});

			it("skips a package with its own box.json wherever it sits under app/", () => {
				var files = $wheels30();
				files["box.json"] = serializeJSON({dependencies: {logbox: "^7.0.0"}, installPaths: {logbox: "app/lib/logbox/"}});
				files["app/lib/lib/logbox/box.json"] = serializeJSON({name: "LogBox"});
				files["app/lib/lib/logbox/system/BaseProxy.cfc"] = "component { function x() { return application.wirebox; } }";
				expect($matchesFor($check($app(files)), "Direct WireBox references")).toBeEmpty();
			});

			it("still flags the app's own code next to such a package", () => {
				var files = $wheels30();
				files["box.json"] = serializeJSON({dependencies: {logbox: "^7.0.0"}, installPaths: {logbox: "./app/lib/logbox"}});
				files["app/lib/logbox/system/BaseProxy.cfc"] = "component { function x() { return application.wirebox; } }";
				files["app/lib/Helper.cfc"] = "component { function x() { return application.wirebox.getInstance(""Foo""); } }";
				expect($matchesFor($check($app(files)), "Direct WireBox references")).toBe(["app/lib/Helper.cfc:1"]);
			});
		});

		describe("upgrade check: CSRF cookie key", () => {

			it("doesn't flag the key for an app on the session store", () => {
				var files = $wheels30();
				files["config/settings.cfm"] = 'set(csrfStore="session");';
				expect($allText($check($app(files)))).notToInclude("csrfCookieEncryptionSecretKey");
			});

			it("doesn't flag the key when csrfStore is never set (session is the default)", () => {
				var files = $wheels30();
				files["config/settings.cfm"] = 'set(reloadPassword="x");';
				expect($allText($check($app(files)))).notToInclude("csrfCookieEncryptionSecretKey");
			});

			it("flags a 4.x cookie-store app with no key (production throws MissingCsrfKey)", () => {
				var files = {
					"vendor/wheels/wheels.json": serializeJSON({name: "wheels-core", version: "4.1.2"}),
					"config/settings.cfm": 'set(csrfStore="cookie");'
				};
				expect($allText($check($app(files)))).toInclude("csrfCookieEncryptionSecretKey");
			});

			it("doesn't flag a 4.x cookie-store app that sets the key", () => {
				var files = {
					"vendor/wheels/wheels.json": serializeJSON({name: "wheels-core", version: "4.1.2"}),
					"config/settings.cfm": 'set(csrfStore="cookie");#chr(10)#set(csrfCookieEncryptionSecretKey=env("WHEELS_CSRF_KEY"));'
				};
				expect($allText($check($app(files)))).notToInclude("csrfCookieEncryptionSecretKey");
			});

			it("flags a cookie-store app with no key", () => {
				var files = $wheels30();
				files["config/settings.cfm"] = 'set(csrfStore="cookie");';
				expect($allText($check($app(files)))).toInclude("csrfCookieEncryptionSecretKey");
			});
		});

		describe("upgrade check: test base classes", () => {

			it("doesn't tell a RocketUnit base to switch to wheels.WheelsTest before conversion", () => {
				var files = $wheels30();
				files["tests/RocketUnit/Test.cfc"] = 'component extends="wheels.Test" {}';
				var report = $check($app(files));
				var rocket = {};
				for (var f in arrayMerge(duplicate(report.breaking), report.advisories)) {
					if (findNoCase("RocketUnit", f.description)) rocket = f;
				}
				expect(rocket).notToBeEmpty();
				expect(rocket.fix).notToInclude('Change to extends="wheels.WheelsTest"');
				expect(rocket.fix).toInclude("convert");
				// RocketUnit still runs on 4.x: not a breaking change that fails the gate.
				expect(arrayToList($descriptions(report.breaking), "|")).notToInclude("RocketUnit");
			});

			it("tells a wheels.Testbox base it can switch to wheels.WheelsTest", () => {
				var files = $wheels30();
				files["tests/specs/OldSpec.cfc"] = 'component extends="wheels.Testbox" {}';
				var text = $allText($check($app(files)));
				expect(text).toInclude("wheels.Testbox");
				expect(text).toInclude("wheels.WheelsTest");
			});
		});
	}
}

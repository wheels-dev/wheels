/**
 * `wheels docs fetch` mirrors the unpacked bundle into the app's
 * public/wheels-docs with $docsMountIntoWebroot. The mirror is replaced only
 * when it is one (it holds the bundle's manifest.json) and only when stale
 * (missing, or its manifest.json differs from the cache's). It is a real copy,
 * never hardlinks, so edits in the app cannot change the shared cache under
 * ~/.wheels/docs/<version>/. A public/wheels-docs without manifest.json is
 * the user's own and is never touched. Same rules as the Linux package
 * wrapper's docs-mirror block (tools/test-linux-launcher-docs-mirror.sh).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.workDir = getTempDirectory() & "docs-mount-spec-" & createUUID();
		directoryCreate(workDir, true);
		variables.Files = createObject("java", "java.nio.file.Files");
	}

	function afterAll() {
		if (directoryExists(variables.workDir)) directoryDelete(variables.workDir, true);
	}

	/** A minimal app (vendor/wheels + public/) and a cache dir for one version. */
	private struct function newFixture(boolean withPublic = true) {
		var base = variables.workDir & "/case-" & createUUID();
		var fx = {app = base & "/app", cache = base & "/cache/1.0.0"};
		directoryCreate(fx.app & "/vendor/wheels", true);
		fileWrite(fx.app & "/vendor/wheels/wheels.json", serializeJSON({version: "1.0.0"}));
		if (arguments.withPublic) directoryCreate(fx.app & "/public", true);
		fx.mount = fx.app & "/public/wheels-docs";
		writeBundle(fx.cache, "1.0.0", {"guides/index.html": "<h1>Guides 1</h1>", "old-only.html": "old"});
		return fx;
	}

	private void function writeBundle(required string dir, required string docsVersion, required struct files) {
		if (directoryExists(arguments.dir)) directoryDelete(arguments.dir, true);
		directoryCreate(arguments.dir, true);
		fileWrite(arguments.dir & "/manifest.json", serializeJSON({docsVersion: arguments.docsVersion}));
		for (var rel in arguments.files) {
			var path = arguments.dir & "/" & rel;
			var parent = getDirectoryFromPath(path);
			if (!directoryExists(parent)) directoryCreate(parent, true);
			fileWrite(path, arguments.files[rel]);
		}
	}

	private any function mountModule(required struct fx) {
		var m = new cli.lucli.Module(cwd = arguments.fx.app);
		prepareMock(m);
		m.$("out");
		makePublic(m, "$docsMountIntoWebroot");
		return m;
	}

	/** Everything the command printed, as the JSON of its out() calls. */
	private string function printed(required any m) {
		var log = arguments.m.$callLog();
		return structKeyExists(log, "out") ? serializeJSON(log.out) : "";
	}

	private any function nioPath(required string path) {
		return createObject("java", "java.io.File").init(arguments.path).toPath();
	}

	private numeric function linkCount(required string path) {
		return variables.Files.getAttribute(nioPath(arguments.path), "unix:nlink", []);
	}

	/** An older CLI's mirror: every file hardlinked to the cache. */
	private void function hardlinkMirror(required string source, required string dest) {
		directoryCreate(arguments.dest, true);
		for (var path in directoryList(arguments.source, true, "path")) {
			var rel = mid(path, len(arguments.source) + 2, len(path));
			var target = arguments.dest & "/" & rel;
			if (directoryExists(path)) {
				if (!directoryExists(target)) directoryCreate(target, true);
			} else {
				var parent = getDirectoryFromPath(target);
				if (!directoryExists(parent)) directoryCreate(parent, true);
				variables.Files.createLink(nioPath(target), nioPath(path));
			}
		}
	}

	function run() {

		describe("wheels docs — the webroot mirror", () => {

			it("creates a real copy on the first mount, independent of the cache", () => {
				var fx = newFixture();
				mountModule(fx).$docsMountIntoWebroot(fx.cache);
				expect(fileExists(fx.mount & "/manifest.json")).toBeTrue();
				expect(fileRead(fx.mount & "/guides/index.html")).toBe("<h1>Guides 1</h1>");
				expect(linkCount(fx.cache & "/guides/index.html")).toBe(1);
				fileWrite(fx.mount & "/guides/index.html", "edited in the app");
				expect(fileRead(fx.cache & "/guides/index.html")).toBe("<h1>Guides 1</h1>");
			});

			it("leaves an up-to-date mirror as it is", () => {
				var fx = newFixture();
				mountModule(fx).$docsMountIntoWebroot(fx.cache);
				fileWrite(fx.mount & "/sentinel.txt", "still here");
				var m = mountModule(fx);
				m.$docsMountIntoWebroot(fx.cache);
				expect(fileExists(fx.mount & "/sentinel.txt")).toBeTrue();
				expect(printed(m)).toInclude("is current");
			});

			it("refreshes the mirror when the cache's manifest.json changes, dropping old files", () => {
				var fx = newFixture();
				mountModule(fx).$docsMountIntoWebroot(fx.cache);
				fileWrite(fx.mount & "/sentinel.txt", "from the old mirror");
				writeBundle(fx.cache, "2.0.0", {"guides/index.html": "<h1>Guides 2</h1>"});
				mountModule(fx).$docsMountIntoWebroot(fx.cache);
				expect(fileRead(fx.mount & "/manifest.json")).toBe(fileRead(fx.cache & "/manifest.json"));
				expect(fileRead(fx.mount & "/guides/index.html")).toBe("<h1>Guides 2</h1>");
				expect(fileExists(fx.mount & "/old-only.html")).toBeFalse();
				expect(fileExists(fx.mount & "/sentinel.txt")).toBeFalse();
			});

			it("never touches a public/wheels-docs without manifest.json, before or after a version change", () => {
				var fx = newFixture();
				directoryCreate(fx.mount, true);
				fileWrite(fx.mount & "/mine.txt", "the user's own file");
				var m = mountModule(fx);
				m.$docsMountIntoWebroot(fx.cache);
				expect(fileRead(fx.mount & "/mine.txt")).toBe("the user's own file");
				expect(fileExists(fx.mount & "/manifest.json")).toBeFalse();
				expect(printed(m)).toInclude("alone: it has no manifest.json");

				writeBundle(fx.cache, "2.0.0", {"guides/index.html": "<h1>Guides 2</h1>"});
				mountModule(fx).$docsMountIntoWebroot(fx.cache);
				expect(directoryList(fx.mount, true, "name")).toBe(["mine.txt"]);
			});

			it("replaces an older hardlinked mirror with a real copy and leaves the cache intact", () => {
				var fx = newFixture();
				hardlinkMirror(fx.cache, fx.mount);
				expect(linkCount(fx.cache & "/guides/index.html")).toBe(2);
				// A stale manifest in the mirror (a new version's cache), written
				// without breaking the links of the other files.
				writeBundle(fx.cache & "-next", "2.0.0", {});
				variables.Files.delete(nioPath(fx.mount & "/manifest.json"));
				fileCopy(fx.cache & "-next/manifest.json", fx.mount & "/manifest.json");

				mountModule(fx).$docsMountIntoWebroot(fx.cache);
				expect(fileRead(fx.mount & "/manifest.json")).toBe(fileRead(fx.cache & "/manifest.json"));
				expect(linkCount(fx.cache & "/guides/index.html")).toBe(1);
				expect(fileRead(fx.cache & "/guides/index.html")).toBe("<h1>Guides 1</h1>");
				expect(fileExists(fx.cache & "/old-only.html")).toBeTrue();
				fileWrite(fx.mount & "/guides/index.html", "edited in the app");
				expect(fileRead(fx.cache & "/guides/index.html")).toBe("<h1>Guides 1</h1>");
			});

			it("clears temp dirs left behind by killed runs", () => {
				var fx = newFixture();
				directoryCreate(fx.app & "/public/.wheels-docs-new.12345/guides", true);
				directoryCreate(fx.app & "/public/.wheels-docs-old.12345", true);
				mountModule(fx).$docsMountIntoWebroot(fx.cache);
				var leftovers = directoryList(fx.app & "/public", false, "name").filter((n) => left(n, 13) == ".wheels-docs-");
				expect(leftovers).toBeEmpty();
				expect(fileExists(fx.mount & "/manifest.json")).toBeTrue();
			});

			it("skips the mount when the project has no public/ webroot", () => {
				var fx = newFixture(withPublic = false);
				var m = mountModule(fx);
				m.$docsMountIntoWebroot(fx.cache);
				expect(directoryExists(fx.app & "/public")).toBeFalse();
				expect(printed(m)).toInclude("skipping the webroot mount");
			});

		});
	}
}

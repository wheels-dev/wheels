component extends="wheels.WheelsTest" {

	function run() {
		describe("PathGuard.pathWithinExact", function() {
			// Pure string containment check over two already-canonical paths. Deterministic
			// on every engine (no filesystem), so these run identically on Lucee, Adobe,
			// BoxLang and the JVM-free RustCFML. Hoist the instance to a var — a
			// parenthesized `new` in receiver position crashes Adobe's compiler in the core
			// suite (cross-engine invariant 16a).

			it("admits a descendant of the root", function() {
				var guard = new wheels.PathGuard();
				expect(guard.pathWithinExact(root = "/srv/app", candidate = "/srv/app/data/x.txt")).toBeTrue();
			});

			it("admits the root itself (exact-root equality)", function() {
				var guard = new wheels.PathGuard();
				expect(guard.pathWithinExact(root = "/srv/app", candidate = "/srv/app")).toBeTrue();
			});

			it("ignores trailing separators on the root", function() {
				var guard = new wheels.PathGuard();
				expect(guard.pathWithinExact(root = "/srv/app/", candidate = "/srv/app/x")).toBeTrue();
				expect(guard.pathWithinExact(root = "/srv/app///", candidate = "/srv/app")).toBeTrue();
			});

			it("rejects a case-distinct sibling directory (the core fix)", function() {
				var guard = new wheels.PathGuard();
				// On a case-sensitive filesystem /srv/app and /srv/App are different dirs;
				// the old CompareNoCase/== folded them together.
				expect(guard.pathWithinExact(root = "/srv/App", candidate = "/srv/app/secret")).toBeFalse();
				expect(guard.pathWithinExact(root = "/srv/App", candidate = "/srv/app")).toBeFalse();
			});

			it("rejects a prefix sibling (root + '-extra'), separator-qualified", function() {
				var guard = new wheels.PathGuard();
				expect(guard.pathWithinExact(root = "/srv/app", candidate = "/srv/app-extra/x")).toBeFalse();
				expect(guard.pathWithinExact(root = "/srv/app", candidate = "/srv/appstuff")).toBeFalse();
			});

			it("does not treat a sibling sharing a name prefix as inside", function() {
				var guard = new wheels.PathGuard();
				expect(guard.pathWithinExact(root = "/srv/app", candidate = "/srv/ap")).toBeFalse();
				expect(guard.pathWithinExact(root = "/srv/app", candidate = "/srv/application")).toBeFalse();
			});

			it("treats a backslash as a separator only on the platform where it is one", function() {
				var guard = new wheels.PathGuard();
				var sep = CreateObject("java", "java.io.File").separator;
				if (sep == "\") {
					// Windows: backslash is the native separator, normalised like "/".
					expect(guard.pathWithinExact(root = "C:\app", candidate = "C:\app\data\x")).toBeTrue();
					expect(guard.pathWithinExact(root = "C:\App", candidate = "C:\app\data\x")).toBeFalse();
				} else {
					// POSIX: a backslash is a legal FILENAME byte, not a separator — a sibling
					// directory whose name contains a backslash must NOT be treated as nested
					// under the root (the unconditional \->/ rewrite wrongly admitted it).
					expect(guard.pathWithinExact(root = "/srv/App", candidate = "/srv/App\outside/file")).toBeFalse();
					expect(guard.pathWithinExact(root = "/srv/app", candidate = "/srv/app/data/x")).toBeTrue();
				}
			});

			it("treats '/' as a root that contains any absolute path", function() {
				var guard = new wheels.PathGuard();
				expect(guard.pathWithinExact(root = "/", candidate = "/anything/here")).toBeTrue();
			});
		});
	}

}

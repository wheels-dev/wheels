/**
 * Integration regressions for the case-folding path-containment sweep. Each guard was
 * confining a canonical target to a root with a case-INSENSITIVE comparison
 * (CompareNoCase / == / Left(x,n)!=y); on a case-sensitive filesystem a canonical path
 * under a case-distinct sibling of the root compared equal and was wrongly admitted.
 * The fix routes every site through wheels.PathGuard.pathWithinExact (exact,
 * separator-qualified). These tests are RED on the pre-fix base code, GREEN after.
 *
 * Techniques:
 *  - Guards whose containment argument is passed directly (dump output, package mapping
 *    path, resolved child path) are tested with CRAFTED non-existent case-distinct
 *    paths. getCanonicalPath() is lexical for a non-existent path, so it never folds
 *    case — these run on every engine, no filesystem fixtures.
 *  - Guards reachable only through an existing symlink (zip extraction, asset/docs
 *    serving) use a real symlink into a case-distinct sibling. That scenario exists only
 *    on a case-sensitive filesystem, and RustCFML does not resolve symlinks, so those
 *    self-skip elsewhere.
 *
 * SAFETY: the fixed-root tests operate on REAL framework dirs. A case-variant sibling
 * (ASSETS vs assets) aliases the real root on a case-insensitive filesystem (a
 * Docker-on-macOS APFS bind mount), where removing it would destroy real content. So
 * those tests probe case-sensitivity AT THE ROOT'S filesystem and skip if insensitive,
 * never touch a path that already exists, and record every path they create so the
 * finally removes ONLY those.
 */
component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("Path case-containment sweep", function() {

			// ---- guard: view/assets.cfc $isResolvedPathInside -------------------
			describe("$isResolvedPathInside (view/assets)", function() {
				var ctx = {ctrl = ""};
				beforeEach(function() {
					ctx.ctrl = g.controller(name = "dummy");
				});

				it("admits a descendant", function() {
					var root = GetTempDirectory() & "pc-in-" & CreateUUID();
					expect(ctx.ctrl.$isResolvedPathInside(root & "/data/x.txt", root)).toBeTrue();
				});

				it("rejects a case-distinct sibling (synthetic, all engines)", function() {
					var base = GetTempDirectory() & "pc-case-" & CreateUUID();
					expect(ctx.ctrl.$isResolvedPathInside(base & "/app/secret", base & "/App")).toBeFalse();
				});

				it("rejects a prefix sibling (root + '-extra')", function() {
					var base = GetTempDirectory() & "pc-pre-" & CreateUUID();
					expect(ctx.ctrl.$isResolvedPathInside(base & "/app-extra/x", base & "/app")).toBeFalse();
				});

				it("rejects an existing symlink into a case-distinct sibling (case-sensitive FS)", function() {
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); }
					if (!$caseSensitiveFS()) { skip("needs a case-sensitive filesystem"); }
					var base = GetTempDirectory() & "pc-sym-" & CreateUUID();
					var parent = base & "/App";
					var outside = base & "/app";
					try {
						DirectoryCreate(parent);
						DirectoryCreate(outside);
						FileWrite(outside & "/secret.txt", CharsetDecode("x", "utf-8"));
						$createSymlink(outside, parent & "/link");
						expect(ctx.ctrl.$isResolvedPathInside(parent & "/link/secret.txt", parent)).toBeFalse();
					} finally {
						$removeTree(base);
					}
				});

				it("admits a descendant when the root is configured in the wrong case (case-insensitive FS)", function() {
					// Skip on a case-sensitive FS (a wrong-case root IS a different dir there) and on
					// RustCFML (its getCanonicalPath is lexical and cannot map a wrong-case root to its
					// real on-disk spelling; in practice its paths are built lexically-consistent).
					if ($caseSensitiveFS()) { skip("only meaningful on a case-insensitive filesystem"); }
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML getCanonicalPath is lexical; cannot map a wrong-case root"); }
					var base = GetTempDirectory() & "pc-wrong-" & CreateUUID();
					var real = base & "/App";
					try {
						DirectoryCreate(real);
						FileWrite(real & "/file.txt", CharsetDecode("x", "utf-8"));
						// Root passed in the 'wrong' case; canonicalising the root maps it to the
						// real on-disk case, so its own descendant is still admitted.
						expect(ctx.ctrl.$isResolvedPathInside(real & "/file.txt", base & "/app")).toBeTrue();
					} finally {
						$removeTree(base);
					}
				});

				it("rejects a symlink into a sibling whose name contains a backslash (POSIX filename byte)", function() {
					// A backslash is a legal filename byte on POSIX, not a separator. A distinct
					// sibling dir named "App\outside" must not be folded into the root "App". Skip
					// on Windows (backslash IS the separator there) and RustCFML (no symlinks).
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); }
					if (CreateObject("java", "java.io.File").separator == "\") { skip("backslash is the native separator on Windows"); }
					var base = GetTempDirectory() & "pc-bs-" & CreateUUID();
					var parent = base & "/App";
					var outside = base & "/App\outside";
					try {
						// Create dirs via java.io.File (CFML FileWrite mangles a backslash path on
						// Lucee). The leaf file need not exist: getCanonicalPath resolves the symlink
						// directory and appends the non-existent leaf lexically.
						CreateObject("java", "java.io.File").init(parent).mkdirs();
						CreateObject("java", "java.io.File").init(outside).mkdirs();
						$createSymlink(outside, parent & "/link");
						expect(ctx.ctrl.$isResolvedPathInside(parent & "/link/secret.txt", parent)).toBeFalse();
					} finally {
						$removeTree(base);
					}
				});
			});

			// ---- guard: PackageLoader.cfc $mappingPathEscapesPackage ------------
			describe("$mappingPathEscapesPackage (PackageLoader)", function() {
				it("does not flag a descendant as escaping", function() {
					var loader = new wheels.PackageLoader(vendorPath = GetTempDirectory(), componentPrefix = "vendor");
					var pkg = GetTempDirectory() & "pc-pkg-" & CreateUUID();
					expect(loader.$mappingPathEscapesPackage(pkg, pkg & "/sub/file.cfc")).toBeFalse();
				});

				it("flags a case-distinct sibling as escaping (synthetic, all engines)", function() {
					var loader = new wheels.PackageLoader(vendorPath = GetTempDirectory(), componentPrefix = "vendor");
					var base = GetTempDirectory() & "pc-pkgcase-" & CreateUUID();
					expect(loader.$mappingPathEscapesPackage(base & "/Pkg", base & "/pkg/evil.cfc")).toBeTrue();
				});

				it("flags an existing symlink into a case-distinct sibling (case-sensitive FS)", function() {
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); }
					if (!$caseSensitiveFS()) { skip("needs a case-sensitive filesystem"); }
					var base = GetTempDirectory() & "pc-pkgsym-" & CreateUUID();
					var pkg = base & "/Pkg";
					var outside = base & "/pkg";
					try {
						DirectoryCreate(pkg);
						DirectoryCreate(outside);
						FileWrite(outside & "/pwned.cfc", CharsetDecode("x", "utf-8"));
						$createSymlink(outside, pkg & "/link");
						var loader = new wheels.PackageLoader(vendorPath = GetTempDirectory(), componentPrefix = "vendor");
						expect(loader.$mappingPathEscapesPackage(pkg, pkg & "/link/pwned.cfc")).toBeTrue();
					} finally {
						$removeTree(base);
					}
				});
			});

			// ---- guard: global/tags.cfm $zipEntryEscapesDestination -------------
			describe("$zipEntryEscapesDestination (tags)", function() {
				it("does not flag a plain entry under the destination", function() {
					var dest = GetTempDirectory() & "pc-zip-" & CreateUUID();
					try {
						DirectoryCreate(dest);
						expect(g.$zipEntryEscapesDestination(dest, "sub/file.txt")).toBeFalse();
					} finally {
						$removeTree(dest);
					}
				});

				it("flags an entry resolving through a symlink into a case-distinct sibling (case-sensitive FS)", function() {
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); }
					if (!$caseSensitiveFS()) { skip("needs a case-sensitive filesystem"); }
					var base = GetTempDirectory() & "pc-zipsym-" & CreateUUID();
					var dest = base & "/Dest";
					var outside = base & "/dest";
					try {
						DirectoryCreate(dest);
						DirectoryCreate(outside);
						$createSymlink(outside, dest & "/link");
						expect(g.$zipEntryEscapesDestination(dest, "link/evil.txt")).toBeTrue();
					} finally {
						$removeTree(base);
					}
				});
			});

			// ---- guard: Public.cfc fixed-root resolvers (symlink escape) --------
			describe("Fixed-root Public.cfc guards (existing-symlink escape, case-sensitive FS)", function() {
				it("$resolveDevAssetPath rejects a symlink into a case-distinct sibling of the assets root", function() {
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); }
					var made = {dirs = [], links = []};
					try {
						var publicCfc = createObject("component", "wheels.Public").$init();
						var root = $canon(ExpandPath("/wheels/public/assets/"));
						if (!DirectoryExists(root)) { skip("root directory not present on disk"); }
						if (!$caseSensitiveAt($parentDir(root))) { skip("root is on a case-insensitive filesystem"); }
						var sibling = $caseVariantSibling(root);
						var linkPath = root & "/pcdevasset.css";
						if (!Len(sibling)) { skip("root basename is caseless — no case-distinct sibling"); }
						if (DirectoryExists(sibling) || FileExists(linkPath)) { skip("fixture sibling/link path already exists — refusing to touch it"); }
						DirectoryCreate(sibling);
						ArrayAppend(made.dirs, sibling);
						FileWrite(sibling & "/secret.css", CharsetDecode("x", "utf-8"));
						$createSymlink(sibling & "/secret.css", linkPath);
						ArrayAppend(made.links, linkPath);
						expect(publicCfc.$resolveDevAssetPath("pcdevasset.css")).toBe("");
					} finally {
						$cleanup(made);
					}
				});

				it("$resolveGuideImagePath rejects a symlink into a case-distinct sibling of the gitbook assets root", function() {
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); }
					var made = {dirs = [], links = []};
					try {
						var publicCfc = createObject("component", "wheels.Public").$init();
						var rootRaw = ExpandPath("/wheels/docs/src/.gitbook/assets/");
						var anchor = $nearestExistingAncestor(rootRaw);
						if (!Len(anchor)) { skip("no existing ancestor to anchor the fixture"); }
						if (!$caseSensitiveAt(anchor)) { skip("root is on a case-insensitive filesystem"); }
						var firstMissing = $firstMissingAncestor(rootRaw);
						$mkdirs(rootRaw);
						if (Len(firstMissing)) { ArrayAppend(made.dirs, firstMissing); }
						var root = $canon(rootRaw);
						var sibling = $caseVariantSibling(root);
						var linkPath = root & "/pcguide.png";
						if (!Len(sibling)) { skip("root basename is caseless — no case-distinct sibling"); }
						if (DirectoryExists(sibling) || FileExists(linkPath)) { skip("fixture sibling/link path already exists — refusing to touch it"); }
						DirectoryCreate(sibling);
						ArrayAppend(made.dirs, sibling);
						FileWrite(sibling & "/secret.png", CharsetDecode("x", "utf-8"));
						$createSymlink(sibling & "/secret.png", linkPath);
						ArrayAppend(made.links, linkPath);
						expect(publicCfc.$resolveGuideImagePath("pcguide.png")).toBe("");
					} finally {
						$cleanup(made);
					}
				});

				it("$resolveGuideImagePath rejects a symlink into a same-case prefix sibling (assets vs assets-extra)", function() {
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); } // symlink needed; not a case issue
					var made = {dirs = [], links = []};
					try {
						var publicCfc = createObject("component", "wheels.Public").$init();
						var rootRaw = ExpandPath("/wheels/docs/src/.gitbook/assets/");
						var anchor = $nearestExistingAncestor(rootRaw);
						if (!Len(anchor)) { skip("no existing ancestor to anchor the fixture"); }
						var firstMissing = $firstMissingAncestor(rootRaw);
						$mkdirs(rootRaw);
						if (Len(firstMissing)) { ArrayAppend(made.dirs, firstMissing); }
						var root = REReplace(Replace($canon(rootRaw), "\", "/", "all"), "/+$", "");
						var sibling = root & "-extra";
						var linkPath = root & "/pcprefix.png";
						if (DirectoryExists(sibling) || FileExists(linkPath)) { skip("fixture sibling/link path already exists — refusing to touch it"); }
						DirectoryCreate(sibling);
						ArrayAppend(made.dirs, sibling);
						FileWrite(sibling & "/secret.png", CharsetDecode("x", "utf-8"));
						$createSymlink(sibling & "/secret.png", linkPath);
						ArrayAppend(made.links, linkPath);
						expect(publicCfc.$resolveGuideImagePath("pcprefix.png")).toBe("");
					} finally {
						$cleanup(made);
					}
				});

				it("$resolveDocsPath rejects a symlink into a case-distinct sibling of the site root", function() {
					// Uses the docsBundlePath config override to point the site root at a
					// self-owned temp bundle under GetTempDirectory() (case-sensitive in the
					// container), so this runs everywhere — no real docs bundle required, and
					// no mutation of the framework tree. Config is restored in the finally.
					if (g.$engineAdapter().isRustCFML()) { skip("RustCFML does not resolve symlinks"); }
					if (!$caseSensitiveFS()) { skip("needs a case-sensitive filesystem"); }
					var made = {dirs = [], links = []};
					var hadKey = StructKeyExists(application.wheels, "docsBundlePath");
					var oldVal = hadKey ? application.wheels.docsBundlePath : "";
					try {
						var bundle = REReplace(Replace(GetTempDirectory(), "\", "/", "all"), "/+$", "") & "/pc-docs-" & CreateUUID();
						DirectoryCreate(bundle);
						ArrayAppend(made.dirs, bundle);
						DirectoryCreate(bundle & "/guides");
						DirectoryCreate(bundle & "/GUIDES"); // case-distinct sibling of the site root
						FileWrite(bundle & "/guides/legit.html", CharsetDecode("ok", "utf-8"));
						FileWrite(bundle & "/GUIDES/secret.html", CharsetDecode("x", "utf-8"));
						$createSymlink(bundle & "/GUIDES/secret.html", bundle & "/guides/pcdocs.html");
						ArrayAppend(made.links, bundle & "/guides/pcdocs.html");
						application.wheels.docsBundlePath = bundle;
						var publicCfc = createObject("component", "wheels.Public").$init();
						// Positive control: the override + bundle must resolve a legit in-root file,
						// so a bare "" from the escape case can't be a vacuous no-bundle result.
						expect(Len(publicCfc.$resolveDocsPath("guides", "legit.html")) > 0).toBeTrue(
							"docsBundlePath override must resolve a legitimate in-root file"
						);
						expect(publicCfc.$resolveDocsPath("guides", "pcdocs.html")).toBe("");
					} finally {
						if (hadKey) {
							application.wheels.docsBundlePath = oldVal;
						} else {
							StructDelete(application.wheels, "docsBundlePath");
						}
						$cleanup(made);
					}
				});
			});

			// ---- guard: Public.cfc $cliResolveDumpPath --------------------------
			describe("$cliResolveDumpPath (dump output confinement)", function() {
				it("rejects an output that resolves into a case-distinct sibling of the web root", function() {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var rootCanon = Replace(CreateObject("java", "java.io.File").init(ExpandPath("/")).getCanonicalPath(), "\", "/", "all");
					var baseName = ListLast(rootCanon, "/");
					if (!Len(baseName)) { skip("web root has no basename"); }
					// Pick a case-DISTINCT spelling with Compare() (case-sensitive): CFML `==`
					// is case-insensitive, so `baseName == UCase(baseName)` is always true.
					var variant = "";
					if (Compare(baseName, UCase(baseName)) != 0) {
						variant = UCase(baseName);
					} else if (Compare(baseName, LCase(baseName)) != 0) {
						variant = LCase(baseName);
					} else {
						skip("web root basename is caseless — no case-distinct scenario");
					}
					expect(publicCfc.$cliResolveDumpPath("../" & variant & "/dump.sql")).toBe("");
				});
			});

		});
	}

	// ---- helpers ------------------------------------------------------------

	// Case-sensitivity of the container-local temp filesystem (where the /tmp-based
	// fixtures live). Behavioural probe, never an OS-name check.
	function $caseSensitiveFS() {
		return $caseSensitiveAt(GetTempDirectory());
	}

	// Case-sensitivity of the filesystem that holds `dir`. Creates a self-owned,
	// UUID-named probe directory, tests it, and removes only that probe.
	function $caseSensitiveAt(required string dir) {
		var probe = REReplace(Replace(arguments.dir, "\", "/", "all"), "/+$", "") & "/pc-fsprobe-" & CreateUUID();
		var sensitive = false;
		try {
			DirectoryCreate(probe);
			DirectoryCreate(probe & "/AAAA");
			sensitive = !DirectoryExists(probe & "/aaaa");
		} catch (any e) {
			sensitive = false;
		} finally {
			try {
				if (DirectoryExists(probe)) {
					DirectoryDelete(probe, true);
				}
			} catch (any e) {
			}
		}
		return sensitive;
	}

	function $canon(required string path) {
		return CreateObject("java", "java.io.File").init(arguments.path).getCanonicalPath();
	}

	function $parentDir(required string path) {
		var r = REReplace(Replace(arguments.path, "\", "/", "all"), "/+$", "");
		var base = ListLast(r, "/");
		return Left(r, Len(r) - Len(base) - 1);
	}

	// A case-distinct sibling of `root` (same parent, basename re-cased), or "" when the
	// basename is caseless. Compare() is case-sensitive; CFML `==` is not.
	function $caseVariantSibling(required string root) {
		var r = REReplace(Replace(arguments.root, "\", "/", "all"), "/+$", "");
		var base = ListLast(r, "/");
		var parent = Left(r, Len(r) - Len(base) - 1);
		var variant = "";
		if (Compare(base, UCase(base)) != 0) {
			variant = UCase(base);
		} else if (Compare(base, LCase(base)) != 0) {
			variant = LCase(base);
		} else {
			return "";
		}
		return parent & "/" & variant;
	}

	// The topmost ancestor of `path` that does not yet exist (what $mkdirs would create
	// first), so cleanup can remove exactly the chain this test made. "" if all exist.
	function $firstMissingAncestor(required string path) {
		var p = REReplace(Replace(arguments.path, "\", "/", "all"), "/+$", "");
		var segs = ListToArray(p, "/", false);
		var acc = "";
		for (var i = 1; i <= ArrayLen(segs); i++) {
			acc = acc & "/" & segs[i];
			if (!DirectoryExists(acc)) {
				return acc;
			}
		}
		return "";
	}

	function $nearestExistingAncestor(required string path) {
		var p = REReplace(Replace(arguments.path, "\", "/", "all"), "/+$", "");
		while (Len(p) > 1 && !DirectoryExists(p)) {
			var base = ListLast(p, "/");
			p = Left(p, Len(p) - Len(base) - 1);
			if (!Len(p)) {
				p = "/";
			}
		}
		return DirectoryExists(p) ? p : "";
	}

	function $mkdirs(required string path) {
		var f = CreateObject("java", "java.io.File").init(arguments.path);
		if (!f.exists()) {
			f.mkdirs();
		}
	}

	// Remove ONLY the paths a test recorded creating: symlinks first (unlink, never the
	// target), then recorded dirs. Never touches an unrecorded or pre-existing path.
	function $cleanup(required struct made) {
		for (var lk in arguments.made.links) {
			$deleteQuietly(lk);
		}
		for (var i = ArrayLen(arguments.made.dirs); i >= 1; i--) {
			try {
				if (DirectoryExists(arguments.made.dirs[i])) {
					DirectoryDelete(arguments.made.dirs[i], true);
				}
			} catch (any e) {
			}
		}
	}

	function $deleteQuietly(required string path) {
		try {
			CreateObject("java", "java.nio.file.Files").deleteIfExists(
				CreateObject("java", "java.io.File").init(arguments.path).toPath()
			);
		} catch (any e) {
		}
	}

	// java.nio symbolic link, link path first (explicit empty FileAttribute[] so the
	// varargs method binds on Lucee — see #4070).
	function $createSymlink(required string target, required string linkPath) {
		var faType = CreateObject("java", "java.lang.Class").forName("java.nio.file.attribute.FileAttribute");
		var noAttrs = CreateObject("java", "java.lang.reflect.Array").newInstance(faType, 0);
		CreateObject("java", "java.nio.file.Files").createSymbolicLink(
			CreateObject("java", "java.io.File").init(arguments.linkPath).toPath(),
			CreateObject("java", "java.io.File").init(arguments.target).toPath(),
			noAttrs
		);
	}

}

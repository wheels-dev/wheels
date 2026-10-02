component extends="wheels.WheelsTest" {

	function run() {

		describe("Storage disk abstraction", function() {

			// ---- S3Signer (SigV4) -------------------------------------------

			describe("S3Signer.presignGetUrl()", function() {

				it("reproduces the AWS-documented SigV4 presigned-GET test vector", function() {
					// Official example from AWS "Authenticating Requests: Using Query
					// Parameters (AWS Signature Version 4)". Pinning the published
					// timestamp makes the signature deterministic.
					var signer = new wheels.storage.S3Signer(
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
						region = "us-east-1",
						bucket = "examplebucket",
						endpoint = "examplebucket.s3.amazonaws.com"
					);

					// NB: never name this local `url` — it is a CFML reserved scope and
					// `expect(url)` would read the URL scope struct, not the return value
					// (Anti-Pattern #11). Use `presigned` throughout this spec.
					var presigned = signer.presignGetUrl(
						key = "test.txt",
						expiresIn = 86400,
						amzDate = "20130524T000000Z"
					);

					expect(presigned).toInclude(
						"X-Amz-Signature=aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404"
					);
					expect(presigned).toInclude("https://examplebucket.s3.amazonaws.com/test.txt?");
					expect(presigned).toInclude("X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request");
					expect(presigned).toInclude("X-Amz-Expires=86400");
				});

				it("preserves slashes in the object key path but encodes the credential", function() {
					var signer = new wheels.storage.S3Signer(
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
						region = "us-east-1",
						bucket = "examplebucket",
						endpoint = "examplebucket.s3.amazonaws.com"
					);
					var presigned = signer.presignGetUrl(key = "reports/2026/q3.pdf", amzDate = "20130524T000000Z");
					expect(presigned).toInclude("/reports/2026/q3.pdf?");
				});

			});

			describe("S3Signer.signedHeaders()", function() {

				it("returns a SigV4 Authorization header plus the content/date headers", function() {
					var signer = new wheels.storage.S3Signer(
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
						region = "us-east-1",
						bucket = "examplebucket"
					);
					var headers = signer.signedHeaders(method = "GET", key = "test.txt", amzDate = "20130524T000000Z");

					expect(headers).toHaveKey("Authorization");
					expect(headers).toHaveKey("x-amz-content-sha256");
					expect(headers).toHaveKey("x-amz-date");
					expect(headers.Authorization).toInclude("AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request");
					expect(headers.Authorization).toInclude("SignedHeaders=host;x-amz-content-sha256;x-amz-date");
					expect(headers.Authorization).toInclude("Signature=");
				});

				it("includes x-amz-acl in the signed header set when acl is passed", function() {
					var signer = new wheels.storage.S3Signer(
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
						region = "us-east-1",
						bucket = "examplebucket"
					);
					var headers = signer.signedHeaders(
						method = "PUT",
						key = "a.txt",
						payload = "x",
						amzDate = "20130524T000000Z",
						acl = "public-read"
					);

					expect(headers).toHaveKey("x-amz-acl");
					expect(headers["x-amz-acl"]).toBe("public-read");
					expect(headers.Authorization).toInclude("SignedHeaders=host;x-amz-acl;x-amz-content-sha256;x-amz-date");
				});

				it("reproduces the AWS-documented SigV4 GET Object header-auth test vector", function() {
					var signer = new wheels.storage.S3Signer(
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
						region = "us-east-1",
						bucket = "examplebucket",
						endpoint = "examplebucket.s3.amazonaws.com"
					);
					var headers = signer.signedHeaders(
						method = "GET",
						key = "test.txt",
						payload = "",
						amzDate = "20130524T000000Z",
						range = "bytes=0-9"
					);

					expect(headers["x-amz-content-sha256"]).toBe(
						"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
					);
					expect(headers.Authorization).toInclude("SignedHeaders=host;range;x-amz-content-sha256;x-amz-date");
					expect(headers.Authorization).toInclude("Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41");
				});

			});

			// ---- LocalDisk --------------------------------------------------

			describe("LocalDisk", function() {

				var ctx = {root = ""};

				beforeEach(function() {
					// $tempPath(), not GetTempDirectory() & ...: RustCFML v0.637.0 returns
					// "/tmp" without a trailing separator on Linux (RustCFML/RustCFML#380),
					// which puts the join at the filesystem root. Same fix as #3444.
					ctx.root = $tempPath("wheels-storage-spec-" & CreateUUID());
					disk = new wheels.storage.drivers.LocalDisk(config = {
						root = ctx.root,
						urlPrefix = "/uploads",
						signingKey = "a-test-signing-key-padded-to-32-bytes!!"
					});
				});

				afterEach(function() {
					if (DirectoryExists(ctx.root)) {
						DirectoryDelete(ctx.root, true);
					}
				});

				it("stores, reports existence, reads back, and deletes an object", function() {
					expect(disk.exists("a/b/hello.txt")).toBeFalse();

					disk.put(key = "a/b/hello.txt", content = "hello world");
					expect(disk.exists("a/b/hello.txt")).toBeTrue();

					var content = disk.get("a/b/hello.txt");
					expect(ToString(content)).toBe("hello world");

					expect(disk.delete("a/b/hello.txt")).toBeTrue();
					expect(disk.exists("a/b/hello.txt")).toBeFalse();
					// Deleting an absent key reports false, never throws.
					expect(disk.delete("a/b/hello.txt")).toBeFalse();
				});

				it("throws Wheels.Storage.NotFound reading a missing key", function() {
					expect(function() {
						disk.get("nope.txt");
					}).toThrow("Wheels.Storage.NotFound");
				});

				it("rejects path-traversal keys", function() {
					expect(function() {
						disk.put(key = "../escape.txt", content = "x");
					}).toThrow("Wheels.Storage.InvalidKey");
				});

				it("throws InvalidKey for empty and slash-only keys", function() {
					expect(function() {
						disk.$resolve("");
					}).toThrow("Wheels.Storage.InvalidKey");
					expect(function() {
						disk.$resolve("/");
					}).toThrow("Wheels.Storage.InvalidKey");
					expect(function() {
						disk.$resolve("///");
					}).toThrow("Wheels.Storage.InvalidKey");

					expect(function() {
						disk.get("");
					}).toThrow("Wheels.Storage.InvalidKey");
					expect(function() {
						disk.put(key = "", content = "x");
					}).toThrow("Wheels.Storage.InvalidKey");
					expect(function() {
						disk.put(key = "/", content = "x");
					}).toThrow("Wheels.Storage.InvalidKey");
				});

				it("follows a symlink under root to a file outside (Find('..') does not see the hop)", function() {
					var outside = $tempPath("wheels-storage-outside-" & CreateUUID());
					var linkPath = ctx.root & "/link";
					DirectoryCreate(outside);
					if (!DirectoryExists(ctx.root)) {
						DirectoryCreate(ctx.root);
					}
					FileWrite(outside & "/secret.txt", CharsetDecode("outside-secret", "utf-8"));
					$createSymlink(outside, linkPath);
					try {
						expect(function() {
							disk.exists("link/secret.txt");
						}).notToThrow(type = "Wheels.Storage.InvalidKey");
						expect(ToString(disk.get("link/secret.txt"))).toBe("outside-secret");
					} finally {
						$deleteSymlink(linkPath);
						if (DirectoryExists(outside)) {
							DirectoryDelete(outside, true);
						}
					}
				});

				it(
					"opt-in resolveSymlinks rejects a symlink escaping root (##4020), or fails closed at init where the runtime can't resolve symlinks",
					function() {
						var strictRoot = $tempPath("wheels-storage-strict-" & CreateUUID());
						if (!DirectoryExists(strictRoot)) {
							DirectoryCreate(strictRoot);
						}
						// Constructing the disk runs the behavioural capability probe. On a runtime
						// that resolves symlinks (a real JVM) it succeeds; on one that does not
						// (RustCFML, or Windows without symlink privilege) init fails closed with
						// Wheels.Storage.InvalidConfiguration rather than silently enabling an
						// ineffective strict mode. A bare `var` struct field (not a `local.`-scoped
						// one) is the only shape that persists a value written inside a catch on
						// BoxLang (cross-engine invariant 11).
						var guard = {failedClosed = false, type = ""};
						var strictDisk = "";
						try {
							strictDisk = new wheels.storage.drivers.LocalDisk(config = {
								root = strictRoot,
								urlPrefix = "/uploads",
								signingKey = "a-test-signing-key-padded-to-32-bytes!!",
								resolveSymlinks = true
							});
						} catch (any e) {
							guard.failedClosed = true;
							guard.type = e.type;
						}
						if (guard.failedClosed) {
							expect(guard.type).toBe("Wheels.Storage.InvalidConfiguration");
							if (DirectoryExists(strictRoot)) {
								DirectoryDelete(strictRoot, true);
							}
							return;
						}
						// Resolving runtime: a symlink planted under root that targets outside is
						// now REJECTED, not followed (contrast the default-mode spec above).
						var outside = $tempPath("wheels-storage-strict-outside-" & CreateUUID());
						var linkPath = strictRoot & "/link";
						DirectoryCreate(outside);
						FileWrite(outside & "/secret.txt", CharsetDecode("outside-secret", "utf-8"));
						$createSymlink(outside, linkPath);
						try {
							expect(function() {
								strictDisk.exists("link/secret.txt");
							}).toThrow("Wheels.Storage.InvalidKey");
							expect(function() {
								strictDisk.get("link/secret.txt");
							}).toThrow("Wheels.Storage.InvalidKey");
						} finally {
							$deleteSymlink(linkPath);
							if (DirectoryExists(outside)) {
								DirectoryDelete(outside, true);
							}
							if (DirectoryExists(strictRoot)) {
								DirectoryDelete(strictRoot, true);
							}
						}
					}
				);

				it("opt-in resolveSymlinks still stores and serves a legitimate file (##4020)", function() {
					var strictRoot = $tempPath("wheels-storage-strict-ok-" & CreateUUID());
					if (!DirectoryExists(strictRoot)) {
						DirectoryCreate(strictRoot);
					}
					var guard = {failedClosed = false};
					var strictDisk = "";
					try {
						strictDisk = new wheels.storage.drivers.LocalDisk(config = {
							root = strictRoot,
							signingKey = "a-test-signing-key-padded-to-32-bytes!!",
							resolveSymlinks = true
						});
					} catch (any e) {
						guard.failedClosed = true;
					}
					try {
						// On a non-resolving runtime the fail-closed init is covered by the spec
						// above; here we only assert the happy path on a resolving one.
						if (guard.failedClosed) {
							return;
						}
						strictDisk.put(key = "docs/report.txt", content = "ok");
						expect(strictDisk.exists("docs/report.txt")).toBeTrue();
						expect(ToString(strictDisk.get("docs/report.txt"))).toBe("ok");
					} finally {
						if (DirectoryExists(strictRoot)) {
							DirectoryDelete(strictRoot, true);
						}
					}
					});

				it("rejects a non-boolean resolveSymlinks config with InvalidConfiguration (##4020)", function() {
					var strictRoot = $tempPath("wheels-storage-nonbool-" & CreateUUID());
					if (!DirectoryExists(strictRoot)) {
						DirectoryCreate(strictRoot);
					}
					try {
						expect(function() {
							new wheels.storage.drivers.LocalDisk(config = {root = strictRoot, resolveSymlinks = "maybe"});
						}).toThrow("Wheels.Storage.InvalidConfiguration");
					} finally {
						if (DirectoryExists(strictRoot)) {
							DirectoryDelete(strictRoot, true);
						}
					}
				});

				it(
					"opt-in resolveSymlinks rejects a symlink to a case-distinct sibling on a case-sensitive filesystem (##4020)",
					function() {
						// Only an escape where the filesystem is case-SENSITIVE: there Store and store
						// are different directories, so a symlink to the lower-cased sibling leaves the
						// root. getCanonicalPath reports real on-disk case, so the containment compare
						// must be exact. Detect case sensitivity behaviourally, never by OS name.
						var base = $tempPath("wheels-storage-case-" & CreateUUID());
						DirectoryCreate(base);
						try {
							DirectoryCreate(base & "/CASEPROBE");
							if (DirectoryExists(base & "/caseprobe")) {
								return; // case-insensitive FS: the sibling is the same dir, not an escape
							}
							var strictRoot = base & "/Store";
							var outside = base & "/store";
							DirectoryCreate(strictRoot);
							DirectoryCreate(outside);
							FileWrite(outside & "/secret.txt", CharsetDecode("outside-secret", "utf-8"));
							var guard = {failedClosed = false};
							var strictDisk = "";
							try {
								strictDisk = new wheels.storage.drivers.LocalDisk(config = {
									root = strictRoot,
									signingKey = "a-test-signing-key-padded-to-32-bytes!!",
									resolveSymlinks = true
								});
							} catch (any e) {
								guard.failedClosed = true;
							}
							if (guard.failedClosed) {
								return; // non-resolving runtime: covered by the fail-closed spec
							}
							var linkPath = strictRoot & "/link";
							$createSymlink(outside, linkPath);
							try {
								expect(function() {
									strictDisk.exists("link/secret.txt");
								}).toThrow("Wheels.Storage.InvalidKey");
							} finally {
								$deleteSymlink(linkPath);
							}
						} finally {
							if (DirectoryExists(base)) {
								DirectoryDelete(base, true);
							}
						}
					}
				);

				it("creates the probe symlink through java.nio (not ln) where the runtime provides it (##4070)", function() {
					var base = $tempPath("wheels-storage-nio-" & CreateUUID());
					DirectoryCreate(base);
					try {
						CreateObject("java", "java.io.File").init(base & "/target").mkdirs();
						// Does this runtime provide Files.createSymbolicLink? RustCFML does not shim it.
						// Probe with the explicit empty FileAttribute[] — the same form LocalDisk uses.
						var nio = {available = false};
						try {
							var faType = CreateObject("java", "java.lang.Class").forName("java.nio.file.attribute.FileAttribute");
							var noAttrs = CreateObject("java", "java.lang.reflect.Array").newInstance(faType, 0);
							CreateObject("java", "java.nio.file.Files").createSymbolicLink(
								CreateObject("java", "java.io.File").init(base & "/probe").toPath(),
								CreateObject("java", "java.io.File").init(base & "/target").toPath(),
								noAttrs
							);
							nio.available = true;
						} catch (any e) {
							nio.available = false;
						}
						if (nio.available) {
							// Where the runtime provides createSymbolicLink, the driver must bind it through
							// java.nio and NOT silently fall back to `ln` (which may be absent, e.g. Windows).
							var disk = new wheels.storage.drivers.LocalDisk(config = {
								root = base,
								signingKey = "a-test-signing-key-padded-to-32-bytes!!"
							});
							expect(disk.$tryCreateSymbolicLinkNio(target = base & "/target", link = base & "/lnk")).toBeTrue(
								"the probe must create the symlink via java.nio where the runtime provides it, not fall back to ln"
							);
						}
					} finally {
						// Remove the symlinks explicitly first: a recursive DirectoryDelete over a
						// directory that contains symlinks errors on Adobe. ($deleteSymlink no-ops
						// when the path isn't a symlink, so unconditional calls are safe.)
						$deleteSymlink(base & "/probe");
						$deleteSymlink(base & "/lnk");
						if (DirectoryExists(base)) {
							DirectoryDelete(base, true);
						}
					}
				});

				it("accepts a key whose segment merely contains '..' (##3912)", function() {
					// Two dots INSIDE a segment are not traversal; the name keeps real chars.
					disk.put(key = "reports/q3..final.pdf", content = "report");
					expect(disk.exists("reports/q3..final.pdf")).toBeTrue();
					expect(ToString(disk.get("reports/q3..final.pdf"))).toBe("report");

					disk.put(key = "a..b.txt", content = "ab");
					expect(ToString(disk.get("a..b.txt"))).toBe("ab");

					disk.put(key = "v1..2/notes.txt", content = "v");
					expect(ToString(disk.get("v1..2/notes.txt"))).toBe("v");
				});

				it("normalises leading, trailing, double and UNC slashes to a key relative to root (##3912)", function() {
					// Every key is relative to the root, so slash runs carry no meaning.
					expect(disk.$resolve("/avatars/1.png")).toBe(disk.$resolve("avatars/1.png"));
					expect(disk.$resolve("a//b.txt")).toBe(disk.$resolve("a/b.txt"));
					expect(disk.$resolve("dir/x/")).toBe(disk.$resolve("dir/x"));
					// UNC / network prefixes normalise to a relative key under root, never escape it.
					expect(disk.$resolve("//server/share/x.txt")).toBe(disk.$resolve("server/share/x.txt"));
					expect(disk.$resolve("\\server\share\x.txt")).toBe(disk.$resolve("server/share/x.txt"));
					// Mixed separators resolve the same as all-forward-slash.
					expect(disk.$resolve("a\b/c.txt")).toBe(disk.$resolve("a/b/c.txt"));
					// Everything stays under the configured root.
					expect(disk.$resolve("/avatars/1.png")).toInclude(ctx.root);

					// "/avatars/1.png" and "avatars/1.png" address the same object.
					disk.put(key = "/avatars/1.png", content = "pixels");
					expect(ToString(disk.get("avatars/1.png"))).toBe("pixels");
				});

				it("treats percent-encoded traversal as a literal segment, never decoding it (##3912)", function() {
					// $resolve does not url-decode, so "%2e%2e%2f" can never become "../".
					var resolved = disk.$resolve("files/%2e%2e%2fsecret");
					expect(resolved).toInclude("%2e%2e%2fsecret");
					expect(resolved).toInclude(ctx.root);
					disk.put(key = "files/%2e%2e%2fsecret", content = "literal");
					expect(ToString(disk.get("files/%2e%2e%2fsecret"))).toBe("literal");
				});

				it("rejects traversal, dot/space-only segments and drive-letter keys (##3912)", function() {
					// cfformat-ignore-start
					var rejected = [
						"../escape.txt",         // parent traversal
						"..\escape.txt",         // Windows-style backslash traversal
						"a/../b.txt",            // mid-path traversal
						"foo/../../etc/passwd",  // deep traversal
						"/../x.txt",             // leading-slash traversal
						"reports/.. /x.txt",     // ".. " — Windows strips the trailing space to ".."
						"reports/ ../x.txt",     // " .." — leading space
						"foo/. ./bar.txt",       // ". ." — dots and spaces only
						"foo/.../bar.txt",       // "..." — dots only
						"foo/   /bar.txt",       // whitespace-only segment
						"C:/Windows/System32",   // drive-letter prefix
						"/C:/x.txt",             // drive letter after a leading slash
						"C:evil.txt"             // drive-relative prefix
					];
					// cfformat-ignore-end
					for (var badKey in rejected) {
						expect(function() {
							disk.$resolve(badKey);
						}).toThrow(type = "Wheels.Storage.InvalidKey", message = "[#badKey#] must be rejected as an invalid key");
					}
				});

				it("builds a public url from the urlPrefix", function() {
					expect(disk.url("a/b.png")).toBe("/uploads/a/b.png");
				});

				it("rfc3986-encodes spaces and reserved characters in url() and signedUrl()", function() {
					expect(disk.url("my docs/q3 report.pdf")).toBe("/uploads/my%20docs/q3%20report.pdf");
					expect(disk.url("a+b*.txt")).toBe("/uploads/a%2Bb%2A.txt");

					var signed = disk.signedUrl(key = "my docs/q3 report.pdf", expiresIn = 600);
					expect(signed).toInclude("/uploads/my%20docs/q3%20report.pdf?");
					expect(signed).toInclude("signature=");

					var qs = ListLast(signed, "?");
					var sig = ReReplace(qs, ".*signature=([a-f0-9]+).*", "\1");
					var exp = Val(ReReplace(qs, ".*expires=([0-9]+).*", "\1"));
					expect(disk.verifySignature(key = "my docs/q3 report.pdf", expires = exp, signature = sig)).toBeTrue();
				});

				it("builds a signed url whose token round-trips through verifySignature", function() {
					var signed = disk.signedUrl(key = "a/b.png", expiresIn = 600);
					expect(signed).toInclude("/uploads/a/b.png?expires=");
					expect(signed).toInclude("signature=");

					var expires = ListFirst(ListLast(signed, "="), "&");
					var qs = ListLast(signed, "?");
					var sig = ReReplace(qs, ".*signature=([a-f0-9]+).*", "\1");
					var exp = Val(ReReplace(qs, ".*expires=([0-9]+).*", "\1"));

					expect(disk.verifySignature(key = "a/b.png", expires = exp, signature = sig)).toBeTrue();
					// Tampering with the key invalidates the token.
					expect(disk.verifySignature(key = "other.png", expires = exp, signature = sig)).toBeFalse();
				});

				it("rejects an expired signed url", function() {
					var exp = 1;
					var sig = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef";
					expect(disk.verifySignature(key = "a/b.png", expires = exp, signature = sig)).toBeFalse();
				});

				it("throws InvalidExpiresIn for non-positive or over-max expiresIn", function() {
					expect(function() {
						disk.signedUrl(key = "a/b.png", expiresIn = 0);
					}).toThrow("Wheels.Storage.InvalidExpiresIn");
					expect(function() {
						disk.signedUrl(key = "a/b.png", expiresIn = -10);
					}).toThrow("Wheels.Storage.InvalidExpiresIn");
					expect(function() {
						disk.signedUrl(key = "a/b.png", expiresIn = 604801);
					}).toThrow("Wheels.Storage.InvalidExpiresIn");
				});

				it("accepts expiresIn at the documented bounds", function() {
					var minSigned = disk.signedUrl(key = "a/b.png", expiresIn = 1);
					expect(minSigned).toInclude("expires=");
					var maxSigned = disk.signedUrl(key = "a/b.png", expiresIn = 604800);
					expect(maxSigned).toInclude("expires=");
				});

				it("binds contentDisposition into the signed-url token", function() {
					var signed = disk.signedUrl(key = "a/b.png", expiresIn = 600, contentDisposition = "attachment; filename=safe.png");
					var qs = ListLast(signed, "?");
					var sig = ReReplace(qs, ".*signature=([a-f0-9]+).*", "\1");
					var exp = Val(ReReplace(qs, ".*expires=([0-9]+).*", "\1"));

					// Verifying with the same disposition succeeds...
					expect(disk.verifySignature(key = "a/b.png", expires = exp, signature = sig, contentDisposition = "attachment; filename=safe.png")).toBeTrue();
					// ...but altering the disposition a holder was granted must invalidate the token.
					expect(disk.verifySignature(key = "a/b.png", expires = exp, signature = sig, contentDisposition = "attachment; filename=evil.exe")).toBeFalse();
				});

				it("rejects a wrong-length signature without erroring", function() {
					var signed = disk.signedUrl(key = "a/b.png", expiresIn = 600);
					var qs = ListLast(signed, "?");
					var exp = Val(ReReplace(qs, ".*expires=([0-9]+).*", "\1"));
					// A truncated token must compare false, never throw (length-mismatch path).
					expect(disk.verifySignature(key = "a/b.png", expires = exp, signature = "deadbeef")).toBeFalse();
				});

				it("requires a signingKey to produce a signed url", function() {
					var unsigned = new wheels.storage.drivers.LocalDisk(config = {root = ctx.root, urlPrefix = "/u"});
					expect(function() {
						unsigned.signedUrl(key = "a.png");
					}).toThrow("Wheels.Storage.MissingSigningKey");
				});

				it("verifySignature returns false when no signingKey is configured", function() {
					var unsigned = new wheels.storage.drivers.LocalDisk(config = {root = ctx.root, urlPrefix = "/u"});
					expect(unsigned.verifySignature(key = "a.png", expires = 4102444800, signature = "deadbeef")).toBeFalse();
				});

				it("requires a non-empty root", function() {
					expect(function() {
						new wheels.storage.drivers.LocalDisk(config = {root = ""});
					}).toThrow("Wheels.Storage.InvalidConfiguration");
				});

			});

			// ---- S3Disk (non-network surface) -------------------------------

			describe("S3Disk url helpers", function() {

				var s3 = "";
				beforeEach(function() {
					s3 = new wheels.storage.drivers.S3Disk(config = {
						bucket = "myapp-prod",
						region = "us-east-1",
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
					});
				});

				it("builds a virtual-hosted public url", function() {
					expect(s3.url("avatars/1.png")).toBe("https://myapp-prod.s3.us-east-1.amazonaws.com/avatars/1.png");
				});

				it("rfc3986-encodes spaces in the public url so it matches the signed wire path", function() {
					// The signer signs the encoded canonical path, but the request URL
					// and public url are built from the raw key. They must use the same
					// encoding or S3 returns SignatureDoesNotMatch for keys containing
					// spaces / reserved characters.
					expect(s3.url("my docs/q3 report.pdf"))
						.toBe("https://myapp-prod.s3.us-east-1.amazonaws.com/my%20docs/q3%20report.pdf");
				});

				it("delegates signedUrl to the SigV4 presigner", function() {
					var presigned = s3.signedUrl(key = "avatars/1.png", expiresIn = 120);
					expect(presigned).toInclude("https://myapp-prod.s3.us-east-1.amazonaws.com/avatars/1.png?");
					expect(presigned).toInclude("X-Amz-Algorithm=AWS4-HMAC-SHA256");
					expect(presigned).toInclude("X-Amz-Expires=120");
					expect(presigned).toInclude("X-Amz-Signature=");
				});

				it("throws InvalidExpiresIn for non-positive or over-max expiresIn", function() {
					expect(function() {
						s3.signedUrl(key = "avatars/1.png", expiresIn = 0);
					}).toThrow("Wheels.Storage.InvalidExpiresIn");
					expect(function() {
						s3.signedUrl(key = "avatars/1.png", expiresIn = -10);
					}).toThrow("Wheels.Storage.InvalidExpiresIn");
					expect(function() {
						s3.signedUrl(key = "avatars/1.png", expiresIn = 604801);
					}).toThrow("Wheels.Storage.InvalidExpiresIn");
				});

				it("accepts expiresIn at the documented SigV4 bounds", function() {
					var minSigned = s3.signedUrl(key = "avatars/1.png", expiresIn = 1);
					expect(minSigned).toInclude("X-Amz-Expires=1");
					var maxSigned = s3.signedUrl(key = "avatars/1.png", expiresIn = 604800);
					expect(maxSigned).toInclude("X-Amz-Expires=604800");
				});

				it("requires bucket/region/credentials", function() {
					expect(function() {
						new wheels.storage.drivers.S3Disk(config = {bucket = "b", region = "us-east-1"});
					}).toThrow("Wheels.Storage.InvalidConfiguration");
				});

			});

			describe("S3Disk request failures", function() {

				// Point the disk at a closed local port so every request hits the
				// cfhttp connection-failure path — hermetic and fast (no DNS, no
				// external network; the TCP connect is refused immediately). cfhttp
				// does not set throwOnError, so a failed request returns a
				// non-numeric status whose Val() is 0. The driver MUST treat that as
				// a failure, never as a stored/served object (silent data loss).
				var s3down = "";
				beforeEach(function() {
					s3down = new wheels.storage.drivers.S3Disk(config = {
						bucket = "myapp",
						region = "us-east-1",
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
						endpoint = "127.0.0.1:1",
						timeout = 5
					});
				});

				it("throws instead of silently succeeding when put() cannot reach S3", function() {
					expect(function() {
						s3down.put(key = "x.txt", content = "data");
					}).toThrow("Wheels.Storage.RequestFailed");
				});

				it("throws instead of returning a bogus body when get() cannot reach S3", function() {
					expect(function() {
						s3down.get(key = "x.txt");
					}).toThrow("Wheels.Storage.RequestFailed");
				});

				it("throws instead of reporting existence when exists() cannot reach S3", function() {
					expect(function() {
						s3down.exists(key = "x.txt");
					}).toThrow("Wheels.Storage.RequestFailed");
				});

				it("throws instead of reporting a successful delete when delete() cannot reach S3", function() {
					expect(function() {
						s3down.delete(key = "x.txt");
					}).toThrow("Wheels.Storage.RequestFailed");
				});

			});

			describe("S3Disk delete()", function() {

				it("HEADs first and returns false when the object is missing", function() {
					var stubDisk = new wheels.tests._assets.storage.S3DiskDeleteStub(config = {
						bucket = "myapp",
						region = "us-east-1",
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
					});
					expect(stubDisk.delete("gone.txt")).toBeFalse();
					expect(stubDisk.lastRequest().method).toBe("HEAD");
				});

				it("deletes an existing object and returns true", function() {
					var stubDisk = new wheels.tests._assets.storage.S3DiskDeleteStub(config = {
						bucket = "myapp",
						region = "us-east-1",
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
					});
					stubDisk.seed("here.txt");
					expect(stubDisk.delete("here.txt")).toBeTrue();
					expect(stubDisk.lastRequest().method).toBe("DELETE");
					expect(stubDisk.delete("here.txt")).toBeFalse();
				});

			});

			describe("S3Disk put() ACL", function() {

				it("sends x-amz-acl private by default and public-read for visibility=public", function() {
					var stubDisk = new wheels.tests._assets.storage.S3DiskDeleteStub(config = {
						bucket = "myapp",
						region = "us-east-1",
						accessKeyId = "AKIAIOSFODNN7EXAMPLE",
						secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
					});
					stubDisk.put(key = "a.txt", content = "x");
					expect(stubDisk.lastRequest().headers["x-amz-acl"]).toBe("private");

					stubDisk.put(key = "b.txt", content = "x", visibility = "public");
					expect(stubDisk.lastRequest().headers["x-amz-acl"]).toBe("public-read");
					expect(stubDisk.lastRequest().headers.Authorization).toInclude("SignedHeaders=host;x-amz-acl;x-amz-content-sha256;x-amz-date");
				});

			});

			// ---- StorageManager ---------------------------------------------

			describe("StorageManager", function() {

				var manager = "";
				beforeEach(function() {
					manager = new wheels.storage.StorageManager(config = {
						default = "local",
						disks = {
							local = {driver = "local", root = $tempPath("wheels-storage-mgr"), urlPrefix = "/uploads"},
							s3 = {
								driver = "s3", bucket = "myapp", region = "us-east-1",
								accessKeyId = "AKIAIOSFODNN7EXAMPLE",
								secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
							}
						}
					});
				});

				it("resolves the default disk when no name is given", function() {
					var d = manager.disk();
					expect(d.url("x.png")).toBe("/uploads/x.png");
				});

				it("resolves a named disk", function() {
					var d = manager.disk("s3");
					expect(d.url("x.png")).toBe("https://myapp.s3.us-east-1.amazonaws.com/x.png");
				});

				it("returns the same cached instance across calls", function() {
					expect(manager.disk("local")).toBe(manager.disk("local"));
				});

				it("throws for an unknown disk name", function() {
					expect(function() {
						manager.disk("ftp");
					}).toThrow("Wheels.Storage.UnknownDisk");
				});

				it("throws for a disk configured with an unknown driver", function() {
					var bad = new wheels.storage.StorageManager(config = {
						default = "weird",
						disks = {weird = {driver = "gopher"}}
					});
					expect(function() {
						bad.disk();
					}).toThrow("Wheels.Storage.UnknownDriver");
				});

				it("exposes default disk name and configured disk names", function() {
					expect(manager.getDefaultDiskName()).toBe("local");
					expect(manager.diskNames()).toInclude("local");
					expect(manager.diskNames()).toInclude("s3");
				});

			});

		});

	}

	function $toPath(required string filePath) {
		return CreateObject("java", "java.io.File").init(arguments.filePath).toPath();
	}

	function $createSymlink(required string target, required string link) {
		$deleteSymlink(arguments.link);
		var pb = CreateObject("java", "java.lang.ProcessBuilder")
			.init(["ln", "-s", arguments.target, arguments.link]);
		var proc = pb.start();
		proc.waitFor();
		if (proc.exitValue() != 0) {
			throw(type = "Wheels.Test.SymlinkError", message = "Failed to create symlink: #arguments.link# -> #arguments.target#");
		}
	}

	function $deleteSymlink(required string link) {
		var jFiles = CreateObject("java", "java.nio.file.Files");
		var linkPath = $toPath(arguments.link);
		if (jFiles.isSymbolicLink(linkPath)) {
			jFiles.delete(linkPath);
		}
	}

}

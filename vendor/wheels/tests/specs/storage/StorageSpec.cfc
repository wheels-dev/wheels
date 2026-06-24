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

			});

			// ---- LocalDisk --------------------------------------------------

			describe("LocalDisk", function() {

				var ctx = {root = ""};

				beforeEach(function() {
					ctx.root = GetTempDirectory() & "wheels-storage-spec-" & CreateUUID();
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

				it("builds a public url from the urlPrefix", function() {
					expect(disk.url("a/b.png")).toBe("/uploads/a/b.png");
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
					var signed = disk.signedUrl(key = "a/b.png", expiresIn = -10);
					var qs = ListLast(signed, "?");
					var sig = ReReplace(qs, ".*signature=([a-f0-9]+).*", "\1");
					var exp = Val(ReReplace(qs, ".*expires=([0-9]+).*", "\1"));
					expect(disk.verifySignature(key = "a/b.png", expires = exp, signature = sig)).toBeFalse();
				});

				it("requires a signingKey to produce a signed url", function() {
					var unsigned = new wheels.storage.drivers.LocalDisk(config = {root = ctx.root, urlPrefix = "/u"});
					expect(function() {
						unsigned.signedUrl(key = "a.png");
					}).toThrow("Wheels.Storage.MissingSigningKey");
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

				it("delegates signedUrl to the SigV4 presigner", function() {
					var presigned = s3.signedUrl(key = "avatars/1.png", expiresIn = 120);
					expect(presigned).toInclude("https://myapp-prod.s3.us-east-1.amazonaws.com/avatars/1.png?");
					expect(presigned).toInclude("X-Amz-Algorithm=AWS4-HMAC-SHA256");
					expect(presigned).toInclude("X-Amz-Expires=120");
					expect(presigned).toInclude("X-Amz-Signature=");
				});

				it("requires bucket/region/credentials", function() {
					expect(function() {
						new wheels.storage.drivers.S3Disk(config = {bucket = "b", region = "us-east-1"});
					}).toThrow("Wheels.Storage.InvalidConfiguration");
				});

			});

			// ---- StorageManager ---------------------------------------------

			describe("StorageManager", function() {

				var manager = "";
				beforeEach(function() {
					manager = new wheels.storage.StorageManager(config = {
						default = "local",
						disks = {
							local = {driver = "local", root = GetTempDirectory() & "wheels-storage-mgr", urlPrefix = "/uploads"},
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

}

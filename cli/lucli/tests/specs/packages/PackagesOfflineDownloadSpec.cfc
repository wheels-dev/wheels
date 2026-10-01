/**
 * `--offline` (request.$wheelsOffline) must keep `wheels packages add` off the
 * network entirely. The registry index and manifest were already gated; the
 * tarball download was not, so a cached manifest still led to a download.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("packages offline: tarball download", () => {

			beforeEach(() => {
				request.$wheelsOffline = true;
			});

			afterEach(() => {
				StructDelete(request, "$wheelsOffline");
			});

			it("refuses the download before any network access", () => {
				var dest = GetTempDirectory() & "wheels-offline-" & CreateUUID() & ".tar.gz";
				var thrown = {type = "", message = ""};
				try {
					new cli.lucli.services.packages.HttpClient().download("https://example.invalid/pkg.tar.gz", dest);
				} catch (any e) {
					thrown.type = e.type;
					thrown.message = e.message;
				}
				expect(thrown.type).toBe("Wheels.Packages.Offline");
				expect(thrown.message).toInclude("--offline");
				expect(FileExists(dest)).toBeFalse();
			});

			it("fails an install from a cached manifest with the offline error, leaving vendor/ untouched", () => {
				var proj = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(proj & "vendor", true);
				var thrown = {type = ""};
				try {
					new cli.lucli.services.packages.Installer(projectRoot = proj).install("wheels-sentry", {
						version: "1.0.0",
						tarball: "https://example.invalid/wheels-sentry-1.0.0.tar.gz",
						sha256: "00"
					});
				} catch (any e) {
					thrown.type = e.type;
				}
				var leftovers = DirectoryList(proj & "vendor", false, "name");
				DirectoryDelete(proj, true);
				expect(thrown.type).toBe("Wheels.Packages.Offline");
				expect(ArrayLen(leftovers)).toBe(0);
			});

			it("still downloads when offline mode is off", () => {
				StructDelete(request, "$wheelsOffline");
				var thrown = {type = ""};
				try {
					new cli.lucli.services.packages.HttpClient(timeoutSeconds = 2).download("https://example.invalid/pkg.tar.gz", GetTempDirectory() & CreateUUID());
				} catch (any e) {
					thrown.type = e.type;
				}
				// example.invalid never resolves: any failure here is the network attempt, not the offline gate.
				expect(thrown.type).notToBe("Wheels.Packages.Offline");
			});
		});
	}
}

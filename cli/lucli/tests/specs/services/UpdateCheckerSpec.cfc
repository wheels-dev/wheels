/**
 * Unit tests for the UpdateChecker service. We focus on the pure-function
 * surface (comparison and snapshot-number extraction) — those are the
 * correctness-critical paths. The HTTP path is exercised by manual smoke
 * tests and the brew tap CI, and is wrapped in a try/catch that swallows
 * all failure modes, so a network outage during `wheels new` is benign.
 *
 * If we ever need to integration-test the HTTP path, refactor init() to
 * accept an injected fetcher callable and stub it here.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.uc = new cli.lucli.services.UpdateChecker();
	}

	function run() {

		describe("UpdateChecker Service", () => {

			describe("$snapshotNumber()", () => {

				it("extracts post-fix snapshot.N numbers", () => {
					expect(uc.$snapshotNumber("4.0.0-snapshot.1789")).toBe(1789);
					expect(uc.$snapshotNumber("5.0.0-snapshot.1")).toBe(1);
					expect(uc.$snapshotNumber("10.20.30-snapshot.99999")).toBe(99999);
				});

				it("extracts legacy SNAPSHOT+N numbers", () => {
					// Older brew bottles built before the SemVer separator fix
					// still carry this form. Must compare against newer snapshots
					// from the post-fix range without errors.
					expect(uc.$snapshotNumber("4.0.0-SNAPSHOT+1656")).toBe(1656);
					expect(uc.$snapshotNumber("3.5.0-SNAPSHOT+42")).toBe(42);
				});

				it("returns 0 for versions without a snapshot suffix", () => {
					// 0 lets the comparison treat the non-snapshot version as
					// older than any snapshot — so a stable user comparing
					// against a snapshot tag (shouldn't happen via the channel
					// router, but defensive) gets a benign result.
					expect(uc.$snapshotNumber("4.0.0")).toBe(0);
					expect(uc.$snapshotNumber("")).toBe(0);
					expect(uc.$snapshotNumber("custom-build")).toBe(0);
				});

			});

			describe("$isNewer()", () => {

				it("returns true when base SemVer is greater on stable", () => {
					expect(uc.$isNewer("4.0.0", "4.0.1", "stable")).toBeTrue();
					expect(uc.$isNewer("4.0.0", "4.1.0", "stable")).toBeTrue();
					expect(uc.$isNewer("4.0.0", "5.0.0", "stable")).toBeTrue();
				});

				it("returns false when base SemVer is equal or lower on stable", () => {
					expect(uc.$isNewer("4.0.0", "4.0.0", "stable")).toBeFalse();
					expect(uc.$isNewer("4.0.1", "4.0.0", "stable")).toBeFalse();
					expect(uc.$isNewer("5.0.0", "4.0.0", "stable")).toBeFalse();
				});

				it("compares snapshot.N on bleeding-edge when base is equal", () => {
					expect(uc.$isNewer("4.0.0-snapshot.1789", "4.0.0-snapshot.1790", "bleeding-edge")).toBeTrue();
					expect(uc.$isNewer("4.0.0-snapshot.1790", "4.0.0-snapshot.1789", "bleeding-edge")).toBeFalse();
					expect(uc.$isNewer("4.0.0-snapshot.100", "4.0.0-snapshot.100", "bleeding-edge")).toBeFalse();
				});

				it("uses base SemVer first on bleeding-edge", () => {
					// If base differs, the snapshot.N is irrelevant. A user on
					// 4.0.0-snapshot.999 still needs to upgrade to 4.0.1-snapshot.1.
					expect(uc.$isNewer("4.0.0-snapshot.999", "4.0.1-snapshot.1", "bleeding-edge")).toBeTrue();
					expect(uc.$isNewer("4.1.0-snapshot.1", "4.0.0-snapshot.999", "bleeding-edge")).toBeFalse();
				});

				it("bridges legacy and post-fix snapshot formats", () => {
					// User on a brew bottle built before the SemVer fix has
					// version "4.0.0-SNAPSHOT+1656". Latest published is
					// "4.0.0-snapshot.1790". Must classify as upgrade-worthy.
					expect(uc.$isNewer("4.0.0-SNAPSHOT+1656", "4.0.0-snapshot.1790", "bleeding-edge")).toBeTrue();
				});

			});

			describe("check() for non-network channels", () => {

				it("skips development channel without making any request", () => {
					var r = uc.check(currentVersion="@build.version@");
					expect(r.skipped).toBeTrue();
					expect(r.channel).toBe("development");
					expect(r.hasUpdate).toBeFalse();
				});

				it("skips release-candidate channel", () => {
					// RC users opted in explicitly; we don't auto-nag them.
					var r = uc.check(currentVersion="4.1.0-rc.1");
					expect(r.skipped).toBeTrue();
					expect(r.channel).toBe("release-candidate");
					expect(r.hasUpdate).toBeFalse();
				});

				it("returns a populated struct even when skipped", () => {
					// Caller code expects a consistent shape regardless of skip
					// reason — guards against AccessOfUndefinedKey errors.
					var r = uc.check(currentVersion="");
					expect(structKeyExists(r, "hasUpdate")).toBeTrue();
					expect(structKeyExists(r, "skipped")).toBeTrue();
					expect(structKeyExists(r, "current")).toBeTrue();
					expect(structKeyExists(r, "latest")).toBeTrue();
					expect(structKeyExists(r, "channel")).toBeTrue();
					expect(structKeyExists(r, "upgradeCommand")).toBeTrue();
				});

			});

		});

	}

}

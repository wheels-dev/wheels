/**
 * #3902: a `packages update` / `add --force` killed mid-swap leaves the old
 * copy as vendor/.wheels-pkg-previous-*, which PackageLoader skips. The next
 * `wheels packages` command restores it when vendor/<name>/ is missing or
 * incomplete, and drops it when the new copy made it into place.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Installer.recoverInterruptedSwaps", () => {

			var fixturePath = ExpandPath("/cli/lucli/tests/_fixtures/packages/wheels-fake-1.0.0.tar.gz");

			var $project = () => {
				var root = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(root & "vendor", true);
				return root;
			};

			var $package = (dir, name, version = "1.0.0") => {
				DirectoryCreate(dir, true);
				FileWrite(dir & "/package.json", SerializeJSON({name: name, version: version}));
			};

			var $hidden = (proj) => {
				var names = [];
				for (var n in DirectoryList(proj & "vendor", false, "name")) {
					if (Left(n, 1) == ".") ArrayAppend(names, n);
				}
				return names;
			};

			it("restores the backup when vendor/<name>/ is missing", () => {
				var proj = $project();
				$package(proj & "vendor/.wheels-pkg-previous-wheels-fake-" & CreateUUID(), "wheels-fake", "1.0.0");
				var messages = new cli.lucli.services.packages.Installer(projectRoot = proj).recoverInterruptedSwaps();
				expect(FileExists(proj & "vendor/wheels-fake/package.json")).toBeTrue();
				expect($hidden(proj)).toBeEmpty();
				expect(ArrayToList(messages, " ")).toInclude("Restored vendor/wheels-fake");
				DirectoryDelete(proj, true);
			});

			it("restores the backup over an incomplete vendor/<name>/ (no package.json)", () => {
				var proj = $project();
				$package(proj & "vendor/.wheels-pkg-previous-wheels-fake-" & CreateUUID(), "wheels-fake", "1.0.0");
				DirectoryCreate(proj & "vendor/wheels-fake", true);
				FileWrite(proj & "vendor/wheels-fake/half-copied.txt", "partial");
				new cli.lucli.services.packages.Installer(projectRoot = proj).recoverInterruptedSwaps();
				expect(FileExists(proj & "vendor/wheels-fake/package.json")).toBeTrue();
				expect(FileExists(proj & "vendor/wheels-fake/half-copied.txt")).toBeFalse();
				expect($hidden(proj)).toBeEmpty();
				DirectoryDelete(proj, true);
			});

			it("drops the backup when the new copy is in place", () => {
				var proj = $project();
				$package(proj & "vendor/.wheels-pkg-previous-wheels-fake-" & CreateUUID(), "wheels-fake", "1.0.0");
				$package(proj & "vendor/wheels-fake", "wheels-fake", "2.0.0");
				var messages = new cli.lucli.services.packages.Installer(projectRoot = proj).recoverInterruptedSwaps();
				expect(DeserializeJSON(FileRead(proj & "vendor/wheels-fake/package.json")).version).toBe("2.0.0");
				expect($hidden(proj)).toBeEmpty();
				expect(ArrayToList(messages, " ")).toInclude("leftover backup");
				DirectoryDelete(proj, true);
			});

			it("recovers a backup named without the package (older CLI) from its package.json", () => {
				var proj = $project();
				$package(proj & "vendor/.wheels-pkg-previous-" & CreateUUID(), "wheels-fake", "1.0.0");
				new cli.lucli.services.packages.Installer(projectRoot = proj).recoverInterruptedSwaps();
				expect(FileExists(proj & "vendor/wheels-fake/package.json")).toBeTrue();
				expect($hidden(proj)).toBeEmpty();
				DirectoryDelete(proj, true);
			});

			it("leaves a backup it cannot attribute and says how to restore it", () => {
				var proj = $project();
				var backup = ".wheels-pkg-previous-" & CreateUUID();
				DirectoryCreate(proj & "vendor/" & backup, true);
				FileWrite(proj & "vendor/" & backup & "/readme.txt", "no package.json");
				var messages = new cli.lucli.services.packages.Installer(projectRoot = proj).recoverInterruptedSwaps();
				expect(DirectoryExists(proj & "vendor/" & backup)).toBeTrue();
				expect(ArrayToList(messages, " ")).toInclude(backup);
				DirectoryDelete(proj, true);
			});

			it("removes a leftover incoming copy", () => {
				var proj = $project();
				$package(proj & "vendor/.wheels-pkg-incoming-wheels-fake-" & CreateUUID(), "wheels-fake", "2.0.0");
				new cli.lucli.services.packages.Installer(projectRoot = proj).recoverInterruptedSwaps();
				expect($hidden(proj)).toBeEmpty();
				expect(DirectoryExists(proj & "vendor/wheels-fake")).toBeFalse();
				DirectoryDelete(proj, true);
			});

			it("does nothing without vendor/ or backups", () => {
				var proj = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(proj, true);
				expect(new cli.lucli.services.packages.Installer(projectRoot = proj).recoverInterruptedSwaps()).toBeEmpty();
				DirectoryDelete(proj, true);
			});

			it("runs before an install, so the interrupted package comes back", () => {
				var proj = $project();
				$package(proj & "vendor/.wheels-pkg-previous-wheels-other-" & CreateUUID(), "wheels-other", "1.0.0");
				var href = "https://example/wheels-fake-1.0.0.tar.gz";
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				fake.seed(href, {status: 200, body: FileReadBinary(fixturePath)});
				new cli.lucli.services.packages.Installer(httpClient = fake, projectRoot = proj).install("wheels-fake", {
					version: "1.0.0",
					tarball: href,
					sha256: LCase(Hash(FileReadBinary(fixturePath), "SHA-256"))
				});
				expect(FileExists(proj & "vendor/wheels-other/package.json")).toBeTrue();
				expect(FileExists(proj & "vendor/wheels-fake/package.json")).toBeTrue();
				expect($hidden(proj)).toBeEmpty();
				DirectoryDelete(proj, true);
			});
		});
	}
}

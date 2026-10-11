/**
 * The shared sshd test fixture (22022/22023) is one Compose project used by every
 * checkout on the machine. Its config must not hold a path into the checkout that
 * created it, or a run from another checkout recreates the containers and a deleted
 * worktree leaves a dangling bind mount; and the up script must reuse containers that
 * are already running and answering rather than recreate them under another run.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		// This spec lives in cli/lucli/tests/specs/deploy/, five levels below the repo root.
		var repoRoot = createObject("java", "java.io.File").init(getDirectoryFromPath(getCurrentTemplatePath()) & "../../../../../").getCanonicalPath() & "/";
		variables.fixtureDir = repoRoot & "cli/lucli/tests/_fixtures/deploy/sshd/";
		variables.upScript = repoRoot & "tools/deploy-sshd-up.sh";
	}

	function run() {

		describe("shared sshd fixture", () => {

			it("passes the public key inline instead of bind-mounting a file from the checkout", () => {
				var compose = fileRead(fixtureDir & "docker-compose.yml");
				expect(reFindNoCase("(?m)^\s*volumes\s*:", compose)).toBe(0, "the sshd services must not mount anything from the checkout");
				expect(compose).notToInclude("PUBLIC_KEY_FILE");
				var publicKey = trim(fileRead(fixtureDir & "test_key.pub"));
				var lines = reMatch('PUBLIC_KEY:\s*"[^"]*"', compose);
				expect(arrayLen(lines)).toBe(2);
				for (var line in lines) {
					expect(line).toInclude(publicKey);
				}
			});

			it("reuses running, answering containers before running docker compose up", () => {
				var script = fileRead(upScript);
				var reuse = find("ps --status running", script);
				var up = find('docker compose -f "$FIX_DIR/docker-compose.yml" up -d', script);
				expect(reuse).toBeGT(0);
				expect(up).toBeGT(reuse, "the reuse check must come before `docker compose up -d`");
				expect(script).toInclude("banner_ok 22022");
				expect(script).toInclude("banner_ok 22023");
			});

		});

	}

}

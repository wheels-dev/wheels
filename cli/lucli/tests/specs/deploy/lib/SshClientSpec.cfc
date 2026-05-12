component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.helper = new cli.lucli.tests._helpers.DeployShellHelper();
		variables.helper.sshdUp();
		variables.fixtureDir = expandPath("/cli/lucli/tests/_fixtures/deploy/sshd");
	}

	function afterAll() {
		variables.helper.sshdDown();
	}

	function run() {
		describe("SshClient", () => {

			it("runs a command and returns exit 0 + stdout", () => {
				var ssh = makeClient(22022);
				var r = ssh.run("echo hello");
				expect(r.exitCode).toBe(0);
				expect(trim(r.stdout)).toBe("hello");
				ssh.close();
			});

			it("returns non-zero exit code for failing command", () => {
				var ssh = makeClient(22022);
				var r = ssh.run("false");
				expect(r.exitCode).toBe(1);
				ssh.close();
			});

			it("captures stderr separately from stdout", () => {
				var ssh = makeClient(22022);
				var r = ssh.run("echo out; echo err 1>&2");
				expect(trim(r.stdout)).toBe("out");
				expect(trim(r.stderr)).toBe("err");
				ssh.close();
			});

			it("uploads a string directly and reads it back via cat", () => {
				var ssh = makeClient(22022);
				ssh.uploadString("hello direct", "/tmp/wheels-deploy-test-up.txt");
				var r = ssh.run("cat /tmp/wheels-deploy-test-up.txt");
				expect(trim(r.stdout)).toBe("hello direct");
				ssh.close();
			});

			it("round-trips content via upload and download", () => {
				var ssh = makeClient(22022);
				ssh.uploadString("roundtrip payload", "/tmp/wheels-deploy-test-round.txt");
				var localDown = getTempFile(getTempDirectory(), "wheels-deploy-down");
				ssh.download("/tmp/wheels-deploy-test-round.txt", localDown);
				expect(fileRead(localDown)).toBe("roundtrip payload");
				fileDelete(localDown);
				ssh.close();
			});

		});
	}

	private any function makeClient(required numeric port) {
		return new cli.lucli.services.deploy.lib.SshClient().init(
			"localhost",
			{
				user: "deploy",
				port: arguments.port,
				privateKey: variables.fixtureDir & "/test_key",
				strictHostKeyChecking: false
			}
		);
	}

}

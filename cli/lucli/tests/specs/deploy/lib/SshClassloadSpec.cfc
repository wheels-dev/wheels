component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("sshj classload (spike)", () => {

			it("loads net.schmizz.sshj.SSHClient from the isolated classpath", () => {
				var loader = new cli.lucli.services.deploy.lib.JarLoader();
				var clazz = loader.loadClass("net.schmizz.sshj.SSHClient");
				expect(clazz.getName()).toBe("net.schmizz.sshj.SSHClient");
			});

			it("instantiates SSHClient without throwing BouncyCastle collision errors", () => {
				var loader = new cli.lucli.services.deploy.lib.JarLoader();
				// No-arg constructor — should work; doesn't open a connection.
				// NOTE: variable name deliberately NOT "client" — that's a Lucee
				// reserved scope ("client scope is not enabled") and the parser
				// rejects `var client = ...` in closures.
				var ssh = loader.newInstance("net.schmizz.sshj.SSHClient");
				expect(isNull(ssh)).toBeFalse();
				// If this throws with a "NoSuchAlgorithmException" or
				// "ClassCastException" mentioning BouncyCastle, the isolation
				// is NOT holding — that's the signal to pre-empt apache-mina-sshd.
			});

			it("loads BouncyCastle from isolated classpath (not Lucee bundled)", () => {
				var loader = new cli.lucli.services.deploy.lib.JarLoader();
				var bc = loader.loadClass("org.bouncycastle.jce.provider.BouncyCastleProvider");
				expect(bc.getName()).toBe("org.bouncycastle.jce.provider.BouncyCastleProvider");
				// Verify it came from our JAR, not Lucee's classpath. The package
				// ProtectionDomain should point at our bcprov-jdk18on-1.78.jar.
				var loc = bc.getProtectionDomain().getCodeSource().getLocation().toString();
				expect(loc).toInclude("bcprov-jdk18on-1.78.jar");
			});

			it("loads PromiscuousVerifier for skip-known-hosts mode", () => {
				var loader = new cli.lucli.services.deploy.lib.JarLoader();
				var v = loader.newInstance("net.schmizz.sshj.transport.verification.PromiscuousVerifier");
				expect(isNull(v)).toBeFalse();
			});

		});

	}

}

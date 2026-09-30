component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Load the shared guard so its helper functions are defined into this
		// component's variables scope, callable from the specs below.
		include "/wheels/public/migrator/_guard.cfm";
		variables.$$hadAllowed = StructKeyExists(application.wheels, "migratorAllowedHosts");
		if (variables.$$hadAllowed) {
			variables.$$origAllowed = application.wheels.migratorAllowedHosts;
		}
	}

	function afterAll() {
		if (variables.$$hadAllowed) {
			application.wheels.migratorAllowedHosts = variables.$$origAllowed;
		} else {
			StructDelete(application.wheels, "migratorAllowedHosts");
		}
	}

	private string function readPublic(required string rel) {
		return FileRead(ExpandPath("/wheels/public/" & arguments.rel));
	}

	function run() {
		describe("$migratorHostIsLocal accepts only local host names", () => {

			beforeEach(() => {
				application.wheels.migratorAllowedHosts = "";
			});

			it("accepts localhost with and without a port", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "localhost")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "localhost:8080")).toBeTrue();
			});

			it("accepts 127.0.0.1 and the wider 127.0.0.0/8 loopback range", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "127.0.0.1")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "127.0.0.1:8080")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "127.5.5.5")).toBeTrue();
			});

			it("accepts the bracketed IPv6 loopback literal", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "[::1]")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "[::1]:8080")).toBeTrue();
			});

			it("accepts any *.localhost name by default (RFC 6761 loopback)", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "myapp.localhost")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "myapp.localhost:8080")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "foo.bar.localhost")).toBeTrue();
				// A foreign name that merely embeds "localhost" as a non-final label is not local.
				expect(variables.$migratorHostIsLocal(hostHeader = "evil.localhost.attacker.com")).toBeFalse();
			});

			it("rejects a foreign host name", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "example.com")).toBeFalse();
				expect(variables.$migratorHostIsLocal(hostHeader = "example.com:8080")).toBeFalse();
			});

			it("rejects an empty Host header (fails closed)", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "")).toBeFalse();
			});

			it("rejects a non-loopback IP literal", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "10.0.0.5")).toBeFalse();
				expect(variables.$migratorHostIsLocal(hostHeader = "192.168.1.10:8080")).toBeFalse();
			});

			it("rejects a bracketed IPv6 host with anything but a port after ]", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "[::1]x")).toBeFalse();
				expect(variables.$migratorHostIsLocal(hostHeader = "[::1]extra")).toBeFalse();
				expect(variables.$migratorHostIsLocal(hostHeader = "[::1]:80x")).toBeFalse();
			});

			it("rejects a 127/8 address with an out-of-range or wrong-count octet", () => {
				expect(variables.$migratorHostIsLocal(hostHeader = "127.0.0.256")).toBeFalse();
				expect(variables.$migratorHostIsLocal(hostHeader = "127.999.0.1")).toBeFalse();
				expect(variables.$migratorHostIsLocal(hostHeader = "127.0.0")).toBeFalse();
				expect(variables.$migratorHostIsLocal(hostHeader = "127.0.0.1.5")).toBeFalse();
			});

			it("accepts a configured extra host name", () => {
				application.wheels.migratorAllowedHosts = "dev.local,app.internal";
				expect(variables.$migratorHostIsLocal(hostHeader = "dev.local")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "app.internal:9000")).toBeTrue();
				expect(variables.$migratorHostIsLocal(hostHeader = "other.local")).toBeFalse();
			});

		});

		describe("host check is wired into the guard and the endpoints", () => {

			it("the shared guard defines the hostname gate and a local-access combiner", () => {
				var g = readPublic("migrator/_guard.cfm");
				expect(g).toInclude("$migratorEnforceLocalHostname");
				expect(g).toInclude("$migratorHostIsLocal");
				expect(g).toInclude("$migratorEnforceLocalAccess");
			});

			it("the command endpoint enforces the local host name", () => {
				var c = readPublic("migrator/command.cfm");
				expect(c).toInclude("$migratorEnforceLocalHostname()");
			});

			it("the 403 names the exact fix for a custom local hostname", () => {
				var g = readPublic("migrator/_guard.cfm");
				expect(g).toInclude("add it with set(migratorAllowedHosts");
				expect(g).toInclude("myapp.test");
			});

			it("the token-issuing views enforce local access before issuing a token", () => {
				for (var rel in ["views/migrator.cfm", "views/templating.cfm"]) {
					var v = readPublic(rel);
					expect(v).toInclude("/wheels/public/migrator/_guard.cfm");
					var guardPos = Find("$migratorEnforceLocalAccess()", v);
					var tokenPos = Find("$migratorCsrfToken =", v);
					expect(guardPos).toBeGT(0, rel & " must call $migratorEnforceLocalAccess()");
					expect(tokenPos).toBeGT(0, rel & " must issue the token");
					expect(guardPos).toBeLT(tokenPos, rel & " must gate before issuing the token");
				}
			});

		});
	}
}

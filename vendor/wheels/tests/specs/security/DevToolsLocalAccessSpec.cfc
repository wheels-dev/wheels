component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.pub = application.wheels.public;
		variables.$$hadAllowed = StructKeyExists(application.wheels, "devToolsAllowedHosts");
		if (variables.$$hadAllowed) {
			variables.$$origAllowed = application.wheels.devToolsAllowedHosts;
		}
	}

	function afterAll() {
		if (variables.$$hadAllowed) {
			application.wheels.devToolsAllowedHosts = variables.$$origAllowed;
		} else {
			StructDelete(application.wheels, "devToolsAllowedHosts");
		}
	}

	function run() {
		describe("$wheelsHostIsLocal accepts only local host names", () => {

			beforeEach(() => {
				application.wheels.devToolsAllowedHosts = "";
			});

			it("accepts localhost, 127.0.0.0/8, and [::1] (with or without a port)", () => {
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "localhost")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "localhost:60007")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "127.0.0.1")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "127.5.5.5:8080")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "[::1]:8080")).toBeTrue();
			});

			it("accepts any *.localhost name (RFC 6761)", () => {
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "myapp.localhost")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "a.b.localhost:9000")).toBeTrue();
			});

			it("rejects foreign, empty, out-of-range, and malformed hosts", () => {
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "example.com")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "127.0.0.256")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "[::1]evil")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "10.0.0.5")).toBeFalse();
			});

			it("accepts a configured extra host name", () => {
				application.wheels.devToolsAllowedHosts = "dev.test,app.internal";
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "dev.test")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "app.internal:9000")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "other.test")).toBeFalse();
			});

		});

		describe("the gate is wired and socket-independent", () => {

			it("the dispatch chokepoint calls the dev-tools gate before invoking a public action", () => {
				var src = FileRead(ExpandPath("/wheels/Dispatch.cfc"));
				var gatePos = Find("$enforceDevToolLocalAccess()", src);
				var invokePos = Find("invokeMethod(application.wheels.public", src);
				expect(gatePos).toBeGT(0, "Dispatch must call the dev-tools gate");
				expect(invokePos).toBeGT(0);
				expect(gatePos).toBeLT(invokePos, "the gate must run before the action");
			});

			it("the gate passes the socket peer, the Host header and X-Forwarded-For to the pure check", () => {
				var src = FileRead(ExpandPath("/wheels/Public.cfc"));
				var body = Mid(src, Find("function $enforceDevToolLocalAccess", src), 900);
				expect(body).toInclude("$devToolAccessCheck(");
				expect(FindNoCase("cgi.REMOTE_ADDR", body)).toBeGT(0, "the dev-tools gate must check the socket peer");
				expect(FindNoCase("HTTP_HOST", body)).toBeGT(0);
				expect(FindNoCase("HTTP_X_FORWARDED_FOR", body)).toBeGT(0);
			});

		});

		describe("$devToolAccessCheck decides from the socket peer as well as the Host header", () => {

			beforeEach(() => {
				application.wheels.devToolsAllowedHosts = "";
			});

			it("denies a non-loopback peer that names a local Host, with no X-Forwarded-For", () => {
				var r = variables.pub.$devToolAccessCheck(remoteAddr = "172.17.0.1", hostHeader = "localhost:8080", forwardedFor = "");
				expect(r.allowed).toBeFalse();
				expect(r.statusCode).toBe(403);
				r = variables.pub.$devToolAccessCheck(remoteAddr = "192.168.1.20", hostHeader = "127.0.0.1", forwardedFor = "");
				expect(r.allowed).toBeFalse();
			});

			it("allows a loopback peer that names a local Host", () => {
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "localhost:8080", forwardedFor = "").allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "0:0:0:0:0:0:0:1", hostHeader = "[::1]:8080", forwardedFor = "").allowed).toBeTrue();
			});

			it("still denies a loopback peer whose Host names another machine (DNS rebinding)", () => {
				var r = variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "other.example", forwardedFor = "");
				expect(r.allowed).toBeFalse();
				expect(r.statusCode).toBe(403);
			});

			it("denies a loopback peer whose X-Forwarded-For carries a non-loopback hop", () => {
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "localhost", forwardedFor = "203.0.113.9").allowed).toBeFalse();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "localhost", forwardedFor = "127.0.0.1, 203.0.113.9").allowed).toBeFalse();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "localhost", forwardedFor = "127.0.0.1").allowed).toBeTrue();
			});

			it("treats only IP-literal X-Forwarded-For hops as loopback", () => {
				for (var hop in ["localhost", "127.1", "::1%lo0", "ip6-localhost", "0177.0.0.1"]) {
					expect(variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "localhost", forwardedFor = hop).allowed).toBeFalse(hop);
				}
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "localhost", forwardedFor = "::1, 127.0.0.1").allowed).toBeTrue();
			});

			it("accepts an IPv6 loopback peer that carries a zone id", () => {
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "0:0:0:0:0:0:0:1%0", hostHeader = "localhost", forwardedFor = "").allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "::1%lo0", hostHeader = "localhost", forwardedFor = "").allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "fe80::1%eth0", hostHeader = "localhost", forwardedFor = "").allowed).toBeFalse();
			});

			it("fails closed on an empty or unresolvable peer", () => {
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "", hostHeader = "localhost", forwardedFor = "").allowed).toBeFalse();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "not-an-address", hostHeader = "localhost", forwardedFor = "").allowed).toBeFalse();
			});

		});

		describe("devToolsAllowedRemoteAddresses opts specific non-loopback peers in", () => {

			beforeEach(() => {
				application.wheels.devToolsAllowedHosts = "";
			});

			it("allows an exact IPv4 or IPv6 peer on the list, and only that peer", () => {
				var allow = "172.17.0.1, fd00::5";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.17.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "fd00:0:0:0:0:0:0:5", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.17.0.2", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
			});

			it("allows an IPv4 peer inside a listed CIDR range, including its IPv4-mapped IPv6 form", () => {
				var allow = "172.16.0.0/12";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "::ffff:172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.32.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "192.168.1.20", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
			});

			it("still requires a local Host header for an allowed peer", () => {
				var allow = "172.16.0.0/12";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "other.example", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
			});

			it("treats malformed entries as matching nothing", () => {
				var allow = "172.16.0.0/33, 10.0.0.0/x, not-an-ip, 999.1.1.1, *";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "10.0.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "8.8.8.8", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
			});

			it("parses IP literals the same way on every engine", () => {
				expect(variables.pub.$normalizeIpLiteral("FD00::5")).toBe("fd00:0:0:0:0:0:0:5");
				expect(variables.pub.$normalizeIpLiteral("::1")).toBe("0:0:0:0:0:0:0:1");
				expect(variables.pub.$normalizeIpLiteral("::ffff:172.18.0.1")).toBe("172.18.0.1");
				expect(variables.pub.$normalizeIpLiteral("0:0:0:0:0:ffff:ac12:1")).toBe("172.18.0.1");
				expect(variables.pub.$normalizeIpLiteral("2001:db8::1:0:0:1")).toBe("2001:db8:0:0:1:0:0:1");
				for (var bad in [
					"", "1::2::3", ":::1", "fd00::5::", "12345::1", "1:2:3:4:5:6:7:8:9", "010.0.0.1", "1.2.3", "localhost", "fe80::1%eth0",
					"127.1", "0177.0.0.1", "2130706433", "0x7f000001", "1:2:3:4:5:6:7:8::", ":0:0:0:0:0:0:1", "0:0:0:0:0:0:1:",
					"::ffff:127.1", "::ffff:127.0.0.01"
				]) {
					expect(variables.pub.$normalizeIpLiteral(bad)).toBe("", bad);
				}
			});

			it("tells loopback from look-alikes after normalizing", () => {
				expect(variables.pub.$normalizeIpLiteral("::ffff:7f00:1")).toBe("127.0.0.1");
				expect(variables.pub.$isLoopbackLiteral(variables.pub.$normalizeIpLiteral("::ffff:7f00:1"))).toBeTrue();
				expect(variables.pub.$normalizeIpLiteral("::127.0.0.1")).toBe("0:0:0:0:0:0:7f00:1");
				expect(variables.pub.$isLoopbackLiteral(variables.pub.$normalizeIpLiteral("::127.0.0.1"))).toBeFalse();
				expect(variables.pub.$normalizeIpLiteral("::")).toBe("0:0:0:0:0:0:0:0");
				expect(variables.pub.$isLoopbackLiteral(variables.pub.$normalizeIpLiteral("::"))).toBeFalse();
				expect(variables.pub.$normalizeIpLiteral("1::")).toBe("1:0:0:0:0:0:0:0");
				expect(variables.pub.$isLoopbackLiteral(variables.pub.$normalizeIpLiteral("1::"))).toBeFalse();
				for (var notLoop in ["127.1", "0177.0.0.1", "2130706433", "0x7f000001", "::ffff:127.1"]) {
					expect(variables.pub.$devToolAccessCheck(remoteAddr = notLoop, hostHeader = "localhost", forwardedFor = "").allowed).toBeFalse(notLoop);
				}
			});

			it("normalises the IPv4-mapped loopback peer", () => {
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "::ffff:127.0.0.1", hostHeader = "localhost", forwardedFor = "").allowed).toBeTrue();
			});

			it("rejects CIDR entries with empty or extra fields instead of reading past them", () => {
				for (var allow in ["172.16.0.0//12", "/172.16.0.0/12", "172.16.0.0/12/", "172.16.0.0/", "/12"]) {
					expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse(allow);
				}
			});

			it("rejects a CIDR range based on the unspecified address", () => {
				var allow = "0.0.0.0/1";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "10.0.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
			});

			it("never treats an all-addresses range or a wildcard as allow-all", () => {
				var allow = "0.0.0.0/0, ::/0, *, 0.0.0.0";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "203.0.113.9", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow).allowed).toBeFalse();
			});

			it("matches the list against the socket peer only, never a forwarded hop", () => {
				var allow = "172.16.0.0/12";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "203.0.113.9", hostHeader = "localhost", forwardedFor = "172.18.0.1", allowedRemoteAddresses = allow).allowed).toBeFalse();
			});

			it("ignores the list outside development and testing", () => {
				var allow = "172.16.0.0/12";
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow, environment = "testing").allowed).toBeTrue();
				expect(variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = allow, environment = "maintenance").allowed).toBeFalse();
			});

		});

		describe("$devToolAccessCheck refuses every dev tool in production", () => {

			it("denies even a loopback peer with a local Host", () => {
				var r = variables.pub.$devToolAccessCheck(remoteAddr = "127.0.0.1", hostHeader = "localhost", forwardedFor = "", environment = "production");
				expect(r.allowed).toBeFalse();
				expect(r.statusCode).toBe(404);
			});

			it("denies a listed peer", () => {
				var r = variables.pub.$devToolAccessCheck(remoteAddr = "172.18.0.1", hostHeader = "localhost", forwardedFor = "", allowedRemoteAddresses = "172.16.0.0/12", environment = "production");
				expect(r.allowed).toBeFalse();
			});

		});
	}
}

component extends="wheels.WheelsTest" {

	function run() {

		describe("Console eval security hardening", () => {

			describe("InetAddress localhost detection", () => {

				it("recognizes 127.0.0.1 as loopback", () => {
					var inet = createObject("java", "java.net.InetAddress").getByName("127.0.0.1");
					expect(inet.isLoopbackAddress()).toBeTrue();
				});

				it("recognizes ::1 (compressed IPv6) as loopback", () => {
					var inet = createObject("java", "java.net.InetAddress").getByName("::1");
					expect(inet.isLoopbackAddress()).toBeTrue();
				});

				it("recognizes 0:0:0:0:0:0:0:1 (full IPv6) as loopback", () => {
					var inet = createObject("java", "java.net.InetAddress").getByName("0:0:0:0:0:0:0:1");
					expect(inet.isLoopbackAddress()).toBeTrue();
				});

				it("recognizes zero-padded IPv6 localhost as loopback", () => {
					var inet = createObject("java", "java.net.InetAddress").getByName("0000:0000:0000:0000:0000:0000:0000:0001");
					expect(inet.isLoopbackAddress()).toBeTrue();
				});

				it("rejects a public IP address as non-loopback", () => {
					var inet = createObject("java", "java.net.InetAddress").getByName("8.8.8.8");
					expect(inet.isLoopbackAddress()).toBeFalse();
				});

				it("rejects a private network IP as non-loopback", () => {
					var inet = createObject("java", "java.net.InetAddress").getByName("10.0.0.1");
					expect(inet.isLoopbackAddress()).toBeFalse();
				});

				it("rejects a link-local IPv6 address as non-loopback", () => {
					var inet = createObject("java", "java.net.InetAddress").getByName("fe80::1");
					expect(inet.isLoopbackAddress()).toBeFalse();
				});

			});

			describe("Content-Type validation logic", () => {

				it("accepts application/json", () => {
					var contentType = "application/json";
					expect(FindNoCase("application/json", contentType) > 0).toBeTrue();
				});

				it("accepts application/json with charset", () => {
					var contentType = "application/json; charset=utf-8";
					expect(FindNoCase("application/json", contentType) > 0).toBeTrue();
				});

				it("rejects text/html", () => {
					var contentType = "text/html";
					expect(FindNoCase("application/json", contentType) > 0).toBeFalse();
				});

				it("rejects empty Content-Type", () => {
					var contentType = "";
					expect(FindNoCase("application/json", contentType) > 0).toBeFalse();
				});

				it("rejects application/x-www-form-urlencoded", () => {
					var contentType = "application/x-www-form-urlencoded";
					expect(FindNoCase("application/json", contentType) > 0).toBeFalse();
				});

			});

		});

	}

}

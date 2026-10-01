/**
 * The CLI half of the dev-server connection challenge (#3769): message,
 * MAC and address canonicalisation. The vectors are the ones
 * vendor/wheels/tests/specs/cli/CliChallengeSpec.cfc asserts for the
 * framework's CFML Hmac(), computed independently (Python hmac/hashlib).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.challenge = new cli.lucli.services.ServerChallenge();
		variables.token = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";
		variables.nonce = "0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0";
		variables.ipv4Mac = "f58ec7c9ce5830e9f113404bf1cbee08ae928108fb32814c0b96fa6cf66ed151";
		variables.ipv6Mac = "84e47413a062c0a9226649b42bfd3c6a562828f3cc52a786a9f3713d78734def";
		variables.loopback6 = "00000000000000000000000000000001";
	}

	function run() {

		describe("ServerChallenge (##3769)", () => {

			it("matches the pinned HMAC-SHA256 vectors shared with the framework", () => {
				var msg4 = challenge.message(nonce, "7f000001", 8080, "7f000001", 54321);
				var msg6 = challenge.message(nonce, loopback6, 8080, loopback6, 54321);
				expect(msg4).toBe(
					"wheels-cli-challenge/v1" & chr(10) & nonce & chr(10) & "7f000001:8080" & chr(10) & "7f000001:54321"
				);
				expect(compare(challenge.mac(token, msg4), ipv4Mac)).toBe(0);
				expect(compare(challenge.mac(token, msg6), ipv6Mac)).toBe(0);
			});

			it("canonicalises addresses to raw bytes: no scope id, IPv4-mapped collapses", () => {
				expect(challenge.canonicalAddressOf("127.0.0.1")).toBe("7f000001");
				expect(challenge.canonicalAddressOf("::ffff:127.0.0.1")).toBe("7f000001");
				expect(challenge.canonicalAddressOf("::1")).toBe(loopback6);
				expect(challenge.canonicalAddressOf("::1%1")).toBe(loopback6);
				// A scoped address object, as a socket can report it.
				var scoped = createObject("java", "java.net.Inet6Address").getByAddress(
					javaCast("null", ""),
					createObject("java", "java.net.InetAddress").getByName("::1").getAddress(),
					javaCast("int", 1)
				);
				expect(scoped.getHostAddress()).toInclude("%");
				expect(challenge.canonicalAddress(scoped)).toBe(loopback6);
			});

			it("compares MACs by bytes, so the framework's uppercase hex still matches", () => {
				expect(challenge.macsMatch(ipv4Mac, uCase(ipv4Mac))).toBeTrue();
				expect(challenge.macsMatch(ipv4Mac, ipv6Mac)).toBeFalse();
			});

			it("never matches anything that is not exactly 32 bytes of hex", () => {
				for (var bad in ["", "00", left(ipv4Mac, 63), ipv4Mac & "0", left(ipv4Mac, 63) & "g", ipv4Mac & " ", ipv4Mac & chr(10)]) {
					expect(challenge.macsMatch(ipv4Mac, bad)).toBeFalse("matched [#bad#]");
				}
				// CFML's regex `$` also matches before a trailing newline.
				expect(challenge.isNonce(nonce & chr(10))).toBeFalse();
				expect(challenge.isNonce(uCase(nonce))).toBeFalse();
			});

			it("issues 64-hex-character secrets that differ every time", () => {
				var a = challenge.newSecret();
				var b = challenge.newSecret();
				expect(challenge.isNonce(a)).toBeTrue();
				expect(challenge.isNonce(b)).toBeTrue();
				expect(a).notToBe(b);
			});

			it("binds the MAC to both ends of the connection", () => {
				var base = challenge.mac(token, challenge.message(nonce, "7f000001", 8080, "7f000001", 54321));
				var otherClient = challenge.mac(token, challenge.message(nonce, "7f000001", 8080, "7f000001", 54322));
				var otherServer = challenge.mac(token, challenge.message(nonce, "7f000001", 8081, "7f000001", 54321));
				var otherFamily = challenge.mac(token, challenge.message(nonce, loopback6, 8080, loopback6, 54321));
				expect(base).notToBe(otherClient);
				expect(base).notToBe(otherServer);
				expect(base).notToBe(otherFamily);
			});

		});

	}

}

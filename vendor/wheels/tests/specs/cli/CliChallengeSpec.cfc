/**
 * The server half of the Wheels CLI connection challenge (#3769).
 *
 * The test vectors are the same ones cli/lucli/tests/specs/services/
 * ServerChallengeSpec.cfc asserts for the CLI's Java HMAC, computed
 * independently (Python hmac/hashlib). They must hold on every engine: a
 * mismatch between the two halves fails closed on a legitimate server.
 */
component extends="wheels.WheelsTest" {

	function run() {

		// Shared with ServerChallengeSpec (CLI).
		var token = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";
		var nonce = "0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0";
		var ipv4Mac = "f58ec7c9ce5830e9f113404bf1cbee08ae928108fb32814c0b96fa6cf66ed151";
		var ipv6Mac = "84e47413a062c0a9226649b42bfd3c6a562828f3cc52a786a9f3713d78734def";
		var loopback6 = "00000000000000000000000000000001";

		describe("CliChallenge wire format (##3769)", () => {

			it("builds the pinned message", () => {
				var challenge = new wheels.public.CliChallenge();
				var lf = Chr(10);
				expect(challenge.$message(nonce, "7f000001", 8080, "7f000001", 54321)).toBe(
					"wheels-cli-challenge/v1" & lf & nonce & lf & "7f000001:8080" & lf & "7f000001:54321"
				);
			});

			it("matches the pinned HMAC-SHA256 vectors, in lowercase hex", () => {
				var challenge = new wheels.public.CliChallenge();
				expect(Compare(challenge.$mac(token, challenge.$message(nonce, "7f000001", 8080, "7f000001", 54321)), ipv4Mac)).toBe(0);
				expect(Compare(challenge.$mac(token, challenge.$message(nonce, loopback6, 8080, loopback6, 54321)), ipv6Mac)).toBe(0);
			});

			it("canonicalises addresses to raw bytes: no scope id, IPv4-mapped collapses", () => {
				var challenge = new wheels.public.CliChallenge();
				expect(challenge.$canonicalAddress("127.0.0.1")).toBe("7f000001");
				expect(challenge.$canonicalAddress("::ffff:127.0.0.1")).toBe("7f000001");
				expect(challenge.$canonicalAddress("::1")).toBe(loopback6);
				expect(challenge.$canonicalAddress("0:0:0:0:0:0:0:1")).toBe(loopback6);
				expect(challenge.$canonicalAddress("::1%1")).toBe(loopback6);
			});

			it("canonicalises address literals without java.net.InetAddress (RustCFML)", () => {
				var challenge = new wheels.public.CliChallenge();
				expect(challenge.$canonicalAddress("10.0.255.1")).toBe("0a00ff01");
				expect(challenge.$canonicalAddress("0:0:0:0:0:0:0:1%lo0")).toBe(loopback6);
				expect(challenge.$canonicalAddress("[::1]")).toBe(loopback6);
				expect(challenge.$canonicalAddress("0:0:0:0:0:ffff:7f00:1")).toBe("7f000001");
				expect(challenge.$canonicalAddress("FE80::1:2%eth0")).toBe("fe800000000000000000000000010002");
				expect(challenge.$canonicalAddress("2001:db8::")).toBe("20010db8000000000000000000000000");
				expect(challenge.$canonicalAddress("64:ff9b::192.0.2.33")).toBe("0064ff9b0000000000000000c0000221");
			});

			it("rejects anything that is not an address literal", () => {
				var challenge = new wheels.public.CliChallenge();
				var bad = [
					"", "localhost", "256.0.0.1", "1.2.3", "1.2.3.4.5", "1.2.3.x", "1..2.3",
					"1:2:3:4:5:6:7:8:9", "1::2::3", "12345::1", "::g", "%1", "1:2:3:4:5:6:7::8"
				];
				for (var literal in bad) {
					var state = {threw = false};
					try {
						challenge.$canonicalAddress(literal);
					} catch (any e) {
						state.threw = true;
					}
					expect(state.threw).toBeTrue("accepted [#literal#]");
				}
			});

		});

		describe("CliChallenge.respond() (##3769)", () => {

			beforeEach(() => {
				variables.tokenFile = GetTempDirectory() & "wheels-cli-token-#CreateUUID()#";
				FileWrite(variables.tokenFile, token);
			});

			afterEach(() => {
				if (FileExists(variables.tokenFile)) {
					FileDelete(variables.tokenFile);
				}
			});

			it("answers the MAC over the connection it was asked on", () => {
				var answer = new wheels.public.CliChallenge().respond(
					nonce = nonce,
					version = "1",
					tokenPath = variables.tokenFile,
					localAddr = "127.0.0.1",
					localPort = 8080,
					remoteAddr = "127.0.0.1",
					remotePort = 54321
				);
				expect(answer.status).toBe(200);
				expect(Compare(answer.body.mac, ipv4Mac)).toBe(0);
			});

			it("binds the MAC to the connection: another client port gets another MAC", () => {
				var answer = new wheels.public.CliChallenge().respond(
					nonce = nonce,
					version = "1",
					tokenPath = variables.tokenFile,
					localAddr = "127.0.0.1",
					localPort = 8080,
					remoteAddr = "127.0.0.1",
					remotePort = 54322
				);
				expect(Compare(answer.body.mac, ipv4Mac)).notToBe(0);
			});

			it("rejects a nonce that is not exactly 64 lowercase hex characters", () => {
				var challenge = new wheels.public.CliChallenge();
				for (var bad in ["", "abc", UCase(nonce), nonce & "0", Left(nonce, 63) & "g", nonce & Chr(10)]) {
					var answer = challenge.respond(
						nonce = bad,
						version = "1",
						tokenPath = variables.tokenFile,
						localAddr = "127.0.0.1",
						localPort = 8080,
						remoteAddr = "127.0.0.1",
						remotePort = 54321
					);
					expect(answer.status).toBe(400);
					expect(StructKeyExists(answer.body, "mac")).toBeFalse();
				}
			});

			it("rejects an unknown protocol version", () => {
				var answer = new wheels.public.CliChallenge().respond(
					nonce = nonce,
					version = "2",
					tokenPath = variables.tokenFile,
					localAddr = "127.0.0.1",
					localPort = 8080,
					remoteAddr = "127.0.0.1",
					remotePort = 54321
				);
				expect(answer.status).toBe(400);
			});

			it("answers one generic 'unavailable' without a token, or with a malformed one", () => {
				var challenge = new wheels.public.CliChallenge();
				var missing = challenge.respond(
					nonce = nonce,
					version = "1",
					tokenPath = variables.tokenFile & "-missing",
					localAddr = "127.0.0.1",
					localPort = 8080,
					remoteAddr = "127.0.0.1",
					remotePort = 54321
				);
				FileWrite(variables.tokenFile, "not-a-token");
				var malformed = challenge.respond(
					nonce = nonce,
					version = "1",
					tokenPath = variables.tokenFile,
					localAddr = "127.0.0.1",
					localPort = 8080,
					remoteAddr = "127.0.0.1",
					remotePort = 54321
				);
				for (var answer in [missing, malformed]) {
					expect(answer.status).toBe(200);
					expect(answer.body.unavailable).toBeTrue();
					expect(StructKeyExists(answer.body, "mac")).toBeFalse();
				}
				expect(SerializeJSON(missing.body)).toBe(SerializeJSON(malformed.body));
			});

			it("never carries the token, even when the MAC step fails with it in the message", () => {
				var challenge = new wheels.public.CliChallenge();
				prepareMock(challenge);
				challenge.$("$mac").$throws(type = "Test.Boom", message = "HMAC failed for key " & token);
				var answer = challenge.respond(
					nonce = nonce,
					version = "1",
					tokenPath = variables.tokenFile,
					localAddr = "127.0.0.1",
					localPort = 8080,
					remoteAddr = "127.0.0.1",
					remotePort = 54321
				);
				expect(answer.status).toBe(200);
				expect(answer.body.unavailable).toBeTrue();
				expect(FindNoCase(token, SerializeJSON(answer))).toBe(0);
			});

		});

		describe("Public.cli() answers the challenge in the right place (##3769)", () => {

			var source = FileRead(ExpandPath("/wheels/Public.cfc"));

			it("after the production gate and before the bridge preamble", () => {
				var start = ReFindNoCase("function\s+cli\s*\(", source);
				expect(start).toBeGT(0);
				var body = Mid(source, start, 800);
				var gatePos = Find("$blockInProduction()", body);
				var challengePos = Find("cliChallenge", body);
				var includePos = Find("/wheels/public/views/cli.cfm", body);
				expect(gatePos).toBeGT(0);
				expect(challengePos).toBeGT(gatePos);
				expect(includePos).toBeGT(challengePos);
			});

			it("$cliChallenge() catches every failure before it writes the answer", () => {
				var start = ReFindNoCase("function\s+\$cliChallenge\s*\(", source);
				expect(start).toBeGT(0);
				var body = Mid(source, start, 1600);
				var tryPos = Find("try {", body);
				var catchPos = Find("catch (any e)", body);
				var writePos = Find("WriteOutput(", body);
				expect(tryPos).toBeGT(0);
				expect(catchPos).toBeGT(tryPos);
				expect(writePos).toBeGT(catchPos);
			});

		});

	}

}

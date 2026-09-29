/**
 * Server half of the Wheels CLI connection challenge (#3769).
 *
 * `wheels start` writes a per-start token, readable by the starting OS user
 * only, into the server's own registry directory (its catalina.base). Before
 * the CLI sends anything secret, it asks `/wheels/cli?command=cliChallenge`
 * with a random nonce, and this answers with an HMAC over the nonce and the
 * connection as this server sees it. The CLI checks the answer against its
 * own side of the same connection.
 *
 * The wire format must match cli/lucli/services/ServerChallenge.cfc byte for
 * byte (both suites assert the same test vector):
 *
 *   key     = the token's 64 lowercase hex characters, as UTF-8 bytes
 *   message = "wheels-cli-challenge/v1" LF nonce LF
 *             serverAddr ":" serverPort LF clientAddr ":" clientPort   (UTF-8)
 *   mac     = HMAC-SHA256(key, message), lowercase hex
 *
 * Addresses are the lowercase hex of the address bytes (no IPv6 scope id; an
 * IPv4-mapped IPv6 address collapses to IPv4): 127.0.0.1 is "7f000001".
 *
 * The token never leaves this component: every answer is either the MAC, one
 * generic "unavailable", or a 400 for a malformed nonce, and any failure
 * (including one whose message would quote the token) becomes "unavailable".
 */
component {

	public any function init() {
		return this;
	}

	/**
	 * `{status, body}` for a challenge request. `nonce` is the raw query
	 * value; the addresses are the servlet request's local (this server's
	 * end) and remote (the client's end) addresses as it reports them.
	 */
	public struct function respond(
		required string nonce,
		required string version,
		required string tokenPath,
		required string localAddr,
		required numeric localPort,
		required string remoteAddr,
		required numeric remotePort
	) {
		var unavailable = {status = 200, body = {"v" = 1, "unavailable" = true}};
		try {
			if (arguments.version != "1" || !$isHex64(arguments.nonce)) {
				return {status = 400, body = {"v" = 1, "error" = "bad-request"}};
			}
			var token = $readToken(arguments.tokenPath);
			if (!Len(token)) {
				return unavailable;
			}
			var messageText = $message(
				nonce = arguments.nonce,
				serverAddr = $canonicalAddress(arguments.localAddr),
				serverPort = arguments.localPort,
				clientAddr = $canonicalAddress(arguments.remoteAddr),
				clientPort = arguments.remotePort
			);
			return {status = 200, body = {"v" = 1, "mac" = $mac(token, messageText)}};
		} catch (any e) {
			return unavailable;
		}
	}

	/** The token at `tokenPath`, or "" unless it is exactly 64 lowercase hex characters. */
	public string function $readToken(required string tokenPath) {
		if (!Len(arguments.tokenPath) || !FileExists(arguments.tokenPath)) {
			return "";
		}
		var token = Trim(FileRead(arguments.tokenPath, "utf-8"));
		return $isHex64(token) ? token : "";
	}

	/**
	 * Exactly 64 lowercase hex characters. The length check matters: in
	 * CFML's regex dialect `$` also matches before a trailing newline.
	 */
	public boolean function $isHex64(required string value) {
		return Len(arguments.value) == 64 && ReFind("^[0-9a-f]+$", arguments.value) > 0;
	}

	/** `<catalina.base>/wheels-cli.token`, or "" when the JVM has no catalina.base. */
	public string function $tokenPath() {
		var base = CreateObject("java", "java.lang.System").getProperty("catalina.base");
		if (IsNull(base) || !Len(base)) {
			return "";
		}
		return base & "/wheels-cli.token";
	}

	/** Lowercase hex of the address bytes; IPv4-mapped IPv6 collapses to IPv4. */
	public string function $canonicalAddress(required string literal) {
		var bytes = CreateObject("java", "java.net.InetAddress").getByName(arguments.literal).getAddress();
		var hex = LCase(BinaryEncode(bytes, "hex"));
		if (Len(hex) == 32 && Left(hex, 24) == "00000000000000000000ffff") {
			return Right(hex, 8);
		}
		return hex;
	}

	public string function $message(
		required string nonce,
		required string serverAddr,
		required numeric serverPort,
		required string clientAddr,
		required numeric clientPort
	) {
		var lf = Chr(10);
		return "wheels-cli-challenge/v1" & lf & arguments.nonce & lf
			& arguments.serverAddr & ":" & Int(arguments.serverPort) & lf
			& arguments.clientAddr & ":" & Int(arguments.clientPort);
	}

	/** HMAC-SHA256 keyed by the token's UTF-8 bytes; lowercase hex (CFML's Hmac() is uppercase). */
	public string function $mac(required string token, required string messageText) {
		return LCase(Hmac(arguments.messageText, arguments.token, "HmacSHA256", "utf-8"));
	}

}

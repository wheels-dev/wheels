/**
 * The CLI half of the dev-server connection challenge (#3769).
 *
 * `wheels start` gives each server a per-start token (ServerRegistry
 * .writeStartToken). Before the CLI writes anything secret on a connection,
 * it sends a random nonce to `/wheels/cli?command=cliChallenge`, and the
 * server answers with an HMAC over the nonce and the connection as the
 * server sees it. Only a process that can read the owner-only token can
 * answer, and binding the connection's addresses and ports stops a listener
 * from relaying the nonce to the real server over its own connection.
 *
 * The wire format is pinned, and vendor/wheels/public/CliChallenge.cfc must
 * produce exactly the same bytes (both suites assert the same test vector):
 *
 *   key     = the token's 64 lowercase hex characters, as UTF-8 bytes
 *   message = "wheels-cli-challenge/v1" LF nonce LF
 *             serverAddr ":" serverPort LF clientAddr ":" clientPort   (UTF-8)
 *   mac     = HMAC-SHA256(key, message), lowercase hex
 *
 * Addresses are the canonical bytes of the address (no IPv6 scope id; an
 * IPv4-mapped IPv6 address collapses to its IPv4 bytes), as lowercase hex:
 * 127.0.0.1 is "7f000001", ::1 is "00000000000000000000000000000001".
 * serverAddr/serverPort are the endpoint the client connected to.
 */
component {

	variables.PREFIX = "wheels-cli-challenge/v1";

	/** 32 random bytes from SecureRandom, as 64 lowercase hex characters. */
	public string function newSecret() {
		var bytes = createObject("java", "java.lang.reflect.Array").newInstance(
			createObject("java", "java.lang.Byte").TYPE,
			javaCast("int", 32)
		);
		createObject("java", "java.security.SecureRandom").init().nextBytes(bytes);
		return lCase(binaryEncode(bytes, "hex"));
	}

	/**
	 * Canonical form of a java.net.InetAddress: the lowercase hex of its raw
	 * bytes, with an IPv4-mapped IPv6 address reduced to its IPv4 bytes. Raw
	 * bytes carry no scope id, so `::1%lo0` and `::1` agree.
	 */
	public string function canonicalAddress(required any inetAddress) {
		var hex = lCase(binaryEncode(arguments.inetAddress.getAddress(), "hex"));
		if (len(hex) == 32 && left(hex, 24) == "00000000000000000000ffff") {
			return right(hex, 8);
		}
		return hex;
	}

	/** canonicalAddress() of an address literal (never a DNS lookup for a literal). */
	public string function canonicalAddressOf(required string literal) {
		return canonicalAddress(createObject("java", "java.net.InetAddress").getByName(arguments.literal));
	}

	public string function message(
		required string nonce,
		required string serverAddr,
		required numeric serverPort,
		required string clientAddr,
		required numeric clientPort
	) {
		var lf = chr(10);
		return variables.PREFIX & lf & arguments.nonce & lf
			& arguments.serverAddr & ":" & int(arguments.serverPort) & lf
			& arguments.clientAddr & ":" & int(arguments.clientPort);
	}

	/** HMAC-SHA256 of `message` keyed by the token's UTF-8 bytes, lowercase hex. */
	public string function mac(required string token, required string message) {
		var algorithm = "HmacSHA256";
		var keySpec = createObject("java", "javax.crypto.spec.SecretKeySpec").init(
			charsetDecode(arguments.token, "utf-8"),
			algorithm
		);
		var hmac = createObject("java", "javax.crypto.Mac").getInstance(algorithm);
		hmac.init(keySpec);
		return lCase(binaryEncode(hmac.doFinal(charsetDecode(arguments.message, "utf-8")), "hex"));
	}

	/**
	 * The MAC a server holding `token` must return for `nonce` on the
	 * connection `sock` (a connected java.net.Socket), from the CLI's side of
	 * it: the server end is the socket's remote address, the client end its
	 * local one.
	 */
	public string function expectedMac(required string token, required string nonce, required any sock) {
		return mac(
			arguments.token,
			message(
				nonce = arguments.nonce,
				serverAddr = canonicalAddress(arguments.sock.getInetAddress()),
				serverPort = arguments.sock.getPort(),
				clientAddr = canonicalAddress(arguments.sock.getLocalAddress()),
				clientPort = arguments.sock.getLocalPort()
			)
		);
	}

	/**
	 * Constant-time comparison of two 32-byte MACs given as hex (either case).
	 * Anything that is not exactly 64 hex characters never matches.
	 */
	public boolean function macsMatch(required string expected, required string actual) {
		if (!$isHex(arguments.expected, 64, true) || !$isHex(arguments.actual, 64, true)) {
			return false;
		}
		return createObject("java", "java.security.MessageDigest").isEqual(
			binaryDecode(arguments.expected, "hex"),
			binaryDecode(arguments.actual, "hex")
		);
	}

	public boolean function isNonce(required string value) {
		return $isHex(arguments.value, 64, false);
	}

	/**
	 * `length` hex characters exactly (lowercase unless `anyCase`). The
	 * length check matters: in CFML's regex dialect `$` also matches before
	 * a trailing newline.
	 */
	public boolean function $isHex(required string value, required numeric length, boolean anyCase = false) {
		if (len(arguments.value) != arguments.length) return false;
		return reFind(arguments.anyCase ? "^[0-9a-fA-F]+$" : "^[0-9a-f]+$", arguments.value) > 0;
	}

}

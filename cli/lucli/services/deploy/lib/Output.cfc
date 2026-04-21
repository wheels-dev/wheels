/**
 * Host-prefixed line-buffered output sink. Matches SSHKit's default UX:
 * every emitted line is `[hostname] text`. Buffers partial lines per-host
 * until a newline arrives so interleaving from concurrent hosts stays
 * readable.
 *
 * Construct with a PrintStream sink (default java.lang.System.out).
 */
component {

	public Output function init(any sink = "") {
		variables.sink = isSimpleValue(arguments.sink) && arguments.sink == ""
			? createObject("java", "java.lang.System").out
			: arguments.sink;
		variables.buffers = {};
		return this;
	}

	public void function write(required string host, required string chunk) {
		var buf = variables.buffers[arguments.host] ?: "";
		var combined = buf & arguments.chunk;
		var lines = listToArray(combined, chr(10), true);
		var endsWithNewline = right(combined, 1) == chr(10);
		for (var i = 1; i <= arrayLen(lines); i++) {
			var isLast = (i == arrayLen(lines));
			if (isLast && !endsWithNewline) {
				variables.buffers[arguments.host] = lines[i];
			} else {
				variables.sink.println("[#arguments.host#] #lines[i]#");
			}
		}
		if (endsWithNewline) variables.buffers[arguments.host] = "";
	}

	public void function flush(required string host) {
		var buf = variables.buffers[arguments.host] ?: "";
		if (len(buf)) {
			variables.sink.println("[#arguments.host#] #buf#");
			variables.buffers[arguments.host] = "";
		}
	}

}

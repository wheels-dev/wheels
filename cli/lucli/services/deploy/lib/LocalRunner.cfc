/**
 * Runs deploy's local commands (registry login, image build and push) on this
 * machine. Argv only: no shell interprets the arguments. Secrets go on stdin.
 * Merged stdout/stderr is read line by line until EOF, so the child can never
 * block on a full pipe while the deploy holds its locks; each line is redacted
 * before it reaches the sink, and a bounded redacted tail is kept for the
 * failure message.
 */
component {

	variables.tailLines = 100;

	/** @sink function(line) receiving each redacted output line; default prints it. */
	public LocalRunner function init(any sink = "") {
		variables.sink = isCustomFunction(arguments.sink) || isClosure(arguments.sink) ? arguments.sink : "";
		return this;
	}

	/** Returns {exitCode, outputTail}. */
	public struct function run(required array argv, string stdin = "") {
		var redaction = new SecretRedaction();
		var pb = createObject("java", "java.lang.ProcessBuilder").init(arguments.argv);
		pb.redirectErrorStream(true);
		var proc = pb.start();
		var input = proc.getOutputStream();
		if (len(arguments.stdin)) {
			input.write(charsetDecode(arguments.stdin, "utf-8"));
		}
		input.close();
		var reader = createObject("java", "java.io.BufferedReader").init(
			createObject("java", "java.io.InputStreamReader").init(proc.getInputStream(), "UTF-8")
		);
		var tail = [];
		try {
			var line = reader.readLine();
			while (!isNull(line)) {
				var shown = redaction.redact(line);
				$emit(shown);
				arrayAppend(tail, shown);
				if (arrayLen(tail) > variables.tailLines) {
					arrayDeleteAt(tail, 1);
				}
				line = reader.readLine();
			}
		} finally {
			reader.close();
		}
		proc.waitFor();
		return {exitCode: proc.exitValue(), outputTail: arrayToList(tail, chr(10))};
	}

	private void function $emit(required string line) {
		if (isSimpleValue(variables.sink)) {
			createObject("java", "java.lang.System").out.println(arguments.line);
			return;
		}
		variables.sink(arguments.line);
	}

}

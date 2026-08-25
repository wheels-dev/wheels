component {

	public SseWriterFake function init() {
		variables.chunks = [];
		variables.checks = 0;
		return this;
	}

	public void function write(required string text) {
		ArrayAppend(variables.chunks, arguments.text);
	}

	public void function flush() {
	}

	public boolean function checkError() {
		variables.checks = variables.checks + 1;
		return variables.checks > 1;
	}

	public array function chunks() {
		return variables.chunks;
	}

}

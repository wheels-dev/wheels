/**
 * A RustCFML engine backend that records start()/stop() calls instead of
 * launching anything. `running` sets what status() reports. Used to pin the
 * one-engine-per-project rules in start/stop (#3913).
 */
component {

	this.running = false;
	this.calls = {start = 0, stop = 0};

	public any function init(boolean running = false) {
		this.running = arguments.running;
		return this;
	}

	public struct function status(required string projectRoot) {
		return this.running ? {running = true, pid = 4242, port = 8931} : {running = false};
	}

	public struct function start(required string projectRoot, numeric port = 8513) {
		this.calls.start++;
		this.running = true;
		return {pid = 4242, port = arguments.port, log = "/dev/null"};
	}

	public string function stop(required string projectRoot) {
		this.calls.stop++;
		var was = this.running;
		this.running = false;
		return was;
	}

}

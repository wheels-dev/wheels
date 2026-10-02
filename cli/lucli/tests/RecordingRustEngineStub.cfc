/**
 * A RustCFML engine backend that records start()/stop() calls instead of
 * launching anything. `running` sets what status() reports. Used to pin the
 * one-engine-per-project rules in start/stop (#3913).
 */
component {

	this.running = false;
	this.calls = {start = 0, stop = 0, install = 0};
	this.lastPort = 0;
	this.installed = true;

	public any function init(boolean running = false, boolean installed = true) {
		this.running = arguments.running;
		this.installed = arguments.installed;
		return this;
	}

	public boolean function isInstalled() {
		return this.installed;
	}

	public string function getEngineVersion() {
		return "0.0.0-stub";
	}

	public string function install() {
		this.calls.install++;
		this.installed = true;
		return "/dev/null";
	}

	public struct function status(required string projectRoot) {
		return this.running ? {running = true, pid = 4242, port = 8931} : {running = false};
	}

	public struct function start(required string projectRoot, numeric port = 8513) {
		this.calls.start++;
		this.lastPort = arguments.port;
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

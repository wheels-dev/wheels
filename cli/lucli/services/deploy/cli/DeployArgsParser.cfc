/**
 * Deploy-only flag parser. Split out from Module.cfc::$deployArgsToOptions so it
 * can be unit-tested without depending on the BaseModule mapping (which only
 * exists inside the LuCLI runtime, not in the WheelsTest test harness).
 *
 * Issue #2674: --version is a picocli-absorbed root flag, so Kamal's documented
 * `wheels deploy --version=v1.2.3` form fails before Module.cfc runs. We accept
 * --release as a picocli-safe alias here; brew/scoop wrappers rewrite
 * --version[=val] -> --release[=val] when "deploy" is the first positional.
 */
component {

    public DeployArgsParser function init() {
        return this;
    }

    public struct function parse(required array args) {
        var opts = {};
        var n = arrayLen(arguments.args);
        var i = 1;
        while (i <= n) {
            var a = arguments.args[i];
            if (a == "--dry-run") {
                opts.dryRun = true;
            } else if (left(a, 14) == "--destination=") {
                opts.destination = mid(a, 15, 99999);
            } else if (a == "--destination" && i < n) {
                opts.destination = arguments.args[i+1];
                i++;
            } else if (left(a, 10) == "--version=") {
                // Documented Kamal-compatible form. picocli normally absorbs --version
                // before the parser runs, so this arm is reachable only when a wrapper
                // has rewritten --version -> --release first, or when arrays are
                // constructed programmatically (tests).
                opts.version = mid(a, 11, 99999);
            } else if (a == "--version" && i < n) {
                opts.version = arguments.args[i+1];
                i++;
            } else if (left(a, 10) == "--release=") {
                // picocli-safe alias for --version (issue #2674).
                opts.version = mid(a, 11, 99999);
            } else if (a == "--release" && i < n) {
                opts.version = arguments.args[i+1];
                i++;
            } else if (left(a, 13) == "--configPath=") {
                opts.configPath = mid(a, 14, 99999);
            } else if (a == "--configPath" && i < n) {
                opts.configPath = arguments.args[i+1];
                i++;
            } else if (left(a, 9) == "--config=") {
                // Alias for --configPath — the deploy guides document --config. CLI audit H9.
                opts.configPath = mid(a, 10, 99999);
            } else if (a == "--config" && i < n) {
                opts.configPath = arguments.args[i+1];
                i++;
            } else if (a == "--force") {
                opts.force = true;
            } else if (left(a, 10) == "--service=") {
                opts.service = mid(a, 11, 99999);
            } else if (a == "--service" && i < n) {
                opts.service = arguments.args[i+1];
                i++;
            } else if (left(a, 8) == "--image=") {
                opts.image = mid(a, 9, 99999);
            } else if (a == "--image" && i < n) {
                opts.image = arguments.args[i+1];
                i++;
            } else if (left(a, 20) == "--registry-username=") {
                opts.registryUsername = mid(a, 21, 99999);
            } else if (a == "--registry-username" && i < n) {
                opts.registryUsername = arguments.args[i+1];
                i++;
            } else if (left(a, 7) == "--host=") {
                opts.host = mid(a, 8, 99999);
            } else if (a == "--host" && i < n) {
                opts.host = arguments.args[i+1];
                i++;
            } else if (left(a, 7) == "--keep=") {
                opts.keep = mid(a, 8, 99999);
            } else if (a == "--keep" && i < n) {
                opts.keep = arguments.args[i+1];
                i++;
            } else if (left(a, 10) == "--message=") {
                opts.message = mid(a, 11, 99999);
            } else if (a == "--message" && i < n) {
                opts.message = arguments.args[i+1];
                i++;
            } else if (left(a, 10) == "--adapter=") {
                opts.adapter = mid(a, 11, 99999);
            } else if (a == "--adapter" && i < n) {
                opts.adapter = arguments.args[i+1];
                i++;
            } else if (left(a, 10) == "--account=") {
                opts.account = mid(a, 11, 99999);
            } else if (a == "--account" && i < n) {
                opts.account = arguments.args[i+1];
                i++;
            } else if (left(a, 7) == "--from=") {
                opts.from = mid(a, 8, 99999);
            } else if (a == "--from" && i < n) {
                opts.from = arguments.args[i+1];
                i++;
            } else if (a == "--confirm") {
                opts.confirm = true;
            } else if (left(a, 7) == "--tail=") {
                opts.tail = mid(a, 8, 99999);
            } else if (a == "--tail" && i < n) {
                opts.tail = arguments.args[i+1];
                i++;
            } else if (left(a, 7) == "--role=") {
                // `deploy app <verb>` role filter; DeployAppCli reads opts.role. CLI audit H9.
                opts.role = mid(a, 8, 99999);
            } else if (a == "--role" && i < n) {
                opts.role = arguments.args[i+1];
                i++;
            } else if (left(a, 12) == "--container=") {
                opts.container = mid(a, 13, 99999);
            } else if (a == "--container" && i < n) {
                opts.container = arguments.args[i+1];
                i++;
            } else if (a == "--follow") {
                opts.follow = true;
            }
            i++;
        }
        return opts;
    }
}

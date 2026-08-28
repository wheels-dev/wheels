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
            i = $matchFlag(opts, arguments.args, i, n);
        }
        return opts;
    }

    /**
     * Matches the token at position i against the grouped flag parsers and
     * returns the index of the next token to inspect. A value-taking flag in
     * its space-separated form consumes two tokens (returns i + 2); every other
     * token — a matched single-token flag or an unrecognized token — returns
     * i + 1, matching the original single-pass loop's unconditional `i++`.
     */
    private numeric function $matchFlag(required struct opts, required array args, required numeric i, required numeric n) {
        var next = $parseDeployFlags(arguments.opts, arguments.args, arguments.i, arguments.n);
        if (next) {
            return next;
        }
        next = $parseConfigFlags(arguments.opts, arguments.args, arguments.i, arguments.n);
        if (next) {
            return next;
        }
        next = $parseBuildFlags(arguments.opts, arguments.args, arguments.i, arguments.n);
        if (next) {
            return next;
        }
        next = $parseRuntimeFlags(arguments.opts, arguments.args, arguments.i, arguments.n);
        if (next) {
            return next;
        }
        next = $parseAppFlags(arguments.opts, arguments.args, arguments.i, arguments.n);
        if (next) {
            return next;
        }
        return arguments.i + 1;
    }

    /**
     * Parses --dry-run, --destination, --version, and --release.
     */
    private numeric function $parseDeployFlags(required struct opts, required array args, required numeric i, required numeric n) {
        var a = arguments.args[arguments.i];
        if (a == "--dry-run") {
            arguments.opts.dryRun = true;
            return arguments.i + 1;
        } else if (left(a, 14) == "--destination=") {
            arguments.opts.destination = mid(a, 15, 99999);
            return arguments.i + 1;
        } else if (a == "--destination" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.destination = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 10) == "--version=") {
            // Documented Kamal-compatible form. picocli normally absorbs --version
            // before the parser runs, so this arm is reachable only when a wrapper
            // has rewritten --version -> --release first, or when arrays are
            // constructed programmatically (tests).
            arguments.opts.version = mid(a, 11, 99999);
            return arguments.i + 1;
        } else if (a == "--version" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.version = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 10) == "--release=") {
            // picocli-safe alias for --version (issue #2674).
            arguments.opts.version = mid(a, 11, 99999);
            return arguments.i + 1;
        } else if (a == "--release" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.version = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        }
        return 0;
    }

    /**
     * Parses --configPath, --config (alias), --force, and --service.
     */
    private numeric function $parseConfigFlags(required struct opts, required array args, required numeric i, required numeric n) {
        var a = arguments.args[arguments.i];
        if (left(a, 13) == "--configPath=") {
            arguments.opts.configPath = mid(a, 14, 99999);
            return arguments.i + 1;
        } else if (a == "--configPath" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.configPath = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 9) == "--config=") {
            // Alias for --configPath — the deploy guides document --config. CLI audit H9.
            arguments.opts.configPath = mid(a, 10, 99999);
            return arguments.i + 1;
        } else if (a == "--config" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.configPath = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (a == "--force") {
            arguments.opts.force = true;
            return arguments.i + 1;
        } else if (left(a, 10) == "--service=") {
            arguments.opts.service = mid(a, 11, 99999);
            return arguments.i + 1;
        } else if (a == "--service" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.service = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        }
        return 0;
    }

    /**
     * Parses --image, --registry-username, --host, and --keep.
     */
    private numeric function $parseBuildFlags(required struct opts, required array args, required numeric i, required numeric n) {
        var a = arguments.args[arguments.i];
        if (left(a, 8) == "--image=") {
            arguments.opts.image = mid(a, 9, 99999);
            return arguments.i + 1;
        } else if (a == "--image" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.image = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 20) == "--registry-username=") {
            arguments.opts.registryUsername = mid(a, 21, 99999);
            return arguments.i + 1;
        } else if (a == "--registry-username" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.registryUsername = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 7) == "--host=") {
            arguments.opts.host = mid(a, 8, 99999);
            return arguments.i + 1;
        } else if (a == "--host" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.host = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 7) == "--keep=") {
            arguments.opts.keep = mid(a, 8, 99999);
            return arguments.i + 1;
        } else if (a == "--keep" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.keep = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        }
        return 0;
    }

    /**
     * Parses --message, --adapter, --account, and --from.
     */
    private numeric function $parseRuntimeFlags(required struct opts, required array args, required numeric i, required numeric n) {
        var a = arguments.args[arguments.i];
        if (left(a, 10) == "--message=") {
            arguments.opts.message = mid(a, 11, 99999);
            return arguments.i + 1;
        } else if (a == "--message" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.message = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 10) == "--adapter=") {
            arguments.opts.adapter = mid(a, 11, 99999);
            return arguments.i + 1;
        } else if (a == "--adapter" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.adapter = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 10) == "--account=") {
            arguments.opts.account = mid(a, 11, 99999);
            return arguments.i + 1;
        } else if (a == "--account" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.account = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 7) == "--from=") {
            arguments.opts.from = mid(a, 8, 99999);
            return arguments.i + 1;
        } else if (a == "--from" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.from = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        }
        return 0;
    }

    /**
     * Parses --confirm, --tail, --role, --container, and --follow.
     */
    private numeric function $parseAppFlags(required struct opts, required array args, required numeric i, required numeric n) {
        var a = arguments.args[arguments.i];
        if (a == "--confirm") {
            arguments.opts.confirm = true;
            return arguments.i + 1;
        } else if (left(a, 7) == "--tail=") {
            arguments.opts.tail = mid(a, 8, 99999);
            return arguments.i + 1;
        } else if (a == "--tail" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.tail = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 7) == "--role=") {
            // `deploy app <verb>` role filter; DeployAppCli reads opts.role. CLI audit H9.
            arguments.opts.role = mid(a, 8, 99999);
            return arguments.i + 1;
        } else if (a == "--role" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.role = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (left(a, 12) == "--container=") {
            arguments.opts.container = mid(a, 13, 99999);
            return arguments.i + 1;
        } else if (a == "--container" && $nextIsValue(arguments.args, arguments.i, arguments.n)) {
            arguments.opts.container = arguments.args[arguments.i + 1];
            return arguments.i + 2;
        } else if (a == "--follow") {
            arguments.opts.follow = true;
            return arguments.i + 1;
        }
        return 0;
    }

    /**
     * True when the token after position i exists and is a plain value, not
     * another `--` flag. Guards every space-separated `--flag value` arm so a
     * value-taking flag with a missing value can never swallow the flag that
     * follows it — before this, `--release --dry-run` consumed --dry-run as
     * the version and a documented dry run dispatched live SSH (issue #3111).
     * Mirrors the identical rule in Module.cfc::$deployStripFlags.
     */
    private boolean function $nextIsValue(required array args, required numeric i, required numeric n) {
        return arguments.i < arguments.n && left(arguments.args[arguments.i + 1], 2) != "--";
    }
}

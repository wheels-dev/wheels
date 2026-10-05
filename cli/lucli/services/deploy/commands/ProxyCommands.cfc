/**
 * kamal-proxy invocations.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/proxy.rb
 * kamal-proxy version pinned: v0.8.6
 *
 * deploy(role, target) is THE load-bearing hand-off point. Emits a
 * `docker exec kamal-proxy kamal-proxy deploy ...` that runs the
 * kamal-proxy CLI inside the already-booted proxy container. This is
 * Kamal's convention and required for on-server parity.
 */
component extends="Base" {

    variables.PROXY_IMAGE = "basecamp/kamal-proxy:v0.8.6";
    variables.PROXY_CONTAINER_NAME = "kamal-proxy";

    public ProxyCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function boot() {
        return docker(
            "run",
            "--detach",
            "--restart unless-stopped",
            "--name", variables.PROXY_CONTAINER_NAME,
            "--network kamal",
            "--publish 80:80",
            "--publish 443:443",
            "--volume #$remoteHome()#/.config/kamal-proxy:/home/kamal-proxy/.config/kamal-proxy",
            variables.PROXY_IMAGE
        );
    }

    /**
     * @healthCheckTimeout Seconds, overriding proxy.healthcheck.timeout for this
     *                     one call: the migrate host's health check waits while
     *                     the migrations run (#4063). 0 keeps the configured value.
     */
    public string function deploy(required any role, required string target, numeric healthCheckTimeout = 0) {
        var p = variables.config.proxy();
        var hc = p.healthcheck();
        var innerArgs = [
            "kamal-proxy", "deploy", variables.config.service(),
            "--target", shellEscape(arguments.target)
        ];
        // Host routing and TLS (Let's Encrypt), as Kamal 2 passes them.
        if (len(p.host())) {
            arrayAppend(innerArgs, ["--host", shellEscape(p.host())], true);
        }
        if (p.ssl()) {
            arrayAppend(innerArgs, "--tls");
        }
        arrayAppend(innerArgs, [
            "--health-check-path", shellEscape(hc.path ?: "/up"),
            "--health-check-interval", $duration(hc.interval ?: 1),
            "--health-check-timeout", $duration(arguments.healthCheckTimeout > 0 ? arguments.healthCheckTimeout : (hc.timeout ?: 30))
        ], true);
        return docker("exec", variables.PROXY_CONTAINER_NAME) & " " & arrayToList(innerArgs, " ");
    }

    public string function remove() {
        return chain([
            docker("stop", variables.PROXY_CONTAINER_NAME),
            docker("rm", variables.PROXY_CONTAINER_NAME)
        ]);
    }

    public string function details() {
        return docker("ps", "--filter", "name=#variables.PROXY_CONTAINER_NAME#");
    }

    public string function logs(struct opts = {}) {
        var tail = arguments.opts.tail ?: 100;
        return docker("logs", "--tail", tail, variables.PROXY_CONTAINER_NAME);
    }

    public string function reboot() {
        // Stop, remove, rebuild — in order. Returns a single chained command.
        return chain([
            remove(),   // stops + rms
            boot()      // rebuilds
        ]);
    }

    public string function start() {
        return docker("start", variables.PROXY_CONTAINER_NAME);
    }

    /**
     * Fresh-host-safe boot, mirroring Kamal's Proxy#start_or_run
     * (`combine start, run, by: "||"`): `docker start` succeeds when the
     * container already exists (running start is a no-op, stopped start
     * resumes it), and the full `docker run` fires only on a truly fresh
     * host. The previous guard — `details() || boot()` — never reached
     * boot() because `docker ps --filter` exits 0 whether or not anything
     * matches (#2957 DEP-5a).
     */
    public string function start_or_run() {
        return start() & " || " & boot();
    }

    public string function stop() {
        return docker("stop", variables.PROXY_CONTAINER_NAME);
    }

    public string function restart() {
        return docker("restart", variables.PROXY_CONTAINER_NAME);
    }

    /**
     * Home directory of the deploy user on the remote host, for the proxy
     * config volume. The previous hardcoded `/home/<user>` was wrong for
     * the DEFAULT ssh user (root's home is /root) — #2957 DEP-11c.
     * compare(), not ==: unix usernames are case-sensitive.
     */
    private string function $remoteHome() {
        var sshUser = variables.config.ssh().user();
        return compare(sshUser, "root") == 0 ? "/root" : "/home/" & sshUser;
    }

    /**
     * kamal-proxy takes Go durations: a bare number of seconds becomes "Ns";
     * an explicit duration such as "500ms" or "2m" is passed through.
     * Anything else is a config error rather than a shell token.
     */
    private string function $duration(required any value) {
        var v = trim(toString(arguments.value));
        // Seconds, whole or fractional: 3 -> 3s, 0.5 -> 0.5s.
        if (len(v) && !reFind("[^0-9.]", v) && reFind("^[0-9]+(\.[0-9]+)?$", v)) {
            return v & "s";
        }
        // An explicit Go duration with one unit: 500ms, 1.5s, 2m.
        if (len(v) && !reFind("[^0-9a-z.]", v) && reFind("^[0-9]+(\.[0-9]+)?(ns|us|ms|s|m|h)$", v)) {
            return v;
        }
        throw(type = "DeployConfigError", message = "invalid proxy healthcheck duration: '#v#' (use seconds such as 3 or 0.5, or a duration such as 500ms)");
    }
}

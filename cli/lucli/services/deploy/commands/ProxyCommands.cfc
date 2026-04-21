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
            "--volume /home/#variables.config.ssh().user()#/.config/kamal-proxy:/home/kamal-proxy/.config/kamal-proxy",
            variables.PROXY_IMAGE
        );
    }

    public string function deploy(required any role, required string target) {
        var hc = variables.config.proxy().healthcheck();
        var innerArgs = [
            "kamal-proxy", "deploy", variables.config.service(),
            "--target", arguments.target,
            "--health-check-path", hc.path ?: "/up",
            "--health-check-timeout", hc.timeout ?: 30
        ];
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

    public string function stop() {
        return docker("stop", variables.PROXY_CONTAINER_NAME);
    }

    public string function restart() {
        return docker("restart", variables.PROXY_CONTAINER_NAME);
    }
}

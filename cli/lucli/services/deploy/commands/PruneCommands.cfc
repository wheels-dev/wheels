/**
 * Prune commands.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/prune.rb
 *
 * Scopes prune operations to labels owned by this service so we
 * never touch containers/images managed by other tooling on the host.
 */
component extends="Base" {

    public PruneCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function all(numeric keep = 5) {
        return chain([containers(arguments.keep), images()]);
    }

    public string function images() {
        return docker(
            "image", "prune", "-f",
            "--filter", "label=service=" & variables.config.service()
        );
    }

    public string function containers(numeric keep = 5) {
        // Grab stopped container IDs for this service, skip the most recent N, rm the rest.
        // tail -n +<N+1> skips the first N lines.
        var filterLabel = "label=service=" & variables.config.service();
        var skip = int(arguments.keep) + 1;
        return "docker ps -a --filter " & filterLabel
             & " --filter status=exited --format '{{.ID}}'"
             & " | tail -n +" & skip
             & " | xargs -r docker rm";
    }
}

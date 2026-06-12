/**
 * App container lifecycle commands.
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/app.rb
 *
 * Container name convention <service>-<role>-<version> MUST match Kamal
 * (on-server parity contract — see spec §7).
 *
 * All methods return strings. No I/O. Tests assert on exact string content.
 */
component extends="Base" {

    public AppCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function run(required any role, required string version) {
        return docker(
            "run",
            "--detach",
            "--restart unless-stopped",
            "--name #container_name(arguments.role, arguments.version)#",
            "--network kamal",
            $labelArgs(arguments.role, arguments.version),
            $envArgs(arguments.role),
            variables.config.absoluteImage(arguments.version),
            arguments.role.cmd()
        );
    }

    public string function start(required any role, required string version) {
        return docker("start", container_name(arguments.role, arguments.version));
    }

    public string function stop(required any role, required string version) {
        return docker("stop", container_name(arguments.role, arguments.version));
    }

    public string function status(required any role, required string version) {
        return docker("inspect", "--format={{.State.Status}}",
                      container_name(arguments.role, arguments.version));
    }

    public string function containers() {
        return docker("ps", "--filter", "label=service=#variables.config.service()#");
    }

    public string function images() {
        return docker("images", variables.config.image());
    }

    public string function logs(struct opts = {}) {
        var parts = ["logs"];
        var tail = arguments.opts.tail ?: 100;
        arrayAppend(parts, "--tail");
        arrayAppend(parts, tail);
        if (arguments.opts.follow ?: false) arrayAppend(parts, "--follow");
        if (len(arguments.opts.container ?: "")) arrayAppend(parts, arguments.opts.container);
        return docker(parts);
    }

    public string function container_name(required any role, required string version) {
        return "#variables.config.service()#-#arguments.role.name()#-#arguments.version#";
    }

    /**
     * Phase 2 simplification: live/maintenance use a marker file on the server
     * rather than kamal-proxy's native maintenance mode. Full proxy-native
     * semantics land in a Phase 3 follow-up task.
     */
    public string function live(required any role, required string version) {
        return "rm -f /tmp/kamal-maintenance-" & variables.config.service();
    }

    public string function maintenance(required any role, required string version) {
        return "touch /tmp/kamal-maintenance-" & variables.config.service();
    }

    public string function remove(required any role, required string version) {
        return chain([
            docker("stop", container_name(arguments.role, arguments.version)),
            docker("rm", container_name(arguments.role, arguments.version))
        ]);
    }

    private array function $labelArgs(required any role, required string version) {
        return [
            "--label", "service=#variables.config.service()#",
            "--label", "role=#arguments.role.name()#",
            "--label", "destination=#variables.config.destination()#",
            "--label", "version=#arguments.version#"
        ];
    }

    /**
     * env.clear values ride as escaped -e pairs; env.secret values NEVER
     * enter argv — run() references the remote env file (written with 600
     * perms by the orchestration layer before this command is dispatched)
     * via --env-file instead (##2957).
     */
    private array function $envArgs(required any role) {
        var env = variables.config.env();
        var parts = [];
        var clear = env.clear();
        for (var k in clear) {
            arrayAppend(parts, "-e");
            arrayAppend(parts, shellEscape(k & "=" & clear[k]));
        }
        if (arrayLen(env.secret())) {
            arrayAppend(parts, "--env-file");
            arrayAppend(parts, env_file_path(arguments.role));
        }
        return parts;
    }

    /**
     * Remote env-file path for a role, relative to the SSH user's home
     * (the cwd of every dispatched command — same convention as the lock
     * symlink). Namespaced by service and destination, mirroring Kamal's
     * .kamal/apps/<service[-destination]>/env/roles/<role>.env layout.
     */
    public string function env_file_path(required any role) {
        return $envRolesDir() & "/" & arguments.role.name() & ".env";
    }

    /**
     * Preparation command for the role env file: mkdir + touch + chmod 600
     * BEFORE the secret content is uploaded over SFTP (##2957).
     */
    public string function ensure_env_file(required any role) {
        return $ensureEnvFileCmd($envRolesDir(), env_file_path(arguments.role));
    }

    private string function $envRolesDir() {
        var ns = variables.config.service();
        if (len(variables.config.destination())) {
            ns &= "-" & variables.config.destination();
        }
        return ".kamal/apps/" & ns & "/env/roles";
    }
}

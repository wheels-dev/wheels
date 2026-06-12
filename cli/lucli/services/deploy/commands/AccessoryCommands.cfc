/**
 * Accessory container lifecycle commands.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/accessory.rb
 *
 * Each method takes an Accessory instance and returns a docker command string.
 * Container name convention: <service>-<accessory_name>
 * Labels: service=<service>-<accessory_name>, role=<accessory_name>
 */
component extends="Base" {

    public AccessoryCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function run(required any accessory) {
        return docker(
            "run",
            "--detach",
            "--restart unless-stopped",
            "--name " & arguments.accessory.containerName(),
            "--network kamal",
            $labelArgs(arguments.accessory),
            $portArgs(arguments.accessory),
            $volumeArgs(arguments.accessory),
            $envArgs(arguments.accessory),
            arguments.accessory.image(),
            arguments.accessory.cmd()
        );
    }

    public string function start(required any accessory) {
        return docker("start", arguments.accessory.containerName());
    }

    public string function stop(required any accessory) {
        return docker("stop", arguments.accessory.containerName());
    }

    public string function restart(required any accessory) {
        return docker("restart", arguments.accessory.containerName());
    }

    public string function details(required any accessory) {
        return docker("inspect", "--format={{.State.Status}}", arguments.accessory.containerName());
    }

    public string function logs(required any accessory, struct opts = {}) {
        var tail = arguments.opts.tail ?: 100;
        var follow = arguments.opts.follow ?: false;
        var parts = ["logs", "--tail", tail];
        if (follow) arrayAppend(parts, "--follow");
        arrayAppend(parts, arguments.accessory.containerName());
        return docker(parts);
    }

    public string function remove(required any accessory) {
        return chain([
            docker("stop", arguments.accessory.containerName()),
            docker("rm", arguments.accessory.containerName())
        ]);
    }

    public string function reboot(required any accessory) {
        return chain([remove(arguments.accessory), run(arguments.accessory)]);
    }

    private array function $labelArgs(required any accessory) {
        return [
            "--label", "service=" & arguments.accessory.labelService(),
            "--label", "role=" & arguments.accessory.name(),
            "--label", "destination=" & variables.config.destination()
        ];
    }

    private array function $portArgs(required any accessory) {
        if (!len(arguments.accessory.port())) return [];
        return ["--publish", arguments.accessory.port()];
    }

    private array function $volumeArgs(required any accessory) {
        var parts = [];
        for (var v in arguments.accessory.volumes()) {
            arrayAppend(parts, "--volume");
            arrayAppend(parts, v);
        }
        return parts;
    }

    /**
     * env.clear values ride as escaped -e pairs; env.secret values NEVER
     * enter argv — run() references the remote env file (written with 600
     * perms by the orchestration layer before this command is dispatched)
     * via --env-file instead (##2957).
     */
    private array function $envArgs(required any accessory) {
        var env = arguments.accessory.env();
        var parts = [];
        var clear = env.clear();
        for (var k in clear) {
            arrayAppend(parts, "-e");
            arrayAppend(parts, shellEscape(k & "=" & clear[k]));
        }
        if (arrayLen(env.secret())) {
            arrayAppend(parts, "--env-file");
            arrayAppend(parts, env_file_path(arguments.accessory));
        }
        return parts;
    }

    /**
     * Remote env-file path for an accessory, relative to the SSH user's
     * home. Namespaced by service and destination, mirroring Kamal's
     * .kamal/apps/<service[-destination]>/env/accessories/<name>.env layout.
     */
    public string function env_file_path(required any accessory) {
        return $envAccessoriesDir() & "/" & arguments.accessory.name() & ".env";
    }

    /**
     * Preparation command for the accessory env file: mkdir + touch +
     * chmod 600 BEFORE the secret content is uploaded over SFTP (##2957).
     */
    public string function ensure_env_file(required any accessory) {
        return $ensureEnvFileCmd($envAccessoriesDir(), env_file_path(arguments.accessory));
    }

    private string function $envAccessoriesDir() {
        var ns = variables.config.service();
        if (len(variables.config.destination())) {
            ns &= "-" & variables.config.destination();
        }
        return ".kamal/apps/" & ns & "/env/accessories";
    }
}

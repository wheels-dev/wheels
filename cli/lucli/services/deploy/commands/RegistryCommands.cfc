/**
 * Registry login/logout commands.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/registry.rb
 */
component extends="Base" {

    public RegistryCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    /**
     * Deliberate divergence from Kamal's `docker login -p sensitive(...)`:
     * the password is never part of the command string. It travels to the
     * remote host over the SSH exec-channel's stdin (SshClient `opts.stdin`)
     * and is consumed by `docker login --password-stdin`, so it can't leak
     * through dry-run output, exception summaries, or the remote process
     * table (##2956).
     */
    public string function login() {
        var reg = variables.config.registry();
        return docker(
            "login",
            reg.server(),
            "-u", reg.username(),
            "--password-stdin"
        );
    }

    public string function logout() {
        return docker("logout", variables.config.registry().server());
    }
}

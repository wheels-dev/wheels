/**
 * Registry login/logout commands.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/registry.rb
 */
component extends="Base" {

    public RegistryCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function login(required struct opts) {
        var reg = variables.config.registry();
        return docker(
            "login",
            reg.server(),
            "-u", reg.username(),
            "-p", arguments.opts.password ?: ""
        );
    }

    public string function logout() {
        return docker("logout", variables.config.registry().server());
    }
}

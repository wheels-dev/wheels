/**
 * Image build/push/pull commands.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/builder.rb
 */
component extends="Base" {

    public BuilderCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function push(required string version) {
        var b = variables.config.builder();
        return docker(
            "buildx", "build",
            "--push",
            "--tag", shellEscape(variables.config.absoluteImage(arguments.version)),
            "--file", shellEscape(b.dockerfile()),
            shellEscape(b.context())
        );
    }

    public string function pull(required string version) {
        return docker("pull", shellEscape(variables.config.absoluteImage(arguments.version)));
    }

    public string function tag(required string version, required string aliasName) {
        return docker(
            "tag",
            shellEscape(variables.config.absoluteImage(arguments.version)),
            shellEscape(variables.config.absoluteImage(arguments.aliasName))
        );
    }

    public string function create() {
        return docker("buildx", "create", "--name", $builderName(), "--driver=docker-container");
    }

    public string function remove() {
        return docker("buildx", "rm", $builderName());
    }

    public string function details() {
        return docker("buildx", "inspect", $builderName());
    }

    public string function dev() {
        var b = variables.config.builder();
        return docker(
            "buildx", "build",
            "--load",
            "--tag", shellEscape(variables.config.image() & ":dirty"),
            "--file", shellEscape(b.dockerfile()),
            shellEscape(b.context())
        );
    }

    public string function $builderName() {
        return "kamal-" & variables.config.service();
    }
}

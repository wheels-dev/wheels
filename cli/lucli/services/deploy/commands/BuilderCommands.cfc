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
            "--tag", variables.config.absoluteImage(arguments.version),
            "--file", b.dockerfile(),
            b.context()
        );
    }

    public string function pull(required string version) {
        return docker("pull", variables.config.absoluteImage(arguments.version));
    }

    public string function tag(required string version, required string aliasName) {
        return docker(
            "tag",
            variables.config.absoluteImage(arguments.version),
            variables.config.absoluteImage(arguments.aliasName)
        );
    }
}

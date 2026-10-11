/**
 * Image build/push/pull commands.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/builder.rb
 */
component extends="Base" {

    public BuilderCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    /**
     * Build and push the release image, honouring the `builder:` block (#4415): one `--platform`
     * list for `arch`, a `--build-arg` per `args` entry, and the service's buildx builder when
     * `remote` is set (`build create` makes it there). The image carries a `service=` label, which
     * is what `prune images` filters on.
     */
    public string function push(required string version) {
        var b = variables.config.builder();
        return docker(
            "buildx", "build",
            "--push",
            "--platform", $platforms(b.arch()),
            len(b.remote()) ? "--builder " & $builderName() : "",
            "--label", shellEscape("service=" & variables.config.service()),
            $buildArgs(b.args()),
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

    /**
     * Create the service's buildx builder; on `builder.remote` (a docker endpoint such as
     * ssh://user@host) when one is configured.
     */
    public string function create() {
        var remote = variables.config.builder().remote();
        return docker(
            "buildx", "create", "--name", $builderName(), "--driver=docker-container",
            len(remote) ? shellEscape(remote) : ""
        );
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

    /**
     * `builder.arch` as one buildx platform list: "amd64" becomes "linux/amd64"; an entry that
     * already names its OS is kept.
     */
    public string function $platforms(required array arch) {
        var platforms = [];
        for (var a in arguments.arch) {
            var p = trim(toString(a));
            if (len(p)) {
                arrayAppend(platforms, find("/", p) ? p : "linux/" & p);
            }
        }
        return arrayToList(platforms, ",");
    }

    /**
     * A `--build-arg 'KEY=value'` pair per `builder.args` entry, in key order so the command is
     * stable.
     */
    public array function $buildArgs(required struct args) {
        var rv = [];
        var keys = structKeyArray(arguments.args);
        arraySort(keys, "textnocase");
        for (var k in keys) {
            arrayAppend(rv, "--build-arg");
            arrayAppend(rv, shellEscape(k & "=" & toString(arguments.args[k])));
        }
        return rv;
    }
}

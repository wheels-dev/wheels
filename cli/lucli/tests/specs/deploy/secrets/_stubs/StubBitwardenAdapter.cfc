component extends="modules.wheels.services.deploy.secrets.BitwardenAdapter" {

    this.lastArgs = [];

    public string function $run(required array cmdArgs) {
        this.lastArgs = arguments.cmdArgs;
        // bw get password <key> — the last arg is the key.
        return "bw-" & arguments.cmdArgs[arrayLen(arguments.cmdArgs)];
    }
}

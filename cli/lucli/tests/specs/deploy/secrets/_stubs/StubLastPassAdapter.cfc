component extends="modules.wheels.services.deploy.secrets.LastPassAdapter" {

    this.lastArgs = [];

    public string function $run(required array cmdArgs) {
        this.lastArgs = arguments.cmdArgs;
        // lpass show -p <key> — last element is the key.
        return "lpass-" & arguments.cmdArgs[arrayLen(arguments.cmdArgs)];
    }
}

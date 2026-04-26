component extends="modules.wheels.services.deploy.secrets.DopplerAdapter" {

    this.lastArgs = [];

    public string function $run(required array cmdArgs) {
        this.lastArgs = arguments.cmdArgs;
        // doppler secrets get <key> --plain [--project <p>]
        // Key is positional arg at index 4 (after "doppler", "secrets", "get").
        return arrayLen(arguments.cmdArgs) >= 4 ? "doppler-" & arguments.cmdArgs[4] : "doppler-unknown";
    }
}

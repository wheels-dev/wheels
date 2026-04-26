component extends="modules.wheels.services.deploy.secrets.AwsSecretsAdapter" {

    this.lastArgs = [];

    public string function $run(required array cmdArgs) {
        this.lastArgs = arguments.cmdArgs;
        // Locate --secret-id <value>.
        var idx = 0;
        for (var i = 1; i <= arrayLen(arguments.cmdArgs); i++) {
            if (arguments.cmdArgs[i] == "--secret-id" && i < arrayLen(arguments.cmdArgs)) {
                idx = i + 1;
                break;
            }
        }
        return idx ? "aws-" & arguments.cmdArgs[idx] : "aws-unknown";
    }
}

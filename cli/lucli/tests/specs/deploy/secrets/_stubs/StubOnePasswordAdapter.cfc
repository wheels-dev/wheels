/**
 * Test subclass: overrides $run to avoid shelling out.
 * Echoes the op:// URI from the command args so assertions can
 * verify the adapter built the right URL shape.
 */
component extends="modules.wheels.services.deploy.secrets.OnePasswordAdapter" {

    this.captureArgs = false;
    this.lastArgs = [];

    public string function $run(required array cmdArgs) {
        this.lastArgs = arguments.cmdArgs;
        // Find the op:// URI in the args (last element after "read").
        for (var a in arguments.cmdArgs) {
            if (left(a, 5) == "op://") return a;
        }
        return "mocked-value";
    }
}

/**
 * Shared base for secret-provider adapters.
 *
 * Supplies a $run(cmdArgs) helper that shells out via
 * java.lang.ProcessBuilder and returns trimmed stdout. Concrete
 * adapters override name() and fetch() but share this plumbing.
 *
 * Subclasses override $run for testability (inject a scripted
 * response). See tests/specs/deploy/secrets/*Spec.cfc for the
 * inline-subclass pattern.
 */
component {

    public BaseAdapter function init() { return this; }

    public string function name() { return ""; }

    public array function fetch(required struct opts) {
        throw(type="BaseAdapter.Unimplemented",
              message="Adapter must implement fetch(opts)");
    }

    /**
     * Run a command via ProcessBuilder. Returns trimmed stdout.
     * Throws {name}.ProviderFailed on non-zero exit.
     * Throws {name}.CliNotFound if the binary cannot be launched.
     */
    public string function $run(required array cmdArgs) {
        var provider = name();
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder").init(arguments.cmdArgs);
            pb.redirectErrorStream(true);
            var proc = pb.start();
            var reader = createObject("java", "java.io.BufferedReader").init(
                createObject("java", "java.io.InputStreamReader").init(proc.getInputStream(), "UTF-8")
            );
            var sb = createObject("java", "java.lang.StringBuilder").init();
            var line = reader.readLine();
            while (!isNull(line)) {
                sb.append(line);
                sb.append(chr(10));
                line = reader.readLine();
            }
            proc.waitFor();
            if (proc.exitValue() != 0) {
                throw(type=provider & ".ProviderFailed",
                      message=provider & " CLI failed with exit " & proc.exitValue() & ": " & trim(sb.toString()));
            }
            return trim(sb.toString());
        } catch (any e) {
            if (len(provider) && left(e.type, len(provider)) == provider) rethrow;
            throw(type=provider & ".CliNotFound",
                  message="Failed to run " & provider & " CLI — is it installed on this machine? (" & e.message & ")");
        }
    }
}

/**
 * Doppler secret-provider adapter.
 *
 * Wraps the `doppler secrets get` CLI. For each key, runs:
 *   doppler secrets get <key> --plain [--project <from>]
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/secrets/adapters/doppler.rb
 */
component extends="cli.lucli.services.deploy.secrets.BaseAdapter" {

    public string function name() { return "doppler"; }

    public array function fetch(required struct opts) {
        var project = arguments.opts.from ?: "";
        var keys = arguments.opts.keys ?: [];
        var out = [];
        for (var key in keys) {
            var args = ["doppler", "secrets", "get", key, "--plain"];
            if (len(project)) {
                arrayAppend(args, "--project");
                arrayAppend(args, project);
            }
            var value = $run(args);
            arrayAppend(out, key & "=" & value);
        }
        return out;
    }
}

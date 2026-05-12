/**
 * Bitwarden secret-provider adapter.
 *
 * Wraps the `bw` CLI. For each key, runs:
 *   bw get password <key>
 *
 * Assumes the session is unlocked (BW_SESSION env var set) — this
 * adapter does not attempt interactive unlock.
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/secrets/adapters/bitwarden.rb
 */
component extends="modules.wheels.services.deploy.secrets.BaseAdapter" {

    public string function name() { return "bitwarden"; }

    public array function fetch(required struct opts) {
        var keys = arguments.opts.keys ?: [];
        var out = [];
        for (var key in keys) {
            var args = ["bw", "get", "password", key];
            var value = $run(args);
            arrayAppend(out, key & "=" & value);
        }
        return out;
    }
}

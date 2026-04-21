/**
 * LastPass secret-provider adapter.
 *
 * Wraps the `lpass` CLI. For each key, runs:
 *   lpass show -p <key>
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/secrets/adapters/last_pass.rb
 */
component extends="cli.lucli.services.deploy.secrets.BaseAdapter" {

    public string function name() { return "lastpass"; }

    public array function fetch(required struct opts) {
        var keys = arguments.opts.keys ?: [];
        var out = [];
        for (var key in keys) {
            var args = ["lpass", "show", "-p", key];
            var value = $run(args);
            arrayAppend(out, key & "=" & value);
        }
        return out;
    }
}

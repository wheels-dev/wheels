/**
 * 1Password secret-provider adapter.
 *
 * Wraps the `op` CLI (v2.x). For each key, runs:
 *   op read op://<from>/<key>/password
 *
 * If `opts.account` is set, prepends `--account <account>`.
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/secrets/adapters/one_password.rb
 */
component extends="modules.wheels.services.deploy.secrets.BaseAdapter" {

    public string function name() { return "op"; }

    public array function fetch(required struct opts) {
        var account = arguments.opts.account ?: "";
        var from = arguments.opts.from ?: "Deploy";
        var keys = arguments.opts.keys ?: [];
        var out = [];
        for (var key in keys) {
            var args = [];
            arrayAppend(args, "op");
            if (len(account)) {
                arrayAppend(args, "--account");
                arrayAppend(args, account);
            }
            arrayAppend(args, "read");
            arrayAppend(args, "op://" & from & "/" & key & "/password");
            var value = $run(args);
            arrayAppend(out, key & "=" & value);
        }
        return out;
    }
}

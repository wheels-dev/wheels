/**
 * Secrets subcommand surface: wheels deploy secrets <verb>
 *
 * Verbs:
 *   fetch --adapter <name> [--account <acct>] [--from <scope>] KEY1 KEY2
 *     -> prints KEY=VALUE lines resolved from the provider
 *
 *   extract <key> --from "<KEY=VALUE\nKEY2=VALUE2>"
 *     -> prints the VALUE for <key> from a fetch-style block
 *
 *   print
 *     -> prints the resolved .kamal/secrets file as KEY=VALUE lines
 *        (uses SecretResolver for $(cmd) expansion)
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/secrets.rb
 *
 * Adapters are registered with multiple aliases (op / 1password,
 * bw / bitwarden, lpass / lastpass) to match Kamal's CLI ergonomics.
 */
component {

    public DeploySecretsCli function init() {
        variables.adapters = {
            "op":        new modules.wheels.services.deploy.secrets.OnePasswordAdapter(),
            "1password": new modules.wheels.services.deploy.secrets.OnePasswordAdapter(),
            "bitwarden": new modules.wheels.services.deploy.secrets.BitwardenAdapter(),
            "bw":        new modules.wheels.services.deploy.secrets.BitwardenAdapter(),
            "aws":       new modules.wheels.services.deploy.secrets.AwsSecretsAdapter(),
            "lastpass":  new modules.wheels.services.deploy.secrets.LastPassAdapter(),
            "lpass":     new modules.wheels.services.deploy.secrets.LastPassAdapter(),
            "doppler":   new modules.wheels.services.deploy.secrets.DopplerAdapter()
        };
        return this;
    }

    /**
     * Fetch secrets from a provider. Returns KEY=VALUE lines joined by \n.
     */
    public string function fetch(required struct opts) {
        var adapterName = arguments.opts.adapter ?: "";
        if (!len(adapterName) || !structKeyExists(variables.adapters, adapterName)) {
            throw(type="DeploySecretsCli.UnknownAdapter",
                  message="Unknown adapter: '" & adapterName & "'. Known: op, 1password, bitwarden, bw, aws, lastpass, lpass, doppler.");
        }
        var keys = arguments.opts.keys ?: [];
        if (!arrayLen(keys)) {
            throw(type="DeploySecretsCli.NoKeys",
                  message="fetch requires at least one key argument");
        }
        var adapter = variables.adapters[adapterName];
        var result = adapter.fetch({
            account: arguments.opts.account ?: "",
            from:    arguments.opts.from ?: "",
            keys:    keys
        });
        return arrayToList(result, chr(10));
    }

    /**
     * Extract a single key's value from a KEY=VALUE text block.
     */
    public string function extract(required struct opts) {
        var key = arguments.opts.key ?: "";
        var text = arguments.opts.from ?: "";
        if (!len(key)) return "";
        for (var line in listToArray(text, chr(10), false)) {
            var eq = find("=", line);
            // eq > 1, not > 0: a line starting with '=' has no key, and
            // left(line, 0) crashes Lucee 7 (Cross-Engine Invariant 8).
            // compare(), not ==: CFML == is case-insensitive, but env var
            // names are case-sensitive and Kamal's extract is an exact
            // match (#2957 DEP-11b).
            if (eq > 1 && compare(left(line, eq - 1), key) == 0) {
                return mid(line, eq + 1, 99999);
            }
        }
        return "";
    }

    /**
     * Print the project's resolved .kamal/secrets as KEY=VALUE lines.
     * Uses SecretResolver so $(cmd) subshells expand.
     */
    public string function print(required struct opts) {
        var resolver = new modules.wheels.services.deploy.lib.SecretResolver({
            projectRoot: arguments.opts.projectRoot ?: expandPath("./"),
            destination: arguments.opts.destination ?: ""
        });
        var all = resolver.all();
        var lines = [];
        for (var k in all) arrayAppend(lines, k & "=" & all[k]);
        return arrayToList(lines, chr(10));
    }

    /**
     * Test seam — swap an adapter with a stub.
     */
    public void function setAdapter(required string adapterName, required any adapter) {
        variables.adapters[arguments.adapterName] = arguments.adapter;
    }
}

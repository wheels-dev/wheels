/**
 * Documentation-only interface for secret provider adapters.
 *
 * CFML doesn't enforce interfaces — this component defines the shape
 * every adapter under cli/lucli/services/deploy/secrets/ is expected
 * to conform to:
 *
 *   adapter.name()                 -> string  (e.g. "op", "bitwarden")
 *   adapter.fetch(opts)            -> array of "KEY=VALUE" strings
 *
 *   opts.account   (optional) provider account/vault identifier
 *   opts.from      (optional) provider scope (vault, region, project)
 *   opts.keys      (required) array of key identifiers to fetch
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/secrets/adapters/*.rb
 *
 * Concrete adapters extend BaseAdapter.cfc which provides a shared
 * $run(cmdArgs) helper wrapping java.lang.ProcessBuilder.
 */
component {

    public SecretAdapterInterface function init() { return this; }

    public string function name() {
        throw(type="SecretAdapterInterface.Unimplemented",
              message="Adapters must override name()");
    }

    public array function fetch(required struct opts) {
        throw(type="SecretAdapterInterface.Unimplemented",
              message="Adapters must override fetch(opts)");
    }
}

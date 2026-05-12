/**
 * AWS Secrets Manager adapter.
 *
 * Wraps the `aws secretsmanager get-secret-value` CLI call. For each
 * key, runs:
 *   aws secretsmanager get-secret-value \
 *     --region <from|us-east-1> \
 *     --secret-id <key> \
 *     --query SecretString \
 *     --output text
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/secrets/adapters/aws_secrets_manager.rb
 */
component extends="modules.wheels.services.deploy.secrets.BaseAdapter" {

    public string function name() { return "aws"; }

    public array function fetch(required struct opts) {
        var region = len(arguments.opts.from ?: "") ? arguments.opts.from : "us-east-1";
        var keys = arguments.opts.keys ?: [];
        var out = [];
        for (var key in keys) {
            var args = [
                "aws", "secretsmanager", "get-secret-value",
                "--region", region,
                "--secret-id", key,
                "--query", "SecretString",
                "--output", "text"
            ];
            var value = $run(args);
            arrayAppend(out, key & "=" & value);
        }
        return out;
    }
}

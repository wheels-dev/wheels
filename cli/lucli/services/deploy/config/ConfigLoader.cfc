/**
 * ConfigLoader — reads a deploy.yml from disk and returns a validated Config.
 *
 * Pipeline (mirrors Kamal's lib/kamal/configuration.rb#load):
 *   1. parse YAML                        (Yaml.parse)
 *   2. merge destination overlay          (Yaml.deepMerge, if destination set)
 *   3. interpolate ${VAR} tokens          (envOverride → .kamal/secrets → System.getenv → "")
 *   4. validate schema                    (Validator)
 *   5. wrap in typed Config object
 *
 * Interpolation is deliberately simple: only ${UPPER_SNAKE} tokens are
 * expanded — same syntax Kamal supports natively, with the same lookup
 * order (envOverride → .kamal/secrets → System.getenv → ""). ERB-style
 * `<%= %>` tags are NOT supported; that's the one deliberate divergence
 * from Ruby Kamal, since rendering ERB would require embedding a Ruby
 * runtime in the CLI. The Mustache layer in this package is used only
 * by `wheels deploy init` to scaffold the initial deploy.yml/secrets
 * files (see DeployMainCli.$init); it is NOT applied to deploy.yml at
 * runtime.
 */
component {

	public any function init(struct opts = {envOverride: {}}) {
		variables.yaml = new modules.wheels.services.deploy.lib.Yaml();
		variables.validator = new Validator();
		variables.envOverride = arguments.opts.envOverride ?: {};
		variables.secretResolver = arguments.opts.secretResolver ?: "";
		return this;
	}

	/**
	 * Load a deploy.yml from disk.
	 *
	 * @path        Absolute path to the base deploy.yml.
	 * @opts        { destination: "production" } — if set, the sibling
	 *              <path>.<destination>.yml is deep-merged on top.
	 */
	public any function load(required string path, struct opts = {destination: ""}) {
		var raw = variables.yaml.parse(fileRead(arguments.path));
		var dest = arguments.opts.destination ?: "";

		if (len(dest)) {
			var overlayPath = $overlayPathFor(arguments.path, dest);
			if (fileExists(overlayPath)) {
				var overlay = variables.yaml.parse(fileRead(overlayPath));
				raw = variables.yaml.deepMerge(raw, overlay);
			}
		}

		// Build a SecretResolver lazily if the caller didn't inject one.
		// Project root is derived from the YAML path via $projectRootFor():
		// the standard `config/deploy.yml` layout resolves `.kamal/secrets`
		// at the PROJECT ROOT (the parent of config/) — the same root
		// `wheels deploy init` scaffolds and DeploySecretsCli reads — while
		// a deploy.yml outside a config/ directory keeps resolving
		// `.kamal/secrets` alongside itself. See issue 3084.
		if (!isObject(variables.secretResolver)) {
			variables.secretResolver = new modules.wheels.services.deploy.lib.SecretResolver({
				projectRoot: $projectRootFor(arguments.path),
				destination: dest
			});
		}

		$noteEnvClearInterpolations(raw);
		raw = $interpolate(raw);
		variables.validator.validate(raw, arguments.path);
		return new Config(raw, {destination: dest});
	}

	/**
	 * The SecretResolver built (or injected) for the most recent load().
	 * Deploy verbs use it to resolve `env.secret` names into values for
	 * remote env-file delivery (##2957). Returns "" before any load when
	 * no resolver was injected.
	 */
	public any function secretResolver() {
		return variables.secretResolver;
	}

	/**
	 * Derive the secrets project root from a deploy.yml path.
	 *
	 * When the YAML sits inside a directory named `config` (the standard
	 * `wheels deploy init` layout: <root>/config/deploy.yml), the project
	 * root is the PARENT of that directory, so `.kamal/secrets` resolves
	 * from the project root — agreeing with DeploySecretsCli and the
	 * registry-login SecretResolver default. Any other layout keeps the
	 * YAML's own directory as the root (`.kamal/secrets` alongside it).
	 */
	public string function $projectRootFor(required string path) {
		var dir = getDirectoryFromPath(arguments.path);
		var lastChar = right(dir, 1);
		var trimmed = (len(dir) > 1 && (lastChar == "/" || lastChar == "\")) ? left(dir, len(dir) - 1) : dir;
		if (len(trimmed) > 1 && listLast(trimmed, "/\") == "config") {
			var parent = getDirectoryFromPath(trimmed);
			if (len(parent)) return parent;
		}
		return dir;
	}

	/**
	 * Build the destination-overlay filename from a base path.
	 *
	 * Strips a trailing `.yml` or `.yaml` if present, then appends
	 * `.<destination>.yml`. Mirrors Kamal's rule:
	 *   deploy.yml + production → deploy.production.yml
	 */
	public string function $overlayPathFor(required string path, required string destination) {
		var p = arguments.path;
		if (right(p, 4) == ".yml") {
			p = left(p, len(p) - 4);
		} else if (right(p, 5) == ".yaml") {
			p = left(p, len(p) - 5);
		} else if (right(p, 4) == ".tmp") {
			// Dev/test-only path — spec writes to getTempFile which yields
			// `.tmp` on Lucee. Treat it the same as `.yml` for overlay naming.
			p = left(p, len(p) - 4);
		}
		return p & "." & arguments.destination & ".yml";
	}

	/**
	 * Recursively walk the parsed tree, expanding ${VAR_NAME} tokens in any
	 * string node. Uppercase-and-underscore only (matches Kamal's simple
	 * interpolation rule and prevents accidental matches against
	 * shell-style `${service}` placeholders).
	 */
	public any function $interpolate(required any node) {
		if (isStruct(arguments.node)) {
			var outS = structNew("ordered");
			for (var k in arguments.node) outS[k] = $interpolate(arguments.node[k]);
			return outS;
		}
		if (isArray(arguments.node)) {
			var outA = [];
			for (var item in arguments.node) arrayAppend(outA, $interpolate(item));
			return outA;
		}
		if (isSimpleValue(arguments.node)) {
			var s = toString(arguments.node);
			if (!find("${", s)) return arguments.node;
			var re = "\$\{([A-Z_][A-Z0-9_]*)\}";
			var matches = reMatch(re, s);
			var rendered = s;
			for (var m in matches) {
				// Strip leading ${ and trailing } to get the bare var name.
				var varName = mid(m, 3, len(m) - 3);
				rendered = replace(rendered, m, $resolveVar(varName), "all");
			}
			return rendered;
		}
		return arguments.node;
	}

	/**
	 * Resolve a single ${VAR} reference:
	 *   1. envOverride struct (explicit test/config override)
	 *   2. SecretResolver (.kamal/secrets + destination overlay, with $(cmd) expansion)
	 *   3. System.getenv(name)
	 *   4. "" (empty string — Kamal behavior for unset vars)
	 */
	public string function $resolveVar(required string name) {
		if (structKeyExists(variables.envOverride, arguments.name)) {
			return variables.envOverride[arguments.name];
		}
		if (isObject(variables.secretResolver) && variables.secretResolver.has(arguments.name)) {
			var secret = variables.secretResolver.get(arguments.name);
			// A value from .kamal/secrets must never be printed, wherever it is interpolated.
			new modules.wheels.services.deploy.lib.SecretRedaction().register(secret);
			return secret;
		}
		var sys = createObject("java", "java.lang.System");
		var fromEnv = sys.getenv(javaCast("string", arguments.name));
		if (!isNull(fromEnv)) return fromEnv;
		return "";
	}


	/**
	 * env.clear values are passed as `-e KEY=value` on the docker run command
	 * line of every host. When one interpolates a ${VAR}, register the
	 * resolved value for redaction (so no printed command shows it) and warn
	 * that a secret belongs in env.secret, which is delivered as a file.
	 * Checks the top-level env, every role's env and every accessory's env.
	 */
	public void function $noteEnvClearInterpolations(required struct raw) {
		var scopes = [];
		if (structKeyExists(arguments.raw, "env") && isStruct(arguments.raw.env)) {
			arrayAppend(scopes, {prefix: "env.clear", env: arguments.raw.env});
		}
		if (structKeyExists(arguments.raw, "servers") && isStruct(arguments.raw.servers)) {
			for (var role in arguments.raw.servers) {
				var r = arguments.raw.servers[role];
				if (isStruct(r) && structKeyExists(r, "env") && isStruct(r.env)) {
					arrayAppend(scopes, {prefix: "servers.#role#.env.clear", env: r.env});
				}
			}
		}
		if (structKeyExists(arguments.raw, "accessories") && isStruct(arguments.raw.accessories)) {
			for (var accName in arguments.raw.accessories) {
				var acc = arguments.raw.accessories[accName];
				if (isStruct(acc) && structKeyExists(acc, "env") && isStruct(acc.env)) {
					arrayAppend(scopes, {prefix: "accessories.#accName#.env.clear", env: acc.env});
				}
			}
		}
		var redaction = new modules.wheels.services.deploy.lib.SecretRedaction();
		for (var scope in scopes) {
			if (!structKeyExists(scope.env, "clear") || !isStruct(scope.env.clear)) {
				continue;
			}
			for (var key in scope.env.clear) {
				var value = scope.env.clear[key];
				if (!isSimpleValue(value) || !find("${", value)) {
					continue;
				}
				var names = [];
				for (var token in reMatch("\$\{[A-Za-z_][A-Za-z0-9_]*\}", value)) {
					var name = mid(token, 3, len(token) - 3);
					redaction.register($resolveVar(name));
					arrayAppend(names, "${" & name & "}");
				}
				if (arrayLen(names)) {
					redaction.addWarning(
						"#scope.prefix#.#key# interpolates #arrayToList(names, ", ")#. env.clear values are passed on the "
						& "docker run command line on every host; move secret values to env.secret, which Wheels delivers "
						& "as a permission-600 env file."
					);
				}
			}
		}
	}
}

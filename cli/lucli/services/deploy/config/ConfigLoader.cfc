/**
 * ConfigLoader — reads a deploy.yml from disk and returns a validated Config.
 *
 * Pipeline (mirrors Kamal's lib/kamal/configuration.rb#load):
 *   1. parse YAML                        (Yaml.parse)
 *   2. merge destination overlay          (Yaml.deepMerge, if destination set)
 *   3. interpolate ${VAR} tokens          (envOverride → System.getenv → "")
 *   4. validate schema                    (Validator)
 *   5. wrap in typed Config object
 *
 * Interpolation is deliberately simple: only ${UPPER_SNAKE} tokens are
 * expanded. ERB-style `<%= %>` tags (Kamal's native syntax) are NOT
 * supported — that's a deliberate divergence. Mustache-style `{{env.FOO}}`
 * is handled by the Mustache layer later, not here.
 */
component {

	public any function init(struct opts = {envOverride: {}}) {
		variables.yaml = new cli.lucli.services.deploy.lib.Yaml();
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
		// Project root defaults to the directory containing the YAML file —
		// this lets `.kamal/secrets` alongside `deploy.yml` resolve naturally.
		if (!isObject(variables.secretResolver)) {
			variables.secretResolver = new cli.lucli.services.deploy.lib.SecretResolver({
				projectRoot: getDirectoryFromPath(arguments.path),
				destination: dest
			});
		}

		raw = $interpolate(raw);
		variables.validator.validate(raw, arguments.path);
		return new Config(raw, {destination: dest});
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
			return variables.secretResolver.get(arguments.name);
		}
		var sys = createObject("java", "java.lang.System");
		var fromEnv = sys.getenv(javaCast("string", arguments.name));
		if (!isNull(fromEnv)) return fromEnv;
		return "";
	}

}

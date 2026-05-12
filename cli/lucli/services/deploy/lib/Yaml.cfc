/**
 * Yaml — thin facade over org.yaml.snakeyaml.Yaml (SnakeYAML 2.3).
 *
 * The JAR ships in cli/lucli/lib/deploy/snakeyaml-2.3.jar and is loaded through
 * JarLoader into an isolated URLClassLoader, keeping it off Lucee's classpath.
 *
 * Security baseline: the underlying Yaml is constructed with SafeConstructor,
 * NOT the default Constructor. SafeConstructor rejects `!!java.*` class tags so
 * a malicious deploy config cannot trigger arbitrary Java class instantiation
 * (the historical Jackson-style gadget-chain attack vector). If reflection
 * cannot locate SafeConstructor we throw — we do NOT silently downgrade.
 *
 * Public API:
 *   parse(src)             YAML string → nested CFML struct/array tree.
 *                          Ordered structs (structNew("ordered")) preserve key
 *                          insertion order from the source document.
 *   dump(data)             CFML struct/array → YAML string via LinkedHashMap /
 *                          ArrayList so SnakeYAML can serialise cleanly.
 *   deepMerge(base, over)  Recursive map merge. Maps merge key-by-key; arrays
 *                          and scalars are replaced whole. Mirrors Kamal's
 *                          destination-overlay semantics. `base` is duplicated
 *                          first so the caller's struct is never mutated.
 */
component {

	public Yaml function init(any jarLoader = "") {
		if (isSimpleValue(arguments.jarLoader) && !len(arguments.jarLoader)) {
			variables.$jarLoader = new modules.wheels.services.deploy.lib.JarLoader();
		} else {
			variables.$jarLoader = arguments.jarLoader;
		}
		// Fail fast at init() so the caller gets a clear error at facade
		// construction time rather than a confusing trace on first parse.
		variables.$yamlClass = variables.$jarLoader.loadClass("org.yaml.snakeyaml.Yaml");
		variables.$safeConstructorClass = variables.$jarLoader.loadClass(
			"org.yaml.snakeyaml.constructor.SafeConstructor"
		);
		variables.$loaderOptionsClass = variables.$jarLoader.loadClass(
			"org.yaml.snakeyaml.LoaderOptions"
		);
		return this;
	}

	/**
	 * Parse a YAML string into CFML structs/arrays.
	 *
	 * @src YAML source.
	 */
	public any function parse(required string src) {
		var loader = variables.$jarLoader;
		var srcLocal = arguments.src;
		var self = this;
		return loader.withIsolatedTCCL(function() {
			var yaml = self.$buildSafeYaml();
			var raw = yaml.load(javaCast("string", srcLocal));
			return self.$javaToCfml(raw);
		});
	}

	/**
	 * Serialise a CFML struct/array tree to a YAML string.
	 *
	 * @data CFML data — struct, array, or scalar.
	 */
	public string function dump(required any data) {
		var loader = variables.$jarLoader;
		var dataLocal = arguments.data;
		var self = this;
		return loader.withIsolatedTCCL(function() {
			var yaml = self.$buildSafeYaml();
			var javaData = self.$cfmlToJava(dataLocal);
			return javaCast("string", yaml.dump(javaData));
		});
	}

	/**
	 * Recursively merge `overlay` on top of `base`.
	 *
	 * Rules:
	 *   - If both sides are maps: merge key-by-key (recursive).
	 *   - Otherwise: overlay wins (arrays and scalars replace whole).
	 *
	 * @base    Left-hand struct (the defaults).
	 * @overlay Right-hand struct (wins on conflict).
	 */
	public any function deepMerge(required any base, required any overlay) {
		// Duplicate base so we never mutate the caller's struct.
		var result = isSimpleValue(arguments.base) ? arguments.base : duplicate(arguments.base);
		return $mergeInto(result, arguments.overlay);
	}

	// -----------------------------------------------------------------------
	// Internals
	// -----------------------------------------------------------------------

	/**
	 * Build `new Yaml(new SafeConstructor(new LoaderOptions()))` via reflection.
	 *
	 * SnakeYAML 2.x requires SafeConstructor to take a LoaderOptions argument
	 * (the no-arg constructor was removed). We look up the matching constructors
	 * by parameter count / type rather than a hard-coded signature so minor
	 * point-release API drift doesn't break us.
	 */
	public any function $buildSafeYaml() {
		// Find LoaderOptions no-arg constructor by iterating — direct
		// getDeclaredConstructor(Class[]) hits the "can't find class [Class]"
		// varargs-bridge limitation on Lucee (same workaround Mustache.cfc uses
		// for compiler()).
		var loaderOptionsCtor = "";
		var loCtors = variables.$loaderOptionsClass.getDeclaredConstructors();
		for (var li = 1; li <= arrayLen(loCtors); li++) {
			if (arrayLen(loCtors[li].getParameterTypes()) == 0) {
				loaderOptionsCtor = loCtors[li];
				break;
			}
		}
		if (isSimpleValue(loaderOptionsCtor) && !len(loaderOptionsCtor)) {
			throw(
				type = "Wheels.Deploy.Yaml.LoaderOptionsConstructorNotFound",
				message = "SnakeYAML LoaderOptions() no-arg constructor not found via reflection."
			);
		}
		var loaderOptions = loaderOptionsCtor.newInstance([]);

		// Find the SafeConstructor(LoaderOptions) constructor.
		var safeCtor = "";
		var ctors = variables.$safeConstructorClass.getDeclaredConstructors();
		for (var i = 1; i <= arrayLen(ctors); i++) {
			var paramTypes = ctors[i].getParameterTypes();
			if (arrayLen(paramTypes) == 1 && paramTypes[1].getName() == "org.yaml.snakeyaml.LoaderOptions") {
				safeCtor = ctors[i];
				break;
			}
		}
		if (isSimpleValue(safeCtor) && !len(safeCtor)) {
			throw(
				type = "Wheels.Deploy.Yaml.SafeConstructorUnavailable",
				message = "SnakeYAML SafeConstructor(LoaderOptions) constructor not found. "
					& "Refusing to downgrade to the unsafe Constructor — this would allow "
					& "arbitrary Java class instantiation via !!java.* tags."
			);
		}
		var safeConstructor = safeCtor.newInstance([loaderOptions]);

		// Find Yaml(BaseConstructor) — the one-arg constructor that accepts any
		// org.yaml.snakeyaml.constructor.BaseConstructor subclass.
		var yamlCtor = "";
		var yamlCtors = variables.$yamlClass.getDeclaredConstructors();
		for (var j = 1; j <= arrayLen(yamlCtors); j++) {
			var yParams = yamlCtors[j].getParameterTypes();
			if (arrayLen(yParams) == 1 && yParams[1].getName() == "org.yaml.snakeyaml.constructor.BaseConstructor") {
				yamlCtor = yamlCtors[j];
				break;
			}
		}
		if (isSimpleValue(yamlCtor) && !len(yamlCtor)) {
			throw(
				type = "Wheels.Deploy.Yaml.YamlConstructorNotFound",
				message = "SnakeYAML Yaml(BaseConstructor) constructor not found via reflection."
			);
		}
		return yamlCtor.newInstance([safeConstructor]);
	}

	/**
	 * Convert a Java object tree (as returned by SnakeYAML) into CFML values.
	 *
	 * Map → ordered struct (preserves YAML key order)
	 * List → CFML array
	 * everything else → passed through as-is (CFML auto-converts scalar boxed
	 * types — String, Integer, Boolean, etc.)
	 */
	public any function $javaToCfml(required any node) {
		if (isNull(arguments.node)) {
			return javaCast("null", "");
		}
		// Maps — use instanceof via reflection to catch LinkedHashMap, HashMap,
		// TreeMap, and any other Map implementation SnakeYAML may return.
		if (isInstanceOf(arguments.node, "java.util.Map")) {
			var out = structNew("ordered");
			var keys = arguments.node.keySet().toArray();
			for (var i = 1; i <= arrayLen(keys); i++) {
				var k = keys[i];
				out[k] = $javaToCfml(arguments.node.get(k));
			}
			return out;
		}
		if (isInstanceOf(arguments.node, "java.util.List")) {
			var arr = [];
			var size = arguments.node.size();
			for (var j = 0; j < size; j++) {
				arrayAppend(arr, $javaToCfml(arguments.node.get(j)));
			}
			return arr;
		}
		// Scalar — CFML unboxes Java primitives / String automatically.
		return arguments.node;
	}

	/**
	 * Convert a CFML struct/array tree into java.util.LinkedHashMap /
	 * java.util.ArrayList so SnakeYAML can serialise it. Scalars pass through.
	 */
	public any function $cfmlToJava(required any data) {
		if (isStruct(arguments.data)) {
			var m = createObject("java", "java.util.LinkedHashMap").init();
			for (var key in arguments.data) {
				m.put(javaCast("string", key), $cfmlToJava(arguments.data[key]));
			}
			return m;
		}
		if (isArray(arguments.data)) {
			var list = createObject("java", "java.util.ArrayList").init();
			for (var i = 1; i <= arrayLen(arguments.data); i++) {
				list.add($cfmlToJava(arguments.data[i]));
			}
			return list;
		}
		return arguments.data;
	}

	/**
	 * Internal: merge overlay into base (base already duplicated by deepMerge).
	 * Returns the merged value.
	 */
	public any function $mergeInto(required any base, required any overlay) {
		// Both must be structs to merge key-by-key; otherwise overlay wins.
		if (!isStruct(arguments.base) || !isStruct(arguments.overlay)) {
			return arguments.overlay;
		}
		var result = arguments.base;
		for (var key in arguments.overlay) {
			if (structKeyExists(result, key) && isStruct(result[key]) && isStruct(arguments.overlay[key])) {
				result[key] = $mergeInto(result[key], arguments.overlay[key]);
			} else {
				// Scalar/array/missing — replace whole.
				result[key] = isSimpleValue(arguments.overlay[key])
					? arguments.overlay[key]
					: duplicate(arguments.overlay[key]);
			}
		}
		return result;
	}

}

/**
 * Mustache — thin facade over com.samskivert.mustache.Mustache (jmustache 1.16).
 *
 * The JAR ships in cli/lucli/lib/deploy/jmustache-1.16.jar and is loaded through
 * JarLoader into an isolated URLClassLoader, so it doesn't collide with any
 * templating library Lucee (or app code) may pull in.
 *
 * Two render modes:
 *   - render(source, ctx)         Missing keys render as empty (jmustache default).
 *   - renderStrict(source, ctx)   Missing keys throw — use for templates where
 *                                 an un-provided variable is a deploy-config bug
 *                                 (e.g. `APP_NAME` in a generated Procfile).
 */
component {

	public Mustache function init(any jarLoader = "") {
		if (isSimpleValue(arguments.jarLoader) && !len(arguments.jarLoader)) {
			variables.$jarLoader = new cli.lucli.services.deploy.lib.JarLoader();
		} else {
			variables.$jarLoader = arguments.jarLoader;
		}
		variables.$mustacheClass = variables.$jarLoader.loadClass("com.samskivert.mustache.Mustache");
		return this;
	}

	/**
	 * Render `source` with `ctx`. Missing keys resolve to empty string.
	 *
	 * @source Mustache template source.
	 * @ctx    Struct of variables available to the template.
	 */
	public string function render(required string source, required struct ctx) {
		return $compileAndExecute(source: arguments.source, ctx: arguments.ctx, strict: false);
	}

	/**
	 * Render `source` with `ctx`. Missing keys throw — jmustache raises
	 * `MustacheException$Context` which bubbles up as a Lucee CFML error.
	 *
	 * @source Mustache template source.
	 * @ctx    Struct of variables available to the template.
	 */
	public string function renderStrict(required string source, required struct ctx) {
		return $compileAndExecute(source: arguments.source, ctx: arguments.ctx, strict: true);
	}

	// -----------------------------------------------------------------------
	// Internals
	// -----------------------------------------------------------------------

	/**
	 * Compile `source` through a configured `Mustache.Compiler` and execute
	 * against `ctx`. The TCCL swap ensures jmustache's internal class lookups
	 * (reflection on value objects) resolve against our isolated loader.
	 */
	public string function $compileAndExecute(
		required string source,
		required struct ctx,
		required boolean strict
	) {
		var loader = variables.$jarLoader;
		var mustacheClass = variables.$mustacheClass;
		var src = arguments.source;
		var ctx = arguments.ctx;
		var strict = arguments.strict;

		return loader.withIsolatedTCCL(function() {
			// mustacheClass is a java.lang.Class<?> — Lucee doesn't dispatch the
			// static compiler() call directly. Resolve via reflection. Iterating
			// getMethods() avoids the `Class<?>[]` varargs-bridge limitation that
			// makes getMethod("compiler") crash with "can't find class [Class]".
			var compilerMethod = "";
			var methods = mustacheClass.getMethods();
			for (var i = 1; i <= arrayLen(methods); i++) {
				if (methods[i].getName() == "compiler" && arrayLen(methods[i].getParameterTypes()) == 0) {
					compilerMethod = methods[i];
					break;
				}
			}
			var compiler = compilerMethod.invoke(javaCast("null", ""), javaCast("Object[]", []));

			if (strict) {
				// strictSections(true) + defaultValue null → throws on missing key.
				compiler = compiler.strictSections(javaCast("boolean", true));
			} else {
				// Non-strict: provide empty-string default so missing keys render
				// as "". jmustache's built-in default is to throw, so we override.
				compiler = compiler.defaultValue(javaCast("string", ""));
			}
			var template = compiler.compile(src);
			var rendered = template.execute(ctx);
			return javaCast("string", rendered);
		});
	}

}

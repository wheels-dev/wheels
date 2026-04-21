/**
 * JarLoader — URLClassLoader wrapper that isolates deploy JARs from Lucee's classpath.
 *
 * Deploy JARs (jmustache, snakeyaml, sshj + BouncyCastle transitives) are loaded into
 * their own URLClassLoader with PlatformClassLoader as parent — NOT the system/app
 * classloader — so BouncyCastle doesn't collide with Lucee's bundled crypto.
 *
 * Pattern lifted from vendor/wheels/wheelstest/BrowserLauncher.cfc (Playwright JAR isolation).
 *
 * Cached by a hash of manifest.json so the loader rebuilds when JARs change.
 */
component {

	/**
	 * @libDir  Absolute path to the directory containing the deploy JARs.
	 *          Defaults to cli/lucli/lib/deploy/ resolved from this CFC's location.
	 */
	public JarLoader function init(string libDir = "") {
		if (!len(arguments.libDir)) {
			var cfcPath = getDirectoryFromPath(getCurrentTemplatePath());
			// cfcPath = .../cli/lucli/services/deploy/lib/
			// libDir  = .../cli/lucli/lib/deploy/
			arguments.libDir = getCanonicalPath(cfcPath & "../../../lib/deploy/");
		}
		if (right(arguments.libDir, 1) != "/") {
			arguments.libDir &= "/";
		}
		variables.$libDir = arguments.libDir;
		variables.$manifestPath = variables.$libDir & "manifest.json";
		return this;
	}

	/**
	 * Return the cached URLClassLoader, building it lazily on first call.
	 * The cache lives in `application.$wheelsDeployJarLoaders` keyed by
	 * manifest-hash, so multiple callers in the same request share a loader
	 * and classes resolve to the same Class<?> object (required for
	 * ClassCastException-free interop).
	 */
	public any function getClassLoader() {
		var key = $manifestHash();

		if (!structKeyExists(application, "$wheelsDeployJarLoaders")) {
			lock name="wheelsDeployJarLoaderInit" timeout="10" type="exclusive" {
				if (!structKeyExists(application, "$wheelsDeployJarLoaders")) {
					application.$wheelsDeployJarLoaders = {};
				}
			}
		}

		if (structKeyExists(application.$wheelsDeployJarLoaders, key)) {
			return application.$wheelsDeployJarLoaders[key];
		}

		lock name="wheelsDeployJarLoader_#key#" timeout="30" type="exclusive" {
			if (structKeyExists(application.$wheelsDeployJarLoaders, key)) {
				return application.$wheelsDeployJarLoaders[key];
			}

			var loader = $buildClassLoader();
			application.$wheelsDeployJarLoaders[key] = loader;
			return loader;
		}
	}

	/**
	 * Load a class through the isolated classloader.
	 *
	 * @fqcn Fully qualified Java class name (e.g. com.samskivert.mustache.Mustache).
	 */
	public any function loadClass(required string fqcn) {
		return getClassLoader().loadClass(arguments.fqcn);
	}

	/**
	 * Construct a new instance of `fqcn` via reflection, swapping the thread context
	 * classloader for the call so service-provider discovery (ServiceLoader,
	 * Thread.currentThread().getContextClassLoader()) finds classes in our
	 * isolated loader instead of Lucee's AppClassLoader.
	 *
	 * @fqcn Fully qualified Java class name.
	 * @args Array of constructor arguments. Empty array → no-arg constructor.
	 */
	public any function newInstance(required string fqcn, array args = []) {
		var klass = loadClass(arguments.fqcn);
		var thread = createObject("java", "java.lang.Thread").currentThread();
		var previousTCCL = thread.getContextClassLoader();
		try {
			thread.setContextClassLoader(getClassLoader());
			if (arrayLen(arguments.args) == 0) {
				var ctor = klass.getDeclaredConstructor(javaCast("Class[]", []));
				return ctor.newInstance(javaCast("Object[]", []));
			}
			// Best-effort: match by arity. If a caller needs exact type matching
			// we extend this later. Deploy JARs we bundle today don't need it.
			var ctors = klass.getDeclaredConstructors();
			for (var i = 1; i <= arrayLen(ctors); i++) {
				if (arrayLen(ctors[i].getParameterTypes()) == arrayLen(arguments.args)) {
					return ctors[i].newInstance(arguments.args);
				}
			}
			throw(
				type = "Wheels.Deploy.JarLoader.NoMatchingConstructor",
				message = "No constructor of #arguments.fqcn# matches #arrayLen(arguments.args)# args."
			);
		} finally {
			thread.setContextClassLoader(previousTCCL);
		}
	}

	/**
	 * Run `callback` with the isolated classloader as the thread context classloader.
	 * Restores the previous TCCL in a finally block.
	 *
	 * Used by facades (Mustache, Yaml, SshClient) that invoke JAR code which calls
	 * Thread.currentThread().getContextClassLoader() internally.
	 */
	public any function withIsolatedTCCL(required any callback) {
		var thread = createObject("java", "java.lang.Thread").currentThread();
		var previousTCCL = thread.getContextClassLoader();
		try {
			thread.setContextClassLoader(getClassLoader());
			return arguments.callback();
		} finally {
			thread.setContextClassLoader(previousTCCL);
		}
	}

	// -----------------------------------------------------------------------
	// Internals
	// -----------------------------------------------------------------------

	/**
	 * Hash of manifest.json — if the manifest changes (JAR added/replaced),
	 * the key changes and a fresh classloader is built.
	 */
	public string function $manifestHash() {
		if (!fileExists(variables.$manifestPath)) {
			return "no-manifest";
		}
		return hash(fileRead(variables.$manifestPath), "SHA-256");
	}

	/**
	 * Construct a new URLClassLoader covering every JAR referenced in manifest.json,
	 * with PlatformClassLoader as parent. Lucee's AppClassLoader is intentionally
	 * NOT the parent: BouncyCastle transitives from sshj would otherwise collide
	 * with Lucee's bundled crypto provider.
	 */
	public any function $buildClassLoader() {
		if (!fileExists(variables.$manifestPath)) {
			throw(
				type = "Wheels.Deploy.JarLoader.ManifestMissing",
				message = "Deploy JAR manifest not found at #variables.$manifestPath#."
			);
		}

		var manifest = deserializeJSON(fileRead(variables.$manifestPath));
		var urls = [];
		var jars = manifest.jars ?: [];

		for (var i = 1; i <= arrayLen(jars); i++) {
			var jarPath = variables.$libDir & jars[i].name;
			if (!fileExists(jarPath)) {
				throw(
					type = "Wheels.Deploy.JarLoader.JarMissing",
					message = "Manifest references JAR that does not exist: #jarPath#."
				);
			}
			var jarFile = createObject("java", "java.io.File").init(jarPath);
			arrayAppend(urls, jarFile.toURI().toURL());
		}

		// PARENT = PlatformClassLoader (JDK stdlib only). Keeps our JAR layer
		// self-contained so BouncyCastle doesn't clash with Lucee's crypto.
		var parentLoader = createObject("java", "java.lang.ClassLoader")
			.getPlatformClassLoader();

		return createObject("java", "java.net.URLClassLoader")
			.init(urls, parentLoader);
	}

}

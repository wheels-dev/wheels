/**
 * Builds and resolves a dependency graph for Wheels packages/modules.
 *
 * Reads manifest data (requires, replaces, suggests) from discovered packages,
 * builds a directed acyclic graph, detects cycles, resolves replacements,
 * and produces a topologically sorted load order.
 *
 * Used by PackageLoader.cfc to determine the correct package instantiation order.
 */
component output="false" {

	/**
	 * Initializes the module graph.
	 */
	public ModuleGraph function init() {
		variables.semver = new wheels.SemVer();
		return this;
	}

	/**
	 * Resolves a set of package manifests into a load order.
	 *
	 * @manifests  Struct keyed by directory name, values are manifest structs (parsed package.json).
	 *             Each manifest must have at minimum: name, version.
	 *             Optional: requires (struct), replaces (struct), suggests (struct).
	 * @return     Struct with keys:
	 *             - loadOrder (array of directory names in dependency order)
	 *             - excluded (struct of dirName => reason, packages excluded by replaces)
	 *             - errors (array of structs {package, message} for unresolvable packages)
	 */
	public struct function resolve(required struct manifests) {
		local.result = {
			loadOrder = [],
			excluded = {},
			errors = []
		};

		// Build lookup: package name -> directory name (for resolving requires by name)
		local.nameToDir = {};
		for (local.dirName in arguments.manifests) {
			local.m = arguments.manifests[local.dirName];
			local.pkgName = StructKeyExists(local.m, "name") ? local.m.name : local.dirName;
			local.nameToDir[local.pkgName] = local.dirName;
		}

		// Phase 1: Process replacements
		local.excluded = $processReplacements(arguments.manifests, local.nameToDir);
		StructAppend(local.result.excluded, local.excluded);

		// Phase 2: Build the active package set (excluding replaced packages)
		local.activeManifests = {};
		for (local.dirName in arguments.manifests) {
			if (!StructKeyExists(local.excluded, local.dirName)) {
				local.activeManifests[local.dirName] = arguments.manifests[local.dirName];
			}
		}

		// Phase 3: Validate requires and build adjacency list
		local.graphData = $buildAdjacencyList(local.activeManifests, local.nameToDir, local.excluded);
		local.adjacency = local.graphData.adjacency;
		local.validNodes = local.graphData.validNodes;

		// Collect errors from validation
		for (local.err in local.graphData.errors) {
			ArrayAppend(local.result.errors, local.err);
		}

		// Phase 4: Topological sort with cycle detection (Kahn's algorithm)
		local.sortResult = $topologicalSort(local.validNodes, local.adjacency);

		if (ArrayLen(local.sortResult.cycle) > 0) {
			// Report cycle errors for all packages in the cycle
			for (local.node in local.sortResult.cycle) {
				ArrayAppend(local.result.errors, {
					package = local.node,
					message = "Circular dependency detected: " & ArrayToList(local.sortResult.cycle, " -> ")
				});
			}
			// Remove cycled packages from load order
			for (local.node in local.sortResult.cycle) {
				local.idx = ArrayFind(local.sortResult.order, local.node);
				if (local.idx > 0) {
					ArrayDeleteAt(local.sortResult.order, local.idx);
				}
			}
		}

		local.result.loadOrder = local.sortResult.order;
		return local.result;
	}

	/**
	 * Processes `replaces` declarations across all manifests.
	 * If package A declares replaces: {"pkg-B": "*"}, and pkg-B is present,
	 * then pkg-B is excluded from loading.
	 *
	 * @return  Struct of excluded dirName => reason string
	 */
	private struct function $processReplacements(required struct manifests, required struct nameToDir) {
		local.excluded = {};

		for (local.dirName in arguments.manifests) {
			local.m = arguments.manifests[local.dirName];
			if (!StructKeyExists(local.m, "replaces") || !IsStruct(local.m.replaces)) {
				continue;
			}

			local.replacerName = StructKeyExists(local.m, "name") ? local.m.name : local.dirName;

			for (local.replacedName in local.m.replaces) {
				local.constraint = local.m.replaces[local.replacedName];

				// Find the replaced package by name
				if (!StructKeyExists(arguments.nameToDir, local.replacedName)) {
					continue; // Replaced package not present — nothing to do
				}

				local.replacedDir = arguments.nameToDir[local.replacedName];

				// Don't replace yourself
				if (local.replacedDir == local.dirName) {
					continue;
				}

				// Check version constraint if the replaced package has a version
				local.replacedManifest = arguments.manifests[local.replacedDir];
				local.replacedVersion = StructKeyExists(local.replacedManifest, "version") ? local.replacedManifest.version : "0.0.0";

				if (variables.semver.satisfiesAll(local.replacedVersion, local.constraint)) {
					local.excluded[local.replacedDir] = "Replaced by #local.replacerName#";
				}
			}
		}

		return local.excluded;
	}

	/**
	 * Builds an adjacency list from active manifests.
	 * Validates that all required packages are present and satisfy version constraints.
	 *
	 * Edges point from dependency to dependent: if A requires B, edge is B -> A.
	 * This means packages with no incoming edges (no dependencies) are processed first.
	 *
	 * @return  Struct with: adjacency (struct of arrays), validNodes (array), errors (array)
	 */
	private struct function $buildAdjacencyList(
		required struct activeManifests,
		required struct nameToDir,
		required struct excluded
	) {
		// adjacency: dirName -> array of dirNames that depend on it
		local.adjacency = {};
		// inDegree: dirName -> count of dependencies
		local.inDegree = {};
		local.validNodes = [];
		local.errors = [];
		local.failedNodes = {};

		// Initialize all active packages as nodes
		for (local.dirName in arguments.activeManifests) {
			local.adjacency[local.dirName] = [];
			local.inDegree[local.dirName] = 0;
		}

		// Process requires
		for (local.dirName in arguments.activeManifests) {
			local.m = arguments.activeManifests[local.dirName];
			local.pkgName = StructKeyExists(local.m, "name") ? local.m.name : local.dirName;

			if (!StructKeyExists(local.m, "requires") || !IsStruct(local.m.requires)) {
				continue;
			}

			for (local.reqName in local.m.requires) {
				local.constraint = local.m.requires[local.reqName];

				// Find the required package
				if (!StructKeyExists(arguments.nameToDir, local.reqName)) {
					ArrayAppend(local.errors, {
						package = local.dirName,
						message = "Required package '#local.reqName#' not found"
					});
					local.failedNodes[local.dirName] = true;
					continue;
				}

				local.reqDir = arguments.nameToDir[local.reqName];

				// Check if required package was excluded (replaced)
				if (StructKeyExists(arguments.excluded, local.reqDir)) {
					ArrayAppend(local.errors, {
						package = local.dirName,
						message = "Required package '#local.reqName#' was replaced by another package"
					});
					local.failedNodes[local.dirName] = true;
					continue;
				}

				// Check if required package is in our active set
				if (!StructKeyExists(arguments.activeManifests, local.reqDir)) {
					ArrayAppend(local.errors, {
						package = local.dirName,
						message = "Required package '#local.reqName#' not found"
					});
					local.failedNodes[local.dirName] = true;
					continue;
				}

				// Check version constraint
				local.reqManifest = arguments.activeManifests[local.reqDir];
				local.reqVersion = StructKeyExists(local.reqManifest, "version") ? local.reqManifest.version : "0.0.0";

				if (!variables.semver.satisfiesAll(local.reqVersion, local.constraint)) {
					ArrayAppend(local.errors, {
						package = local.dirName,
						message = "Required package '#local.reqName#' version #local.reqVersion# does not satisfy constraint #local.constraint#"
					});
					local.failedNodes[local.dirName] = true;
					continue;
				}

				// Add edge: reqDir -> dirName (dependency loads before dependent)
				ArrayAppend(local.adjacency[local.reqDir], local.dirName);
				local.inDegree[local.dirName] = local.inDegree[local.dirName] + 1;
			}
		}

		// Process suggests (soft edges — influence order but don't fail)
		for (local.dirName in arguments.activeManifests) {
			local.m = arguments.activeManifests[local.dirName];

			if (!StructKeyExists(local.m, "suggests") || !IsStruct(local.m.suggests)) {
				continue;
			}

			for (local.sugName in local.m.suggests) {
				if (!StructKeyExists(arguments.nameToDir, local.sugName)) {
					continue; // Suggested package not present — that's fine
				}

				local.sugDir = arguments.nameToDir[local.sugName];

				// Skip if excluded or not active or is a failed node
				if (StructKeyExists(arguments.excluded, local.sugDir)) {
					continue;
				}
				if (!StructKeyExists(arguments.activeManifests, local.sugDir)) {
					continue;
				}
				if (StructKeyExists(local.failedNodes, local.sugDir)) {
					continue;
				}

				// Don't add duplicate edges
				if (ArrayFind(local.adjacency[local.sugDir], local.dirName) > 0) {
					continue;
				}

				// Soft edge: sugDir -> dirName
				ArrayAppend(local.adjacency[local.sugDir], local.dirName);
				local.inDegree[local.dirName] = local.inDegree[local.dirName] + 1;
			}
		}

		// Build valid nodes list (exclude failed)
		for (local.dirName in arguments.activeManifests) {
			if (!StructKeyExists(local.failedNodes, local.dirName)) {
				ArrayAppend(local.validNodes, local.dirName);
			}
		}

		return {
			adjacency = local.adjacency,
			inDegree = local.inDegree,
			validNodes = local.validNodes,
			errors = local.errors
		};
	}

	/**
	 * Kahn's algorithm for topological sort with cycle detection.
	 *
	 * @validNodes  Array of node names to sort
	 * @adjacency   Struct of node -> array of dependent nodes
	 * @return      Struct with: order (array), cycle (array of nodes in cycle, empty if none)
	 */
	private struct function $topologicalSort(required array validNodes, required struct adjacency) {
		// Compute in-degree for valid nodes only
		local.inDegree = {};
		for (local.node in arguments.validNodes) {
			local.inDegree[local.node] = 0;
		}

		// Build a set of valid nodes for quick lookup
		local.validSet = {};
		for (local.node in arguments.validNodes) {
			local.validSet[local.node] = true;
		}

		for (local.node in arguments.validNodes) {
			if (StructKeyExists(arguments.adjacency, local.node)) {
				for (local.dep in arguments.adjacency[local.node]) {
					if (StructKeyExists(local.validSet, local.dep)) {
						local.inDegree[local.dep] = local.inDegree[local.dep] + 1;
					}
				}
			}
		}

		// Find all nodes with in-degree 0 (no dependencies)
		local.queue = [];
		for (local.node in arguments.validNodes) {
			if (local.inDegree[local.node] == 0) {
				ArrayAppend(local.queue, local.node);
			}
		}

		// Sort the initial queue for deterministic ordering
		ArraySort(local.queue, "textnocase");

		local.order = [];
		local.processed = 0;

		while (ArrayLen(local.queue) > 0) {
			// Take first from queue
			local.current = local.queue[1];
			ArrayDeleteAt(local.queue, 1);
			ArrayAppend(local.order, local.current);
			local.processed++;

			// Reduce in-degree for dependents
			if (StructKeyExists(arguments.adjacency, local.current)) {
				local.nextBatch = [];
				for (local.dep in arguments.adjacency[local.current]) {
					if (StructKeyExists(local.validSet, local.dep)) {
						local.inDegree[local.dep] = local.inDegree[local.dep] - 1;
						if (local.inDegree[local.dep] == 0) {
							ArrayAppend(local.nextBatch, local.dep);
						}
					}
				}
				// Sort next batch for determinism
				if (ArrayLen(local.nextBatch) > 0) {
					ArraySort(local.nextBatch, "textnocase");
					for (local.item in local.nextBatch) {
						ArrayAppend(local.queue, local.item);
					}
				}
			}
		}

		// Any remaining nodes with in-degree > 0 are in a cycle
		local.cycle = [];
		if (local.processed < ArrayLen(arguments.validNodes)) {
			for (local.node in arguments.validNodes) {
				if (local.inDegree[local.node] > 0) {
					ArrayAppend(local.cycle, local.node);
				}
			}
		}

		return {
			order = local.order,
			cycle = local.cycle
		};
	}

}

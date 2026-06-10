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
			// Kahn's algorithm leaves both true cycle members AND their
			// downstream dependents unprocessed. Distinguish them so a package
			// that merely requires a cycled package is reported as a casualty
			// of the cycle, not mislabeled as a circular dependency itself.
			// (Unprocessed nodes were never added to sortResult.order, so no
			// removal from the load order is needed.)
			local.classified = $classifyCycleNodes(local.sortResult.cycle, local.adjacency);
			for (local.node in local.classified.members) {
				ArrayAppend(local.result.errors, {
					package = local.node,
					message = "Circular dependency detected: " & ArrayToList(
						$findCyclePath(local.node, local.adjacency, local.classified.memberSet),
						" -> "
					)
				});
			}
			for (local.node in local.classified.dependents) {
				ArrayAppend(local.result.errors, {
					package = local.node,
					message = "Cannot load: depends on package(s) involved in a circular dependency (#ArrayToList(local.classified.members, ", ")#)"
				});
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

		// Process packages in sorted directory-name order so the outcome is
		// deterministic regardless of struct iteration order, and skip the
		// replaces declarations of packages that have already been excluded —
		// an excluded package never loads, so its declarations must not apply.
		// This also resolves mutual replaces (A replaces B AND B replaces A):
		// the first package in sorted order wins and the other is excluded,
		// instead of both being silently removed from the load order.
		local.sortedDirs = StructKeyArray(arguments.manifests);
		ArraySort(local.sortedDirs, "textnocase");

		for (local.dirName in local.sortedDirs) {
			if (StructKeyExists(local.excluded, local.dirName)) {
				continue;
			}
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
	 * In-degrees are computed by $topologicalSort (restricted to the valid
	 * nodes), so this function intentionally does not track them.
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
		local.validNodes = [];
		local.errors = [];
		local.failedNodes = {};

		// Initialize all active packages as nodes
		for (local.dirName in arguments.activeManifests) {
			local.adjacency[local.dirName] = [];
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
			validNodes = local.validNodes,
			errors = local.errors
		};
	}

	/**
	 * Splits the unprocessed nodes left over from Kahn's algorithm into true
	 * cycle members (nodes that can reach themselves following edges within
	 * the unprocessed set) and downstream dependents (nodes that merely
	 * depend, directly or transitively, on a cycle member and therefore never
	 * reached in-degree zero).
	 *
	 * @cycleNodes  Array of unprocessed node names from $topologicalSort
	 * @adjacency   Struct of node -> array of dependent nodes
	 * @return      Struct with: members (sorted array), dependents (sorted array), memberSet (struct)
	 */
	private struct function $classifyCycleNodes(required array cycleNodes, required struct adjacency) {
		local.unprocessedSet = {};
		for (local.node in arguments.cycleNodes) {
			local.unprocessedSet[local.node] = true;
		}

		local.members = [];
		local.dependents = [];
		local.memberSet = {};

		for (local.node in arguments.cycleNodes) {
			if ($canReachSelf(local.node, arguments.adjacency, local.unprocessedSet)) {
				ArrayAppend(local.members, local.node);
				local.memberSet[local.node] = true;
			} else {
				ArrayAppend(local.dependents, local.node);
			}
		}

		ArraySort(local.members, "textnocase");
		ArraySort(local.dependents, "textnocase");

		return {
			members = local.members,
			dependents = local.dependents,
			memberSet = local.memberSet
		};
	}

	/**
	 * Returns true when the given node can reach itself following adjacency
	 * edges restricted to the allowed node set — i.e. the node is part of a
	 * dependency cycle. Iterative DFS.
	 */
	private boolean function $canReachSelf(
		required string startNode,
		required struct adjacency,
		required struct allowedSet
	) {
		local.stack = [];
		local.visited = {};

		if (StructKeyExists(arguments.adjacency, arguments.startNode)) {
			for (local.next in arguments.adjacency[arguments.startNode]) {
				if (StructKeyExists(arguments.allowedSet, local.next)) {
					ArrayAppend(local.stack, local.next);
				}
			}
		}

		while (ArrayLen(local.stack) > 0) {
			local.current = local.stack[ArrayLen(local.stack)];
			ArrayDeleteAt(local.stack, ArrayLen(local.stack));
			if (local.current == arguments.startNode) {
				return true;
			}
			if (StructKeyExists(local.visited, local.current)) {
				continue;
			}
			local.visited[local.current] = true;
			if (StructKeyExists(arguments.adjacency, local.current)) {
				for (local.next in arguments.adjacency[local.current]) {
					if (StructKeyExists(arguments.allowedSet, local.next)) {
						ArrayAppend(local.stack, local.next);
					}
				}
			}
		}

		return false;
	}

	/**
	 * Finds an actual cycle path starting and ending at the given node,
	 * following edges restricted to verified cycle members. Returns an array
	 * like ["a", "b", "a"] suitable for rendering as "a -> b -> a". Falls
	 * back to a single-element array if no path is found (which cannot happen
	 * for a node $classifyCycleNodes verified as a cycle member).
	 *
	 * Iterative DFS; each stack frame carries the path taken to reach it so
	 * no arrays are mutated across function boundaries (Adobe CF passes
	 * arrays by value).
	 */
	private array function $findCyclePath(
		required string startNode,
		required struct adjacency,
		required struct memberSet
	) {
		local.stack = [{node = arguments.startNode, path = [arguments.startNode]}];
		local.visited = {};

		while (ArrayLen(local.stack) > 0) {
			local.frame = local.stack[ArrayLen(local.stack)];
			ArrayDeleteAt(local.stack, ArrayLen(local.stack));
			if (!StructKeyExists(arguments.adjacency, local.frame.node)) {
				continue;
			}
			for (local.next in arguments.adjacency[local.frame.node]) {
				if (local.next == arguments.startNode) {
					local.completed = Duplicate(local.frame.path);
					ArrayAppend(local.completed, local.next);
					return local.completed;
				}
				if (!StructKeyExists(arguments.memberSet, local.next) || StructKeyExists(local.visited, local.next)) {
					continue;
				}
				local.visited[local.next] = true;
				local.nextPath = Duplicate(local.frame.path);
				ArrayAppend(local.nextPath, local.next);
				ArrayAppend(local.stack, {node = local.next, path = local.nextPath});
			}
		}

		return [arguments.startNode];
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

		// Any remaining nodes with in-degree > 0 are either true cycle members
		// or downstream dependents of one — resolve() classifies them via
		// $classifyCycleNodes before reporting.
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

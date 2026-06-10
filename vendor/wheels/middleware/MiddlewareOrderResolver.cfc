/**
 * Resolves ordering of plugin-registered middleware using numeric priority
 * and before/after constraints. Uses Kahn's algorithm (topological sort)
 * with priority as tiebreaker for nodes at the same depth.
 *
 * Options recognized per entry:
 *   name     (string)       — unique name for this middleware (defaults to pluginName)
 *   priority (numeric)      — lower runs first (default 10)
 *   before   (string/array) — name(s) this middleware must run before
 *   after    (string/array) — name(s) this middleware must run after
 *
 * [section: Middleware]
 * [category: Core]
 */
component output="false" {

	/**
	 * Resolve the ordering of middleware entries.
	 *
	 * @entries Array of structs, each with keys: middleware, options, pluginName.
	 * @return  Ordered array of the same entry structs.
	 */
	public array function resolve(required array entries) {
		if (ArrayLen(arguments.entries) <= 1) {
			return arguments.entries;
		}

		// 1. Normalize: assign a unique name and priority to each entry
		//    (duplicate names are warned about and suffixed).
		local.named = $normalizeEntries(arguments.entries);

		// 2. Build adjacency list and in-degree map from before/after constraints.
		local.graph = $buildGraph(local.named);

		// 3. Topological sort with priority tiebreaker (Kahn's algorithm).
		local.sorted = $topologicalSort(local.named, local.graph);

		return local.sorted;
	}

	/**
	 * Assign a resolved name and numeric priority to each entry.
	 * Duplicate names are warned about and suffixed so every graph node stays
	 * unique: duplicates would otherwise collapse into a single node, making
	 * the topological sort mis-diagnose the unvisited remainder as a circular
	 * dependency and fall back to priority-only ordering, discarding all
	 * before/after constraints. Constraints that reference a duplicated name
	 * apply to the first registration only.
	 */
	private array function $normalizeEntries(required array entries) {
		local.result = [];
		local.seen = {};
		for (local.entry in arguments.entries) {
			local.opts = StructKeyExists(local.entry, "options") ? local.entry.options : {};

			// Name: explicit option > pluginName > derive from middleware path.
			if (StructKeyExists(local.opts, "name") && Len(Trim(local.opts.name))) {
				local.resolvedName = Trim(local.opts.name);
			} else if (StructKeyExists(local.entry, "pluginName") && Len(Trim(local.entry.pluginName))) {
				local.resolvedName = Trim(local.entry.pluginName);
			} else if (IsSimpleValue(local.entry.middleware)) {
				local.resolvedName = ListLast(local.entry.middleware, ".");
			} else {
				local.resolvedName = "middleware_#CreateUUID()#";
			}

			// Registrant shown in duplicate-name warnings (pluginName may be absent).
			local.registrant = StructKeyExists(local.entry, "pluginName") && Len(Trim(local.entry.pluginName)) ? local.entry.pluginName : local.resolvedName;

			// Duplicate name: warn and rename this entry to a unique node name.
			local.dupKey = LCase(local.resolvedName);
			if (StructKeyExists(local.seen, local.dupKey)) {
				WriteLog(
					type = "warning",
					text = "Wheels middleware ordering: duplicate name '#local.resolvedName#' — "
						& "registered by '#local.seen[local.dupKey]#' and '#local.registrant#'. "
						& "Both entries are kept, but before/after constraints referencing "
						& "'#local.resolvedName#' apply to the first registration only. "
						& "Use unique names to avoid ambiguous ordering."
				);
				local.suffix = 2;
				while (StructKeyExists(local.seen, LCase(local.resolvedName & "__dup" & local.suffix))) {
					local.suffix++;
				}
				local.resolvedName = local.resolvedName & "__dup" & local.suffix;
			}
			local.seen[LCase(local.resolvedName)] = local.registrant;

			// Priority: numeric option or default 10.
			local.priority = 10;
			if (StructKeyExists(local.opts, "priority") && IsNumeric(local.opts.priority)) {
				local.priority = local.opts.priority;
			}

			// Normalize before/after to arrays.
			local.before = $toArray(local.opts, "before");
			local.after = $toArray(local.opts, "after");

			ArrayAppend(local.result, {
				entry = local.entry,
				name = local.resolvedName,
				priority = local.priority,
				before = local.before,
				after = local.after
			});
		}
		return local.result;
	}

	/**
	 * Convert a string or array option to a normalized array.
	 */
	private array function $toArray(required struct opts, required string key) {
		if (!StructKeyExists(arguments.opts, arguments.key)) {
			return [];
		}
		local.val = arguments.opts[arguments.key];
		if (IsArray(local.val)) {
			return local.val;
		}
		if (IsSimpleValue(local.val) && Len(Trim(local.val))) {
			return ListToArray(local.val);
		}
		return [];
	}

	/**
	 * Build directed graph edges from before/after constraints.
	 * Returns struct with: adjacency (name -> array of names it must come before)
	 *                      inDegree (name -> count of predecessors)
	 */
	private struct function $buildGraph(required array named) {
		// Build a name lookup (case-insensitive).
		local.nameSet = {};
		for (local.item in arguments.named) {
			local.nameSet[LCase(local.item.name)] = true;
		}

		local.adjacency = {};
		local.inDegree = {};

		// Initialize all nodes.
		for (local.item in arguments.named) {
			local.key = LCase(local.item.name);
			if (!StructKeyExists(local.adjacency, local.key)) {
				local.adjacency[local.key] = [];
			}
			if (!StructKeyExists(local.inDegree, local.key)) {
				local.inDegree[local.key] = 0;
			}
		}

		// Process constraints.
		for (local.item in arguments.named) {
			local.fromKey = LCase(local.item.name);

			// "before" means this entry must run before the target -> edge: this -> target.
			for (local.target in local.item.before) {
				local.targetKey = LCase(Trim(local.target));
				if (!StructKeyExists(local.nameSet, local.targetKey)) {
					WriteLog(
						type = "warning",
						text = "Wheels middleware ordering: '#local.item.name#' declares before='#local.target#' "
							& "but no middleware named '#local.target#' is registered. Constraint ignored."
					);
					continue;
				}
				if (local.fromKey != local.targetKey) {
					ArrayAppend(local.adjacency[local.fromKey], local.targetKey);
					local.inDegree[local.targetKey]++;
				}
			}

			// "after" means this entry must run after the target -> edge: target -> this.
			for (local.target in local.item.after) {
				local.targetKey = LCase(Trim(local.target));
				if (!StructKeyExists(local.nameSet, local.targetKey)) {
					WriteLog(
						type = "warning",
						text = "Wheels middleware ordering: '#local.item.name#' declares after='#local.target#' "
							& "but no middleware named '#local.target#' is registered. Constraint ignored."
					);
					continue;
				}
				if (local.fromKey != local.targetKey) {
					if (!StructKeyExists(local.adjacency, local.targetKey)) {
						local.adjacency[local.targetKey] = [];
					}
					ArrayAppend(local.adjacency[local.targetKey], local.fromKey);
					local.inDegree[local.fromKey]++;
				}
			}
		}

		return {adjacency = local.adjacency, inDegree = local.inDegree};
	}

	/**
	 * Kahn's algorithm with priority tiebreaker.
	 * When multiple nodes have in-degree 0, lower priority runs first.
	 * Falls back to priority-only sort if a cycle is detected.
	 */
	private array function $topologicalSort(required array named, required struct graph) {
		local.adjacency = arguments.graph.adjacency;
		local.inDegree = Duplicate(arguments.graph.inDegree);

		// Index by lowercase name for fast lookup.
		local.byName = {};
		for (local.item in arguments.named) {
			local.byName[LCase(local.item.name)] = local.item;
		}

		// Collect initial zero in-degree nodes.
		local.queue = [];
		for (local.key in local.inDegree) {
			if (local.inDegree[local.key] == 0) {
				ArrayAppend(local.queue, local.key);
			}
		}

		local.sorted = [];
		local.visited = 0;

		while (ArrayLen(local.queue)) {
			// Sort queue by priority (lower first) for deterministic tiebreaking.
			local.queue = $sortByPriority(local.queue, local.byName);

			// Take the highest-priority (lowest number) node.
			local.current = local.queue[1];
			ArrayDeleteAt(local.queue, 1);

			ArrayAppend(local.sorted, local.byName[local.current].entry);
			local.visited++;

			// Reduce in-degree for neighbors.
			if (StructKeyExists(local.adjacency, local.current)) {
				for (local.neighbor in local.adjacency[local.current]) {
					local.inDegree[local.neighbor]--;
					if (local.inDegree[local.neighbor] == 0) {
						ArrayAppend(local.queue, local.neighbor);
					}
				}
			}
		}

		// Cycle detection: not all nodes visited.
		if (local.visited < ArrayLen(arguments.named)) {
			WriteLog(
				type = "warning",
				text = "Wheels middleware ordering: circular dependency detected among plugin middleware. "
					& "Falling back to priority-only ordering. Review before/after constraints."
			);
			return $fallbackPrioritySort(arguments.named);
		}

		return local.sorted;
	}

	/**
	 * Sort an array of name keys by their priority value (lower first).
	 */
	private array function $sortByPriority(required array keys, required struct byName) {
		if (ArrayLen(arguments.keys) <= 1) {
			return arguments.keys;
		}
		// Build sortable pairs, then sort.
		local.pairs = [];
		for (local.key in arguments.keys) {
			ArrayAppend(local.pairs, {key = local.key, priority = arguments.byName[local.key].priority});
		}
		ArraySort(local.pairs, function(a, b) {
			return a.priority - b.priority;
		});
		local.result = [];
		for (local.pair in local.pairs) {
			ArrayAppend(local.result, local.pair.key);
		}
		return local.result;
	}

	/**
	 * Fallback: sort entries by priority only (ignoring constraints).
	 */
	private array function $fallbackPrioritySort(required array named) {
		local.copy = Duplicate(arguments.named);
		ArraySort(local.copy, function(a, b) {
			return a.priority - b.priority;
		});
		local.result = [];
		for (local.item in local.copy) {
			ArrayAppend(local.result, local.item.entry);
		}
		return local.result;
	}

}

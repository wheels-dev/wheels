component {
	/**
	 * Authorizes the current user for an action on a record by dispatching to the
	 * record's policy (`app/policies/<ModelName>Policy.cfc`). Throws
	 * `Wheels.NotAuthorized` (HTTP 403) when the policy denies, and returns the
	 * record unchanged when it allows so the call can be inlined:
	 *
	 * ```
	 * function update() {
	 *   post = authorize(model("Post").findByKey(params.key));
	 *   post.update(params.post);
	 * }
	 * ```
	 *
	 * A missing policy class throws `Wheels.Policy.NotDefined` in development and
	 * testing (loud, Pundit-style, to catch typos) and silently denies in
	 * production — the same environment posture as `tableName()` (##3079). A
	 * policy class that lacks a method for the action denies.
	 *
	 * [section: Controller]
	 * [category: Authorization Functions]
	 *
	 * @record The model instance (or model class / model name string) to authorize against.
	 * @action The policy method to dispatch. Defaults to the current `params.action`, resolved at call time.
	 */
	public any function authorize(required any record, string action = "") {
		local.action = arguments.action;
		if (!Len(local.action)) {
			if (
				StructKeyExists(variables, "params")
				&& IsStruct(variables.params)
				&& StructKeyExists(variables.params, "action")
			) {
				local.action = variables.params.action;
			} else if ($get("showErrorInformation")) {
				Throw(
					type = "Wheels.Policy.MissingAction",
					message = "authorize() could not resolve an action to authorize.",
					extendedInfo = "No `action` argument was passed and `params.action` is not available on this controller. Pass the action explicitly, e.g. `authorize(record=post, action=""update"")`."
				);
			}
		}
		local.modelName = $policyModelName(arguments.record);
		local.policy = $policyFor(arguments.record);
		local.allowed = false;
		if (
			IsObject(local.policy)
			&& Len(local.action)
			&& StructKeyExists(local.policy, local.action)
			&& IsCustomFunction(local.policy[local.action])
		) {
			// Dynamic dispatch via the built-in Invoke() — Adobe CF's compiler
			// rejects a direct `local.policy[local.action]()` call outright
			// (InvalidIdentifierException at compile time, verified on Adobe
			// 2023), and extracting the function reference first drops the
			// receiver binding on BoxLang. Invoke(instance, methodName) is the
			// cross-engine-proven form (see QueryBuilder/ScopeChain
			// onMissingMethod). The StructKeyExists + IsCustomFunction guard
			// mirrors the action-dispatch gate in processing.cfc ($callAction).
			local.allowed = Invoke(local.policy, local.action);
			// A policy method that forgets to return yields null — on Adobe CF a
			// null assignment deletes the variable, so re-materialize the deny.
			if (IsNull(local.allowed)) {
				local.allowed = false;
			}
		}
		if (!IsBoolean(local.allowed) || !local.allowed) {
			$notAuthorized(action = local.action, modelName = local.modelName);
		}
		return arguments.record;
	}

	/**
	 * Non-throwing boolean policy check for conditionals and views (views run in
	 * the controller's `variables` scope, so `can()` is available in templates
	 * automatically):
	 *
	 * ```
	 * <cfif can("update", post)>##linkTo(text="Edit", route="editPost", key=post.id)##</cfif>
	 * ```
	 *
	 * Returns `false` (deny) for a guest, for an empty record, and for actions the
	 * policy has no method for. A missing policy class still throws
	 * `Wheels.Policy.NotDefined` in development/testing so typos fail loud; in
	 * production it returns `false`.
	 *
	 * [section: Controller]
	 * [category: Authorization Functions]
	 *
	 * @action The policy method to check.
	 * @record The model instance (or model class / model name string) to check against. Empty string denies.
	 */
	public boolean function can(required string action, any record = "") {
		local.policy = $policyFor(arguments.record);
		if (
			!IsObject(local.policy)
			|| !StructKeyExists(local.policy, arguments.action)
			|| !IsCustomFunction(local.policy[arguments.action])
		) {
			return false;
		}
		// Dynamic dispatch via Invoke() (see authorize() for the cross-engine
		// reasoning). The IsNull guard covers a policy method that forgets to
		// return — null deletes the variable on Adobe CF.
		local.allowed = Invoke(local.policy, arguments.action);
		return !IsNull(local.allowed) && IsBoolean(local.allowed) && local.allowed;
	}

	/**
	 * Narrows a collection to the records the current user may see by delegating
	 * to the policy's `scope()` method. Returns whatever the policy returns —
	 * conventionally a chainable finder you keep composing:
	 *
	 * ```
	 * function index() {
	 *   posts = policyScope(model("Post")).findAll(page = params.page, perPage = 25);
	 * }
	 * ```
	 *
	 * Pass the model class first and chain scopes after the call
	 * (`policyScope(model("Post")).active()`) — a query-builder or scope chain
	 * that is already in flight cannot be introspected for its model. When the
	 * policy class is missing, this throws `Wheels.Policy.NotDefined` in
	 * development/testing and returns a default-deny (no rows) chain in
	 * production.
	 *
	 * [section: Controller]
	 * [category: Authorization Functions]
	 *
	 * @collection The model class to narrow.
	 */
	public any function policyScope(required any collection) {
		local.modelName = $policyModelName(arguments.collection);
		if (!Len(local.modelName) && $get("showErrorInformation")) {
			Throw(
				type = "Wheels.Policy.InvalidCollection",
				message = "policyScope() could not derive a model from the passed collection.",
				extendedInfo = "Pass the model class first and chain from the result, e.g. `policyScope(model(""Post"")).active().findAll()`. Query-builder and scope chains that are already in flight cannot be passed to policyScope()."
			);
		}
		local.policy = $policyFor(arguments.collection);
		if (!IsObject(local.policy)) {
			// Production missing-policy posture: default-deny (no rows). The empty
			// whereIn sets the injection-safe always-empty flag (##2736) without
			// interpolating the property name into SQL.
			return arguments.collection.whereIn("id", []);
		}
		return local.policy.scope(arguments.collection);
	}

	/**
	 * Internal function. Resolves and instantiates the policy for a record.
	 * Returns the initialized policy object, or an empty string when no policy
	 * applies (which callers treat as deny). A resolvable model name whose policy
	 * file is missing throws `Wheels.Policy.NotDefined` in development/testing
	 * and returns an empty string (silent deny) in production.
	 */
	public any function $policyFor(required any record) {
		local.modelName = $policyModelName(arguments.record);
		if (!Len(local.modelName)) {
			return "";
		}
		local.className = $policyClassName(local.modelName);
		local.policyPath = $get("policyPath");
		local.file = false;
		if (DirectoryExists(ExpandPath(local.policyPath))) {
			local.file = $fileExistsNoCase(ExpandPath(local.policyPath & "/" & local.className & ".cfc"));
		}
		if (IsBoolean(local.file) && !local.file) {
			if ($get("showErrorInformation")) {
				Throw(
					type = "Wheels.Policy.NotDefined",
					message = "No policy found for the `#local.modelName#` model.",
					extendedInfo = "Create `#local.policyPath#/#local.className#.cfc` (e.g. by running `wheels generate policy #local.modelName#`) with one method per action to grant. In production a missing policy silently denies instead of throwing."
				);
			}
			return "";
		}
		local.componentPath = ListChangeDelims(local.policyPath, ".", "/") & "." & SpanExcluding(local.file, ".");
		local.policy = CreateObject("component", local.componentPath);
		local.policy.init(user = $currentUserForPolicy(), record = arguments.record);
		return local.policy;
	}

	/**
	 * Internal function. Derives the model name a policy should be resolved for:
	 * model instances and model classes report their class model name, strings
	 * pass through (headless / by-name checks), and everything else — including
	 * the boolean `false` a missed finder returns — yields an empty string.
	 */
	public string function $policyModelName(required any record) {
		if (IsBoolean(arguments.record)) {
			return "";
		}
		if (IsSimpleValue(arguments.record)) {
			return Trim(arguments.record);
		}
		if (IsObject(arguments.record) && StructKeyExists(arguments.record, "$classData")) {
			local.classData = arguments.record.$classData();
			if (StructKeyExists(local.classData, "modelName")) {
				return local.classData.modelName;
			}
		}
		return "";
	}

	/**
	 * Internal function. Maps a model name to its conventional policy class name
	 * (`Post` -> `PostPolicy`).
	 */
	public string function $policyClassName(required string modelName) {
		return capitalize(arguments.modelName) & "Policy";
	}

	/**
	 * Internal function. Resolves the identity policies are evaluated against, in
	 * order: (1) the DI service registered as `currentUser` when present, (2) the
	 * first registered authenticator strategy that exposes a `currentUser()`
	 * method (e.g. `wheels.auth.SessionStrategy`) and reports a non-empty
	 * principal, (3) an empty string (guest). Apps customize by registering the
	 * `currentUser` DI service or by overriding this method on their base
	 * controller.
	 */
	public any function $currentUserForPolicy() {
		// 1. Explicit DI registration wins.
		try {
			if (IsDefined("application.wheelsdi") && application.wheelsdi.containsInstance("currentUser")) {
				return application.wheelsdi.getInstance("currentUser");
			}
		} catch (any e) {
			// A broken resolver must not turn every request into a 500 — fall through to the next seam.
		}
		// 2. A configured authenticator whose strategy can report the current user.
		try {
			if (IsDefined("application.wheelsdi") && application.wheelsdi.containsInstance("authenticator")) {
				local.authenticator = application.wheelsdi.getInstance("authenticator");
				local.strategyNames = local.authenticator.getStrategyNames();
				for (local.strategyName in local.strategyNames) {
					local.strategy = local.authenticator.getStrategy(local.strategyName);
					if (StructKeyExists(local.strategy, "currentUser")) {
						local.candidate = local.strategy.currentUser();
						if (IsStruct(local.candidate) && !StructIsEmpty(local.candidate)) {
							return local.candidate;
						}
					}
				}
			}
		} catch (any e) {
			// Session scope unavailable or authenticator misconfigured — treat as guest.
		}
		// 3. Guest.
		return "";
	}

	/**
	 * Internal function. Surfaces a policy denial as HTTP 403, mirroring how
	 * `$throwErrorOrShow404Page()` wires `Wheels.RecordNotFound` to 404: the
	 * status header is committed first, then development/testing throw
	 * `Wheels.NotAuthorized` (re-asserted to 403 by the onError status mapping in
	 * `wheels.events.EventMethods`) while production renders a minimal body and
	 * aborts so no policy detail leaks.
	 */
	public void function $notAuthorized(required string action, string modelName = "") {
		$header(statusCode = 403);
		if ($get("showErrorInformation")) {
			local.target = Len(arguments.modelName) ? " on `#arguments.modelName#`" : "";
			Throw(
				type = "Wheels.NotAuthorized",
				message = "Not authorized to perform the `#arguments.action#` action#local.target#.",
				extendedInfo = "The resolved policy denied this action (policies are default-deny). Override the `#arguments.action#` method in the policy to grant access. This error maps to HTTP 403."
			);
		} else {
			WriteOutput("Forbidden");
			abort;
		}
	}
}

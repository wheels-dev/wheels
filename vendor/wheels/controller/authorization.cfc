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
	 * policy class that lacks a method for the action throws
	 * `Wheels.Policy.UnknownAction` (a typo, not a deny). Reserved `init` and
	 * `scope` still deny as `Wheels.NotAuthorized`. Only boolean `true` grants.
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
		local.allowed = $invokePolicyAction(
			policy = local.policy,
			action = local.action,
			modelName = local.modelName
		);
		if (!$policyGranted(local.allowed)) {
			$notAuthorized(action = local.action, modelName = local.modelName);
		}
		return arguments.record;
	}

	/**
	 * Boolean policy check for conditionals and views (views run in the
	 * controller's `variables` scope, so `can()` is available in templates
	 * automatically):
	 *
	 * ```
	 * <cfif can("update", post)>##linkTo(text="Edit", route="editPost", key=post.id)##</cfif>
	 * ```
	 *
	 * Returns `false` (deny) for a guest, for an empty record, and for a policy
	 * method that does not return boolean `true`. A missing method throws
	 * `Wheels.Policy.UnknownAction`. A missing policy class still throws
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
		return $policyGranted(
			$invokePolicyAction(
				policy = local.policy,
				action = arguments.action,
				modelName = $policyModelName(arguments.record)
			)
		);
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
		if (!Len(local.modelName)) {
			if ($get("showErrorInformation")) {
				Throw(
					type = "Wheels.Policy.InvalidCollection",
					message = "policyScope() could not derive a model from the passed collection.",
					extendedInfo = "Pass the model class first and chain from the result, e.g. `policyScope(model(""Post"")).active().findAll()`. Query-builder and scope chains that are already in flight cannot be passed to policyScope()."
				);
			}
			// Production InvalidCollection: fail-closed. Do not call whereIn on a
			// collection we could not resolve (empty IN, matching-all, or no method).
			return CreateObject("component", "wheels.Policy").init();
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
	 * Internal function. `init` and `scope` are Policy lifecycle methods, not
	 * grantable actions. authorize()/can() must not Invoke them (missing
	 * `collection` on scope() is a 500, not Wheels.NotAuthorized).
	 */
	public boolean function $isReservedPolicyAction(required string actionName) {
		return ListFindNoCase("init,scope", arguments.actionName) > 0;
	}

	/**
	 * Internal function. Dispatches a policy action. Missing methods throw
	 * `Wheels.Policy.UnknownAction`. Reserved `init`/`scope`, an empty action,
	 * or a missing policy object return false (deny). Dynamic dispatch uses
	 * Invoke() — Adobe CF rejects `policy[action]()` at compile time, and an
	 * extracted function reference drops the receiver on BoxLang.
	 */
	public any function $invokePolicyAction(required any policy, required string action, string modelName = "") {
		if (!IsObject(arguments.policy) || !Len(arguments.action) || $isReservedPolicyAction(arguments.action)) {
			return false;
		}
		if (!StructKeyExists(arguments.policy, arguments.action) || !IsCustomFunction(arguments.policy[arguments.action])) {
			local.target = Len(arguments.modelName) ? " on the `#arguments.modelName#` policy" : "";
			Throw(
				type = "Wheels.Policy.UnknownAction",
				message = "No `#arguments.action#` method#local.target#.",
				extendedInfo = "A missing policy method is a typo, not a deny. Declare the method to grant, or inherit the default-deny from wheels.Policy for a known action. Reserved `init` and `scope` deny as Wheels.NotAuthorized."
			);
		}
		local.allowed = Invoke(arguments.policy, arguments.action);
		if (IsNull(local.allowed)) {
			return false;
		}
		return local.allowed;
	}

	/**
	 * Internal function. Only boolean `true` grants. CFML string truthies
	 * (`yes`, `true`) and numeric `1` serialize to something other than the
	 * JSON boolean `true`, so they deny.
	 */
	public boolean function $policyGranted(required any allowed) {
		if (IsNull(arguments.allowed)) {
			return false;
		}
		return SerializeJSON(arguments.allowed) == "true";
	}

	/**
	 * Internal function. Resolves the identity policies are evaluated against, in
	 * order: (1) the DI service registered as `currentUser` when present, (2) the
	 * first registered authenticator strategy that exposes a `currentUser()`
	 * method (e.g. `wheels.auth.SessionStrategy`) and reports a non-empty
	 * principal, (3) an empty string (guest). A throwing `currentUser` service
	 * or authenticator strategy propagates. Apps customize by registering the
	 * `currentUser` DI service or by overriding this method on their base
	 * controller.
	 */
	public any function $currentUserForPolicy() {
		if (IsDefined("application.wheelsdi") && application.wheelsdi.containsInstance("currentUser")) {
			return application.wheelsdi.getInstance("currentUser");
		}
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
		if ($get("showErrorInformation") || StructKeyExists(request, "$wheelsIsolateAbort")) {
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

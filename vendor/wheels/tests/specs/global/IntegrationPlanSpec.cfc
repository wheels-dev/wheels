component extends="wheels.WheelsTest" {

	/**
	 * Covers the cached component-integration plan (#3213, #3457): the plan
	 * must never carry null function references, because a null ref is copied
	 * into every materialized model/controller/mapper instance and Lucee 7
	 * throws a bare NullPointerException when it later enumerates the
	 * component. $componentIntegrationPlan validates the cached plan once per
	 * request and rebuilds it in place when it is poisoned.
	 */
	function run() {

		describe("component integration plan", function() {

			beforeEach(function() {
				g = application.wo;
				_planPath = "wheels.model";
				_checkKey = LCase(_planPath);
				// Make sure a cached plan exists before tests poke at it.
				g.$componentIntegrationPlan(_planPath);
				_originalPlan = application.wheels.integrationPlans[_planPath];
			});

			afterEach(function() {
				if (IsArray(_originalPlan) && StructKeyExists(application.wheels.integrationPlans, _planPath)) {
					application.wheels.integrationPlans[_planPath] = _originalPlan;
				}
				if (StructKeyExists(request.wheelsIntegrationPlanChecks, _checkKey)) {
					StructDelete(request.wheelsIntegrationPlanChecks, _checkKey);
				}
				if (StructKeyExists(request.wheelsIntegrationPlans, _checkKey)) {
					StructDelete(request.wheelsIntegrationPlans, _checkKey);
				}
			});

			it("builds a model plan with no null references", function() {
				var plan = g.$buildComponentIntegrationPlan("wheels.model");
				expect(ArrayLen(plan)).toBeGT(0);
				expect(g.$integrationPlanHasNullRefs(plan)).toBeFalse();
			});

			it("detects entries with missing or null references", function() {
				var plan = g.$buildComponentIntegrationPlan("wheels.model");
				var poisoned = $shallowCopyPlan(plan);
				StructDelete(poisoned[1].publicMethods[1], "ref");
				expect(g.$integrationPlanHasNullRefs(poisoned)).toBeTrue();
			});

			it("rebuilds a cached plan that contains null references", function() {
				_originalPlan = application.wheels.integrationPlans[_planPath];
				application.wheels.integrationPlans[_planPath] = $shallowCopyPlan(_originalPlan);
				StructDelete(application.wheels.integrationPlans[_planPath][1].publicMethods[1], "ref");
				// force re-validation within this request (both the once-per-request
				// flag and the request-scope plan cache must be cleared so the
				// poisoned application-scope plan is re-read)
				if (StructKeyExists(request.wheelsIntegrationPlanChecks, _checkKey)) {
					StructDelete(request.wheelsIntegrationPlanChecks, _checkKey);
				}
				if (StructKeyExists(request.wheelsIntegrationPlans, _checkKey)) {
					StructDelete(request.wheelsIntegrationPlans, _checkKey);
				}
				var plan = g.$componentIntegrationPlan(_planPath);
				expect(g.$integrationPlanHasNullRefs(plan)).toBeFalse();
				expect(application.wheels.integrationPlans[_planPath]).toBe(plan);
			});

			it("serves the plan from the request scope after its first use", function() {
				if (StructKeyExists(request.wheelsIntegrationPlans, _checkKey)) {
					StructDelete(request.wheelsIntegrationPlans, _checkKey);
				}
				var first = g.$componentIntegrationPlan(_planPath);
				expect(request.wheelsIntegrationPlans[_planPath]).toBe(first);
				// a second call returns the same request-cached array without
				// touching the application scope again
				var second = g.$componentIntegrationPlan(_planPath);
				expect(second).toBe(first);
			});

		});

	}

	/**
	 * Shallow-copies an integration plan, copying each publicMethods entry so
	 * poisoning the copy can never mutate the live cached plan.
	 */
	private array function $shallowCopyPlan(required array plan) {
		var rv = [];
		for (var comp in arguments.plan) {
			var methods = [];
			for (var pm in comp.publicMethods) {
				ArrayAppend(methods, {name = pm.name, ref = pm.ref});
			}
			ArrayAppend(rv, {
				instance = comp.instance,
				methods = comp.methods,
				publicMethods = methods,
				fullName = comp.fullName
			});
		}
		return rv;
	}

}

component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Dev-Mode Interface Contract Verification", () => {

			it("$verifyInterfaceContracts does not throw in a healthy app", () => {
				// S1: a call with no expect() is a silent no-op. completed=true
				// only after the live function returns; a throw, or deleting the
				// call and leaving this expect, fails the spec.
				var state = {completed = false, type = ""};
				try {
					g.$verifyInterfaceContracts();
					state.completed = true;
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.completed).toBeTrue(
					"$verifyInterfaceContracts must complete without throwing (got #state.type#)"
				);
			});

			it("$verifyInterfaceContracts checks that model has finder methods", () => {
				var user = model("user");
				var requiredMethods = ["findAll", "findOne", "findByKey", "save", "valid"];
				for (var m in requiredMethods) {
					expect(StructKeyExists(user, m)).toBeTrue("Model missing required method: #m#");
				}
			});

			it("$verifyInterfaceContracts checks that controller has rendering methods", () => {
				var params = {controller: "wheels", action: "wheels"};
				var ctrl = g.controller(name = "wheels", params = params);
				var requiredMethods = ["renderView", "renderPartial", "renderText", "redirectTo"];
				for (var m in requiredMethods) {
					expect(StructKeyExists(ctrl, m)).toBeTrue("Controller missing required method: #m#");
				}
			});

			it("controller instances have h() and hAttr() mixed in from view helpers", () => {
				var ctrl = g.controller(name = "dummy");
				expect(StructKeyExists(ctrl, "h")).toBeTrue("Controller missing mixin: h()");
				expect(StructKeyExists(ctrl, "hAttr")).toBeTrue("Controller missing mixin: hAttr()");
			});

		});

	}

}

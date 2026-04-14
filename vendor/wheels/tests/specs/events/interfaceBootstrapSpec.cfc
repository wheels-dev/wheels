component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Dev-Mode Interface Contract Verification", () => {

			it("$verifyInterfaceContracts does not throw in a healthy app", () => {
				g.$verifyInterfaceContracts();
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

		});

	}

}

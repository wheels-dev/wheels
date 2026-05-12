component extends="wheels.WheelsTest" {

	function run() {
		describe("debug.cfm Packages section", () => {
			// The debug bar's Environment > Packages section shows ONLY locally
			// installed packages (application.wheels.packageMeta). The list of
			// packages available from the wheels-packages registry belongs on
			// the standalone Tools > Packages page (packagelist.cfm), not in
			// the inline debug overlay — keeps the bar compact and avoids
			// every page load triggering a registry-listAll() walk.
			it("does NOT render registry packages in the inline Environment panel (##2530)", () => {
				var priorPublic = application.wheels.public;
				var hadPkgComp = StructKeyExists(application.wheels, "enablePackagesComponent");
				var priorPkgComp = hadPkgComp ? application.wheels.enablePackagesComponent : false;
				var hadEnv = StructKeyExists(application.wheels, "environment");
				var priorEnv = hadEnv ? application.wheels.environment : "development";
				var hadPkgMeta = StructKeyExists(application.wheels, "packageMeta");
				var priorPkgMeta = hadPkgMeta ? application.wheels.packageMeta : {};
				var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};

				try {
					application.wheels.environment = "development";
					application.wheels.enablePackagesComponent = true;
					application.wheels.packageMeta = {};
					application.wheels.public = CreateObject("component", "wheels.tests._assets.packages.FakePublic").init(
						packages = [
							{
								name = "wheels-sentry-fixture-pkg",
								description = "Fixture registry package for ##2530",
								tags = [],
								homepage = "",
								latestVersion = "9.9.9"
							}
						]
					);

					if (!StructKeyExists(request, "wheels")) {
						request.wheels = {};
					}
					request.wheels.execution = {total = 0};
					request.wheels.params = {controller = "wheels", action = "tests", route = "", key = ""};

					// debug.cfm bails out (cfexit) when url.format is one of
					// json/xml/csv/pdf so it never breaks an API response. The
					// test runner is hit with format=json — clear it for the
					// duration of the include so the template renders.
					var hadUrlFormat = StructKeyExists(url, "format");
					var priorUrlFormat = hadUrlFormat ? url.format : "";
					if (hadUrlFormat) {
						StructDelete(url, "format");
					}

					var output = "";
					try {
						output = application.wo.$includeAndReturnOutput($template = "/wheels/events/onrequestend/debug.cfm");
					} finally {
						if (hadUrlFormat) {
							url.format = priorUrlFormat;
						}
					}

					expect(output contains "wheels-sentry-fixture-pkg").toBeFalse(
						"debug.cfm must NOT render the registry-packages table inline "
						& "in the Environment panel. The registry list belongs on the "
						& "standalone Tools > Packages page. See issue ##2530."
					);
				} finally {
					application.wheels.public = priorPublic;
					if (hadPkgComp) {
						application.wheels.enablePackagesComponent = priorPkgComp;
					} else {
						StructDelete(application.wheels, "enablePackagesComponent");
					}
					if (hadEnv) {
						application.wheels.environment = priorEnv;
					}
					if (hadPkgMeta) {
						application.wheels.packageMeta = priorPkgMeta;
					} else {
						StructDelete(application.wheels, "packageMeta");
					}
					request.wheels = priorReqWheels;
				}
			});
		});
	}

}

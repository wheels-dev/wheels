component extends="wheels.WheelsTest" {

	function run() {

		describe("debug.cfm Packages section", () => {

			// Regression for issue #2530: the debug-bar Packages tab only renders
			// the "installed" table (driven by application.wheels.packageMeta).
			// It never calls Public.$loadRegistryPackages, so the "available
			// from the registry" table is missing entirely. The same call is
			// already wired into vendor/wheels/public/views/packagelist.cfm.
			it("renders registry packages alongside installed packages (##2530)", () => {
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
					application.wheels.public = CreateObject(
						"component",
						"wheels.tests._assets.packages.FakePublic"
					).init(packages = [
						{
							name: "wheels-sentry-fixture-pkg",
							description: "Fixture registry package for ##2530",
							tags: [],
							homepage: "",
							latestVersion: "9.9.9"
						}
					]);

					if (!StructKeyExists(request, "wheels")) {
						request.wheels = {};
					}
					request.wheels.execution = {total: 0};
					request.wheels.params = {controller: "wheels", action: "tests", route: "", key: ""};

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
						output = application.wo.$includeAndReturnOutput(
							$template = "/wheels/events/onrequestend/debug.cfm"
						);
					} finally {
						if (hadUrlFormat) {
							url.format = priorUrlFormat;
						}
					}

					expect(output contains "wheels-sentry-fixture-pkg").toBeTrue(
						"Expected debug.cfm output to include the registry package name "
						& "'wheels-sentry-fixture-pkg' but the registry-packages table "
						& "is not being rendered. See issue ##2530."
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

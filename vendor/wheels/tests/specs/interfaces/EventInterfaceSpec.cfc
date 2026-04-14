component extends="wheels.WheelsTest" {

	function run() {

		describe("Event Interface Contracts", () => {

			describe("EventHandlerInterface", () => {

				beforeEach(() => {
					eventMethods = CreateObject("component", "wheels.events.EventMethods");
				});

				it("exposes all required event handler methods", () => {
					var methods = [
						"$runOnError", "$runOnRequestStart", "$runOnRequestEnd",
						"$runOnSessionStart", "$runOnSessionEnd",
						"$runOnMissingTemplate", "$getRequestFormat"
					];
					for (var m in methods) {
						expect(structKeyExists(eventMethods, m)).toBeTrue("EventMethods missing: #m#()");
					}
				});

				it("$runOnError has correct return type and parameters", () => {
					var meta = getMetaData(eventMethods["$runOnError"]);
					expect(meta.returnType ?: "any").toBe("string");

					var paramNames = [];
					for (var p in meta.parameters) {
						arrayAppend(paramNames, p.name);
					}
					expect(arrayFindNoCase(paramNames, "exception") > 0).toBeTrue("Missing parameter: exception");
					expect(arrayFindNoCase(paramNames, "eventName") > 0).toBeTrue("Missing parameter: eventName");
				});

				it("$runOnRequestStart has void return type", () => {
					var meta = getMetaData(eventMethods["$runOnRequestStart"]);
					expect(meta.returnType ?: "any").toBe("void");
				});

				it("$getRequestFormat returns string", () => {
					var meta = getMetaData(eventMethods["$getRequestFormat"]);
					expect(meta.returnType ?: "any").toBe("string");
				});

			});

		});

	}

}

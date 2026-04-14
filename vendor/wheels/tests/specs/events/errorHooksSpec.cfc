component extends="wheels.WheelsTest" {

	function run() {

		describe("Error Lifecycle Hooks", () => {

			beforeEach(() => {
				application.wheels.onErrorCallbacks = [];
			});

			afterEach(() => {
				application.wheels.onErrorCallbacks = [];
			});

			it("has an empty onErrorCallbacks array by default", () => {
				expect(application.wheels).toHaveKey("onErrorCallbacks");
				expect(application.wheels.onErrorCallbacks).toBeArray();
			});

			it("registerOnError adds a callback", () => {
				var callCount = {value: 0};
				application.wo.registerOnError(function(exception) {
					callCount.value++;
				});
				expect(ArrayLen(application.wheels.onErrorCallbacks)).toBe(1);
			});

			it("$fireOnErrorCallbacks invokes all registered callbacks", () => {
				var log = {entries: []};
				application.wo.registerOnError(function(exception) {
					ArrayAppend(log.entries, "first");
				});
				application.wo.registerOnError(function(exception) {
					ArrayAppend(log.entries, "second");
				});

				var fakeException = {message: "test error", type: "TestError"};
				application.wo.$fireOnErrorCallbacks(fakeException);

				expect(ArrayLen(log.entries)).toBe(2);
				expect(log.entries[1]).toBe("first");
				expect(log.entries[2]).toBe("second");
			});

			it("$fireOnErrorCallbacks does not throw if a callback fails", () => {
				var tracker = {secondRan: false};
				application.wo.registerOnError(function(exception) {
					throw(type="CallbackBug", message="Broken callback");
				});
				application.wo.registerOnError(function(exception) {
					tracker.secondRan = true;
				});

				var fakeException = {message: "test", type: "TestError"};
				application.wo.$fireOnErrorCallbacks(fakeException);
				expect(tracker.secondRan).toBeTrue();
			});

		});

	}

}

component extends="wheels.WheelsTest" {

	function run() {

		describe("Compile-Time Interface Enforcement", () => {

			it("Injector declares InjectorInterface implementation", () => {
				var meta = getComponentMetaData("wheels.Injector");
				expect(meta).toHaveKey("implements");

				// Metadata format varies by engine — check both struct and array
				var found = false;
				if (isStruct(meta.implements)) {
					found = structKeyExists(meta.implements, "wheels.interfaces.di.InjectorInterface");
				} else if (isArray(meta.implements)) {
					for (var iface in meta.implements) {
						if (isStruct(iface) && (iface.name ?: "") == "wheels.interfaces.di.InjectorInterface") {
							found = true;
							break;
						}
					}
				}
				expect(found).toBeTrue("Injector should implement wheels.interfaces.di.InjectorInterface");
			});

			it("EventMethods declares EventHandlerInterface implementation", () => {
				var meta = getComponentMetaData("wheels.events.EventMethods");
				expect(meta).toHaveKey("implements");

				var found = false;
				if (isStruct(meta.implements)) {
					found = structKeyExists(meta.implements, "wheels.interfaces.events.EventHandlerInterface");
				} else if (isArray(meta.implements)) {
					for (var iface in meta.implements) {
						if (isStruct(iface) && (iface.name ?: "") == "wheels.interfaces.events.EventHandlerInterface") {
							found = true;
							break;
						}
					}
				}
				expect(found).toBeTrue("EventMethods should implement wheels.interfaces.events.EventHandlerInterface");
			});

		});

	}

}

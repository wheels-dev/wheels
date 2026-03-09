component extends="wheels.WheelsTest" {

    function run() {

		describe("Basic Stuff", function() {

			it("mappings", function() {
                debug(getApplicationMetadata().mappings);
			});

		});
	}

}

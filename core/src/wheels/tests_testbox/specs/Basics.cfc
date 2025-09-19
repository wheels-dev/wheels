component extends="wheels.Testbox" {

    function run() {

		describe("Basic Stuff", function() {

			it("mappings", function() {
                debug(getApplicationMetadata().mappings);
			});

		});
	}

}

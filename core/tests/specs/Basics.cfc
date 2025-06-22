component extends="testbox.system.BaseSpec" {

    function run() {

		describe("Basic Stuff", function() {

			it("mappings", function() {
                debug(getApplicationMetadata().mappings);
			});

		});
	}

}

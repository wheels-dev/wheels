/**
 * MockBox writes a stub file for each mocked method under its generation path and
 * fails when that directory is missing, as `public/testbox/system/stubs` is in an app
 * made with `wheels new`. WheelsTest's getMockBox() creates it first.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("MockBox stub directory", () => {

			it("is created when missing, so a mocked method works", () => {
				var id = Replace(CreateUUID(), "-", "", "all");
				var root = "/wheels/tests/_assets/mockstubs-" & id;
				var state = {greeting = "", created = false, original = getMockBox().getGenerationPath()};
				try {
					var stub = getMockBox(root & "/nested/").createStub();
					state.created = DirectoryExists(ExpandPath(root & "/nested"));
					stub.$("greet", "hello");
					state.greeting = stub.greet();
				} finally {
					getMockBox(state.original);
					$removeTree(ExpandPath(root));
				}
				expect(state.created).toBeTrue("the nested stub directory was not created");
				expect(state.greeting).toBe("hello");
			});

			it("is left alone when it exists", () => {
				var mockBox = getMockBox();
				var path = ExpandPath(mockBox.getGenerationPath());
				$ensureMockStubDirectory(mockBox);
				expect(DirectoryExists(path)).toBeTrue(path);
				$ensureMockStubDirectory(mockBox);
				expect(DirectoryExists(path)).toBeTrue(path);
			});

		});

	}

}

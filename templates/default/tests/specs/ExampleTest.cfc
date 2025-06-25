component extends="testbox.system.BaseSpec" {
	
	function run() {
		describe("Example Test Suite", function() {
			
			it("should pass a simple test", function() {
				expect(true).toBe(true);
			});
			
			it("should do basic math", function() {
				expect(1 + 1).toBe(2);
			});
			
		});
	}
	
}
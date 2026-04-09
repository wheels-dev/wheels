component extends="wheels.WheelsTest" {

	function run() {

		describe("Enum scope WHERE clause escaping", () => {

			beforeEach(() => {
				local.model = model("author");
			});

			it("passes normal enum values through unchanged", () => {
				local.model.enum(property="status", values="draft,published,archived");
				var scopes = local.model.$classData().scopes;
				expect(scopes).toHaveKey("draft");
				expect(scopes.draft.where).toBe("status = 'draft'");
				expect(scopes).toHaveKey("published");
				expect(scopes.published.where).toBe("status = 'published'");
			});

			it("doubles single quotes to prevent SQL injection", () => {
				local.model.enum(property="status", values={injected: "val' OR '1'='1"});
				var scopes = local.model.$classData().scopes;
				expect(scopes).toHaveKey("injected");
				expect(scopes.injected.where).toBe("status = 'val'' OR ''1''=''1'");
			});

			it("doubles backslashes to neutralize MySQL backslash escape sequences", () => {
				local.model.enum(property="status", values={injected: "\' OR 1=1 --"});
				var scopes = local.model.$classData().scopes;
				expect(scopes).toHaveKey("injected");
				expect(scopes.injected.where).toBe("status = '\\'' OR 1=1 --'");
			});

			it("strips null bytes from enum values", () => {
				var malicious = "val" & Chr(0) & "ue";
				local.model.enum(property="status", values={nullbyte: malicious});
				var scopes = local.model.$classData().scopes;
				expect(scopes).toHaveKey("nullbyte");
				expect(scopes.nullbyte.where).toBe("status = 'value'");
				expect(scopes.nullbyte.where).notToInclude(Chr(0));
			});

			it("handles combined attack vectors safely", () => {
				var malicious = Chr(0) & "\' OR 1=1 --";
				local.model.enum(property="status", values={combined: malicious});
				var scopes = local.model.$classData().scopes;
				expect(scopes).toHaveKey("combined");
				expect(scopes.combined.where).toBe("status = '\\'' OR 1=1 --'");
				expect(scopes.combined.where).notToInclude(Chr(0));
			});

			it("generates safe WHERE clause for struct-mapped enum values", () => {
				local.model.enum(property="priority", values={low: 0, medium: 1, high: 2});
				var scopes = local.model.$classData().scopes;
				expect(scopes).toHaveKey("low");
				expect(scopes.low.where).toBe("priority = '0'");
				expect(scopes).toHaveKey("high");
				expect(scopes.high.where).toBe("priority = '2'");
			});

		});

	}

}

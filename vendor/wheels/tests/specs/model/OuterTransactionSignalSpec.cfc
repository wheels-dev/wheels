component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("model invokeWithTransaction respects outer-transaction signal (issue ##2789)", () => {

			beforeEach(() => {
				// Defensive cleanup in case a prior failing run left the flag set.
				if (StructKeyExists(request, "$wheelsTransactionWrapper")) {
					StructDelete(request, "$wheelsTransactionWrapper");
				}
				queryExecute(
					"DELETE FROM c_o_r_e_tags WHERE name IN ('outerSig_control', 'outerSig_signal', 'outerSig_signal_create', 'outerSig_signal_update', 'outerSig_signal_delete')",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
			});

			afterEach(() => {
				if (StructKeyExists(request, "$wheelsTransactionWrapper")) {
					StructDelete(request, "$wheelsTransactionWrapper");
				}
				queryExecute(
					"DELETE FROM c_o_r_e_tags WHERE name IN ('outerSig_control', 'outerSig_signal', 'outerSig_signal_create', 'outerSig_signal_update', 'outerSig_signal_delete')",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
			});

			it("control: model.create(transaction='rollback') without the flag rolls the row back", () => {
				// Establishes the baseline that the rollback path actually works
				// in this environment, so the inverse assertion below is meaningful.
				var beforeCount = g.model("tag").count();
				g.model("tag").create(name = "outerSig_control", transaction = "rollback");
				var afterCount = g.model("tag").count();
				expect(afterCount).toBe(beforeCount);
			});

			it("treats invokeWithTransaction as 'alreadyopen' when request.$wheelsTransactionWrapper is set", () => {
				// With the outer-transaction signal set, the model must NOT open
				// its own cftransaction — even when the caller explicitly passes
				// transaction='rollback'. The save is treated as alreadyopen, so
				// no cftransaction is begun and no rollback is issued; the INSERT
				// runs in the ambient (auto-commit) connection state and persists.
				// This is the surrogate observable for the original MSSQL bug
				// (#2789): inside a migrator's outer cftransaction, the model's
				// nested cftransaction silently rolled the row back. Bypassing the
				// model's wrapper eliminates the nested-transaction entirely.
				var beforeCount = g.model("tag").count();
				request.$wheelsTransactionWrapper = true;
				try {
					g.model("tag").create(name = "outerSig_signal", transaction = "rollback");
				} finally {
					StructDelete(request, "$wheelsTransactionWrapper");
				}
				var afterCount = g.model("tag").count();
				expect(afterCount).toBe(beforeCount + 1);
			});

			it("also bypasses the wrapper for update via save()", () => {
				// Same semantics for the update path: save() with
				// transaction='rollback' would normally roll the UPDATE back, but
				// with the signal set, the wrapper is bypassed.
				var tag = g.model("tag").create(name = "outerSig_signal_update");
				request.$wheelsTransactionWrapper = true;
				try {
					tag.name = "outerSig_signal_update_modified";
					tag.save(transaction = "rollback");
				} finally {
					StructDelete(request, "$wheelsTransactionWrapper");
				}
				var refetched = g.model("tag").findByKey(tag.id);
				expect(refetched.name).toBe("outerSig_signal_update_modified");
				// Cleanup explicit because the name no longer matches the afterEach pattern.
				queryExecute(
					"DELETE FROM c_o_r_e_tags WHERE id = :id",
					{ id = { value = tag.id, cfsqltype = "cf_sql_integer" } },
					{ datasource = application.wheels.dataSourceName }
				);
			});

			it("also bypasses the wrapper for deleteAll", () => {
				// Same semantics for deleteAll: transaction='rollback' would
				// normally roll the DELETE back, but with the signal set the
				// wrapper is bypassed, so the DELETE persists.
				g.model("tag").create(name = "outerSig_signal_delete");
				request.$wheelsTransactionWrapper = true;
				try {
					g.model("tag").deleteAll(where = "name = 'outerSig_signal_delete'", transaction = "rollback");
				} finally {
					StructDelete(request, "$wheelsTransactionWrapper");
				}
				var remaining = g.model("tag").count(where = "name = 'outerSig_signal_delete'");
				expect(remaining).toBe(0);
			});

		});

	}

}

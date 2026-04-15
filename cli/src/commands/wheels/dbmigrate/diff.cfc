/**
 * Diff
 * Generates auto-migration from model/DB schema differences.
 **/
component aliases='wheels db diff' extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @modelName Optional. If omitted, runs diffAll() across all models.
	 * @rename Rename hint in the form OLD:NEW (repeatable).
	 *         For diffAll, prefix with model: User.old_col:newCol
	 * @threshold Heuristic confidence threshold (default 0.7).
	 * @write Write the migration file(s). Default: preview only.
	 * @name Migration name (single-model only).
	 * @help Generate a migration from model/DB schema differences.
	 **/
	function run(
		string modelName = "",
		string rename = "",
		numeric threshold = 0.7,
		boolean write = false,
		string name = ""
	) {
		try {
			arguments = reconstructArgs(arguments);

			// Build hints struct from --rename flags
			local.hints = $parseRenameFlags(arguments.rename, arguments.modelName);

			// Build query string
			local.qs = "&command=diff";
			if (Len(arguments.modelName)) {
				local.qs &= "&modelName=" & URLEncodedFormat(arguments.modelName);
			}
			if (!StructIsEmpty(local.hints)) {
				local.qs &= "&hints=" & URLEncodedFormat(SerializeJSON(local.hints));
			}
			local.qs &= "&threshold=" & arguments.threshold;
			if (arguments.write) {
				local.qs &= "&write=true";
				if (Len(arguments.name)) {
					local.qs &= "&name=" & URLEncodedFormat(arguments.name);
				}
			}

			local.results = $sendToCliCommand(local.qs);
			if (!local.results.success) {
				detailOutput.error(StructKeyExists(local.results, "message") ? local.results.message : "Diff failed");
				return;
			}

			if (StructKeyExists(local.results, "model")) {
				$renderSingleModelDiff(local.results.model, local.results.migrationWritten);
			} else {
				$renderDiffAll(local.results.models, local.results.migrationsWritten);
			}
		} catch (any e) {
			detailOutput.error("Failed to run diff: " & e.message);
		}
	}

	/**
	 * Parses --rename flags into a hints struct.
	 * Single-model: returns {renames: {"old": "new"}}
	 * diffAll: returns {hints: {"Model": {renames: {"old": "new"}}}}
	 */
	private struct function $parseRenameFlags(required string rename, required string modelName) {
		if (!Len(arguments.rename)) {
			return {};
		}

		local.isDiffAll = !Len(arguments.modelName);
		local.pairs = ListToArray(arguments.rename, ",");
		local.result = local.isDiffAll ? {hints: {}} : {renames: {}};

		for (local.p in local.pairs) {
			local.parts = ListToArray(local.p, ":");
			if (ArrayLen(local.parts) != 2) {
				Throw(message="invalid --rename format: '#local.p#'. Expected OLD:NEW or Model.OLD:NEW");
			}
			local.lhs = Trim(local.parts[1]);
			local.rhs = Trim(local.parts[2]);

			if (local.isDiffAll) {
				if (!Find(".", local.lhs)) {
					Throw(message="--rename for diffAll requires Model.col format, got '#local.lhs#'");
				}
				local.dot = Find(".", local.lhs);
				local.m = Left(local.lhs, local.dot - 1);
				local.col = Mid(local.lhs, local.dot + 1, Len(local.lhs));
				if (!StructKeyExists(local.result.hints, local.m)) {
					local.result.hints[local.m] = {renames: {}};
				}
				if (StructKeyExists(local.result.hints[local.m].renames, local.col)) {
					Throw(message="duplicate --rename for #local.m#.#local.col#");
				}
				local.result.hints[local.m].renames[local.col] = local.rhs;
			} else {
				if (StructKeyExists(local.result.renames, local.lhs)) {
					Throw(message="duplicate --rename for #local.lhs#");
				}
				local.result.renames[local.lhs] = local.rhs;
			}
		}

		return local.result;
	}

	private void function $renderSingleModelDiff(required struct model, string migrationWritten = "") {
		detailOutput.header("Diff for " & arguments.model.modelName & " (" & arguments.model.tableName & ")");

		if (ArrayLen(arguments.model.renameColumns)) {
			detailOutput.subHeader("Renames (will apply)");
			for (local.r in arguments.model.renameColumns) {
				print.line("  " & local.r.from & " -> " & local.r.to
					& "    [" & local.r.type & "]  (source: " & local.r.source & ")").toConsole();
			}
		}

		if (ArrayLen(arguments.model.suggestedRenames)) {
			detailOutput.subHeader("Suggested renames (pass --rename to confirm)");
			for (local.s in arguments.model.suggestedRenames) {
				local.flag = local.s.ambiguous ? " [AMBIGUOUS]" : "";
				print.line("  " & local.s.from & " -> " & local.s.to
					& "    [" & local.s.type & "]  confidence: "
					& NumberFormat(local.s.confidence, "0.00") & local.flag).toConsole();
				print.line("    wheels dbmigrate diff " & arguments.model.modelName
					& " --rename=" & local.s.from & ":" & local.s.to).toConsole();
			}
		}

		if (ArrayLen(arguments.model.addColumns)) {
			detailOutput.subHeader("Adds");
			for (local.a in arguments.model.addColumns) {
				print.line("  + " & local.a.name & "    [" & local.a.type & "]").toConsole();
			}
		}

		if (ArrayLen(arguments.model.removeColumns)) {
			// Build a set of column names that appear as "from" in suggestedRenames
			// so we can add a pointer hint to the remove line.
			local.suggestedFroms = {};
			for (local.s in arguments.model.suggestedRenames) {
				local.suggestedFroms[LCase(local.s.from)] = true;
			}

			detailOutput.subHeader("Removes");
			for (local.rm in arguments.model.removeColumns) {
				local.suffix = StructKeyExists(local.suggestedFroms, LCase(local.rm.name))
					? "    (will DROP - use --rename if this is actually a rename)"
					: "    (will DROP)";
				print.line("  - " & local.rm.name & local.suffix).toConsole();
			}
		}

		if (ArrayLen(arguments.model.changeColumns)) {
			detailOutput.subHeader("Changes");
			for (local.c in arguments.model.changeColumns) {
				print.line("  ~ " & local.c.name & "    " & local.c.from.type & " -> " & local.c.to.type).toConsole();
			}
		}

		print.line("").toConsole();
		if (Len(arguments.migrationWritten)) {
			detailOutput.statusSuccess("Migration file written. Run 'wheels dbmigrate latest' to apply.");
		} else {
			print.yellowLine("Preview only - no migration file written. Pass --write to commit.").toConsole();
		}
	}

	private void function $renderDiffAll(required struct models, required array migrationsWritten) {
		local.count = StructCount(arguments.models);
		if (local.count == 0) {
			print.greenLine("No changes detected across all models.").toConsole();
			return;
		}
		detailOutput.header("Diff across " & local.count & " model(s) with changes");
		for (local.name in arguments.models) {
			print.line("").toConsole();
			$renderSingleModelDiff(arguments.models[local.name], "");
		}
		print.line("").toConsole();
		if (ArrayLen(arguments.migrationsWritten)) {
			detailOutput.statusSuccess("Wrote migrations for: " & ArrayToList(arguments.migrationsWritten, ", "));
		} else {
			print.yellowLine("Preview only - no migration files written. Pass --write to commit.").toConsole();
		}
	}

}

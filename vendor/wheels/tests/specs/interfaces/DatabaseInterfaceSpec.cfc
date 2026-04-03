component extends="wheels.WheelsTest" {

	function run() {

		describe("Database Interface Contracts", () => {

			describe("DatabaseModelAdapterInterface", () => {

				it("H2 model adapter exposes all required methods", () => {
					var adapter = CreateObject("component", "wheels.databaseAdapters.H2Model");
					var methods = [
						"$init", "$executeQuery", "$performQuery", "$identitySelect",
						"$generatedKey", "$getColumns", "$getColumnInfo",
						"$getValidationType", "$quoteIdentifier", "$quoteValue",
						"$stripIdentifierQuotes", "$tableAlias", "$tableName",
						"$columnAlias", "$removeColumnAliasesInOrderClause",
						"$isAggregateFunction", "$addColumnsToSelectAndGroupBy",
						"$convertMaxRowsToLimit", "$moveAggregateToHaving",
						"$randomOrder", "$defaultValues", "$comment",
						"$cleanInStatementValue", "$queryParams",
						"$setSharedModel", "$isSharedModel"
					];
					for (var m in methods) {
						expect(structKeyExists(adapter, m)).toBeTrue(
							"H2Model adapter missing: #m#()"
						);
					}
				});

			});

			describe("DatabaseMigratorAdapterInterface", () => {

				it("H2 migrator adapter exposes all required methods", () => {
					var adapter = CreateObject("component", "wheels.databaseAdapters.H2Migrator");
					var methods = [
						"typeToSQL", "addPrimaryKeyOptions", "primaryKeyConstraint",
						"addColumnOptions", "optionsIncludeDefault", "quote",
						"quoteTableName", "quoteColumnName", "createTable",
						"renameTable", "dropTable", "addColumnToTable",
						"changeColumnInTable", "renameColumnInTable",
						"dropColumnFromTable", "addForeignKeyToTable",
						"dropForeignKeyFromTable", "foreignKeySQL",
						"addIndex", "removeIndex", "createView", "dropView",
						"addRecordPrefix", "addRecordSuffix"
					];
					for (var m in methods) {
						expect(structKeyExists(adapter, m)).toBeTrue(
							"H2Migrator adapter missing: #m#()"
						);
					}
				});

			});

		});

	}

}

/**
 * @MIGRATION_NAME@
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 */
component extends="wheels.migrator.Migration" {
    
    /**
     * Run the migration UP
     */
    function up() {
        transaction {
            // Create table
            // createTable(name="@TABLE_NAME@", force=false) {
            //     // Primary key
            //     column(name="id", type="integer", autoIncrement=true, primaryKey=true);
            //     
            //     // Columns
            //     @COLUMN_DEFINITIONS@
            //     
            //     // Timestamps
            //     timestamps();
            // }
            
            // Add indexes
            // addIndex(table="@TABLE_NAME@", columns="columnName");
            
            // Add foreign keys
            // addForeignKey(table="@TABLE_NAME@", referenceTable="otherTable", column="otherTableId", referenceColumn="id");
        }
    }
    
    /**
     * Reverse the migration DOWN
     */
    function down() {
        transaction {
            // Drop table
            // dropTable("@TABLE_NAME@");
            
            // Or reverse specific changes
            // removeColumn(table="@TABLE_NAME@", column="columnName");
            // removeIndex(table="@TABLE_NAME@", indexName="indexName");
        }
    }
}
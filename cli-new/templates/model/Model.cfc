/**
 * @MODEL_NAME@ Model
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 */
component extends="Model" {
    
    function config() {
        // Table configuration
        table("@TABLE_NAME@");
        
        // Property definitions
@PROPERTY_DEFINITIONS@
        
        // Timestamps
        timestamps();
        
        // Validations
@VALIDATIONS@
        
        // Associations
@ASSOCIATIONS@
    }
}
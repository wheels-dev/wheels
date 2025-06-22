/**
 * @MODEL_NAME@ Model with Validations
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
        
        // Custom validation methods
        validate("validateCustomRules");
        
        // Associations
@ASSOCIATIONS@
        
        // Callbacks
        beforeValidation("trimProperties");
    }
    
    /**
     * Custom validation rules
     */
    private function validateCustomRules() {
        // Add your custom validation logic here
        // Example:
        // if (len(this.name) && len(this.name) < 3) {
        //     addError(property="name", message="Name must be at least 3 characters long");
        // }
    }
    
    /**
     * Trim all string properties before validation
     */
    private function trimProperties() {
        var properties = getProperties();
        for (var prop in properties) {
            if (isSimpleValue(this[prop.name]) && prop.type == "string") {
                this[prop.name] = trim(this[prop.name]);
            }
        }
    }
}
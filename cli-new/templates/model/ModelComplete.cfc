/**
 * @MODEL_NAME@ Model - Full Featured
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 * 
 * This model includes:
 * - Property definitions
 * - Validations
 * - Audit trail
 * - Soft deletes
 * - Scopes
 * - Custom methods
 */
component extends="Model" {
    
    function config() {
        // Table configuration
        table("@TABLE_NAME@");
        
        // Property definitions
@PROPERTY_DEFINITIONS@
        
        // Audit fields
        property(name="createdBy", type="string", defaultValue="");
        property(name="updatedBy", type="string", defaultValue="");
        property(name="deletedBy", type="string", defaultValue="");
        
        // Timestamps
        timestamps();
        
        // Soft deletes
        softDeletes();
        
        // Validations
@VALIDATIONS@
        
        // Custom validations
        validate("validateCustomRules");
        
        // Associations
@ASSOCIATIONS@
        
        // Callbacks
        beforeValidation("sanitizeData");
        beforeCreate("setDefaults,setCreatedBy");
        beforeUpdate("setUpdatedBy");
        beforeDelete("setSoftDeleteAudit");
        afterFind("decorateRecord");
    }
    
    /**
     * Custom validation rules
     */
    private function validateCustomRules() {
        // Add your custom validation logic here
    }
    
    /**
     * Sanitize data before validation
     */
    private function sanitizeData() {
        var properties = getProperties();
        for (var prop in properties) {
            if (structKeyExists(this, prop.name) && isSimpleValue(this[prop.name])) {
                if (prop.type == "string") {
                    this[prop.name] = trim(this[prop.name]);
                }
            }
        }
    }
    
    /**
     * Set default values
     */
    private function setDefaults() {
        // Set any default values here
    }
    
    /**
     * Set created by user
     */
    private function setCreatedBy() {
        if (hasUserContext()) {
            this.createdBy = getUserId();
            this.updatedBy = getUserId();
        }
    }
    
    /**
     * Set updated by user
     */
    private function setUpdatedBy() {
        if (hasUserContext()) {
            this.updatedBy = getUserId();
        }
    }
    
    /**
     * Set soft delete audit info
     */
    private function setSoftDeleteAudit() {
        if (hasUserContext()) {
            this.deletedBy = getUserId();
        }
    }
    
    /**
     * Decorate record after finding
     */
    private function decorateRecord() {
        // Add computed properties or format data here
    }
    
    /**
     * Check if user context exists
     */
    private function hasUserContext() {
        return structKeyExists(session, "userId") && len(session.userId);
    }
    
    /**
     * Get current user ID
     */
    private function getUserId() {
        return session.userId ?: "system";
    }
    
    /**
     * Check if record can be edited by user
     */
    public function canBeEditedBy(required string userId) {
        // Add your authorization logic here
        return true;
    }
    
    /**
     * Check if record can be deleted by user
     */
    public function canBeDeletedBy(required string userId) {
        // Add your authorization logic here
        return true;
    }
    
    // ========================================
    // Scopes
    // ========================================
    
    /**
     * Scope: Active records (not deleted)
     */
    public function scopeActive(query) {
        return arguments.query.where("deletedAt IS NULL");
    }
    
    /**
     * Scope: Deleted records only
     */
    public function scopeDeleted(query) {
        return arguments.query.where("deletedAt IS NOT NULL");
    }
    
    /**
     * Scope: Recently created
     */
    public function scopeRecent(query, numeric days = 7) {
        var cutoffDate = dateAdd("d", -arguments.days, now());
        return arguments.query.where("createdAt >= ?", [cutoffDate]);
    }
    
    /**
     * Scope: Created by user
     */
    public function scopeCreatedBy(query, required string userId) {
        return arguments.query.where("createdBy = ?", [arguments.userId]);
    }
    
    // ========================================
    // Business Logic Methods
    // ========================================
    
    /**
     * Get display name for the record
     */
    public function getDisplayName() {
        // Override this method to provide a meaningful display name
        if (structKeyExists(this, "name")) {
            return this.name;
        } else if (structKeyExists(this, "title")) {
            return this.title;
        } else {
            return "@MODEL_NAME@ ##" & this.id;
        }
    }
    
    /**
     * Convert to string representation
     */
    public function toString() {
        return getDisplayName();
    }
}
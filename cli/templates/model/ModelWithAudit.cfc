/**
 * @MODEL_NAME@ Model with Audit Trail
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
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
        
        // Timestamps (includes createdAt and updatedAt)
        timestamps();
        
        // Soft deletes
        softDeletes();
        property(name="deletedBy", type="string", defaultValue="");
        
        // Validations
@VALIDATIONS@
        
        // Associations
@ASSOCIATIONS@
        
        // Callbacks for audit trail
        beforeCreate("setCreatedBy");
        beforeUpdate("setUpdatedBy");
        beforeDelete("setSoftDeleteAudit");
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
}
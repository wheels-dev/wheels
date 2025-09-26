component extends="Model" {
    
    function config() {
        // Table configuration
        // table("${tableName}");
        // primaryKey("${primaryKeyColumn}");

        // Property configuration
        // property(name="${propertyName}", sql=false); // Calculated property
        // property(name="${dateProperty}", dataType="datetime");
        
        // Associations
        // hasMany("${hasManySample}");
        // belongsTo("${belongsToSample}");
        // hasOne("${hasOneSample}");

        // Validations
        // validatesPresenceOf("${requiredFields}");
        // validatesUniquenessOf("${uniqueFields}");
        // validatesLengthOf(property="${lengthField}", minimum=${minLength}, maximum=${maxLength});
        // validatesFormatOf(property="${emailField}", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");

        // Callbacks
        // beforeSave("${beforeSaveMethod}");
        // afterCreate("${afterCreateMethod}");
        // afterUpdate("${afterUpdateMethod}");
    }
    
    // Callback methods
    private function setDefaults() {
        if (!len(this.slug)) {
            this.slug = createSlug(this.title);
        }
    }

    // Custom finder methods
    function findActive() {
        return findAll(where="active = 1");
    }

    function findByName(required string name) {
        return findOne(where="name = '#arguments.name#'");
    }

    function isActive() {
        return this.active == true;
    }

    // Validation methods
    // private function ${beforeSaveMethod}() {
        // Custom validation or data transformation
        // Example: Hash password before saving
        // if (len(trim(this.password))) {
        //     this.password = hash(this.password, "SHA-256");
        // }
    // }

    // Callback methods
    // private function ${afterCreateMethod}() {
        // Actions to perform after creating a new record
        // Example: Send welcome email
        // sendEmail(template="welcome", to=this.email);
    // }

    // private function ${afterUpdateMethod}() {
        // Actions to perform after updating a record
        // Example: Clear cache
        // cacheDelete("${modelNameLower}-" & this.id);
    // }
}
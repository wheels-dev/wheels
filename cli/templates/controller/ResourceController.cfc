/**
 * @CONTROLLER_NAME@ Resource Controller
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 * 
 * RESTful controller with standard CRUD actions
 */
component extends="Controller" {
    
    function config() {
        // Filters
        // filters(through="authenticate");
        
        // Verification
        verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
        
        // Response formats
        provides("html,json");
    }
    
    /**
     * GET /@PLURAL_LOWER_NAME@
     * Display a list of @PLURAL_LOWER_NAME@
     */
    function index() {
        @PLURAL_LOWER_NAME@ = model("@MODEL_NAME@").findAll(
            order="createdAt DESC",
            page=params.page ?: 1,
            perPage=25
        );
        
        renderWith(@PLURAL_LOWER_NAME@);
    }
    
    /**
     * GET /@PLURAL_LOWER_NAME@/:key
     * Display a single @SINGULAR_LOWER_NAME@
     */
    function show() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            objectNotFound();
        }
        
        renderWith(@SINGULAR_LOWER_NAME@);
    }
    
    /**
     * GET /@PLURAL_LOWER_NAME@/new
     * Display form for creating new @SINGULAR_LOWER_NAME@
     */
    function new() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").new();
        renderView();
    }
    
    /**
     * POST /@PLURAL_LOWER_NAME@
     * Create a new @SINGULAR_LOWER_NAME@
     */
    function create() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").new(params.@SINGULAR_LOWER_NAME@);
        
        if (@SINGULAR_LOWER_NAME@.save()) {
            flashInsert(success="@MODEL_NAME@ created successfully!");
            
            if (isAjax() || isJson()) {
                renderWith(@SINGULAR_LOWER_NAME@);
            } else {
                redirectTo(route="@SINGULAR_LOWER_NAME@", key=@SINGULAR_LOWER_NAME@.key());
            }
        } else {
            flashInsert(error="There was a problem creating the @SINGULAR_LOWER_NAME@.");
            
            if (isAjax() || isJson()) {
                renderWith(@SINGULAR_LOWER_NAME@.allErrors());
            } else {
                renderView(action="new");
            }
        }
    }
    
    /**
     * GET /@PLURAL_LOWER_NAME@/:key/edit
     * Display form for editing @SINGULAR_LOWER_NAME@
     */
    function edit() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            objectNotFound();
        }
        
        renderView();
    }
    
    /**
     * PUT/PATCH /@PLURAL_LOWER_NAME@/:key
     * Update existing @SINGULAR_LOWER_NAME@
     */
    function update() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            objectNotFound();
        }
        
        if (@SINGULAR_LOWER_NAME@.update(params.@SINGULAR_LOWER_NAME@)) {
            flashInsert(success="@MODEL_NAME@ updated successfully!");
            
            if (isAjax() || isJson()) {
                renderWith(@SINGULAR_LOWER_NAME@);
            } else {
                redirectTo(route="@SINGULAR_LOWER_NAME@", key=@SINGULAR_LOWER_NAME@.key());
            }
        } else {
            flashInsert(error="There was a problem updating the @SINGULAR_LOWER_NAME@.");
            
            if (isAjax() || isJson()) {
                renderWith(@SINGULAR_LOWER_NAME@.allErrors());
            } else {
                renderView(action="edit");
            }
        }
    }
    
    /**
     * DELETE /@PLURAL_LOWER_NAME@/:key
     * Delete @SINGULAR_LOWER_NAME@
     */
    function delete() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            objectNotFound();
        }
        
        if (@SINGULAR_LOWER_NAME@.delete()) {
            flashInsert(success="@MODEL_NAME@ deleted successfully!");
            
            if (isAjax() || isJson()) {
                renderWith({success=true, message="@MODEL_NAME@ deleted successfully!"});
            } else {
                redirectTo(route="@PLURAL_LOWER_NAME@");
            }
        } else {
            flashInsert(error="There was a problem deleting the @SINGULAR_LOWER_NAME@.");
            
            if (isAjax() || isJson()) {
                renderWith({success=false, errors=@SINGULAR_LOWER_NAME@.allErrors()});
            } else {
                redirectTo(route="@PLURAL_LOWER_NAME@");
            }
        }
    }
    
    /**
     * Handle object not found
     */
    private function objectNotFound() {
        if (isAjax() || isJson()) {
            renderWith({error="@MODEL_NAME@ not found"}, status=404);
        } else {
            renderView(template="/404");
        }
    }
    
    /**
     * Check if request wants JSON response
     */
    private function isJson() {
        return params.format == "json" || findNoCase("application/json", request.headers["Accept"] ?: "");
    }
}
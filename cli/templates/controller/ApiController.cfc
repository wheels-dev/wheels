/**
 * @CONTROLLER_NAME@ API Controller
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 * 
 * RESTful API controller for @MODEL_NAME@
 */
component extends="Controller" {
    
    function config() {
        // API configuration
        provides("json,xml");
        
        // Disable view rendering for all actions
        usesLayout(false);
        
        // Authentication
        // filters(through="authenticateAPI");
        
        // Rate limiting
        // filters(through="rateLimit");
        
        // CORS headers
        // filters(through="setCORSHeaders");
        
        // Verification
        verifies(except="index,create", params="key", paramsTypes="integer", handler="notFound");
    }
    
    /**
     * GET /api/@PLURAL_LOWER_NAME@
     * List all @PLURAL_LOWER_NAME@
     */
    function index() {
        // Parse query parameters
        param name="params.page" default="1" type="numeric";
        param name="params.perPage" default="25" type="numeric";
        param name="params.sort" default="createdAt DESC";
        param name="params.include" default="";
        
        // Build query
        var query = model("@MODEL_NAME@").findAll(
            page = params.page,
            perPage = params.perPage,
            order = params.sort,
            returnAs = "objects"
        );
        
        // Build response
        var response = {
            data = [],
            meta = {
                page = params.page,
                perPage = params.perPage,
                total = query.recordCount,
                totalPages = ceiling(query.recordCount / params.perPage)
            }
        };
        
        // Transform data
        for (var item in query) {
            arrayAppend(response.data, serializeModel(item));
        }
        
        renderJSON(response);
    }
    
    /**
     * GET /api/@PLURAL_LOWER_NAME@/:key
     * Get a single @SINGULAR_LOWER_NAME@
     */
    function show() {
        var @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            return notFound();
        }
        
        renderJSON({
            data = serializeModel(@SINGULAR_LOWER_NAME@)
        });
    }
    
    /**
     * POST /api/@PLURAL_LOWER_NAME@
     * Create a new @SINGULAR_LOWER_NAME@
     */
    function create() {
        // Parse JSON body
        var data = deserializeJSON(getHTTPRequestData().content);
        
        // Create model instance
        var @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").new(data);
        
        if (@SINGULAR_LOWER_NAME@.save()) {
            renderJSON(
                data = {
                    data = serializeModel(@SINGULAR_LOWER_NAME@)
                },
                status = 201
            );
        } else {
            renderJSON(
                data = {
                    errors = @SINGULAR_LOWER_NAME@.allErrors()
                },
                status = 422
            );
        }
    }
    
    /**
     * PUT/PATCH /api/@PLURAL_LOWER_NAME@/:key
     * Update an existing @SINGULAR_LOWER_NAME@
     */
    function update() {
        var @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            return notFound();
        }
        
        // Parse JSON body
        var data = deserializeJSON(getHTTPRequestData().content);
        
        if (@SINGULAR_LOWER_NAME@.update(data)) {
            renderJSON({
                data = serializeModel(@SINGULAR_LOWER_NAME@)
            });
        } else {
            renderJSON(
                data = {
                    errors = @SINGULAR_LOWER_NAME@.allErrors()
                },
                status = 422
            );
        }
    }
    
    /**
     * DELETE /api/@PLURAL_LOWER_NAME@/:key
     * Delete a @SINGULAR_LOWER_NAME@
     */
    function delete() {
        var @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            return notFound();
        }
        
        if (@SINGULAR_LOWER_NAME@.delete()) {
            renderJSON(
                data = {
                    message = "@MODEL_NAME@ deleted successfully"
                },
                status = 204
            );
        } else {
            renderJSON(
                data = {
                    errors = ["Unable to delete @SINGULAR_LOWER_NAME@"]
                },
                status = 422
            );
        }
    }
    
    // ========================================
    // Private Methods
    // ========================================
    
    /**
     * Serialize model for API response
     */
    private function serializeModel(required any model) {
        var data = {
            id = arguments.model.key(),
            type = "@PLURAL_LOWER_NAME@"
        };
        
        // Add model properties
        var properties = arguments.model.properties();
        for (var prop in properties) {
            // Skip internal properties
            if (!listFindNoCase("id,createdAt,updatedAt,deletedAt", prop.name)) {
                data[prop.name] = arguments.model[prop.name];
            }
        }
        
        // Add timestamps
        data.createdAt = arguments.model.createdAt;
        data.updatedAt = arguments.model.updatedAt;
        
        return data;
    }
    
    /**
     * Handle not found errors
     */
    private function notFound() {
        renderJSON(
            data = {
                error = "Resource not found"
            },
            status = 404
        );
    }
    
    /**
     * Render JSON response
     */
    private function renderJSON(required any data, numeric status = 200) {
        // Set response headers
        header(statusCode = arguments.status);
        header(name = "Content-Type", value = "application/json");
        
        // Allow CORS if configured
        // header(name = "Access-Control-Allow-Origin", value = "*");
        
        renderText(serializeJSON(arguments.data));
    }
    
    /**
     * API Authentication filter
     */
    private function authenticateAPI() {
        // Check for API token in header
        var authHeader = getHTTPRequestData().headers["Authorization"] ?: "";
        
        if (!len(authHeader) || !findNoCase("Bearer ", authHeader)) {
            renderJSON(
                data = {error = "Unauthorized"},
                status = 401
            );
            return false;
        }
        
        // Validate token
        var token = replaceNoCase(authHeader, "Bearer ", "");
        // Add your token validation logic here
        
        return true;
    }
    
    /**
     * Set CORS headers
     */
    private function setCORSHeaders() {
        header(name = "Access-Control-Allow-Origin", value = "*");
        header(name = "Access-Control-Allow-Methods", value = "GET, POST, PUT, PATCH, DELETE, OPTIONS");
        header(name = "Access-Control-Allow-Headers", value = "Content-Type, Authorization");
        
        // Handle preflight requests
        if (getHTTPRequestData().method == "OPTIONS") {
            renderText("");
            return false;
        }
        
        return true;
    }
}
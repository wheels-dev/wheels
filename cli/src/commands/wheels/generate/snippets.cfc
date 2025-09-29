/**
 * Generate code snippets for common patterns
 *
 * Examples:
 * wheels g snippets auth-filter
 * wheels g snippets --list
 * wheels g snippets --category=model
 */
component aliases="wheels g snippets" extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @pattern.hint Snippet pattern name
     * @list.hint Show all available snippets
     * @category.hint Filter by category (authentication, model, controller, view, database)
     * @output.hint Output format (console or file)
     * @path.hint Output path (required for file output)
     * @customize.hint Create custom snippet
     * @create.hint Create new snippet template
     * @force.hint Overwrite existing files
     */
    function run(
        string pattern = "",
        boolean list = false,
        string category = "",
        string output = "console",
        string path = "",
        boolean customize = false,
        boolean create = false,
        boolean force = false
    ) {
        // Reconstruct arguments for handling --prefixed options
        arguments = reconstructArgs(arguments);

        if (arguments.list) {
            return listSnippets(arguments.category);
        }

        if (arguments.create) {
            return createCustomSnippet(arguments.pattern);
        }

        if (arguments.customize) {
            return showCustomizationOptions();
        }

        if (!len(arguments.pattern)) {
            detailOutput.error("Pattern name is required");
            detailOutput.getPrint().line("Usage: wheels g snippets <pattern-name>");
            detailOutput.getPrint().line("Run 'wheels g snippets --list' to see available patterns");
            setExitCode(1);
            return;
        }

        var snippet = getSnippetByName(arguments.pattern);
        if (!structCount(snippet)) {
            detailOutput.error("Snippet '#arguments.pattern#' not found");
            detailOutput.getPrint().line("Run 'wheels g snippets --list' to see available patterns");
            setExitCode(1);
            return;
        }

        if (arguments.output == "file") {
            if (!len(arguments.path)) {
                detailOutput.error("--path is required when using --output=file");
                setExitCode(1);
                return;
            }
            writeSnippetToFile(snippet, arguments.path, arguments.force);
        } else {
            printSnippet(snippet);
        }
    }

    /**
     * List available snippets
     */
    private function listSnippets(string category = "") {
        var snippets = getAvailableSnippets();
        var categories = {};

        for (var snippet in snippets) {
            if (len(arguments.category) && snippet.category != arguments.category) {
                continue;
            }
            if (!structKeyExists(categories, snippet.category)) {
                categories[snippet.category] = [];
            }
            arrayAppend(categories[snippet.category], snippet);
        }

        detailOutput.header("", "Available Snippets");

        var categoryOrder = ["Authentication", "Model", "Controller", "View", "Database"];
        for (var cat in categoryOrder) {
            var key = lCase(cat);
            if (structKeyExists(categories, key)) {
                detailOutput.getPrint().line("");
                detailOutput.getPrint().boldLine("#cat#:");
                for (var snippet in categories[key]) {
                    detailOutput.getPrint().line("  - #snippet.name# - #snippet.description#");
                }
            }
        }

        detailOutput.getPrint().line("");
        detailOutput.getPrint().line("");
        detailOutput.nextSteps([
            "Generate a snippet: wheels g snippets <pattern-name>"
        ]);
    }

    /**
     * Print snippet to console
     */
    private function printSnippet(required struct snippet) {
        detailOutput.header("", "Generating Snippet: #arguments.snippet.name#");
        detailOutput.getPrint().line("");

        var content = getSnippetContent(arguments.snippet);
        detailOutput.getPrint().line(content);
        detailOutput.getPrint().line("");

        detailOutput.success("Snippet '#arguments.snippet.name#' generated successfully!");
    }

    /**
     * Write snippet to file
     */
    private function writeSnippetToFile(required struct snippet, required string path, boolean force = false) {
        if (fileExists(arguments.path) && !arguments.force) {
            detailOutput.error("File already exists: #arguments.path#");
            detailOutput.getPrint().line("Use --force to overwrite");
            setExitCode(1);
            return;
        }

        var content = getSnippetContent(arguments.snippet);

        // Create directory if needed
        var dir = getDirectoryFromPath(arguments.path);
        if (!directoryExists(dir)) {
            directoryCreate(dir, true);
        }

        fileWrite(arguments.path, content);
        detailOutput.create("Created: #arguments.path#");
    }

    /**
     * Get available snippets
     */
    private function getAvailableSnippets() {
        return [
            {name: "login-form", category: "authentication", description: "Login form with remember me"},
            {name: "auth-filter", category: "authentication", description: "Authentication filter"},
            {name: "password-reset", category: "authentication", description: "Password reset flow"},
            {name: "user-registration", category: "authentication", description: "User registration with validation"},
            {name: "soft-delete", category: "model", description: "Soft delete implementation"},
            {name: "audit-trail", category: "model", description: "Audit trail with timestamps"},
            {name: "sluggable", category: "model", description: "URL-friendly slugs"},
            {name: "versionable", category: "model", description: "Version tracking"},
            {name: "searchable", category: "model", description: "Full-text search"},
            {name: "crud-actions", category: "controller", description: "Complete CRUD actions"},
            {name: "api-controller", category: "controller", description: "JSON API controller"},
            {name: "nested-resource", category: "controller", description: "Nested resource controller"},
            {name: "admin-controller", category: "controller", description: "Admin area controller"},
            {name: "form-with-errors", category: "view", description: "Form with error handling"},
            {name: "pagination-links", category: "view", description: "Pagination navigation"},
            {name: "search-form", category: "view", description: "Search form with filters"},
            {name: "ajax-form", category: "view", description: "AJAX form submission"},
            {name: "migration-indexes", category: "database", description: "Common index patterns"},
            {name: "seed-data", category: "database", description: "Database seeding"},
            {name: "constraints", category: "database", description: "Foreign key constraints"}
        ];
    }

    /**
     * Get snippet by name
     */
    private function getSnippetByName(required string name) {
        var snippets = getAvailableSnippets();
        for (var snippet in snippets) {
            if (snippet.name == arguments.name) {
                return snippet;
            }
        }
        return {};
    }

    /**
     * Get snippet content
     */
    private function getSnippetContent(required struct snippet) {
        switch (arguments.snippet.name) {
            case "login-form":
                return '##startFormTag(action="create")##' & chr(10) &
                       '  ##textField(objectName="user", property="email", label="Email")##' & chr(10) &
                       '  ##passwordField(objectName="user", property="password", label="Password")##' & chr(10) &
                       '  ##checkBox(objectName="user", property="rememberMe", label="Remember me")##' & chr(10) &
                       '  ##submitTag(value="Login")##' & chr(10) &
                       '##endFormTag()##';

            case "auth-filter":
                return 'function init() {' & chr(10) &
                       '  filters(through="authenticate", except="new,create");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'private function authenticate() {' & chr(10) &
                       '  if (!StructKeyExists(session, "userId")) {' & chr(10) &
                       '    redirectTo(route="login");' & chr(10) &
                       '  }' & chr(10) &
                       '}';

            case "password-reset":
                return 'function requestReset() {' & chr(10) &
                       '  user = model("User").findOne(where="email=''##params.email##''");' & chr(10) &
                       '  if (IsObject(user)) {' & chr(10) &
                       '    token = Hash(CreateUUID());' & chr(10) &
                       '    user.update(resetToken=token, resetExpiresAt=DateAdd("h", 1, Now()));' & chr(10) &
                       '    // Send email with token' & chr(10) &
                       '  }' & chr(10) &
                       '}';

            case "user-registration":
                return '##startFormTag(action="create")##' & chr(10) &
                       '  ##textField(objectName="user", property="firstName", label="First Name")##' & chr(10) &
                       '  ##textField(objectName="user", property="email", label="Email")##' & chr(10) &
                       '  ##passwordField(objectName="user", property="password", label="Password")##' & chr(10) &
                       '  ##submitTag(value="Register")##' & chr(10) &
                       '##endFormTag()##';

            case "soft-delete":
                return 'function init() {' & chr(10) &
                       '  property(name="deletedAt", sql="deleted_at");' & chr(10) &
                       '  beforeDelete("softDelete");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'private function softDelete() {' & chr(10) &
                       '  this.deletedAt = Now();' & chr(10) &
                       '  this.save(validate=false, callbacks=false);' & chr(10) &
                       '  return false;' & chr(10) &
                       '}';

            case "audit-trail":
                return 'function init() {' & chr(10) &
                       '  property(name="createdBy", sql="created_by");' & chr(10) &
                       '  property(name="updatedBy", sql="updated_by");' & chr(10) &
                       '  beforeSave("setAuditFields");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'private function setAuditFields() {' & chr(10) &
                       '  if (StructKeyExists(session, "userId")) {' & chr(10) &
                       '    if (this.isNew()) this.createdBy = session.userId;' & chr(10) &
                       '    this.updatedBy = session.userId;' & chr(10) &
                       '  }' & chr(10) &
                       '}';

            case "sluggable":
                return 'function init() {' & chr(10) &
                       '  property(name="slug");' & chr(10) &
                       '  beforeSave("generateSlug");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'private function generateSlug() {' & chr(10) &
                       '  if (!len(this.slug) && len(this.title)) {' & chr(10) &
                       '    this.slug = lCase(reReplace(this.title, "[^a-zA-Z0-9]", "-", "all"));' & chr(10) &
                       '  }' & chr(10) &
                       '}';

            case "versionable":
                return 'function init() {' & chr(10) &
                       '  property(name="version", default=1);' & chr(10) &
                       '  beforeUpdate("incrementVersion");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'private function incrementVersion() {' & chr(10) &
                       '  this.version = this.version + 1;' & chr(10) &
                       '}';

            case "searchable":
                return 'function search(required string query) {' & chr(10) &
                       '  return findAll(where="title LIKE ''%##arguments.query##%'' OR content LIKE ''%##arguments.query##%''");' & chr(10) &
                       '}';

            case "crud-actions":
                return 'function index() {' & chr(10) &
                       '  users = model("User").findAll();' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'function show() {' & chr(10) &
                       '  user = model("User").findByKey(params.key);' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'function create() {' & chr(10) &
                       '  user = model("User").create(params.user);' & chr(10) &
                       '  if (user.valid()) {' & chr(10) &
                       '    redirectTo(route="user", key=user.id);' & chr(10) &
                       '  } else {' & chr(10) &
                       '    renderView(action="new");' & chr(10) &
                       '  }' & chr(10) &
                       '}';

            case "api-controller":
                return 'function init() {' & chr(10) &
                       '  provides("json");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'function index() {' & chr(10) &
                       '  users = model("User").findAll();' & chr(10) &
                       '  renderWith(data={users=users});' & chr(10) &
                       '}';

            case "nested-resource":
                return 'function init() {' & chr(10) &
                       '  filters(through="findParent");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'private function findParent() {' & chr(10) &
                       '  user = model("User").findByKey(params.userId);' & chr(10) &
                       '}';

            case "admin-controller":
                return 'function init() {' & chr(10) &
                       '  filters(through="requireAdmin");' & chr(10) &
                       '}' & chr(10) & chr(10) &
                       'private function requireAdmin() {' & chr(10) &
                       '  if (!currentUser().isAdmin()) {' & chr(10) &
                       '    redirectTo(route="home");' & chr(10) &
                       '  }' & chr(10) &
                       '}';

            case "form-with-errors":
                return '##errorMessagesFor("user")##' & chr(10) & chr(10) &
                       '##startFormTag(action="create")##' & chr(10) &
                       '  ##textField(objectName="user", property="firstName", label="First Name")##' & chr(10) &
                       '  <cfif user.errors("firstName").len()>' & chr(10) &
                       '    <span class="error">##user.errors("firstName").get()##</span>' & chr(10) &
                       '  </cfif>' & chr(10) &
                       '  ##submitTag(value="Submit")##' & chr(10) &
                       '##endFormTag()##';

            case "pagination-links":
                return '<cfif users.totalPages gt 1>' & chr(10) &
                       '  <nav>' & chr(10) &
                       '    <cfif users.currentPage gt 1>' & chr(10) &
                       '      ##linkTo(text="Previous", params={page: users.currentPage - 1})##' & chr(10) &
                       '    </cfif>' & chr(10) &
                       '    <cfloop from="1" to="####users.totalPages####" index="pageNum">' & chr(10) &
                       '      ##linkTo(text=pageNum, params={page: pageNum})##' & chr(10) &
                       '    </cfloop>' & chr(10) &
                       '    <cfif users.currentPage lt users.totalPages>' & chr(10) &
                       '      ##linkTo(text="Next", params={page: users.currentPage + 1})##' & chr(10) &
                       '    </cfif>' & chr(10) &
                       '  </nav>' & chr(10) &
                       '</cfif>';

            case "search-form":
                return '##startFormTag(method="get")##' & chr(10) &
                       '  ##textField(name="q", value=params.q, placeholder="Search...")##' & chr(10) &
                       '  ##submitTag(value="Search")##' & chr(10) &
                       '##endFormTag()##';

            case "ajax-form":
                return '##startFormTag(action="create", id="userForm")##' & chr(10) &
                       '  ##textField(objectName="user", property="name")##' & chr(10) &
                       '  ##submitTag(value="Submit")##' & chr(10) &
                       '##endFormTag()##' & chr(10) & chr(10) &
                       '<script>' & chr(10) &
                       '$("##userForm").submit(function(e) {' & chr(10) &
                       '  e.preventDefault();' & chr(10) &
                       '  $.post($(this).attr("action"), $(this).serialize());' & chr(10) &
                       '});' & chr(10) &
                       '</script>';

            case "migration-indexes":
                return 't.index("email");' & chr(10) &
                       't.index(["last_name", "first_name"]);' & chr(10) &
                       't.index("email", unique=true);' & chr(10) &
                       't.index("user_id");';

            case "seed-data":
                return 'execute("INSERT INTO users (name, email) VALUES (''Admin'', ''admin@example.com'')");"';

            case "constraints":
                return 't.references("user_id", "users");' & chr(10) &
                       't.references("category_id", "categories");';

            default:
                return "Snippet not found";
        }
    }

    /**
     * Create custom snippet
     */
    private function createCustomSnippet(required string name) {
        detailOutput.header("", "Creating Custom Snippet");

        var snippetDir = getCWD() & "/app/snippets/" & arguments.name;

        if (directoryExists(snippetDir)) {
            detailOutput.error("Snippet '#arguments.name#' already exists");
            setExitCode(1);
            return;
        }

        // Create directory
        directoryCreate(snippetDir, true);

        // Create basic template file
        var templateContent = '// Custom snippet: #arguments.name#' & chr(10) &
                             '// Add your code here';

        fileWrite(snippetDir & "/template.txt", templateContent);

        detailOutput.create("Created: #snippetDir#");
        detailOutput.success("Custom snippet '#arguments.name#' created successfully!");

        detailOutput.nextSteps([
            "Edit: #snippetDir#/template.txt",
            "Use: wheels g snippets #arguments.name#"
        ]);
    }

    /**
     * Show customization options
     */
    private function showCustomizationOptions() {
        detailOutput.header("", "Customization Options");
        detailOutput.getPrint().line("You can customize snippets by:");
        detailOutput.getPrint().line("  1. Creating custom snippets with --create");
        detailOutput.getPrint().line("  2. Saving snippets to files with --output=file");
        detailOutput.getPrint().line("  3. Filtering by category with --category");
    }
}
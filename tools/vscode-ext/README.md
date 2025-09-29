# Wheels VS Code Extension

The ultimate VS Code extension for Wheels framework development! Boost productivity and makes development easier and faster. Get helpful code completion, file scaffolding, parameter hints, smart navigation, file templates, and real-time validation - all designed for specifically for Wheels developers.

## Features

### File Templates & Scaffolding

Quickly generate controllers, models, and views with ready-made templates that include common code patterns, validations, and best practices.

**How to use it:**
- **Right-click method:** Right-click any folder → "New Wheels Component" → Choose Controller/Model/View → Enter name
    ![Wheels File Scaffolding Demo 1](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/scaffolding-demo-1.gif)
- **Command palette:** Ctrl+Shift+P → "Wheels: Create Controller" → Enter target path → Enter name
    ![Wheels File Scaffolding Demo 2](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/scaffolding-demo-2.gif)
    ![Wheels File Scaffolding Demo 3](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/scaffolding-demo-3.gif)

**Examples:**

**Creating a Users Controller:**
- Right-click `app/controllers/` folder → "New Wheels Component" → "Controller (CRUD Actions)" → Type "Users"
- Generates `Users.cfc` with complete CRUD actions: index(), show(), new(), create(), edit(), update(), delete()
- Same goes for `models` and `views`

**Creating a Product Model:**
- Command Palette → "Wheels: Create Model" → Path: `app/models` → Name: "Product"
- Generates `Product.cfc` with associations, validations, callbacks, and custom finder methods
- Also, you can create `controller` and `view` from this way

**Features:**
- Files use the name you type
- Creates missing directories automatically
- Complete CRUD controllers with error handling
- Models with validations, associations, and custom methods
- Views with proper CFML template structure

---

### Quick Code Templates

#### Component Templates

Create complete component structures instantly with professional templates that include best practices and common patterns.

**How to use it:**
- In any CFML file, type the template keyword (`wcontroller` or `wmodel`)
- Press Tab/Enter to import complete structure
- Language automatically sets to CFML

**Examples:**

**Controller Template:**
```cfml
// Type "wcontroller" + Tab to get:
component extends="Controller" {
    function config() {
        // Filters, verification, formats
        // filters(through="authenticate", except="index");
        // verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");
        // provides("html,json");
    }

    function index() {
        items = model("Item").findAll(order="name ASC");
        // renderWith(items);
    }

    function show() {
        // item is set by findRecord() filter or:
        // item = model("Item").findByKey(params.key);
    }

    // Complete CRUD actions: new, create, edit, update, delete
}
```

![Wheels Quick Code Demo 1](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/quick-code-demo-1.gif)

**Model Template:**
```cfml
// Type "wmodel" + Tab to get:
component extends="Model" {
    function config() {
        // Associations
        hasMany("orders");
        belongsTo("category");

        // Validations
        validatesPresenceOf("name,email");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");

        // Callbacks
        beforeSave("hashPassword");
        afterCreate("sendWelcomeEmail");
    }

    function findByEmail(required string email) {
        return findOne(where="email = '#arguments.email#'");
    }

    function fullName() {
        return trim("#firstname# #lastname#");
    }
}
```

![Wheels Quick Code Demo 2](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/quick-code-demo-2.gif)

---

#### Function Snippets

Get intelligent code completion for Wheels functions with multiple parameter options - choose between basic **required parameters** or **full parameter** sets.

**How to use it:**
- Type any Wheels function name (e.g., `findAll`, `mimeTypes`)
- Choose from dropdown options:
  - **Basic version** - Only required parameters
  - **Full version** - All available parameters
- Tab through parameters to fill in values

**Examples:**

**Model Functions:**
```cfml
// Type "findAll" and choose from dropdown:
// Option 1: findAll (basic - required params only)
users = findAll()

// Option 2: findAll(allParams) (full version with all parameters)
users = findAll(where = "", order = "", group = "", select = "", distinct = "false", include = "")

// After selecting either option, customize as needed:
users = findAll(where = "active = 1", order = "name ASC")
```

**Utility Functions:**
```cfml
// Type "mimeTypes" and choose from dropdown:
// Option 1: mimeTypes (basic - required params only)
type = mimeTypes(extension = "")

// Option 2: mimeTypes(allParams) (with optional fallback)
type = mimeTypes(extension = "", fallback = "")

// Practical usage:
type = mimeTypes(extension = "pdf", fallback = "application/pdf")
```

**Features:**
- 300+ Wheels framework functions included
- Dual options: basic (required) vs. full (all parameters)
- Smart parameter completion with Tab navigation
- Context-aware suggestions based on function type

---

### Go to Definition (F12)

Click on Wheels components references to instantly jump to the corresponding file/component. Works with models, controllers, routes, and views.

**How to use it:**
- Ctrl+Click (or Cmd+Click on Mac) on any Wheels component reference
- Or press F12 while cursor is on the component name
- Or right-click → "Go to Definition"

**Examples:**
```cfml
// Ctrl+Click on "User" to jump to `User.cfc` model
user = model("User").findAll();

// Ctrl+Click on "users" to jump to `Users.cfc` controller
redirectTo(controller="users", action="show");

// Ctrl+Click on "editUser" to jump to Users.cfc edit() action
linkTo(route="editUser", key=user.id);

// Ctrl+Click on "users/show" to jump to users/show.cfm
renderView("users/show");
```

**Supported patterns:**
- `model("ModelName")` → jumps to `ModelName.cfc`
- `controller="name"` → jumps to `Name.cfc`
- `route="routeName"` → jumps to controller action
- `renderView("path")` → jumps to view file

![Wheels Go To Definition Demo](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/go-to-definition-demo.gif)

---

### Smart Parameter System

Intelligent parameter assistance for Wheels functions with real-time hints, auto-completion, and validation.

---

#### Parameter Highlighting (Ctrl+Shift+Space)

Show function parameters on the fly with smart highlighting that appears when you start typing parameter names.

**How to use it:**
- Type opening parenthesis `(` after any Wheels function call
- Or press Ctrl+Shift+Space to manually trigger
- Start typing parameter names to see intelligent highlighting

**Examples:**
```cfml
// Type opening parenthesis to see all parameters
findAll(     // Shows: where?, order?, group?, select?, include?, cache?, reload?
             // Parameter types: where: string, order: string, group: string, etc.

// Smart highlighting as you type
findAll(w    // Highlights "where" parameter in suggestion list
findAll(wh   // Further narrows to "where"
findAll(where="active = 1", o    // Now highlights "order" parameter
```

[Demo will be added here]

---

#### Parameter Auto-completion

Type partial parameter names and it will automatically display for quick snippets, press Tab/Enter to auto-complete with parameters.

**How to use it:**
- Type partial parameter name inside function parentheses
- Press Tab/Enter to auto-complete to full `parameterName = ""` format

**Examples:**
```cfml
// Type partial parameter name and press Tab to auto-complete with snippet
findAll(o    // Type "o" + Tab → becomes "order = """
findAll(wh   // Type "wh" + Tab → becomes "where = """
linkTo(rou   // Type "rou" + Tab → becomes "route = """
validatesPresenceOf("name", mes  // Type "mes" + Tab → becomes "message = """

// Works inside function calls with existing parameters
findAll(where="active = 1", o  // Type "o" + Tab → becomes "order = """

// Result after Tab completion:
findAll(where="active = 1", order = "")  // Cursor positioned inside quotes
```

[Demo will be added here]

---

#### Parameter Validation

Real-time validation that detects incorrect parameter names in Wheels functions when using named parameter syntax.

**How it works:**
- Only validates when using named parameter syntax with `=` (parameterName="value")
- Yellow underlines show invalid parameter names
- No validation for positional parameters (function("value1", "value2"))
- Works with 300+ Wheels framework functions

**Examples:**

**Invalid Parameter Names (Yellow Underlines):**
```cfml
// findAll with incorrect parameter names
model("User").findAll(ordr="name ASC")        // "ordr" should be "order"
model("User").findAll(useIndex=false)         // "useIndex" should be "reload"
model("User").findAll(wher="active = 1")      // "wher" should be "where"

// linkTo with incorrect parameter names
linkTo(rout="users")                          // "rout" should be "route"
linkTo(route="users", txt="All Users")        // "txt" should be "text"
linkTo(route="users", metod="post")           // "metod" should be "method"

// Model validation with incorrect parameter names
validatesPresenceOf("name", mesage="Required") // "mesage" should be "message"
validatesLengthOf("email", minimun=5)         // "minimun" should be "minimum"

// Form helpers with incorrect parameter names
textField(objectNam="user", property="name")  // "objectNam" should be "objectName"
startFormTag(rout="users", method="post")     // "rout" should be "route"
```

**Correct Usage (No Warnings):**
```cfml
// Correct named parameters - no underlines
model("User").findAll(order="name ASC", where="active = 1")
linkTo(route="users", text="All Users", method="get")
validatesPresenceOf("name", message="Name is required")
textField(objectName="user", property="name", label="Full Name")

// Positional parameters - no validation (already working)
model("User").findAll("active = 1", "name ASC")  // No warnings shown
linkTo("users", "All Users")                      // No warnings shown
textField("user", "name")                         // No warnings shown
```

**Parameter Suggestions:**
When invalid parameters are detected, the extension suggests the correct parameter name:
- `ordr` → suggests `order`
- `wher` → suggests `where`
- `grp` → suggests `group`
- `txt` → suggests `text`
- `mesage` → suggests `message`

**Features:**
- Only validates named parameter syntax (param="value")
- Ignores positional parameters (no interference with existing code)
- Context-aware suggestions based on function name
- Works with all Wheels API functions
- Real-time validation as you type

[Demo will be added here]

---

### Hover Documentation

Hover over Wheels function names to see clean, professional documentation with parameter details and examples.

**How to use it:**
- Simply hover your mouse over any Wheels function name
- Documentation appears automatically
- Works across multiple lines

**Examples:**
```cfml
// Hover over "findAll" shows:
// Parameters: where?, order?, group?, select?, include?, cache?, reload?, etc.
// Returns: Query object or array of model instances
// Example: findAll(where="active = 1", order="name ASC")
users = model("User").findAll();

// Hover over "linkTo" shows complete parameter reference:
// route, controller, action, key, params, anchor, text, confirm, method, etc.
// Shows parameter types and default values
linkTo(route="editUser", key=user.id, text="Edit User");

// Hover over "hasMany" shows association options:
// name, class, foreignKey, dependent, include, order, conditions, etc.
hasMany(name="orders", dependent="delete");
```

**Features:**
- Context-aware (shows for function calls, not variables or strings)
- Multi-line function support
- Parameter tables with types, defaults, and descriptions
- Professional VS Code-style formatting
- Fast performance with intelligent caching

[Demo will be added here]

---

## Installation & Setup

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search "Wheels"
4. Install and reload VS Code

**No configuration needed** - works immediately with any CFML file.

## Troubleshooting

### Extension Not Working?
- Check file language is set to "CFML" (bottom-right corner of VS Code)
- Reload window: Ctrl+Shift+P → "Developer: Reload Window"

### Go to Definition Not Working?
- Ensure your Wheels project is opened as a workspace folder
- Check file structure follows standard Wheels layout
- Use correct syntax: `model("User")` not `model('User')`

### Parameter Hints Not Showing?
- Use Ctrl+Shift+Space to manually trigger
- Ensure you're in a function call context
- Check file language is set to CFML

### Files Created in Wrong Location?
- Extension creates files where you right-click or specify
- For Command Palette, double-check the target path you entered

## Resources

- [Wheels Documentation](https://wheels.dev/docs)
- [Community Discussions](https://github.com/wheels-dev/wheels/discussions)
- [Report Issues](https://github.com/wheels-dev/wheels/issues)
- [Extension Source Code](https://github.com/wheels-dev/wheels/tree/main/tools/vscode-ext)

---

**Build faster, code smarter — with Wheels!**
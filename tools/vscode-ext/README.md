# Wheels VS Code Extension

The ultimate VS Code extension for Wheels framework development! Boost your productivity and makes development easier and faster. Get helpful code completion, smart navigation, file templates, and real-time assistance as you write your CFML code.

## Features

### File Templates & Scaffolding

Create complete Wheels controllers, models, and views templates instantly with ready-made templates that include common code patterns, validations, and best practices.

**How to use it:**
- **Right-click method:** Right-click any folder → "New Wheels Component" → Choose Controller/Model/View → Enter name
    ![Wheels File Scaffolding Demo 1](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/scaffolding-demo-1.gif)
- **Command palette:** Ctrl+Shift+P → "Wheels: Create Controller" → Enter target path → Enter name
    ![Wheels File Scaffolding Demo 2](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/scaffolding-demo-2.gif)
    ![Wheels File Scaffolding Demo 3](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/scaffolding-demo-3.gif)

**Examples:**
- Right-click `templates` folder → Create Controller → Type "Users" → Creates `Users.cfc` in `templates` folder
- Command Palette → "Wheels: Create Model" → Path: `app/models/admin` → Name: "User" → Creates `User.cfc` in that location

**Features:**
- Files use the name you type
- Creates missing directories automatically
- Complete CRUD controllers with error handling
- Models with validations, associations, and custom methods
- Views with proper CFML template structure

---

### Quick Code Templates

Type short keywords and press Tab to expand into complete code templates with proper structure and best practices.

**How to use it:**
- In any CFML file, type the snippet keyword
- Press Tab to expand
- Language is automatically set to CFML

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

**Available snippets:**
- `wcontroller` → Complete CRUD controller with all actions and error handling
- `wmodel` → Model with validations, associations, callbacks, custom methods

[Demo will be added here]

---

### Go to Definition (F12)

Click on Wheels components references to instantly jump to the corresponding files. Works with models, controllers, routes, and views.

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

![Wheels Go To Definition Demo](https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/vscode-ext/assets/go-to-definition.gif)

**Supported patterns:**
- `model("ModelName")` → jumps to `ModelName.cfc`
- `controller="name"` → jumps to `Name.cfc`
- `route="routeName"` → jumps to controller action
- `renderView("path")` → jumps to view file

[Demo will be added here]

---

### Smart Parameter Help (Ctrl+Shift+Space)

Shows function parameters as you type with intelligent highlighting that only appears when you start typing parameter names.

**How to use it:**
- Type opening parenthesis `(` after any Wheels function
- Or press Ctrl+Shift+Space to manually trigger
- Navigate between parameters with Tab
- Start typing parameter names to see intelligent highlighting

**Examples:**
```cfml
// Type opening parenthesis to see all available parameters
findAll(     // Shows: where?, order?, group?, select?, include?, etc.

// Start typing to see intelligent highlighting
findAll(w    // Highlights "where" parameter
findAll(o    // Highlights "order" parameter

// Works with method chaining
model("User").findAll(     // Shows findAll parameters

// Multiple parameters with smart highlighting
findAll(where="active = 1", o    // Highlights "order" parameter next
```

**Features:**
- Works with 300+ Wheels framework functions
- Highlights when you start typing (not by default)
- Shows parameter types, defaults, and descriptions
- Supports complex method chaining
- Context-aware (for actual function calls)

[Demo will be added here]

---

### Route Validation

Real-time error detection that catches route typos, missing parameters, and suggests best practices as you type.

**How to use it:**
- Just type route code - validation happens automatically
- Red underlines show errors
- Yellow underlines show warnings
- Blue underlines show suggestions

**Examples:**
```cfml
// ERROR: Typo detection
linkTo(rout="users")              // "Did you mean 'route'?"
linkTo(root="home")               // "Did you mean 'route'?"

// WARNING: Missing parameters
linkTo(route="editUser")          // "Edit routes typically require a 'key' parameter"
linkTo(route="deleteUser")        // "Delete routes typically require a 'key' parameter"

// INFO: Best practices
linkTo(controller="users", action="index")  // "Consider using route parameter instead"

// WARNING: Suspicious routes
linkTo(route="a")                 // "Potentially invalid route: 'a' (too short)"
linkTo(route="USER LIST")         // "Route contains spaces"

// CORRECT: No warnings
linkTo(route="editUser", key=user.id)      // All good!
redirectTo(route="users")                   // Perfect!
```

**Validation types:**
- Typo detection (`rout=`, `root=` → suggests `route=`)
- Missing key parameters for edit/update/delete routes
- Suspicious route names (too short, all caps, spaces)
- Best practice suggestions

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
// Hover over "findAll" to see complete documentation
users = findAll()     // Shows: parameters, types, descriptions, examples

// Hover over "linkTo" for parameter reference
linkTo()              // Shows: complete parameter table with defaults

// Hover over "hasMany" for association help
hasMany()             // Shows: association options and usage patterns

// Context-aware - shows for function calls
findAll = "some string"  // No hover (correctly detected as variable)
"findAll is a function"  // No hover (correctly detected as string)
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

- [Wheels Framework Documentation](https://wheels.dev/docs)
- [Community Discussions](https://github.com/wheels-dev/wheels/discussions)
- [Report Issues](https://github.com/wheels-dev/wheels/issues)
- [Extension Source Code](https://github.com/wheels-dev/wheels/tree/main/tools/vscode-ext)

---

**Build faster, code smarter — with Wheels!**
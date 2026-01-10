# Controller Code Snippets

## Description
Common controller patterns and code snippets for Wheels applications.

## Basic Controller Structure
```cfm
component extends="Controller" {
    function config() {
        // Parameter verification
        verifies(params="key", paramsTypes="integer", only="show,edit,update,delete");

        // Filters
        filters(through="authenticate", except="index,show");
        filters(through="findResource", only="show,edit,update,delete");

        // Content types
        provides("html,json");
    }

    function index() {
        resources = model("Resource").findAll(order="createdAt DESC");
    }

    function show() {
        // resource set by findResource filter
    }

    private function authenticate() {
        if (!session.authenticated) {
            redirectTo(controller="sessions", action="new");
        }
    }

    private function findResource() {
        resource = model("Resource").findByKey(params.key);
        if (!IsObject(resource)) {
            flashInsert(error="Resource not found");
            redirectTo(action="index");
        }
    }
}
```

## CRUD Action Patterns
```cfm
// CREATE actions
function new() {
    user = model("User").new();
    roles = model("Role").findAll();
}

function create() {
    user = model("User").new(params.user);

    if (user.save()) {
        redirectTo(route="user", key=user.id, success="User created successfully!");
    } else {
        roles = model("Role").findAll();
        flashInsert(error="Please fix the errors below");
        renderView(action="new");
    }
}

// UPDATE actions
function edit() {
    user = model("User").findByKey(params.key);
    roles = model("Role").findAll();
}

function update() {
    user = model("User").findByKey(params.key);

    if (user.update(params.user)) {
        redirectTo(route="user", key=user.id, success="User updated successfully!");
    } else {
        roles = model("Role").findAll();
        renderView(action="edit");
    }
}

// DELETE action
function delete() {
    user = model("User").findByKey(params.key);

    if (user.delete()) {
        flashInsert(success="User deleted successfully");
    } else {
        flashInsert(error="Unable to delete user");
    }

    redirectTo(action="index");
}
```

## Authentication Patterns
```cfm
// Authentication filter
private function authenticate() {
    if (!isLoggedIn()) {
        flashInsert(error="Please login to continue");
        redirectTo(controller="sessions", action="new", returnUrl=cgi.request_url);
    }
}

// Authorization filter
private function requireOwnership() {
    resource = model("Resource").findByKey(params.key);
    if (!IsObject(resource) || resource.userId != session.userId) {
        flashInsert(error="Access denied");
        redirectTo(action="index");
    }
    variables.resource = resource;
}

// Helper methods
function currentUser() {
    if (!StructKeyExists(variables, "currentUser")) {
        variables.currentUser = model("User").findByKey(session.userId);
    }
    return variables.currentUser;
}

function isLoggedIn() {
    return StructKeyExists(session, "userId") && session.userId;
}
```

## API Controller Patterns
```cfm
component extends="Controller" {
    function config() {
        provides("json");
        filters(through="authenticateAPI");
    }

    function index() {
        users = model("User").findAll();
        renderWith(users);
    }

    function show() {
        user = model("User").findByKey(params.key);

        if (IsObject(user)) {
            renderWith(user);
        } else {
            renderWith(data={error: "User not found"}, status=404);
        }
    }

    function create() {
        user = model("User").new(params.user);

        if (user.save()) {
            renderWith(user, status=201);
        } else {
            renderWith(data={errors: user.allErrors()}, status=422);
        }
    }

    private function authenticateAPI() {
        if (!isValidAPIKey(params.apiKey)) {
            renderWith(data={error: "Invalid API key"}, status=401);
        }
    }
}
```

## Pagination Patterns
```cfm
function index() {
    // Basic pagination
    users = model("User").findAll(
        page=params.page ?: 1,
        perPage=25,
        order="lastName, firstName"
    );

    // With search
    whereClause = "";
    if (Len(params.search)) {
        whereClause = "firstName LIKE '%#params.search#%' OR lastName LIKE '%#params.search#%'";
    }

    users = model("User").findAll(
        where=whereClause,
        page=params.page ?: 1,
        perPage=25,
        order="lastName, firstName"
    );
}
```

## Form Handling Patterns
```cfm
function create() {
    user = model("User").new(params.user);

    // Handle file upload
    if (StructKeyExists(params, "avatar") && Len(params.avatar)) {
        user.avatarPath = handleFileUpload(params.avatar);
    }

    if (user.save()) {
        // Send email notification
        sendNotificationEmail(user);

        redirectTo(route="user", key=user.id, success="User created!");
    } else {
        // Reload form data
        roles = model("Role").findAll();
        renderView(action="new");
    }
}

private function handleFileUpload(file) {
    uploadPath = ExpandPath("/uploads/avatars/");

    if (!DirectoryExists(uploadPath)) {
        DirectoryCreate(uploadPath);
    }

    fileName = CreateUUID() & "." & ListLast(file.name, ".");
    FileMove(file.tempFile, uploadPath & fileName);

    return "/uploads/avatars/" & fileName;
}
```
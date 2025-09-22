code examples:

`````accessibleProperties:
Use this method inside your model’s config() function to whitelist which properties can be set via mass assignment operations (such as updateAll(), updateOne() and etc).
This helps protect your model from accidental or malicious updates to sensitive fields (e.g., isAdmin, passwordHash, etc.).

1. Allow only one property
// In models/User.cfc
function config() {
    // Only allow `isActive` to be set through mass assignment
    accessibleProperties("isActive");
}

// Example usage
User.updateAll(isActive=true);

2. Allow multiple properties
// In models/User.cfc
function config() {
    // Allow name and email to be set
    accessibleProperties("firstName,lastName,email");
}

// Example usage
User.create(firstName="Zain", lastName="Ul Abideen", email="zain@example.com");

5. Dynamic restriction per model
// In models/Post.cfc
function config() {
    if (application.env == "production") {
        // Lock down sensitive fields in production
        accessibleProperties("title,content");
    } else {
        // In dev, keep it open for testing
    }
}







`````addColumn:
Adds a new column to an existing table.
This function is only available inside a migration CFC and is part of the Wheels migrator API.

Use it to evolve your database schema safely through versioned migrations.

1. Add a simple string column
addColumn(
    table="members",
    columnType="string",
    columnName="status",
    limit=50
);


👉 Adds a status column (string, max 50 chars) to the members table.

2. Add an integer column with default value
addColumn(
    table="orders",
    columnType="integer",
    columnName="priority",
    default=0
);


👉 Adds a priority column with default value 0.

3. Add a boolean column that does not allow NULL
addColumn(
    table="users",
    columnType="boolean",
    columnName="isActive",
    null=false,
    default=1
);


👉 Adds an isActive column with default value true (1), disallowing NULL.

4. Add a decimal column with precision and scale
addColumn(
    table="products",
    columnType="decimal",
    columnName="price",
    precision=10,
    scale=2
);


👉 Adds a price column with up to 10 digits total, including 2 decimal places.

5. Add a reference (foreign key) column
addColumn(
    table="orders",
    columnType="reference",
    columnName="userId",
    referenceName="users"
);


👉 Adds a userId column to orders and links it to the users table.












`````addError:
Adds a custom error to a model instance.
This is useful when built-in validations don’t fully cover your business rules, or when you want to enforce conditional logic.

The error will be attached to the given property and can later be retrieved using functions like errorsOn() or allErrors().

1. Add a simple error
// In models/User.cfc
this.addError(
    property="email",
    message="Sorry, you are not allowed to use that email. Try again, please."
);


👉 Adds an error on the email property.

2. Add an error with a name identifier
this.addError(
    property="password",
    message="Password must contain at least one special character.",
    name="weakPassword"
);


👉 Adds a weakPassword error on the password property.
Later you can check for it:

if (user.hasError("password", "weakPassword")) {
    // Handle specifically the weak password case
}

3. Adding multiple errors to the same property
this.addError(property="username", message="Username already taken.", name="duplicate");
this.addError(property="username", message="Username cannot contain spaces.", name="invalidChars");


👉 Two different errors on username, each distinguished by their name.

4. Conditional custom errors
// Suppose only company emails are allowed
if (!listLast(this.email, "@") == "company.com") {
    this.addError(
        property="email",
        message="Please use your company email address.",
        name="invalidDomain"
    );
}


👉 Custom rule ensures only company domain emails are accepted.

5. Combine with built-in validations
// Inside a callback
function beforeSave() {
    if (this.age < 18) {
        this.addError(property="age", message="You must be at least 18 years old.");
    }
}


👉 Even though validatesPresenceOf("age") might exist, addError() gives you extra conditional control.



`````addErrorToBase:
Adds an error directly on the model object itself, not tied to a specific property.
This is useful when the error applies to the object as a whole or to a combination of properties, rather than a single field (for example: comparing two values, enforcing cross-property business rules, or validating external conditions).

1. Add a general error
this.addErrorToBase(
    message="Your email address must be the same as your domain name."
);


👉 Error applies to the whole object, not just email.

2. Add a named error
this.addErrorToBase(
    message="Order total must be greater than zero.",
    name="invalidTotal"
);


👉 Useful for distinguishing this error later when multiple base errors exist.

3. Enforce a cross-property rule
if (this.startDate > this.endDate) {
    this.addErrorToBase(
        message="Start date cannot be after end date.",
        name="invalidDateRange"
    );
}


👉 Rule depends on two properties, so the error belongs on the object as a whole.

4. Business logic validation
if (this.balance < this.minimumDeposit) {
    this.addErrorToBase(
        message="Balance is below the required minimum deposit.",
        name="lowBalance"
    );
}


👉 Example where validation involves external business rules, not just a single column.

5. Using with valid()
if (!user.valid()) {
    dump(user.allErrors());
    // Will include base-level errors from addErrorToBase()
}










`````addForeignKey:
Adds a foreign key constraint between two tables.
This ensures that values in one table’s column must exist in the referenced column of another table, enforcing referential integrity.

This function is only available inside a migration CFC and is part of the Wheels migrator API.

1. Basic foreign key
addForeignKey(
    table="orders",
    referenceTable="users",
    column="userId",
    referenceColumn="id"
);


👉 Ensures that every orders.userId must exist in users.id.

2. Foreign key for many-to-one relation
addForeignKey(
    table="comments",
    referenceTable="posts",
    column="postId",
    referenceColumn="id"
);


👉 Ensures each comment is linked to a valid post.

3. Foreign key with a custom reference column
addForeignKey(
    table="invoices",
    referenceTable="customers",
    column="customerCode",
    referenceColumn="code"
);


👉 Links invoices.customerCode to customers.code instead of a numeric ID.

4. Multiple foreign keys in one migration
// In migration
addForeignKey(
    table="enrollments",
    referenceTable="students",
    column="studentId",
    referenceColumn="id"
);

addForeignKey(
    table="enrollments",
    referenceTable="courses",
    column="courseId",
    referenceColumn="id"
);


👉 enrollments table is linked to both students and courses.












`````addFormat:
Registers a new MIME type in your Wheels application for use with responding to multiple formats.
This is helpful when your app needs to handle file types beyond the defaults provided by Wheels (e.g., serving JavaScript, PowerPoint, JSON, custom data formats).

Works in controllers, models, tests, migrators, migrations, and table definitions.

1. Add a JavaScript format
addFormat(
    extension="js",
    mimeType="text/javascript"
);


👉 Allows controllers to respond to .js requests with the correct MIME type.

2. Add PowerPoint formats
addFormat(extension="ppt", mimeType="application/vnd.ms-powerpoint");
addFormat(extension="pptx", mimeType="application/vnd.ms-powerpoint");


👉 Enables Wheels to correctly serve legacy and modern PowerPoint files.

3. Add JSON format
addFormat(
    extension="json",
    mimeType="application/json"
);


👉 Useful for APIs that need to respond with .json requests.

4. Add PDF format
addFormat(
    extension="pdf",
    mimeType="application/pdf"
);


👉 Ensures .pdf responses are correctly labeled for browsers.

5. Add multiple custom data formats
addFormat(extension="csv", mimeType="text/csv");
addFormat(extension="yaml", mimeType="application/x-yaml");


👉 Expands your app to handle CSV and YAML outputs.











`````addIndex:
Adds a database index on one or more columns of a table.
Indexes speed up queries that filter, sort, or join on those columns.
This function is only available inside a migration CFC and is part of the Wheels migrator API.

1. Add a unique index on a single column
addIndex(
    table="members",
    columnNames="username",
    unique=true
);


👉 Ensures username values in members are unique.

2. Add a non-unique index for faster queries
addIndex(
    table="orders",
    columnNames="createdAt"
);


👉 Speeds up queries filtering or ordering by createdAt.

3. Add a composite index (multiple columns)
addIndex(
    table="posts",
    columnNames="authorId,createdAt"
);


👉 Optimizes queries that filter or sort on both authorId and createdAt.

4. Add an index with a custom name
addIndex(
    table="comments",
    columnNames="postId",
    indexName="idx_comments_postId"
);


👉 Creates index with a custom name instead of default comments_postId.

5. Composite unique index
addIndex(
    table="enrollments",
    columnNames="studentId,courseId",
    unique=true,
    indexName="unique_enrollments"
);


👉 Prevents the same studentId and courseId pair from being inserted more than once.
















`````addRecord:
Inserts a new record into a table.
This function is only available inside a migration CFC and is part of the Wheels migrator API.

Useful for seeding initial data (like admin users, roles, or lookup values) alongside schema changes.

Examples
1. Add a single record
addRecord(
    table="people",
    id=1,
    title="Mr",
    firstname="Bruce",
    lastname="Wayne", 
    email="bruce@wayneenterprises.com",
    tel="555-67869099"
);


👉 Inserts one record into the people table.

2. Add a record with only required fields
addRecord(
    table="roles",
    id=1,
    name="Admin"
);


👉 Seeds an Admin role into the roles table.

3. Add a record with default values in schema
addRecord(
    table="users",
    email="zain@example.com",
    firstName="Zain",
    lastName="Ul Abideen"
);


👉 Relies on schema defaults (e.g., isActive=true) for missing fields.

4. Add lookup data
addRecord(
    table="statuses",
    id=1,
    name="Pending"
);
addRecord(
    table="statuses",
    id=2,
    name="Approved"
);
addRecord(
    table="statuses",
    id=3,
    name="Rejected"
);


👉 Seeds reusable lookup/status values.

5. Add a record referencing another table
// Assuming user with ID=1 exists
addRecord(
    table="posts",
    id=1,
    title="First Post",
    content="Hello, Wheels!",
    userId=1
);


👉 Creates a post tied to an existing user.













`````addReference:
Adds a reference column and a foreign key constraint to a table in one step.
This is a shortcut for creating an integer column (e.g., userId) and then linking it to another table using a foreign key.

This function is only available inside a migration CFC and is part of the Wheels migrator API.

1. Add a user reference to orders
addReference(
    table="orders",
    referenceName="users"
);


👉 Adds a userId column to orders and creates a foreign key to users.id.

2. Add a post reference to comments
addReference(
    table="comments",
    referenceName="posts"
);


👉 Creates a postId column on comments and links it to posts.id.

3. Add references to multiple tables
addReference(table="enrollments", referenceName="students");
addReference(table="enrollments", referenceName="courses");


👉 Adds both studentId and courseId to enrollments with foreign keys to students and courses.

4. Composite example (reference + other fields)
addColumn(table="votes", columnType="boolean", columnName="upvote", default=1);
addReference(table="votes", referenceName="users");
addReference(table="votes", referenceName="posts");


👉 Builds a votes table that connects users and posts with foreign keys.













`````afterCreate:
Registers one or more callback methods that are automatically executed after a new object is created (i.e., after calling create() on a model).

This is part of the model lifecycle callbacks in Wheels.

1. Single callback method
// Instruct Wheels to call the `fixObj` method after an object is created
afterCreate("fixObj");

function fixObj() {
    variables.fixed = true;
}

2. Multiple callbacks
afterCreate("logCreation,notifyAdmin");

function logCreation() {
    writeLog("New record created at #now()#");
}

function notifyAdmin() {
    // send an email notification
}

3. With object attributes
afterCreate("setDefaults");

function setDefaults() {
    if (!len(variables.status)) {
        variables.status = "pending";
    }
}

4. Practical usage in User.cfc
component extends="Model" {
    function config() {
        afterCreate("assignRole,sendWelcomeEmail");
    }

    function assignRole() {
        if (isNull(roleId)) {
            roleId = Role.findOneByName("User").id;
        }
    }

    function sendWelcomeEmail() {
        // code to send welcome email
    }
}















`````afterDelete:
Registers one or more callback methods that should be executed after an object is deleted from the database.

This hook allows you to perform cleanup, logging, or side effects when a record has been removed.

1. Single callback method
// Call `logDeletion` after an object is deleted
afterDelete("logDeletion");

function logDeletion() {
    writeLog("Record deleted at #now()#");
}

2. Multiple callbacks
afterDelete("archiveData,notifyAdmin");

function archiveData() {
    // move deleted data to an archive table
}

function notifyAdmin() {
    // send a notification email
}

3. With related cleanup
afterDelete("removeAssociatedRecords");

function removeAssociatedRecords() {
    // remove orphaned child records manually
    Order.deleteAll(where="userId = #this.id#");
}

4. Practical usage in User.cfc
component extends="Model" {
    function config() {
        afterDelete("cleanupSessions,sendGoodbyeEmail");
    }

    function cleanupSessions() {
        Session.deleteAll(where="userId = #id#");
    }

    function sendGoodbyeEmail() {
        // code to send a farewell email
    }
}











`````afterFind:
Registers one or more callback methods that should be executed after an existing object has been initialized, typically via finder methods such as findByKey, findOne, findAll, or other query-based lookups.

This hook is useful for adjusting, enriching, or transforming model objects immediately after they are loaded from the database.

1. Add a timestamp when data was fetched
component extends="Model" {
    function config() {
        afterFind("setTime");
    }

    function setTime() {
        arguments.fetchedAt = now();
        return arguments;
    }
}


When you call:

user = model("User").findByKey(1);
writeOutput(user.fetchedAt); // Shows the time record was retrieved

2. Format or normalize data
afterFind("normalizeEmail");

function normalizeEmail() {
    this.email = lcase(this.email);
}


Ensures all email addresses are lowercased when loaded.

3. Load related info automatically
afterFind("attachProfile");

function attachProfile() {
    this.profile = model("Profile").findOne(where="userId = #this.id#");
}


Now every User object automatically has its related profile loaded.

4. Multiple callbacks
afterFind("setTime,normalizeEmail,attachProfile");


All three methods will run in order after the object is retrieved.













`````afterInitialization:
Registers one or more callback methods that should be executed after an object has been initialized.

Initialization happens in two cases:

When a new object is created (via new() or similar).

When an existing object is fetched from the database (via findByKey, findOne, etc.).

This makes afterInitialization() more general than afterCreate() or afterFind(), since it runs in both scenarios.

1. Normalize data after every initialization
afterInitialization("normalizeName");

function normalizeName() {
    this.firstName = trim(this.firstName);
    this.lastName = trim(this.lastName);
}


Ensures whitespace is stripped whether the object is new or fetched.

2. Add a helper attribute for all instances
afterInitialization("addFullName");

function addFullName() {
    this.fullName = this.firstName & " " & this.lastName;
}


Now every object has a fullName property set right after creation or retrieval.

3. Multiple callbacks
afterInitialization("normalizeName,addFullName");


Runs both methods sequentially.

4. Practical example in User.cfc
component extends="Model" {
    function config() {
        afterInitialization("normalizeName,addFullName,setFetchedAt");
    }

    function normalizeName() {
        this.firstName = trim(this.firstName);
        this.lastName = trim(this.lastName);
    }

    function addFullName() {
        this.fullName = this.firstName & " " & this.lastName;
    }

    function setFetchedAt() {
        arguments.fetchedAt = now();
        return arguments;
    }
}













`````afterNew:
Registers one or more callback methods that should be executed after a new object has been initialized, typically via the new() method.

This hook is useful for setting default values, preparing derived attributes, or running logic every time you create a fresh model instance (before saving it to the database).

1. Set default values for new records
afterNew("setDefaults");

function setDefaults() {
    this.isActive = true;
    this.role = "member";
}


Whenever a new object is initialized, default values are assigned.

2. Generate a temporary property
afterNew("assignTempId");

function assignTempId() {
    this.tempId = createUUID();
}


Each new object will have a unique tempId until it’s saved.

3. Multiple callbacks
afterNew("setDefaults,assignTempId");


Runs both methods sequentially for every new object.

4. Example in User.cfc
component extends="Model" {
    function config() {
        afterNew("setDefaults,prepareDisplayName");
    }

    function setDefaults() {
        this.isActive = true;
    }

    function prepareDisplayName() {
        this.displayName = this.firstName & " " & this.lastName;
    }
}















`````afterSave:
Registers one or more callback methods that should be executed after an object is saved to the database.

This hook runs whether the save was the result of creating a new record or updating an existing one. It’s ideal for tasks that must happen after persistence, such as logging, syncing data, or triggering external processes.

1. Log every save
afterSave("logSave");

function logSave() {
    writeLog("User ##this.id## saved at #now()#");
}

2. Trigger notifications
afterSave("notifyAdmin");

function notifyAdmin() {
    if (this.role == "admin") {
        sendEmail(to="superadmin@example.com", subject="Admin Updated", body="Admin user #this.id# has been updated.");
    }
}

3. Multiple callbacks
afterSave("logSave,notifyAdmin");

4. Example in Order.cfc
component extends="Model" {
    function config() {
        afterSave("recalculateInventory,sendConfirmation");
    }

    function recalculateInventory() {
        Inventory.updateStock(this.productId, -this.quantity);
    }

    function sendConfirmation() {
        EmailService.sendOrderConfirmation(this.id);
    }
}
















`````afterUpdate:
Registers one or more callback methods that should be executed after an existing object has been updated in the database.

This hook is ideal for performing follow-up tasks whenever a record changes — such as logging, cache invalidation, or sending notifications about updates.

1. Simple logging
afterUpdate("logUpdate");

function logUpdate() {
    writeLog("Record ##this.id## was updated at #now()#");
}

2. Trigger an email when a specific field changes
afterUpdate("notifyEmailChange");

function notifyEmailChange() {
    if (this.hasChanged("email")) {
        sendEmail(
            to=this.email,
            subject="Your email was updated",
            body="Hi #this.firstName#, your email address has been changed."
        );
    }
}

3. Multiple callbacks
afterUpdate("logUpdate,notifyEmailChange");

4. Example in Order.cfc
component extends="Model" {
    function config() {
        afterUpdate("updateInventory,sendUpdateNotification");
    }

    function updateInventory() {
        Inventory.adjustStock(this.productId, -this.quantity);
    }

    function sendUpdateNotification() {
        EmailService.sendOrderUpdate(this.id);
    }
}

















`````afterValidation:
Registers one or more callback methods that should be executed after an object has been validated.

This hook is useful for running extra logic that depends on validation results, such as adjusting error messages, performing side validations, or preparing data before saving.

1. Add a custom validation error
afterValidation("checkRestrictedEmails");

function checkRestrictedEmails() {
    if (listFindNoCase("test@example.com,admin@example.com", this.email)) {
        this.addError("email", "That email address is not allowed.");
    }
}

2. Normalize data after validation
afterValidation("normalizePhone");

function normalizePhone() {
    if (len(this.phone)) {
        this.phone = rereplace(this.phone, "[^0-9]", "", "all");
    }
}

3. Multiple callbacks
afterValidation("checkRestrictedEmails,normalizePhone");

4. Example in User.cfc
component extends="Model" {
    function config() {
        validatesPresenceOf("email");
        afterValidation("checkRestrictedEmails,normalizePhone");
    }

    function checkRestrictedEmails() {
        if (listFindNoCase("banned@example.com", this.email)) {
            this.addError("email", "This email address is not permitted.");
        }
    }

    function normalizePhone() {
        this.phone = rereplace(this.phone, "[^0-9]", "", "all");
    }
}


















`````afterValidationOnCreate:
Registers one or more callback methods that should be executed after a new object has been validated (i.e., when running validations during a create() or save() on a new record).

This hook is useful when you want to apply custom logic only during new record creation, not during updates.

1. Add a creation-only error
afterValidationOnCreate("checkSignupEmail");

function checkSignupEmail() {
    if (listFindNoCase("banned@example.com,blocked@example.com", this.email)) {
        this.addError("email", "This email address cannot be used for registration.");
    }
}

2. Generate a default username if missing
afterValidationOnCreate("generateUsername");

function generateUsername() {
    if (!len(this.username)) {
        this.username = listFirst(this.email, "@");
    }
}

3. Multiple callbacks
afterValidationOnCreate("checkSignupEmail,generateUsername");

4. Example in User.cfc
component extends="Model" {
    function config() {
        validatesPresenceOf("email");
        validatesFormatOf(property="email", regex="^[\w\.-]+@[\w\.-]+\.\w+$");

        afterValidationOnCreate("checkSignupEmail,generateUsername");
    }

    function checkSignupEmail() {
        if (listFindNoCase("banned@example.com", this.email)) {
            this.addError("email", "This email address is restricted.");
        }
    }

    function generateUsername() {
        if (!len(this.username)) {
            this.username = listFirst(this.email, "@");
        }
    }
}













`````afterValidationOnUpdate:
Registers one or more callback methods that should be executed after an existing object has been validated (i.e., when running validations during an update() or save() on an already-persisted record).

This hook is useful when you want logic to run only on updates, not on initial creation.

1. Prevent updating restricted emails
afterValidationOnUpdate("checkRestrictedEmail");

function checkRestrictedEmail() {
    if (this.email eq "admin@example.com") {
        this.addError("email", "You cannot change this email address.");
    }
}

2. Automatically update a lastModifiedBy field
afterValidationOnUpdate("setLastModifiedBy");

function setLastModifiedBy() {
    this.lastModifiedBy = session.userId;
}

3. Multiple callbacks
afterValidationOnUpdate("checkRestrictedEmail,setLastModifiedBy");

4. Example in User.cfc
component extends="Model" {
    function config() {
        validatesPresenceOf("email");
        validatesFormatOf(property="email", regex="^[\w\.-]+@[\w\.-]+\.\w+$");

        afterValidationOnUpdate("checkRestrictedEmail,setLastModifiedBy");
    }

    function checkRestrictedEmail() {
        if (this.email eq "admin@example.com") {
            this.addError("email", "This email cannot be changed.");
        }
    }

    function setLastModifiedBy() {
        this.lastModifiedBy = session.userId;
    }
}














`````allChanges:
Returns a struct containing all unsaved changes made to an object since it was last loaded or saved.

Each entry in the struct uses the property name as the key and the new (unsaved) value as the value.

1. Basic usage
member = model("member").findByKey(params.memberId);

// Change some values (not saved yet)
member.firstName = params.newFirstName;
member.email = params.newEmail;

// Get all pending changes
allChanges = member.allChanges();
// Example output: { "firstName"="John", "email"="john@example.com" }

2. Checking if changes exist before saving
member = model("member").findByKey(42);
member.status = "inactive";

if (!structIsEmpty(member.allChanges())) {
    writeDump(var=member.allChanges(), label="Pending Changes");
    member.save();
}

3. Using in a validation callback
afterValidation("logChanges");

function logChanges() {
    var changes = this.allChanges();
    if (!structIsEmpty(changes)) {
        log(message="User ##this.id## updated fields: #structKeyList(changes)#");
    }
}

4. Example with multiple updates
user = model("user").findByKey(10);

user.firstName = "Jane";
user.lastName  = "Doe";
user.email     = "jane.doe@example.com";

changes = user.allChanges();
// Output might be: { "firstName"="Jane", "lastName"="Doe", "email"="jane.doe@example.com" }



















`````allErrors:
Returns an array of error objects for the current model instance.

Each error object includes:

message → the human-readable validation error

name → the internal error name

property → the model property associated with the error

By default, only errors for the current object are returned. Associations can be included if needed.

1. Get all validation errors
user = model("user").new(
    username = "",
    password = ""
);

// Validate the object
user.valid();

// Fetch errors
errorInfo = user.allErrors();

writeDump(var=errorInfo, label="User Errors");


Sample output:

[
  {
    "message": "Username must not be blank.",
    "name": "usernameError",
    "property": "username"
  },
  {
    "message": "Password must not be blank.",
    "name": "passwordError",
    "property": "password"
  }
]

2. Including associated model errors
order = model("order").new(
    customer = model("customer").new(name="")
);

// Validate both order and associated customer
order.valid();

// Get errors from both order and customer
errors = order.allErrors(includeAssociations=true);

3. Checking for errors before saving
user = model("user").new(email="not-an-email");

if (!user.valid()) {
    errors = user.allErrors();
    for (err in errors) {
        writeOutput("Error on #err.property#: #err.message#<br>");
    }
}

















`````announce:
Outputs a custom message during migration execution.
This is useful for logging progress or providing context when multiple migration steps are running.

1. Announce a step in a migration
announce("Adding status column to members table...");
addColumn(
    table = "members",
    columnType = "string",
    columnName = "status",
    limit = 50
);

2. Announce progress in multiple steps
announce("Creating orders table...");
createTable("orders", function(table) {
    table.integer("id");
    table.string("description");
});

announce("Adding index on orders.description...");
addIndex(table="orders", columnNames="description");

3. Use for debugging migrations
announce("Starting migration at #Now()#");

// Migration logic here...

announce("Migration completed successfully.");



















`````assert:
Asserts that an expression evaluates to true in a test.
If the expression evaluates to false, the test will fail and an error will be raised.

This is one of the core testing functions available when writing legacy tests in Wheels.

1. Basic true assertion
// Passes because 2 + 2 = 4
assert(2 + 2 EQ 4);

2. Assertion that fails
// This will fail the test because 5 is not less than 3
assert(5 LT 3);

3. With model object conditions
user = model("user").findByKey(1);

// Assert that the user has an email set
assert(len(user.email));



















`````authenticityToken:
Returns the raw CSRF authenticity token for the current user session.
This token is used to help protect against Cross-Site Request Forgery (CSRF) attacks by verifying that form submissions or AJAX requests originate from your application.

You typically won’t call this function directly in views — instead, Wheels provides helpers like authenticityTokenField() to generate hidden form fields. But authenticityToken() can be useful if you need direct access to the token string (for example, in custom JavaScript code).

1. Get the raw CSRF token in a controller
token = authenticityToken();

2. Output token manually in a form (not recommended, but possible)
<form action="/posts/create" method="post">
    <input type="hidden" name="authenticityToken" value="#authenticityToken()#">
    <input type="text" name="title">
    <input type="submit" value="Save">
</form>

3. Use in AJAX request headers
fetch("/posts/create", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": "<cfoutput>#authenticityToken()#</cfoutput>"
  },
  body: JSON.stringify({ title: "New Post" })
});
















`````authenticityTokenField:
Generates a hidden form field that contains a CSRF authenticity token.
This token is required for verifying that POST, PUT, PATCH, or DELETE requests originated from your application, helping protect against Cross-Site Request Forgery (CSRF) attacks.

When you use startFormTag(), Wheels automatically includes the token field for you. You’ll usually only need to call authenticityTokenField() manually when creating forms without startFormTag() or when building raw HTML forms.

1. Adding a CSRF token to a manual form
<!--- Needed here because we're not using startFormTag --->
<form action="#urlFor(route='posts')#" method="post">
  #authenticityTokenField()#
  <input type="text" name="title">
  <input type="submit" value="Create Post">
</form>

2. No token needed for safe GET forms
<!--- Not needed here because GET requests are not protected --->
<form action="#urlFor(route='invoices')#" method="get">
  <input type="text" name="search">
  <input type="submit" value="Find Invoice">
</form>

3. Custom AJAX form with CSRF token
<form id="ajaxForm">
  #authenticityTokenField()#
  <input type="text" name="title">
  <button type="submit">Save</button>
</form>

document.getElementById("ajaxForm").addEventListener("submit", function(e) {
  e.preventDefault();

  const token = document.querySelector("input[name='authenticityToken']").value;

  fetch("/posts", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": token
    },
    body: JSON.stringify({ title: "CSRF-protected post" })
  });
});


















`````autoLink:
Scans a block of text for URLs and/or email addresses and automatically converts them into clickable links.

This helper is handy for displaying user-generated content, comments, or messages where you want to make links interactive without manually adding <a> tags.

1. Auto-link a URL
#autoLink("Download Wheels from https://wheels.dev")#


Output:

Download Wheels from <a href="https://wheels.dev">https://wheels.dev</a>

2. Auto-link an email address
#autoLink("Email us at info@cfwheels.org")#


Output:

Email us at <a href="mailto:info@cfwheels.org">info@cfwheels.org</a>

3. Only link URLs, not emails
#autoLink("Visit https://cfwheels.org or email support@cfwheels.org", link="URLs")#


Output:

Visit <a href="https://cfwheels.org">https://cfwheels.org</a> or email support@cfwheels.org

4. Only link email addresses
#autoLink("Contact info@cfwheels.org or see https://cfwheels.org", link="emailAddresses")#


Output:

Contact <a href="mailto:info@cfwheels.org">info@cfwheels.org</a> or see https://cfwheels.org

5. Disable auto-linking of relative URLs
#autoLink("See /about for more info", relative=false)#


Output:

See /about for more info

6. Control XSS encoding
#autoLink("Check https://cfwheels.org?search=<script>alert('xss')</script>", encode=true)#


Encodes dangerous content to prevent XSS.




















`````automaticValidations:
Controls whether automatic validations should be enabled for a specific model.

By default, Wheels can automatically infer validations from your database schema (e.g., NOT NULL fields, field length limits, etc.). This function lets you override that behavior at the model level — enabling or disabling automatic validations regardless of the global setting.

1. Disable automatic validations for a single model
component extends="Model" {
    function config() {
        automaticValidations(false);
    }
}


Useful when automatic validations are enabled globally but a model requires custom validation handling.

2. Enable automatic validations explicitly for a model
component extends="Model" {
    function config() {
        automaticValidations(true);
    }
}


Ensures this model always applies database-inferred validations, even if global automatic validations are turned off.

3. Combining with custom validations
component extends="Model" {
    function config() {
        automaticValidations(false); // turn off inferred rules
        validatesPresenceOf("email");
        validatesFormatOf(property="email", regex="^[\\w\\.-]+@[\\w\\.-]+\\.\\w+$");
    }
}


Here, automatic validations are disabled, but explicit validation rules are still applied.





















`````average:
Calculates the average value for a given property in a model’s table, using the SQL AVG() function.

If no records match the criteria, you can specify a value to return using the ifNull argument (e.g., 0 to ensure a numeric return).

1. Average salary for all employees
avgSalary = model("employee").average("salary");

2. Average salary filtered by department
avgSalary = model("employee").average(
    property = "salary",
    where    = "departmentId = #params.key#"
);

3. Ensure a numeric value is always returned
avgSalary = model("employee").average(
    property = "salary",
    where    = "salary BETWEEN #params.min# AND #params.max#",
    ifNull   = 0
);

4. Average with distinct values only
avgSalary = model("employee").average(
    property = "salary",
    distinct = true
);

5. Grouped average by department
avgSalaries = model("employee").average(
    property = "salary",
    group    = "departmentId"
);



















`````beforeAll:
Registers code that should execute once before the entire legacy test suite runs.

Useful for setting up global test data, seeding, or initializing resources that multiple tests depend on.

1. Run setup before all tests
function beforeAll() {
    // Seed the database with initial data
    model("user").create(firstName="Admin", email="admin@example.com");
    
    // Set a global variable for tests
    application.testMode = true;
}

2. Load configuration once for the test suite
function beforeAll() {
    variables.config = {
        apiKey = "12345",
        environment = "test"
    };
}

















`````beforeCreate:
Registers method(s) that should be called before a new object is created.

This allows you to modify or validate data, set defaults, or perform logic right before the object is persisted in the database for the first time.

1. Run a method before saving a new object
config() {
    beforeCreate("fixObj");
}

function fixObj() {
    // Ensure a default role is assigned
    if (!structKeyExists(this, "roleId")) {
        this.roleId = 2; // Assign "user" role
    }
}

2. Generate a unique slug before creation
config() {
    beforeCreate("generateSlug");
}

function generateSlug() {
    this.slug = lcase(replace(this.title, " ", "-", "all"));
}

3. Hash a password before inserting a new user
config() {
    beforeCreate("hashPassword");
}

function hashPassword() {
    this.password = hash(this.password, "SHA-256");
}


















`````beforeDelete:
Registers method(s) that should be called before an object is deleted.

This allows you to perform cleanup, enforce constraints, or prevent deletion if certain conditions are not met.

1. Basic usage: run a method before deleting
config() {
    beforeDelete("fixObj");
}

function fixObj() {
    // Example: log deletions
    writeLog("Deleting record with ID #this.id#");
}

2. Prevent deletion if conditions fail
config() {
    beforeDelete("checkIfAdmin");
}

function checkIfAdmin() {
    if (!session.isAdmin) {
        throw(type="SecurityException", message="Only admins can delete records.");
    }
}

3. Cascade cleanup before deletion
config() {
    beforeDelete("cleanupAssociations");
}

function cleanupAssociations() {
    // Delete related comments before removing a post
    model("comment").deleteAll(where="postId = #this.id#");
}




















`````beforeSave:
Registers method(s) that should be called before an object is saved (this applies to both create and update operations).

This is useful for performing transformations, validations, or logging before data is persisted.

1. Basic usage: run a method before save
config() {
    beforeSave("fixObj");
}

function fixObj() {
    // Example: Trim whitespace before saving
    this.username = trim(this.username);
}

2. Automatically update a timestamp
config() {
    beforeSave("updateTimestamp");
}

function updateTimestamp() {
    this.lastModifiedAt = now();
}

3. Normalize data before saving
config() {
    beforeSave("normalizeData");
}

function normalizeData() {
    // Example: ensure email is lowercase
    this.email = lcase(this.email);

    // Example: capitalize first name
    this.firstName = ucase(left(this.firstName, 1)) & mid(this.firstName, 2);
}

4. Prevent save if conditions fail
config() {
    beforeSave("blockInactiveUsers");
}

function blockInactiveUsers() {
    if (!this.isActive) {
        throw(type="ValidationException", message="Inactive users cannot be saved.");
    }
}





















`````beforeUpdate:
Registers method(s) that should be called before an existing object is updated.

This is useful for enforcing rules, transforming values, or checking conditions specifically for update operations (unlike beforeSave(), which applies to both create and update).

1. Basic usage: register a method before update
config() {
    beforeUpdate("fixObj");
}

function fixObj() {
    // Example: trim whitespace before updating
    this.lastName = trim(this.lastName);
}

2. Update an "last modified" timestamp
config() {
    beforeUpdate("updateTimestamp");
}

function updateTimestamp() {
    this.updatedAt = now();
}

3. Prevent updating sensitive fields
config() {
    beforeUpdate("restrictEmailChange");
}

function restrictEmailChange() {
    if (this.hasChanged("email")) {
        throw(type="ValidationException", message="Email address cannot be changed.");
    }
}

4. Audit updates with logging
config() {
    beforeUpdate("logChanges");
}

function logChanges() {
    var changes = this.allChanges();
    writeLog(text="User ##this.id## updated with changes: #serializeJSON(changes)#", file="audit");
}






















`````beforeValidation:
Registers method(s) that should be called before an object is validated.

This hook is helpful when you want to adjust, normalize, or clean up data before validation rules run. It ensures the object is in the correct state so that validations pass or fail as expected.

1. Basic usage: register a method before validation
config() {
    beforeValidation("fixObj");
}

function fixObj() {
    // Example: normalize names before validation
    this.firstName = trim(this.firstName);
    this.lastName = trim(this.lastName);
}

2. Ensure default values before validation
config() {
    beforeValidation("setDefaults");
}

function setDefaults() {
    if (!len(this.status)) {
        this.status = "pending";
    }
}

3. Convert input formats before validating
config() {
    beforeValidation("normalizePhone");
}

function normalizePhone() {
    // Remove spaces/dashes so the validation regex can run correctly
    this.phoneNumber = rereplace(this.phoneNumber, "[^0-9]", "", "all");
}

4. Multi-method callback
config() {
    beforeValidation("sanitizeEmail, normalizeUsername");
}

function sanitizeEmail() {
    this.email = lcase(trim(this.email));
}

function normalizeUsername() {
    this.username = rereplace(this.username, "[^a-zA-Z0-9]", "", "all");
}





















`````beforeValidationOnCreate:
Registers method(s) that should be called before a new object is validated.

This hook is useful when you want to prepare or sanitize data specifically for new records, ensuring that validations run on properly formatted data. It will not run on updates—only on create() or new() + save() operations.

1. Basic usage: register a method before validation on create
config() {
    beforeValidationOnCreate("fixObj");
}

function fixObj() {
    this.firstName = trim(this.firstName);
}

2. Ensure default values only for new records
config() {
    beforeValidationOnCreate("setDefaults");
}

function setDefaults() {
    if (!len(this.role)) {
        this.role = "member";
    }
}

3. Normalize data formats for new users
config() {
    beforeValidationOnCreate("normalizeNewUserData");
}

function normalizeNewUserData() {
    // Make sure emails are stored lowercase for new accounts
    this.email = lcase(trim(this.email));
}

4. Run multiple setup methods before new record validation
config() {
    beforeValidationOnCreate("assignUUID, sanitizeName");
}

function assignUUID() {
    if (!len(this.uuid)) {
        this.uuid = createUUID();
    }
}

function sanitizeName() {
    this.fullName = trim(this.fullName);
}























`````beforeValidationOnUpdate:
Registers method(s) that should be called before an existing object is validated.

This hook is useful when you want to adjust, sanitize, or enforce rules specifically for updates (not for new records). It ensures the object is in the correct state before validation checks run.

1. Basic usage: register a method before validation on update
config() {
    beforeValidationOnUpdate("fixObj");
}

function fixObj() {
    this.lastName = trim(this.lastName);
}

2. Prevent changes to immutable fields
config() {
    beforeValidationOnUpdate("restrictImmutableFields");
}

function restrictImmutableFields() {
    if (this.hasChanged("email")) {
        this.addError(property="email", message="Email cannot be changed once set.");
    }
}

3. Normalize input before update validations
config() {
    beforeValidationOnUpdate("sanitizePhone");
}

function sanitizePhone() {
    this.phoneNumber = rereplace(this.phoneNumber, "[^0-9]", "", "all");
}

4. Run multiple pre-validation methods for updates
config() {
    beforeValidationOnUpdate("updateTimestamp, sanitizeNotes");
}

function updateTimestamp() {
    this.lastModified = now();
}

function sanitizeNotes() {
    this.notes = trim(this.notes);
}


















`````belongsTo:
Sets up a belongsTo association between this model and another model.

Use this when the current model contains a foreign key referencing another model. This establishes a one-to-many relationship from the perspective of the other model (i.e., this model “belongs to” a parent model).

1. Standard belongsTo association
// Specify that instances of this model belong to an author
belongsTo("author");


Wheels will automatically deduce the foreign key as authorId and the associated model as Author.

2. Custom foreign key and model name
// Foreign key does not follow convention
belongsTo(
    name = "bookWriter",
    modelName = "author",
    foreignKey = "authorId"
);


Useful when your database column names or model names deviate from Wheels conventions.

3. Specify LEFT OUTER JOIN
belongsTo(
    name = "publisher",
    joinType = "outer"
);



















`````bigInteger:
Adds one or more big integer columns to a table definition in a migration.

Use this when you need columns capable of storing large integer values, typically larger than standard integer columns.

1. Add a single big integer column
bigInteger(columnNames="userId");

2. Add multiple big integer columns
bigInteger(columnNames="orderId, invoiceId");

3. Add a column with a default value and disallow NULLs
bigInteger(columnNames="views", default="0", null=false);

4. Add a column with a custom limit
bigInteger(columnNames="serialNumber", limit=20);















`````binary:
Adds one or more binary columns to a table definition in a migration.

Use this for storing raw binary data, such as files, images, or other byte streams.

1. Add a single binary column
binary(columnNames="profilePicture");

2. Add multiple binary columns
binary(columnNames="thumbnail, documentBlob");

3. Add a binary column that allows NULLs
binary(columnNames="attachment", null=true);

4. Add a binary column with a default value
binary(columnNames="signature", default="0x00");



















`````boolean:
Adds one or more boolean columns to a table definition in a migration.

Use this for columns that store true/false values.

1. Add a single boolean column
boolean(columnNames="isActive");

2. Add multiple boolean columns
boolean(columnNames="isPublished, isVerified");

3. Add a boolean column with a default value
boolean(columnNames="isAdmin", default="false");

4. Add a boolean column that allows NULLs
boolean(columnNames="isArchived", null=true);



















`````buttonTag:
Builds and returns a string containing a button form control for use in your HTML forms.

Use this helper to create buttons with custom content, types, values, images, and optional HTML wrappers.

1. Basic submit button
#startFormTag(action="something")#
    #buttonTag(content="Submit this form", value="save")#
#endFormTag()#

2. Button with a different type
#buttonTag(content="Reset form", type="reset")#

3. Button using an image
#buttonTag(image="submit.png", value="save")#

4. Button with HTML wrappers
#buttonTag(content="Click Me", prepend="<div class='btn-wrapper'>", append="</div>")#

5. Disable encoding for raw HTML content
#buttonTag(content="<strong>Submit</strong>", encode=false)#




















`````buttonTo:
Creates a form containing a single button that submits to a URL. The URL is constructed the same way as linkTo().

This helper is useful when you want a button that performs a specific action (GET, POST, PUT, DELETE, PATCH) without manually creating a form.

1. Basic button submitting to an action
#buttonTo(text="Delete Account", action="performDelete", disable="Wait...")#

2. Button with an ID and class applied to the input
#buttonTo(text="Edit", action="edit", inputId="edit-button", inputClass="edit-button-class")#

3. Button using an image instead of text
#buttonTo(image="delete-icon.png", action="delete")#

4. Button linking to a specific route with query parameters
#buttonTo(text="View Report", route="reportRoute", params="year=2025&month=9")#

5. Button using DELETE method
#buttonTo(text="Remove", action="deleteItem", method="delete")#

















`````caches:
Tells Wheels to cache one or more controller actions.

Caching improves performance by storing the output of actions so that repeated requests do not require re-running the action logic.

1. Cache a single action (default 60 minutes)
caches("termsOfUse");

2. Cache multiple actions for 30 minutes
caches(actions="browseByUser, browseByTitle", time=30);

3. Cache actions as static pages, skipping filters
caches(actions="termsOfUse, codeOfConduct", static=true);

4. Cache content separately based on runtime variable
caches(action="home", appendToKey="request.region");


















`````clearCachableActions:
Removes one or more actions from the list of cacheable actions in a controller.

Use this when you want to prevent previously cached actions from being cached or to reset caching for certain actions.

1. Clear a single action from cache
clearCachableActions("termsOfUse");

2. Clear multiple actions from cache
clearCachableActions(actions="termsOfUse,codeOfConduct");

3. Clear all cacheable actions in the controller
clearCachableActions();




















`````capitalize:
Capitalizes the first letter of every word in the provided text, creating a nicely formatted title or sentence.

1. Capitalize a single sentence
#capitalize("wheels is a framework")#
<!--- Output: Wheels Is A Framework --->

2. Capitalize a name
#capitalize("john doe")#
<!--- Output: John Doe --->

3. Capitalize a title
#capitalize("introduction to wheels framework")#
<!--- Output: Introduction To Wheels Framework --->

















`````change:
Used in migrations to alter an existing table in the database.

This function allows you to modify the structure of a table, such as adding, modifying, or removing columns, by wrapping your table definition changes in a change() block.

1. Alter a table to add new columns
change(table="members", addColumns=true) {
    string(columnNames="nickname", limit=50, null=true);
    boolean(columnNames="isPremium", default=false);
}

2. Alter existing columns without adding new ones
change(table="members") {
    string(columnNames="email", limit=150, null=false); // Modify length and nullability
}


















`````changeColumn:
Changes the definition of an existing column in a database table.

This function is used in migration CFCs to update column properties such as type, size, default value, nullability, precision, and scale.

1. Change the type and limit of a column
changeColumn(
    table='members',
    columnName='status',
    columnType='string',
    limit=50
);

2. Change a decimal column’s precision and scale
changeColumn(
    table='products',
    columnName='price',
    columnType='decimal',
    precision=10,
    scale=2
);

3. Change a column to allow NULL and set a default value
changeColumn(
    table='users',
    columnName='nickname',
    columnType='string',
    limit=100,
    null=true,
    default='Guest'
);

4. Move a column to a specific position in the table
changeColumn(
    table='orders',
    columnName='status',
    columnType='string',
    limit=20,
    afterColumn='orderDate'
);






















`````changedFrom:
Returns the previous value of a property that has been modified on a model object.

Wheels tracks changes to object properties until the object is saved to the database. If no previous value exists (the property was never modified), it returns an empty string.

This is useful for auditing, logging, or conditional logic based on changes to object properties.

1. Track changes on a single property
member = model("member").findByKey(params.memberId);
member.email = params.newEmail;

// Get the previous value of the email
oldValue = member.changedFrom("email");

2. Using dynamic property function
// Dynamic method naming also works
oldValue = member.emailChangedFrom();

3. Check before saving
member.firstName = "Bruce";

if (member.changedFrom("firstName") != "") {
    writeOutput("First name was changed from " & member.changedFrom("firstName"));
}

member.save();





















`````changedProperties:
Returns a list of property names that have been modified on a model object but not yet saved to the database.

This is useful for tracking which fields were updated, triggering specific actions based on changes, or performing conditional validation.

1. Track changed properties
member = model("member").findByKey(params.memberId);
member.firstName = params.newFirstName;
member.email = params.newEmail;

// Get a list of properties that have changed
changedProperties = member.changedProperties();

// Example output: ["firstName", "email"]

2. Conditional logic based on changes
if (arrayLen(member.changedProperties()) > 0) {
    writeOutput("The following fields were changed: " & arrayToList(member.changedProperties()));
}



















`````changeTable:
Creates a table definition object used to store and apply modifications to an existing table in the database.

This function is only available inside a migration CFC and works in conjunction with table definition methods like string(), integer(), boolean(), etc., and the change() method to apply the changes.

1. Add new columns to an existing table
t = changeTable(name='employees');
t.string(columnNames="fullName", default="", null=true, limit=255);
t.boolean(columnNames="isActive", default=true);
t.change();

2. Modify multiple columns
t = changeTable(name='products');
t.string(columnNames="productName", limit=150, null=false);
t.decimal(columnNames="price", precision=10, scale=2);
t.change();





















`````char:
Adds one or more CHAR columns to a table definition in a migration.

Use this function to define fixed-length string columns when creating or modifying a table.

1. Add a single CHAR column
char(columnNames="status", limit=1, default="A", null=false);

2. Add multiple CHAR columns
char(columnNames="type,code", limit=2, default="", null=true);

3. Add a CHAR column without a limit
char(columnNames="initials", null=true);



















`````checkBox:
Builds and returns a string containing a checkbox form control for a model object property.
Supports nested associations, deep object forms, and automatic error handling. You can also customize labels, placement, and HTML attributes.

1. Basic checkbox for a single boolean property
#checkBox(
    objectName="photo",
    property="isPublic",
    label="Display this photo publicly."
)#

2. Checkbox for a nested hasMany association
<cfloop from="1" to="#ArrayLen(user.photos)#" index="i">
    <div>
        <h3>#user.photos[i].title#:</h3>
        <div>
            #checkBox(
                objectName="user",
                association="photos",
                position=i,
                property="isPublic",
                label="Display this photo publicly."
            )#
        </div>
    </div>
</cfloop>





















`````checkBoxTag:
Builds and returns a string containing a checkbox form control. Unlike checkBox(), this function works purely with form tag attributes rather than binding to a model object.
You can customize the label, placement, checked state, and add HTML attributes.

1. Basic checkbox
#checkBoxTag(
    name="subscribe",
    value="true",
    label="Subscribe to our newsletter",
    checked=false
)#

2. Checkboxes generated from a query
// Controller
pizza = model("pizza").findByKey(session.pizzaId);
selectedToppings = pizza.toppings();
toppings = model("topping").findAll(order="name");

// View
<fieldset>
    <legend>Toppings</legend>
    <cfoutput query="toppings">
        #checkBoxTag(
            name="toppings",
            value="true",
            label=toppings.name,
            checked=YesNoFormat(ListFind(ValueList(selectedToppings.id), toppings.id))
        )#
    </cfoutput>
</fieldset>





















`````clearChangeInformation:
Clears all internal tracking information that Wheels maintains about an object’s properties.
This does not undo changes made to the object—it simply resets the record of which properties are considered “changed,” so methods like hasChanged(), changedProperties(), or allChanges() will no longer report them.

This is useful when you modify a property programmatically (for example, in a callback) and don’t want Wheels to attempt saving or reporting it as a change.

1. Clear change information for a single property
// Convert startTime to UTC in an "afterFind" callback
this.startTime = DateConvert("Local2UTC", this.startTime);

// Tell Wheels to clear internal change tracking for this property
this.clearChangeInformation(property="startTime");

2. Clear change information for all properties
// Clear internal tracking for all properties of the object
this.clearChangeInformation();



















`````clearErrors:
Clears all validation or manual errors stored on a model object.
You can clear all errors, or target specific errors either by property name or by a custom error name.

This is useful when resetting an object’s state before re-validation, updating values programmatically, or handling conditional validation logic.

1. Clear all errors on the object
// Remove all errors regardless of property
this.clearErrors();

2. Clear errors on a specific property
// Remove all errors associated with the 'firstName' property
this.clearErrors("firstName");

3. Clear a specific error by name
// Remove only the error named 'emailFormatError' without affecting other errors
this.clearErrors(name="emailFormatError");



















`````collection:
Defines a collection route in your Wheels application.
Collection routes operate on a set of resources and do not require an id, unlike member routes which act on a single resource.

This is useful when building actions that retrieve, filter, or display multiple objects, such as search pages, listings, or batch operations.

Example 1: Basic collection route
<cfscript>
mapper()
    .resources(name="photos", nested=true)
        .collection()
            .get("search")  // GET /photos/search
        .end()
    .end()
.end();
</cfscript>



















`````column:
Adds a column to a table definition in a migration. This function is used when defining or altering database tables. It supports multiple column types and allows you to specify constraints like default values, nullability, length, and precision.

Use this inside a table definition object in a migration CFC when building or modifying tables.

1. Add a string column
t = changeTable(name="employees");
t.column(columnName="fullName", columnType="string", limit=255, null=false, default="Unknown");
t.change();

2. Add a decimal column
t = changeTable(name="products");
t.column(columnName="price", columnType="decimal", precision=10, scale=2, null=false, default="0.00");
t.change();

3. Add a boolean column
t = changeTable(name="members");
t.column(columnName="isActive", columnType="boolean", null=false, default="1");
t.change();



















`````columnDataForProperty:
Returns a struct containing metadata about a specific property in a model. This includes information such as type, constraints, default values, and other column-specific details. It’s useful when you need to introspect the schema of your model dynamically.

1. Inspect a simple property
user = model("user").findByKey(1);
data = user.columnDataForProperty("email");

writeDump(data);


Output might include:

{
  "columnName": "email",
  "columnType": "string",
  "default": "",
  "null": false,
  "limit": 255
}

2. Use column metadata for validation or dynamic forms
columns = model("product").columnDataForProperty("price");

if(columns.null EQ false AND columns.columnType EQ "decimal") {
    writeOutput("Price is required and must be decimal.");
}




















`````columnForProperty:
Returns the database column name that corresponds to a given model property. This is useful when your model property names differ from the actual database column names, or when you need to dynamically generate SQL queries or mappings.

1. Retrieve the column name for a property
user = model("user").findByKey(1);
columnName = user.columnForProperty("email");

writeOutput(columnName);  // Might output: "email_address"

2. Use in dynamic SQL queries
userModel = model("user");
column = userModel.columnForProperty("firstName");
query = "SELECT #column# FROM users WHERE id = 1";



















`````columnNames:
Returns a list of column names for the table mapped to this model. The list is ordered according to the columns’ ordinal positions in the database table. This is useful for dynamically generating queries, forms, or for inspecting the database structure associated with a model.

1. Get all column names for a model
userModel = model("user");
columns = userModel.columnNames();

writeOutput(columns);
// Might output: "id,first_name,last_name,email,created_at,updated_at"

2. Use column names to dynamically select fields in a query
userModel = model("user");
queryColumns = userModel.columnNames();
q = "SELECT #queryColumns# FROM users WHERE active = 1";



















`````columns:
Returns an array of database column names for the table associated with the model. This method excludes calculated or transient properties that are defined in the model but not stored in the database.

1. Get an array of columns for a model
userModel = model("user");
columnArray = userModel.columns();

writeDump(columnArray);
// Might output: ["id", "first_name", "last_name", "email", "created_at", "updated_at"]

2. Loop through the columns for dynamic processing
userModel = model("user");
for(column in userModel.columns()) {
    writeOutput("Column: #column#<br>");
}

















`````compareTo:
Compares the current model object with another model object to determine if they are effectively the same. This is useful for checking equality between two instances of the same model before performing operations like updates or merges.

1. Compare two user objects
user1 = model("user").findByKey(1);
user2 = model("user").findByKey(2);

if(user1.compareTo(user2)) {
    writeOutput("Objects are the same.");
} else {
    writeOutput("Objects are different.");
}

2. Compare dynamically after changing a property
user1 = model("user").findByKey(1);
user2 = model("user").findByKey(1);

user2.email = "newemail@example.com";

writeDump(user1.compareTo(user2)); // Will output false because email changed





















`````constraints:
Defines variable patterns for route parameters when setting up routes using the Wheels mapper(). This allows you to restrict the values that route parameters can take, such as limiting an id parameter to numbers only or enforcing a specific string format.

1. Constrain a route parameter to digits only
mapper()
    .resources(name="users")
        .member(id=":userId")
            .constraints({ userId="^\d+$" })
        .end()
    .end()
.end();


Here, the userId parameter must be a number, otherwise the route won’t match.

2. Constrain multiple parameters
mapper()
    .resources(name="orders")
        .member(orderId=":orderId", itemId=":itemId")
            .constraints({ 
                orderId="^\d+$", 
                itemId="^\d{3}-[A-Z]{2}$" 
            })
        .end()
    .end()
.end();





















`````contentFor:
contentFor() is used to store a section's output in a layout. It allows you to define content in your view templates and then render it in a layout using #includeContent()#. The function maintains a stack for each section, so multiple pieces of content can be added in a controlled order.

1. Basic usage
<!--- In your view --->
<cfsavecontent variable="mySidebar">
    <h1>My Sidebar Text</h1>
</cfsavecontent>

<cfset contentFor(sidebar=mySidebar)>

<!--- In your layout --->
<html>
    <head><title>My Site</title></head>
    <body>
        <cfoutput>
            #includeContent("sidebar")#  <!-- Renders the sidebar content -->
            #includeContent()#           <!-- Renders main content -->
        </cfoutput>
    </body>
</html>

2. Adding multiple pieces to the same section
<cfset contentFor(sidebar="First piece of content")>
<cfset contentFor(sidebar="Second piece of content", position="first")>

<!--- Renders 'Second piece of content' first, then 'First piece of content' --->
#includeContent("sidebar")#

3. Overwriting content
<cfset contentFor(sidebar="Old content")>
<cfset contentFor(sidebar="New content", overwrite=true)>

<!--- Only 'New content' will be rendered --->
#includeContent("sidebar")#





















`````contentForLayout:
contentForLayout() is used to render the main content of the current view inside a layout. In Wheels, when a controller action renders a view, that view generates content. This content can then be injected into the layout at the appropriate place using contentForLayout().

Essentially, it’s the placeholder for the view’s body content in your layout template.

Example
Controller:
// PostsController.cfc
function show() {
    var post = model("post").findByKey(params.id);
    render(view="show", args={post=post});
}

View (views/posts/show.cfm):
<h2>#post.title#</h2>
<p>#post.body#</p>

Layout (views/layout.cfm):
<html>
<head>
    <title>Blog</title>
</head>
<body>
    <nav>Home | Posts</nav>

    <!-- Inject view content -->
    #contentForLayout()#

    <footer>&copy; 2025 My Blog</footer>
</body>
</html>


Output when visiting /posts/show?id=1:

<html>
<head>
    <title>Blog</title>
</head>
<body>
    <nav>Home | Posts</nav>

    <h2>Hello World</h2>
    <p>This is my first post!</p>

    <footer>&copy; 2025 My Blog</footer>
</body>
</html>























`````controller:
The controller() function in Wheels is used to define routes that point to a specific controller. However, it is considered deprecated, because it does not align with RESTful routing principles. Wheels encourages using resources() and other RESTful routing helpers instead.

Example Usage (Deprecated)
<cfscript>
mapper()
    .controller(controller="posts", path="/blog")
.end();
</cfscript>


This maps the /blog URL path to the PostsController.

Not RESTful: all HTTP methods map to the same controller without distinctions for actions like show, create, update, etc.

Recommended Alternative

Use RESTful routing with resources() instead:

<cfscript>
mapper()
    .resources(name="posts", path="/blog")
        .get("index")
        .get("show")
        .post("create")
        .patch("update")
        .delete("destroy")
    .end()
.end();
</cfscript>


This defines standard RESTful actions with proper HTTP verbs.

More maintainable and consistent with modern API practices.

























`````controller:
The controller() function creates and returns a controller object with a custom name and optional parameters. It is primarily used for testing, but can also be used in code to instantiate a controller programmatically.

Unlike the deprecated routing controller() function, this helper does not define routes—it creates controller instances.

Example Usage
<cfscript>
// Create a users controller object for testing or programmatic use
testController = controller("users", {userId: 42, action: "show"});

// Call an action on the controller object
result = testController.show();
</cfscript>



















`````count:
The count() method calculates the number of records in a table that match a given set of conditions. It internally uses the SQL COUNT() function. If no arguments are provided, it returns the total number of rows in the table.

It works on model classes.

Example Usage
<cfscript>
// Count all authors
authorCount = model("author").count();

// Count authors with last names starting with "A"
authorOnACount = model("author").count(where="lastName LIKE 'A%'");

// Count authors with books starting with "A"
authorWithBooksOnACount = model("author").count(include="books", where="booktitle LIKE 'A%'");

// Count comments for a specific post (requires a hasMany association from post to comment)
aPost = model("post").findByKey(params.postId);
amount = aPost.commentCount();  // internally calls model("comment").count(where="postId=#post.id#")
</cfscript>




















`````create:
The create() method is used to create a database table based on the table definition that has been built using the migrator’s table definition functions (string(), integer(), boolean(), etc.).

This method is only available within a migration CFC and finalizes the table creation in the database.

Usage
<cfscript>
t = table(name="employees");
t.string(columnNames="firstName", limit=50, null=false);
t.string(columnNames="lastName", limit=50, null=false);
t.integer(columnNames="age", null=true);
t.boolean(columnNames="isActive", default="1");

// Create the table in the database
t.create();
</cfscript>





















`````create:
The create() method is used to instantiate a new model object, set its properties, and save it to the database (if validations pass). Even if validation fails, the method still returns the unsaved object, including any validation errors.

It’s a higher-level convenience function that combines object creation, property assignment, validation, and saving into a single call.

Usage Examples

Using a struct for properties:

newAuthor = model("author").create(properties=params.author);


Using named arguments:

newAuthor = model("author").create(firstName="John", lastName="Doe");


Mixing named arguments and a struct:

newAuthor = model("author").create(active=1, properties=params.author);


Scoped creation via associations (hasOne or hasMany):

aCustomer = model("customer").findByKey(params.customerId);
anOrder = aCustomer.createOrder(shipping=params.shipping);




















`````createMigration:
The createMigration() method is used to generate a new migration file for managing database schema changes. While you can call it from your application code, it is primarily intended for use via the CLI or Wheels GUI.

A migration file allows you to define table creations, modifications, or deletions in a structured way that can be applied or rolled back consistently.

1. Create an empty migration file:

result = application.wheels.migrator.createMigration("MyMigrationFile");


Generates a blank migration file with a timestamped prefix.

You can then edit it to define your table or schema changes.

2. Create a migration file from a template (e.g., create-table):

result = application.wheels.migrator.createMigration("MyMigrationFile", "create-table");


Generates a migration file pre-populated with a create-table template.

Useful for quickly scaffolding new tables with column definitions.























`````createTable:
The createTable() function is used in migration CFCs to define a new database table. It returns a TableDefinition object, on which you can specify columns, primary keys, timestamps, and other table properties. Once the table is defined, you call create() to actually create it in the database.

1. Basic Users Table

t = createTable(name='users'); 
t.string(columnNames='firstname,lastname', default='', null=false, limit=50);
t.string(columnNames='email', default='', null=false, limit=255); 
t.string(columnNames='passwordHash', default='', null=true, limit=500);
t.string(columnNames='passwordResetToken,verificationToken', default='', null=true, limit=500);
t.boolean(columnNames='passwordChangeRequired,verified', default=false); 
t.datetime(columnNames='passwordResetTokenAt,passwordResetAt,loggedinAt', default='', null=true); 
t.integer(columnNames='roleid', default=0, null=false, limit=3);
t.timestamps();
t.create();


Creates a users table with standard user columns, boolean flags, timestamps, and role ID.

2. Table with Custom Primary Key

t = createTable(name='tokens', id=false);
t.primaryKey(name='id', null=false, type="string", limit=35 );
t.datetime(columnNames="expiresAt", null=false);
t.integer(columnNames='requests', default=0, null=false);
t.timestamps();
t.create();


Creates a tokens table without the default id column, specifying a custom primary key of type string.

3. Join Table with Composite Primary Keys

t = createTable(name='userkintins', id=false); 
t.primaryKey(name="userid", null=false, limit=11);
t.primaryKey(name='profileid', type="string", limit=11 );  
t.create();


Useful for many-to-many relationships, defining multiple primary keys (composite key).






















`````createView:
The createView() function is used in migration CFCs to define a new database view. It returns a ViewDefinition object, on which you can specify the view’s SQL query and properties. Once the view is fully defined, you call create() to actually create it in the database.

1. Simple View Creation

v = createView(name='active_users');
v.select('id, firstname, lastname, email');
v.from('users');
v.where('active = 1');
v.create();


Creates a view active_users that selects only active users from the users table.

2. View with Join

v = createView(name='user_orders');
v.select('u.id, u.firstname, u.lastname, o.id as orderId, o.total');
v.from('users u');
v.join('orders o', 'u.id = o.userId');
v.where('o.status = "completed"');
v.create();


Creates a user_orders view joining users and orders tables, filtering only completed orders.






















`````csrfMetaTags:
The csrfMetaTags() helper generates meta tags containing your application's CSRF authenticity token. This is useful for JavaScript/AJAX requests that need to POST data securely, ensuring that the request comes from a trusted source.

Usage

Place it inside the <head> section of your layout:

<head>
    <title>My Application</title>
    #csrfMetaTags()#
</head>


This will output something like:

<meta name="csrf-token" content="YOUR_AUTH_TOKEN_HERE">
<meta name="csrf-param" content="authenticityToken">


csrf-token → contains the actual CSRF token.

csrf-param → the parameter name your server expects (authenticityToken by default).


















`````cycle:
cycle() is a view helper used to loop through a list of values sequentially, returning the next value each time it’s called. This is especially useful for things like alternating row colors in tables or assigning sequential classes in repeated HTML elements.

Basic Example: Alternating Table Row Colors
<table>
	<thead>
		<tr>
			<th>Name</th>
			<th>Phone</th>
		</tr>
	</thead>
	<tbody>
		<cfoutput query="employees">
			<tr class="#cycle("odd,even")#">
				<td>#employees.name#</td>
				<td>#employees.phone#</td>
			</tr>
		</cfoutput>
	</tbody>
</table>


Rows will alternate CSS classes odd and even automatically.

Advanced Example: Nested Cycles
<cfoutput query="employees" group="departmentId">
	<div class="#cycle(values="even,odd", name="row")#">
		<ul>
			<cfoutput query="employees">
				<cfset rank = cycle(values="president,vice-president,director,manager,specialist,intern", name="position")>
				<li class="#rank#">#employees.name#</li>
			</cfoutput>
		</ul>
	</div>
</cfoutput>


Here, you can have multiple cycles running independently by assigning a unique name to each (row, position).

Nested cycles reset independently, so you can cycle within groups or sections.




















`````dataSource:
dataSource() is a model configuration method used to override the default database connection for a specific model. This is useful when you want a model to query a different database or use specific credentials than the application default.

Example Usage
// In models/User.cfc
component extends="Model" {

    function config() {
        // Use a custom datasource for this model
        dataSource("users_source");
        
        // Optional: specify credentials
        // dataSource("users_source", "dbUser", "dbPass");
    }
}


Effect: Whenever this model performs queries (e.g., findAll(), create(), update()), Wheels will use the users_source datasource instead of the application default.

This does not affect other models, so each model can have its own data source if needed.



















`````date:
date() is a table definition function used in a migration CFC to add one or more DATE columns to a table.

Example Usage
// In a migration CFC
t = createTable(name="events");

t.date(
    columnNames="startDate,endDate", 
    default="", 
    null=false
);

t.create();

















`````dateSelect:
dateSelect() generates three select dropdowns (month, day, year) for choosing a date. It works with a model object property or any variable you pass in.

Example 1: Basic usage
#dateSelect(objectName="user", property="dateOfBirth")#


Outputs month/day/year selects for the user.dateOfBirth property.

Example 2: Only month and year (no day)
#dateSelect(objectName="order", property="expirationDate", order="month,year")#


Useful for credit card expiration dates.

Only month and year dropdowns appear.

Example 3: Custom year range
#dateSelect(
    objectName="event",
    property="eventDate",
    startYear=2000,
    endYear=2030
)#


Dropdown shows years 2000–2030.

Example 4: Custom month display
#dateSelect(
    objectName="user",
    property="anniversary",
    monthDisplay="abbreviations"
)#


Months display as Jan, Feb, Mar… instead of full names.

Example 5: Include blank options
#dateSelect(
    objectName="profile",
    property="graduationDate",
    includeBlank="- Select Date -"
)#


Adds a blank option at the top of each select with the label - Select Date -.

Example 6: Using labels and custom HTML
#dateSelect(
    objectName="employee",
    property="hireDate",
    label="Hire Date",
    labelPlacement="before",
    prepend="<div class='date-wrapper'>",
    append="</div>"
)#


Adds a label and wraps selects inside a div for styling.






















`````dateSelectTags:
dateSelectTags() is similar to dateSelect(), but instead of binding to a model object, it works directly with a name and selected value. It generates three select dropdowns (month, day, year) for form tags.

Example 1: Basic usage
#dateSelectTags(name="dateStart", selected=params.dateStart)#


Outputs month/day/year selects with the value pre-selected from params.dateStart.

Example 2: Month and year only
#dateSelectTags(name="expiration", selected=params.expiration, order="month,year")#


Useful for credit card expiration date inputs.

Only month and year dropdowns appear.

Example 3: Custom year range
#dateSelectTags(name="eventDate", startYear=2000, endYear=2030)#


Dropdown shows years 2000–2030.

Example 4: Custom month display
#dateSelectTags(name="anniversary", monthDisplay="abbreviations")#


Months display as Jan, Feb, Mar… instead of full names.

Example 5: Include blank options
#dateSelectTags(name="graduationDate", includeBlank="- Select Date -")#


Adds a blank option at the top of each dropdown with - Select Date -.

Example 6: Using labels and custom HTML
#dateSelectTags(
    name="hireDate",
    label="Hire Date",
    labelPlacement="before",
    prepend="<div class='date-wrapper'>",
    append="</div>"
)#


Adds a label and wraps selects inside a <div> for styling.






















`````datetime:
Adds datetime columns to a table definition when creating or altering a table in a migration. These columns store both date and time values.

Example 1: Basic usage
t = createTable(name='appointments'); 
t.datetime(columnNames='startAt,endAt');
t.create();


Creates startAt and endAt columns as datetime columns in the appointments table.

Example 2: With NULL allowed
t = createTable(name='events'); 
t.datetime(columnNames='cancelledAt', null=true);
t.create();


cancelledAt column allows NULL values.

Example 3: With default timestamp
t = createTable(name='logs'); 
t.datetime(columnNames='createdAt', default='CURRENT_TIMESTAMP');
t.create();


Sets createdAt to the current timestamp by default.

Example 4: Multiple datetime columns with defaults
t = createTable(name='tasks'); 
t.datetime(columnNames='assignedAt,completedAt', default='CURRENT_TIMESTAMP', null=false);
t.create();


Both columns are non-nullable and default to the current timestamp.























`````dateTimeSelect:
Generates a set of six HTML select controls for choosing both date and time (month, day, year, hour, minute, second) bound to a model object property.

Example 1: Basic usage
#dateTimeSelect(objectName="article", property="publishedAt")#


Generates all six selects for article.publishedAt.

Example 2: Custom date and time order
#dateTimeSelect(
    objectName="appointment",
    property="dateTimeStart",
    dateOrder="month,day",
    timeOrder="hour,minute"
)#


Only shows month & day for date and hour & minute for time.

Example 3: 12-hour format with AM/PM
#dateTimeSelect(
    objectName="meeting",
    property="startTime",
    twelveHour=true,
    timeOrder="hour,minute"
)#


Hours dropdown uses 1–12 with AM/PM options.

Example 4: Include blank options and custom year range
#dateTimeSelect(
    objectName="event",
    property="eventTime",
    startYear=2020,
    endYear=2030,
    includeBlank=true
)#


Adds an empty option for each select and sets the year range to 2020–2030.

Example 5: Custom separators
#dateTimeSelect(
    objectName="flight",
    property="departure",
    dateSeparator="/",
    timeSeparator="."
)#


Shows / between date selects and . between time selects.






















`````dateTimeSelectTags:
Generates six HTML <select> dropdowns for date and time selection (month, day, year, hour, minute, second) using a name and selected value instead of binding to a model object.

Example 1: Basic usage
#dateTimeSelectTags(
    name="dateTimeStart",
    selected=params.dateTimeStart
)#


Generates six selects for date/time with default order and all fields included.

Example 2: Show only month, day, hour, and minute
#dateTimeSelectTags(
    name="dateTimeStart",
    selected=params.dateTimeStart,
    dateOrder="month,day",
    timeOrder="hour,minute"
)#


Excludes year and seconds from the dropdowns.

Example 3: 12-hour format with AM/PM
#dateTimeSelectTags(
    name="meetingTime",
    selected=params.meetingTime,
    twelveHour=true,
    timeOrder="hour,minute"
)#


Hours are displayed as 1–12 with AM/PM dropdown.

Example 4: Custom year range with blank options
#dateTimeSelectTags(
    name="eventTime",
    selected=params.eventTime,
    startYear=2020,
    endYear=2030,
    includeBlank=true
)#


Adds blank options and limits year selection to 2020–2030.

Example 5: Custom separators between date and time
#dateTimeSelectTags(
    name="flightDeparture",
    selected=params.departure,
    dateSeparator="/",
    timeSeparator="."
)#


Uses / between date selects and . between time selects.























`````daySelectTag:
Generates a single HTML <select> dropdown for the days of the week, based on a name attribute. This version works without binding to a model object.

Example 1: Basic usage
#daySelectTag(name="dayOfWeek", selected=params.dayOfWeek)#


Generates a standard select dropdown for all days of the week.

Pre-selects the value from params.dayOfWeek if available.

Example 2: Include a blank option
#daySelectTag(name="meetingDay", selected=params.meetingDay, includeBlank=true)#


Adds a blank option at the top so users can select nothing.

Example 3: Custom label before the field
#daySelectTag(
    name="deliveryDay",
    selected=params.deliveryDay,
    label="Choose delivery day:",
    labelPlacement="before"
)#


Adds a label that appears before the dropdown.

Example 4: Prepend and append HTML
#daySelectTag(
    name="eventDay",
    prepend="<div class='select-wrapper'>",
    append="</div>"
)#


Wraps the dropdown inside a <div> for styling purposes.





















`````debug:
Used in tests to inspect any expression. It behaves like a cfdump but is tailored for the testing environment. This helps you examine values while writing or running legacy tests.

Example 1: Basic usage
// In a test
user = model("user").findByKey(1);

// Inspect the user object
debug(user);


Dumps the contents of the user object to the test output.

Example 2: Debug without output
// Evaluate an expression but don't output
result = someFunction();
debug(result, display=false);


Useful when you want to leave the debug call in place for later but don’t want it to show in test output immediately.

Example 3: Debug an expression directly
debug(2 + 2);


Quickly examines a simple expression, like a calculation or string.





















`````decimal:
Adds decimal (numeric) columns to a table definition when creating or altering tables via a migration CFC.

Example 1: Basic decimal column
t = changeTable("products");
t.decimal(columnNames="price", default="0.00", null=false, precision=10, scale=2);
t.change();


Adds a price column with up to 10 digits, 2 of which are after the decimal point, default 0.00, and cannot be NULL.

Example 2: Multiple decimal columns
t = changeTable("invoices");
t.decimal(columnNames="tax,discount", default="0.00", null=false, precision=8, scale=2);
t.change();


Adds tax and discount columns with the same configuration.

Example 3: Nullable decimal column with no default
t = createTable("payments");
t.decimal(columnNames="amountDue", null=true, precision=12, scale=4);
t.create();


Adds a amountDue column that can be NULL and allows up to 12 digits, 4 of which are after the decimal.






















`````delete:
Creates a route that matches a URL requiring an HTTP DELETE method. Typically used for actions that delete records in the database.

Example 1: Member route with nested resource
<cfscript>
mapper()
    // Route: /articles/987/reviews/12542
    .delete(
        name="articleReview", 
        pattern="articles/[articleKey]/reviews/[key]", 
        to="reviews##delete"
    )
.end();
</cfscript>

Example 2: Simple resource route
<cfscript>
mapper()
    // Route: /cooked-books
    .delete(name="cookedBooks", controller="cookedBooks", action="delete")
.end();
</cfscript>

Example 3: Logout route
<cfscript>
mapper()
    // Route: /logout
    .delete(name="logout", to="sessions##delete")
.end();
</cfscript>

Example 4: Controller in a package
<cfscript>
mapper()
    // Route: /statuses/4918
    .delete(name="statuses", to="statuses##delete", package="clients")
.end();
</cfscript>

Example 5: Blog comment delete
<cfscript>
mapper()
    // Route: /comments/5432
    .delete(
        name="comment",
        pattern="comments/[key]",
        to="comments##delete",
        package="blog"
    )
.end();
</cfscript>


















`````delete:
Deletes the current model object from the database. If a beforeDelete callback exists and prevents deletion, the object will not be deleted. Returns true if deletion succeeds, otherwise false.

Example 1: Delete a single object
<cfscript>
post = model("post").findByKey(33);
success = post.delete();
</cfscript>


Deletes the post with ID 33 from the database.

Returns true if deletion succeeds.

Example 2: Scoped delete via association
<cfscript>
post = model("post").findByKey(params.postId);
comment = model("comment").findByKey(params.commentId);

// Calls comment.delete() internally
post.deleteComment(comment);
</cfscript>


If post has a hasMany association to comment, this uses the association method to delete a related comment.

Example 3: Permanent deletion (bypass soft-delete)
<cfscript>
post = model("post").findByKey(33);
post.delete(softDelete=false);
</cfscript>


Forces a hard delete even if the model uses soft-delete columns.






















`````deleteAll:
Deletes all records in a model that match the where condition. By default, the objects are not instantiated, so callbacks and validations are skipped. You can choose to instantiate them if you want callbacks and validations to run. The method returns the number of records deleted.

Example 1: Delete inactive users (skip callbacks and validations)
<cfscript>
recordsDeleted = model("user").deleteAll(where="inactive=1", instantiate=false);
writeOutput("Deleted #recordsDeleted# inactive users.");
</cfscript>


Deletes all users where inactive=1.

Objects are not instantiated, so callbacks and validations are skipped.

Example 2: Scoped delete using an association
<cfscript>
post = model("post").findByKey(params.postId);

// Deletes all comments associated with this post
howManyDeleted = post.deleteAllComments();
writeOutput("Deleted #howManyDeleted# comments for this post.");
</cfscript>


Assumes a hasMany association from post → comment.

Internally calls model("comment").deleteAll(where="postId=#post.id#").

Example 3: Delete and run callbacks
<cfscript>
recordsDeleted = model("user").deleteAll(
    where="inactive=1", 
    instantiate=true,   // instantiate objects to trigger callbacks
    callbacks=true
);
</cfscript>


Deletes the records after instantiating the objects.

Any beforeDelete or afterDelete callbacks are triggered.




















`````deleteByKey:
Finds a record by its primary key and deletes it. Returns true if the deletion succeeds, false otherwise.

Example 1: Delete a user by primary key
<cfscript>
result = model("user").deleteByKey(1);

if (result) {
    writeOutput("User deleted successfully.");
} else {
    writeOutput("Failed to delete user.");
}
</cfscript>


Deletes the user with id=1.

Returns true on success, false on failure.

Example 2: Delete a record permanently (ignore soft delete)
<cfscript>
result = model("user").deleteByKey(1, softDelete=false);

if (result) {
    writeOutput("User permanently deleted.");
}
</cfscript>


Ignores any soft delete column.

The record is removed from the database entirely.

Example 3: Disable callbacks
<cfscript>
result = model("user").deleteByKey(1, callbacks=false);

writeOutput("Deleted user without triggering callbacks: #result#");
</cfscript>


Skips any beforeDelete or afterDelete logic.























`````deleteOne:
Finds a single record based on conditions and deletes it. Returns true if deletion succeeds, false otherwise.

It is useful when you want to remove one specific record without fetching it manually first.

Example 1: Delete the most recently signed-up user
<cfscript>
result = model("user").deleteOne(order="signupDate DESC");

if (result) {
    writeOutput("Deleted the most recently signed-up user.");
} else {
    writeOutput("No user found to delete.");
}
</cfscript>


Deletes one record based on the order of signupDate descending.

Only the first matching record is deleted.

Example 2: Delete a specific user by condition
<cfscript>
result = model("user").deleteOne(where="email='test@example.com'");

writeOutput("Deletion status: #result#");
</cfscript>


Finds a user with the email test@example.com and deletes it.

Example 3: Scoped delete via association
<cfscript>
// Assuming a hasOne association: user -> profile
aUser = model("user").findByKey(params.userId);
aUser.deleteProfile(); // deletes the profile associated with this user
</cfscript>


deleteProfile() internally calls model("profile").deleteOne(where="userId=#aUser.id#").



















`````deobfuscateParam:
Converts an obfuscated string back into its original value. This is typically used when IDs or other sensitive data are encoded for security purposes and need to be restored to their original form.

Example 1: Deobfuscate a single value
<cfscript>
// Assume "b7ab9a50" is an obfuscated ID
originalValue = deobfuscateParam("b7ab9a50");

writeOutput("Original value: #originalValue#");
</cfscript>


Converts the obfuscated string "b7ab9a50" back to its original value.

Useful for safely passing IDs in URLs or forms while preventing direct exposure of database keys.

Example 2: Deobfuscate a request parameter
<cfscript>
// Assume params.userId contains an obfuscated user ID
userId = deobfuscateParam(params.userId);

user = model("user").findByKey(userId);
writeDump(user);
</cfscript>


Safely retrieves a user using an obfuscated ID passed in a URL or form.




















`````distanceOfTimeInWords:
Calculates the difference between two dates and returns a human-readable string describing that difference, like "about 1 month" or "2 days".

Example 1: Basic usage
<cfscript>
rightNow = now();
aWhileAgo = dateAdd("d", -30, rightNow);

timeDifference = distanceOfTimeInWords(aWhileAgo, rightNow);
writeOutput(timeDifference); // Outputs: "about 1 month"
</cfscript>


Calculates the difference between two dates.

Returns "about 1 month" because aWhileAgo is 30 days before rightNow.

Example 2: Include seconds
<cfscript>
startTime = now();
endTime = dateAdd("s", 45, startTime);

timeDifference = distanceOfTimeInWords(startTime, endTime, true);
writeOutput(timeDifference); // Outputs: "less than a minute" or "45 seconds" depending on Wheels version
</cfscript>


Useful when you need a more precise human-readable difference for very short intervals.

Example 3: Past vs future dates
<cfscript>
pastDate = dateAdd("d", -10, now());
futureDate = dateAdd("d", 5, now());

writeOutput(distanceOfTimeInWords(pastDate, now()));   // "10 days"
writeOutput(distanceOfTimeInWords(now(), futureDate)); // "5 days"
</cfscript>


Works regardless of the order of the dates.

Always returns a human-friendly description.





















`````down:
down() defines the steps to revert a database migration. It’s executed when rolling back a migration, typically to undo the changes applied by the corresponding up() function.

Example Usage
function down() {
    transaction {
        try {
            // Code to reverse migration
            dropTable('myTable');
        } catch (any e) {
            local.exception = e;
        }

        if (StructKeyExists(local, "exception")) {
            // Rollback if an error occurred
            transaction action="rollback";
            throw(
                errorCode="1", 
                detail=local.exception.detail, 
                message=local.exception.message, 
                type="any"
            );
        } else {
            // Commit transaction if no errors
            transaction action="commit";
        }
    }
}





















`````dropForeignKey:
dropForeignKey() is used to remove a foreign key constraint from a table in the database. This is typically done during schema changes in migrations.

Availability: Only within a migration CFC.

Example Usage
function up() {
    // Remove a foreign key from the orders table
    dropForeignKey(
        table="orders", 
        keyName="fk_orders_customerId"
    );
}


table = "orders" → the table that has the foreign key.

keyName = "fk_orders_customerId" → the exact name of the foreign key constraint you want to drop.


















`````dropReference:
dropReference() is used to remove a foreign key constraint from a table in the database using the reference name that was originally used to create it. This is slightly different from dropForeignKey(), which requires the actual key name.

Availability: Only within a migration CFC.

Example Usage
function up() {
    // Remove a foreign key reference from the orders table
    dropReference(
        table="orders", 
        referenceName="customer_ref"
    );
}


table = "orders" → the table that contains the foreign key reference.

referenceName = "customer_ref" → the reference name that was originally defined when the foreign key was created.




















`````dropTable:
dropTable() is used to remove a table from the database entirely. This is a destructive operation, so all data in the table will be lost.

Availability: Only within a migration CFC.

Example Usage
function down() {
    // Drop the 'users' table
    dropTable(name="users");
}


name = "users" → the table that you want to remove from the database.

Notes

Typically used in the down() method of a migration when rolling back a previous createTable().

Can be combined with transaction {} to ensure rollback in case of errors:

function down() {
    transaction {
        try {
            dropTable("orders");
        } catch (any e) {
            transaction action="rollback";
            throw(errorCode="1", detail=e.detail, message=e.message, type="any");
        }
        transaction action="commit";
    }
}


Caution: This operation permanently deletes all data in the table.






















`````dropView:
dropView() is used to remove a database view entirely. A view is a saved query that acts like a virtual table, so this operation deletes that virtual table definition.

Availability: Only within a migration CFC.

Example Usage
function down() {
    // Drop the 'active_users' view
    dropView(name="active_users");
}


name = "active_users" → the view that you want to remove from the database.

Notes

Typically used in the down() method of a migration when rolling back a previous createView().

Can be wrapped in a transaction for safety:

function down() {
    transaction {
        try {
            dropView("recent_orders");
        } catch (any e) {
            transaction action="rollback";
            throw(errorCode="1", detail=e.detail, message=e.message, type="any");
        }
        transaction action="commit";
    }
}


Caution: This permanently deletes the view definition. Any queries depending on the view will fail after this operation.





















`````end:
end() is used to close or terminate a nested routing block in a Wheels mapper() configuration. It signals the end of a block like namespace, scope, or a nested resources block.

Chaining:
end() is always chained to the current routing block and allows you to return to the previous scope or finish the entire routing configuration.

Example Usage
<cfscript>
mapper()
    .namespace("admin")
        .resources("products")
    .end() // Ends the `namespace` block

    .scope(package="public")
        .resources(name="products", nested=true)
            .resources("variations")
        .end() // Ends the nested `resources` block
    .end() // Ends the `scope` block
.end(); // Ends the `mapper` block
</cfscript>



















`````endFormTag:
endFormTag() generates the closing </form> tag for a form in your view. It’s typically used in conjunction with startFormTag().

Basic Example
#startFormTag(action="create")#
   <input type="text" name="firstName" placeholder="First Name">
   <input type="text" name="lastName" placeholder="Last Name">
#endFormTag()#


Output:

<form action="/create" method="post">
   <input type="text" name="firstName" placeholder="First Name">
   <input type="text" name="lastName" placeholder="Last Name">
</form>

🔹 With Prepend and Append
#startFormTag(action="update")#
   <input type="email" name="email" placeholder="Email">
#endFormTag(prepend="<div class='form-wrapper'>", append="</div>")#


Output:

<div class='form-wrapper'>
<form action="/update" method="post">
   <input type="email" name="email" placeholder="Email">
</form>
</div>

🔹 Encoded Output
#startFormTag(action="login")#
   <input type="text" name="username">
#endFormTag(encode=true)#


Ensures that any special characters in prepend or append are safely encoded.

Prevents XSS attacks if the content is user-generated.

🔹 Nested Form Wrapper Example
#startFormTag(action="register", prepend="<section>")#
   <input type="text" name="username">
   <input type="password" name="password">
#endFormTag(append="</section>")#


Output:

<section>
<form action="/register" method="post">
   <input type="text" name="username">
   <input type="password" name="password">
</form>
</section>























`````errorCount:
errorCount() returns the number of validation or callback errors associated with a model object. You can optionally filter by a specific property or a named error.

Example 1 — Count all errors on an object
author = model("author").create(params.author);

if (author.errorCount() GTE 10) {
    // Handle authors with 10 or more errors
    writeOutput("This author has too many errors!");
}


Counts all errors associated with the author object.

Useful for general validation checks before saving or processing an object.

🔹 Example 2 — Count errors for a specific property
if (author.errorCount("email") GT 0) {
    // Handle errors related only to the `email` property
    writeOutput("The email field has errors!");
}


Only considers errors attached to the email property.

Great for targeting specific fields in forms or validations.

🔹 Example 3 — Count errors by error name
if (author.errorCount("", "invalidFormat") GT 0) {
    // Handle errors with a specific error name
    writeOutput("There are fields with invalid formatting!");
}


Uses the name argument to filter errors created with a custom name.

property can be left blank if you want to count across all properties.

🔹 Example 4 — Combined property and error name
if (author.errorCount("email", "invalidFormat") GT 0) {
    // Only counts `invalidFormat` errors on the `email` property
    writeOutput("Email is formatted incorrectly!");
}


Combines filtering by property and error name for precise error handling.



















`````errorMessageOn:
errorMessageOn() returns the first validation error message for a specific property on a model object. If no error exists, it returns an empty string.

Example 1 — Basic usage
<cfoutput>
#errorMessageOn(objectName="author", property="email")#
</cfoutput>


Displays the first error message for the email property of the author object.

Default wrapper is <span class="error-message">.

🔹 Example 2 — Custom wrapper and class
<cfoutput>
#errorMessageOn(
    objectName="author",
    property="email",
    wrapperElement="div",
    class="alert alert-danger"
)#
</cfoutput>


Wraps the error in a <div> instead of <span>.

Uses Bootstrap classes for styling.

🔹 Example 3 — Prepend or append text
<cfoutput>
#errorMessageOn(
    objectName="author",
    property="email",
    prependText="Error: ",
    appendText=" Please fix it."
)#
</cfoutput>


Prepends "Error: " and appends " Please fix it." around the actual error message.

🔹 Example 4 — With HTML encoding disabled
<cfoutput>
#errorMessageOn(
    objectName="author",
    property="email",
    encode=false
)#
</cfoutput>


Output is not encoded, which can be useful if you want to include HTML formatting inside the error message itself.






















`````errorMessagesFor:
errorMessagesFor() generates a list (<ul>) of all error messages for a given model object. It is commonly used in forms to display all validation errors at once.

Example 1 — Basic usage
<cfoutput>
#errorMessagesFor(objectName="author")#
</cfoutput>


Generates a <ul class="error-messages"> containing all errors for the author object.

Default behavior includes all associated object errors.

🔹 Example 2 — Custom CSS class
<cfoutput>
#errorMessagesFor(objectName="author", class="alert alert-danger")#
</cfoutput>


Uses a custom CSS class for styling (e.g., Bootstrap alerts).

🔹 Example 3 — Exclude duplicate errors
<cfoutput>
#errorMessagesFor(objectName="author", showDuplicates=false)#
</cfoutput>


Prevents duplicate messages from appearing multiple times in the list.

🔹 Example 4 — Include or exclude associated objects
<cfoutput>
<!--- Only show errors on this object, not on associated objects --->
#errorMessagesFor(objectName="author", includeAssociations=false)#
</cfoutput>


Useful if you want to display errors for the main object separately from associated objects (like a nested profile or address).

🔹 Example 5 — HTML encoding disabled
<cfoutput>
#errorMessagesFor(objectName="author", encode=false)#
</cfoutput>


Errors are output as-is, allowing embedded HTML in the messages (use with caution).






















`````errorsOn:
errorsOn() returns an array of all errors associated with a specific property of a model object. You can also filter by a specific error name if needed. This is useful when you need programmatic access to errors rather than just displaying them in the view.

Example 1 — Basic usage
<cfscript>
user = model("user").findByKey(12);

errors = user.errorsOn("emailAddress");

writeDump(errors);
</cfscript>


Returns an array of error objects associated with the emailAddress property.

Each element typically contains the error message and metadata like name or type.

🔹 Example 2 — Filter by error name
<cfscript>
errors = user.errorsOn("emailAddress", "uniqueEmail");

writeDump(errors);
</cfscript>


Returns only errors for emailAddress that have the error name uniqueEmail.

🔹 Example 3 — Checking if a property has any errors
<cfscript>
if (arrayLen(user.errorsOn("password")) > 0) {
    writeOutput("Password has errors!");
}
</cfscript>


This is helpful when you need conditional logic based on whether a field has errors.

🔹 Example 4 — Iterating over errors
<cfscript>
errors = user.errorsOn("username");

for (var e in errors) {
    writeOutput("Error: " & e.message & "<br>");
}
</cfscript>


Loops through all errors on a property and outputs the messages individually.






















`````errorsOnBase:
errorsOnBase() returns an array of all errors associated with the object as a whole, not tied to any specific property. This is useful for general errors such as system-level validations, cross-field validations, or custom errors added at the object level.

Example 1 — Get all base errors
<cfscript>
user = model("user").findByKey(12);

errors = user.errorsOnBase();

writeDump(errors);
</cfscript>


Returns all general errors on the user object.

Each element typically contains message, name, and type information.

🔹 Example 2 — Filter by error name
<cfscript>
errors = user.errorsOnBase("accountLocked");

writeDump(errors);
</cfscript>


Returns only base errors that have the error name accountLocked.

🔹 Example 3 — Conditional logic with base errors
<cfscript>
if (arrayLen(user.errorsOnBase()) > 0) {
    writeOutput("There are general errors on this user account.");
}
</cfscript>


This can be used to block actions or display notices when object-level errors exist.

🔹 Example 4 — Iterating over base errors
<cfscript>
for (var e in user.errorsOnBase()) {
    writeOutput("General error: " & e.message & "<br>");
}
</cfscript>


Loops through each object-level error and outputs its message.
























`````excerpt:
excerpt() extracts a portion of text surrounding the first instance of a given phrase. This is useful for previews, search result snippets, or highlighting context around a keyword.

Example 1 — Basic usage
<cfscript>
text = "Wheels is a Rails-like MVC framework for Adobe ColdFusion and Lucee";

snippet = excerpt(text=text, phrase="framework", radius=5);

writeOutput(snippet);
</cfscript>


Output:

... MVC framework for ...


Extracts 5 characters before and after "framework".

Adds ... at the start and end to indicate truncation.

🔹 Example 2 — Increase radius
<cfscript>
snippet = excerpt(text=text, phrase="framework", radius=20);

writeOutput(snippet);
</cfscript>


Output:

... Rails-like MVC framework for Adobe Cold...


Shows more surrounding context (20 characters before and after the phrase).

🔹 Example 3 — Custom excerpt string
<cfscript>
snippet = excerpt(
    text=text,
    phrase="framework",
    radius=10,
    excerptString="***"
);

writeOutput(snippet);
</cfscript>


Output:

*** Rails-like MVC framework for Adob ***


Uses *** instead of ... to mark truncated text.

🔹 Example 4 — When phrase is near the start
<cfscript>
snippet = excerpt(text="Frameworks are powerful tools", phrase="Framework", radius=5);

writeOutput(snippet);
</cfscript>


Output:

Frameworks are po...


Does not prepend ... because the phrase is near the start of the text.























`````execute:
execute() allows you to run a raw SQL query directly from a migration file. This is useful when you need to perform operations that aren’t easily handled by the built-in migration methods like createTable() or addColumn().

Example 1 — Basic SQL execution
<cfscript>
function up() {
    transaction {
        // Execute a raw SQL statement
        execute(sql="INSERT INTO users (firstname, lastname, email) VALUES ('John', 'Doe', 'john@example.com')");
    }
}
</cfscript>


Inserts a new row into the users table.

Can be used for data migrations as well as schema changes.

🔹 Example 2 — Creating an index
<cfscript>
function up() {
    transaction {
        execute(sql="CREATE INDEX idx_users_email ON users(email)");
    }
}
</cfscript>


Adds an index on the email column of the users table.

🔹 Example 3 — Dropping a table
<cfscript>
function down() {
    transaction {
        execute(sql="DROP TABLE old_logs");
    }
}
</cfscript>


Executes raw SQL to remove a table.





















`````exists:
exists() checks whether a record exists in the database table associated with the model. It can check for a specific primary key, a condition (WHERE clause), or just verify if any record exists.

1. Check if a record exists with a WHERE clause
// Check if a user named Joe exists
result = model("user").exists(where="firstName = 'Joe'");

if(result) {
    writeOutput("Joe exists!");
} else {
    writeOutput("No Joe found.");
}

2. Check if a specific record exists using a primary key
// Primary key passed through URL/form
if(model("user").exists(key=params.key)) {
    writeOutput("The user exists!");
}

3. Scoped check for associations (belongsTo, hasOne, hasMany)
// belongsTo association example
comment = model("comment").findByKey(params.commentId);
commentHasAPost = comment.hasPost(); // internally calls exists on post

// hasOne association example
user = model("user").findByKey(params.userId);
userHasProfile = user.hasProfile(); // internally calls exists on profile

// hasMany association example
post = model("post").findByKey(params.postId);
postHasComments = post.hasComments(); // internally calls exists on comment
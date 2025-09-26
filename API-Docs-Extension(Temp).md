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

























`````fail:
Forces a test to fail intentionally.
You can call fail() inside a test when you want to:

Stop execution and explicitly mark the test as failed.

Highlight cases that should never happen.

Ensure unimplemented test logic is flagged until completed.

When called, it throws an exception that results in a test failure. You can optionally pass a custom message to clarify why the failure occurred.

1. Simple fail with no message
it("should fail on purpose", function() {
    fail();
});


👉 Marks the test as failed without explanation.

2. Fail with a custom message
it("should fail with a message", function() {
    fail("This path should never be reached!");
});


👉 Produces a failure with the message This path should never be reached!.

3. Guarding unexpected conditions
it("should not allow null users", function() {
    var user = getUserById(123);
    if (isNull(user)) {
        fail("Expected user with ID 123 to exist but got null.");
    }
});


👉 Test fails only if the condition is unexpected.

4. Marking incomplete tests (TDD style)
it("should calculate user score correctly", function() {
    fail("Not implemented yet");
});


👉 Ensures you don’t forget to implement this test later.

5. Fail inside a conditional branch
it("should only accept active users", function() {
    var user = createUser(isActive=false);
    
    if (!user.isActive) {
        fail("Inactive user slipped through validation.");
    }
});





















`````fileField:
Generates a file upload input (<input type="file">) tied to an object’s property.
It automatically integrates with Wheels’ form and validation system, including:

Using labels (before, after, or around the field).

Handling nested associations (hasMany / belongsTo).

Displaying validation errors with wrapping elements.

Allowing HTML attributes (e.g., class, id, rel).

This helper is most often used inside a formFor() block to ensu

1. Basic usage with a label
#fileField(label="Profile Picture", objectName="user", property="avatar")#


👉 Renders:

<label for="user-avatar">Profile Picture</label>
<input type="file" id="user-avatar" name="user[avatar]">

2. Adding custom attributes
#fileField(
    label="Upload Resume", 
    objectName="jobApplication", 
    property="resumeFile", 
    class="upload-input", 
    accept=".pdf,.docx"
)#


👉 Adds CSS class and restricts file types.

3. Custom label placement
#fileField(
    label="Select File", 
    objectName="document", 
    property="attachment", 
    labelPlacement="before"
)#


👉 Places label before the <input> instead of wrapping.

4. Prepending/Appending extra markup
#fileField(
    label="Photo", 
    objectName="gallery", 
    property="image", 
    prepend='<div class="field-wrapper">', 
    append='</div>'
)#


👉 Wraps the input in custom markup.

5. Nested association with hasMany
<fieldset>
    <legend>Screenshots</legend>
    <cfloop from="1" to="#ArrayLen(site.screenshots)#" index="i">
        #fileField(
            label="File ##i#", 
            objectName="site", 
            association="screenshots", 
            position=i, 
            property="file"
        )#
        #textField(
            label="Caption ##i#", 
            objectName="site", 
            association="screenshots", 
            position=i, 
            property="caption"
        )#
    </cfloop>
</fieldset>


























`````fileFieldTag:
Creates a file upload field (<input type="file">) using a supplied name.
This helper is lower-level than fileField() — it does not bind to a model object but still provides:

Optional label generation (before, after, or wrapping).

Easy customization with prepend / append.

Safe encoding to prevent XSS.

Pass-through for any additional HTML attributes (e.g., class, id, accept).

Useful when you want quick form fields without object binding.

1. Basic usage with label
#fileFieldTag(label="Upload Photo", name="photo")#


👉 Output:

<label for="photo">Upload Photo</label>
<input type="file" id="photo" name="photo">

2. With custom attributes
#fileFieldTag(
    label="Resume", 
    name="resume", 
    class="upload", 
    id="resume-upload", 
    accept=".pdf,.docx"
)#


👉 Adds CSS class, ID, and file type restrictions.

3. Label placement options
#fileFieldTag(label="Avatar", name="avatar", labelPlacement="before")#
#fileFieldTag(label="Attachment", name="attachment", labelPlacement="after")#


👉 Moves the label before or after the <input> instead of wrapping.

4. Prepending/Appending markup
#fileFieldTag(
    label="Select File", 
    name="document", 
    prepend='<div class="field-wrapper">', 
    append='</div>'
)#


👉 Wraps the input inside a custom <div>.

5. Label customization with prepend/append
#fileFieldTag(
    label="Profile Photo", 
    name="profile", 
    prependToLabel='<span class="required">*</span>', 
    appendToLabel=' <small>(max 2MB)</small>'
)#




















`````filterChain:
The filterChain() function returns an array of all filters that are set on the current controller in the order they will be executed. By default, it includes both before and after filters, but you can specify the type argument if you want to return only one type. For example, setting type="after" will return only the filters that run after the controller action.

1. Get the complete filter chain
// In a controller with both before and after filters
filters(through="requireLogin");
filters(through="logAction", type="after");

myFilterChain = filterChain();
// => ["requireLogin", "logAction"]

2. Only before filters
filters(through="authenticateUser");
filters(through="checkPermissions");
filters(through="cleanupSession", type="after");

beforeFilters = filterChain(type="before");
// => ["authenticateUser", "checkPermissions"]

3. Only after filters
filters(through="trackAnalytics", type="after");
filters(through="logPerformance", type="after");

afterFilters = filterChain(type="after");
// => ["trackAnalytics", "logPerformance"]

4. Mixed filters with execution order
filters(through="requireLogin");               // before
filters(through="checkSubscription");          // before
filters(through="auditTrail", type="after");   // after

writeDump(filterChain());
// => ["requireLogin", "checkSubscription", "auditTrail"]


👉 Shows how order is preserved: all before filters first, followed by after filters.

5. Using filterChain in debugging
// In ApplicationController.cfc
function debugFilters() {
    writeDump(var=filterChain(), label="Filter Chain for #getController()#");
}


👉 Useful for debugging which filters are active for a given controller.























`````filters:
The filters() function lets you specify methods in your controller that should run automatically either before or after certain actions. Filters are useful for handling cross-cutting concerns such as authentication, authorization, logging, or cleanup, without having to repeat the same code inside each action. By default, filters run before the action, but you can configure them to run after, limit them to specific actions, exclude them from others, or control their placement in the filter chain.

1. Run a filter before all actions
// Always execute restrictAccess before every action
filters("restrictAccess");

2. Multiple filters before all actions
// Run both isLoggedIn and checkIPAddress before all actions
filters(through="isLoggedIn, checkIPAddress");

3. Exclude specific actions
// Run filters before all actions, except home and login
filters(through="isLoggedIn, checkIPAddress", except="home, login");

4. Limit filters to specific actions
// Only run ensureAdmin before the delete action
filters(through="ensureAdmin", only="delete");

5. Run filters after an action
// Run logAction after every action
filters(through="logAction", type="after");





















`````findAll:
The findAll() function retrieves records from a model’s database table based on the conditions you provide. You can filter results using the where argument, order them with order, group them with group, or limit them with maxRows. For more advanced queries, you can include associations with include, return only certain columns with select, or even enable pagination using page and perPage. The results can be returned as a query, an array of objects, an array of structs, or just the SQL string itself (using the returnAs argument). This makes findAll() a flexible tool for fetching multiple records in different formats and contexts.

1. Get all users created recently (simple filter + order):

recentUsers = model("user").findAll(
    where="createdAt >= '2025-01-01'",
    order="createdAt DESC"
);


Fetches all users created since Jan 1st, ordered with the most recent first.

2. Limit results (top 5 users, random order):

fiveRandomUsers = model("user").findAll(
    maxRows=5,
    order="random"
);


Returns 5 random users.

3. Include associations (articles with their author):

articles = model("article").findAll(
    include="author",
    where="published=1",
    order="createdAt DESC"
);


Fetches published articles and also joins the related author records.

4. Paginated results (songs, page 2):

songs = model("song").findAll(
    include="album(artist)",
    page=2,
    perPage=25
);


Gets 25 songs for page 2 (records 26–50), including album and artist details.

5. Dynamic finder shortcut (books by year):

books = model("book").findAllByReleaseYear(params.year);


Equivalent to filtering with where="releaseYear=#params.year#".






















`````findAllKeys:
The findAllKeys() function retrieves all primary key values for a model’s records and returns them as a list. By default, the values are separated with commas, but you can change the delimiter with the delimiter argument or add single quotes around each value with the quoted argument. Since findAllKeys() accepts all arguments that findAll() does, you can also filter results with where, control ordering with order, or even include associations when filtering. This makes it useful when you need just the IDs of records without fetching full objects or rows.

1. Get all IDs for a model (basic usage):

artistIds = model("artist").findAllKeys();


Returns a comma-delimited list of all artist IDs.

2. Get active artist IDs with custom delimiter and quotes:

artistIds = model("artist").findAllKeys(
    quoted=true,
    delimiter="|",
    where="active=1"
);


Returns only active artist IDs, quoted and separated with |.

3. Limit results (top 10 user IDs):

userIds = model("user").findAllKeys(
    maxRows=10,
    order="createdAt DESC"
);


Returns the 10 most recently created user IDs.

4. Paginated IDs (books, second page):

bookIds = model("book").findAllKeys(
    page=2,
    perPage=20,
    order="title ASC"
);


Fetches IDs for books on page 2 (records 21–40), ordered alphabetically.

5. Grouped query with HAVING (order IDs by sales total):

orderIds = model("order").findAllKeys(
    group="productId",
    where="totalAmount > 500"
);


Returns order IDs for products that generated more than $500 in sales.























`````findByKey:
The findByKey() function retrieves a single record from the database using its primary key value and returns it as an object by default. If the record is not found, it returns false, making it easy to handle missing data gracefully. You can also control what columns are returned using the select argument, include related associations, or override the return format to a query, struct, or even raw SQL. Since it accepts the same options as other read functions like findOne(), you can apply caching, indexing, and even include soft-deleted records when needed.

1. Fetch a single record by ID (basic usage):

author = model("author").findByKey(99);


Returns the author with primary key 99 as an object.

2. Fetch a record dynamically (from form/URL param):

author = model("author").findByKey(params.key);
if (!isObject(author)) {
    flashInsert(message="Author #params.key# was not found");
    redirectTo(back=true);
}


Safely checks if the author exists before continuing.

3. Select only specific columns:

user = model("user").findByKey(42, select="firstName,lastName,email");


Fetches only the given fields for the user with ID 42.

4. Include associations (eager loading):

article = model("article").findByKey(
    params.articleId,
    include="author,comments"
);


Returns an article along with its associated author and comments in a single query.

5. Return as query instead of object:

productQuery = model("product").findByKey(
    10,
    returnAs="query"
);


Fetches the product record as a standard ColdFusion query result set.























`````findFirst:
The findFirst() function fetches the first record from the database table mapped to the model, ordered by the primary key value by default. You can customize the ordering by passing a property name through the property argument, which is also aliased as properties. This makes it useful when you want the "first" record based on a specific field (e.g., earliest created date, alphabetically first name, lowest price, etc.). The result is returned as a model object.

1. Get the first record by primary key (default behavior):

firstUser = model("user").findFirst();


Fetches the user with the lowest primary key value.

2. Get the first record alphabetically by name:

firstAuthor = model("author").findFirst(property="lastName");


Fetches the author with the alphabetically first last name.

3. Get the earliest created record (using a timestamp column):

firstArticle = model("article").findFirst(property="createdAt");


Fetches the oldest article based on creation date.

4. Get the cheapest product:

cheapestProduct = model("product").findFirst(property="price");


Fetches the product with the lowest price.

5. Use alias properties instead of property:

firstComment = model("comment").findFirst(properties="createdAt");


Works the same as property — useful when you prefer the plural alias.





















`````findLastOne:
The findLastOne() function fetches the last record from the database table mapped to the model, ordered by the primary key value by default. You can override this ordering by passing a property name through the property argument (also aliased as properties). This is useful when you want to retrieve the "last" record based on something other than the primary key, such as the most recently created entry, the highest price, or the latest updated timestamp. The result is returned as a model object. This function was formerly known as findLast.

1. Get the last record by primary key (default behavior):

lastUser = model("user").findLastOne();


Fetches the user with the highest primary key value.

2. Get the last record alphabetically by name:

lastAuthor = model("author").findLastOne(property="lastName");


Fetches the author with the alphabetically last last name.

3. Get the most recently created record:

lastArticle = model("article").findLastOne(property="createdAt");


Fetches the article with the latest creation date.

4. Get the most expensive product:

priciestProduct = model("product").findLastOne(property="price");


Fetches the product with the highest price.

5. Use alias properties instead of property:

lastComment = model("comment").findLastOne(properties="createdAt");


Works the same as property — useful when you prefer the plural alias.























`````findOne:
The findOne() function retrieves the first record that matches the given search criteria. By default, this is determined by the WHERE and ORDER BY clauses that you pass in. If no criteria are provided, Wheels will return the first record it finds in the table (ordered by the primary key unless otherwise specified). When returnAs is set to object (the default), the function will return a model object if a record is found, or false if no record matches the conditions. For cleaner and more expressive code, Wheels supports Dynamic Finders, which allow you to call findOneBy... methods instead of writing explicit where clauses. This function is commonly used when you need only a single record — for example, the latest order, the first matching user, or a related object via an association.

1. Get the most recent order:

order = model("order").findOne(order="datePurchased DESC");


Fetches the latest order based on the purchase date.

2. Use a dynamic finder to locate a user by last name:

person = model("user").findOneByLastName("Smith");


Equivalent to findOne(where="lastName='Smith'").

3. Use a dynamic finder with multiple conditions:

user = model("user").findOneByEmailAndPassword("someone@somewhere.com,mypass");


Equivalent to findOne(where="email='someone@somewhere.com' AND password='mypass'").

4. Use associations with scoped calls (hasOne):

user = model("user").findByKey(params.userId);
profile = user.profile();


Internally runs model("profile").findOne(where="userId=#user.id#").

5. Use associations with scoped calls (hasMany):

post = model("post").findByKey(params.postId);
comment = post.findOneComment(where="text='I Love Wheels!'");


Internally runs model("comment").findOne(where="postId=#post.id#").























`````flash:
The flash() function is used in controllers to access data stored in the Flash scope. Flash is a temporary storage mechanism that lets you persist values across the next request (often after a redirect). You can use it to retrieve a specific key or the entire Flash struct. If you pass in a key, it returns the value associated with it; if no key is passed, it returns all the Flash contents as a struct.

Examples
// Get a specific Flash value (commonly used for notifications or messages)
notice = flash("notice");

// Get another value stored in Flash, e.g., an error message
errorMsg = flash("error");

// Retrieve the entire Flash scope as a struct
allFlash = flash();

Example Usage in a Redirect Flow
// In one action: set a flash message before redirect
flashInsert(message="Profile updated successfully", key="notice");
redirectTo(action="show");

// In the redirected action: retrieve the message
notice = flash("notice"); // "Profile updated successfully"

Example with Conditional Check
if (structKeyExists(flash(), "error")) {
    writeOutput("Error: " & flash("error"));
}





















`````flashClear:
The flashClear() function removes all keys and values from the Flash scope. This is useful when you want to reset or clear out any temporary messages or data that were carried over from a previous request. After calling flashClear(), the Flash will be empty for the remainder of the request and any future requests until new values are inserted.

Examples
// Clear all flash values at the start of an action
flashClear();

// Example flow: clear messages after they've been displayed
notice = flash("notice");
if (len(notice)) {
    writeOutput(notice);
    flashClear(); // reset Flash so it doesn't show again
}

// Use before redirecting if you want to ensure no old flash values remain
flashClear();
redirectTo(action="index");





















`````flashCount:
The flashCount() function returns the number of keys currently stored in the Flash scope. This is useful to check whether there are any flash messages or temporary data before attempting to read or display them. It helps in conditionally rendering notifications or determining if the Flash is empty.

Examples
// Get the number of items in Flash
count = flashCount();

// Check if there are any flash messages before displaying
if (flashCount() > 0) {
    writeOutput("You have " & flashCount() & " messages in Flash.");
}

// Example flow: only display notice if Flash is not empty
if (flashCount() > 0 && structKeyExists(flash(), "notice")) {
    writeOutput(flash("notice"));
}




















`````flashDelete:
The flashDelete() function removes a specific key from the Flash scope. It is useful when you want to delete a particular temporary message or piece of data without clearing the entire Flash. The function returns true if the key existed and was deleted, or false if the key was not present.

Examples
// Delete a single flash message
flashDelete(key="errorMessage");

// Delete another key and check if it existed
if (flashDelete(key="notice")) {
    writeOutput("Notice deleted from Flash.");
} else {
    writeOutput("Notice key did not exist.");
}

// Conditional usage before displaying flash
if (structKeyExists(flash(), "warning")) {
    warningMsg = flash("warning");
    flashDelete(key="warning"); // remove after reading
    writeOutput(warningMsg);
}





















`````flashInsert:
The flashInsert() function adds a new key-value pair to the Flash scope. This is useful for storing temporary messages or data that you want to persist across the next request, typically after a redirect. You can insert any type of value, such as strings, numbers, or structs, and later retrieve it using flash().

Examples
// Insert a simple flash message
flashInsert(msg="It Worked!");

// Insert multiple types of data
flashInsert(userId=123);
flashInsert(errorMessage="Something went wrong");

// Typical usage: insert a message before redirecting
flashInsert(notice="Profile updated successfully");
redirectTo(action="show");

// Insert a structured value
flashInsert(userStruct={id=42, name="Alice"});



















`````flashIsEmpty:
The flashIsEmpty() function checks whether the Flash scope contains any keys. It returns true if the Flash is empty and false if it contains one or more keys. This is useful for conditionally displaying messages or deciding whether to process Flash data before reading or clearing it.

Examples
// Check if the Flash is empty
if (flashIsEmpty()) {
    writeOutput("No messages to display.");
} else {
    writeOutput("There are messages in Flash.");
}

// Use before reading a specific key
if (!flashIsEmpty() && structKeyExists(flash(), "notice")) {
    writeOutput(flash("notice"));
}

// Typical flow: after clearing Flash
flashClear();
writeOutput(flashIsEmpty()); // true






















`````flashKeep:
The flashKeep() function allows you to preserve Flash data for one additional request. By default, Flash values are only available for the very next request; calling flashKeep() prevents them from being cleared after the current request. You can choose to keep the entire Flash or only specific keys. This is useful when you want messages or temporary data to persist through multiple redirects or page loads.

Examples
// Keep the entire Flash for the next request
flashKeep();

// Keep a specific key, e.g., "error"
flashKeep("error");

// Keep multiple keys, e.g., "error" and "success"
flashKeep("error,success");

// Typical usage: keep a flash message after a redirect chain
flashInsert(notice="Profile saved successfully");
flashKeep("notice");
redirectTo(action="nextStep");





















`````flashKeyExists:
The flashKeyExists() function checks whether a specific key is present in the Flash scope. It returns true if the key exists and false if it does not. This is useful for conditionally displaying or processing Flash messages or data before attempting to read them.

Examples
// Check if the "error" key exists
errorExists = flashKeyExists("error");

// Conditional display based on key existence
if (flashKeyExists("notice")) {
    writeOutput(flash("notice"));
}

// Example usage in a form flow
if (flashKeyExists("validationErrors")) {
    errors = flash("validationErrors");
    // Process or display errors
}



















`````flashMessages:
The flashMessages() function generates a formatted HTML output of messages stored in the Flash scope. It is typically used in views or layouts to display temporary notifications like success messages, alerts, or errors. You can choose to display all messages, a specific key, or multiple keys in a defined order. Additional options let you customize the container’s HTML class, include an empty container if no messages exist, and control whether the message content is URL-encoded.

Examples
// Insert messages into the Flash in a controller
flashInsert(success="Your post was successfully submitted.");
flashInsert(alert="Don't forget to tweet about this post!");
flashInsert(error="This is an error message.");

<!--- In the layout or view, show all messages --->
#flashMessages()#
/* Generates:
<div class="flashMessages">
    <p class="alertMessage">Don't forget to tweet about this post!</p>
    <p class="errorMessage">This is an error message.</p>
    <p class="successMessage">Your post was successfully submitted.</p>
</div>
*/

// Show only the "success" message
#flashMessages(key="success")#
/* Generates:
<div class="flashMessage">
    <p class="successMessage">Your post was successfully submitted.</p>
</div>
*/

// Show both "success" and "alert" messages in that order
#flashMessages(keys="success,alert")#
/* Generates:
<div class="flashMessages">
    <p class="successMessage">Your post was successfully submitted.</p>
    <p class="alertMessage">Don't forget to tweet about this post!</p>
</div>
*/


















`````float:
The float() function is used in a table definition during a migration to add one or more float-type columns to a database table. You can specify column names, default values, and whether the columns allow NULL. This helps define numeric columns with decimal values in your schema.

Examples
// Basic usage: add a single float column
table.float("price");

// Add multiple float columns at once
table.float("length,width,height");

// Add a float column with a default value
table.float("discount", default="0.0");

// Add a float column that cannot be null
table.float("taxRate", null=false);

// Add multiple float columns with defaults
table.float("latitude,longitude", default="0.0");

// Combine default value and null constraint
table.float("weight", default="1.0", null=false);





















`````get:
The get() function defines a route that only responds to HTTP GET requests. This is typically used for actions that display data, like listing resources or showing a single record. You can configure the route’s URL pattern, the controller and action it maps to, and optionally a name, package, or nested scope. It is recommended to only use get() for retrieving data; for routes that modify data, use post(), put(), patch(), or delete().

Examples
<cfscript>
mapper()
    // Basic GET route using "to"
    .get(name="post", pattern="posts/[slug]", to="posts##show")

    // GET route using controller and action separately
    .get(name="posts", controller="posts", action="index")

    // Custom URL pattern
    .get(name="authors", pattern="the-scribes", to="authors##index")

    // Namespaced controller
    .get(name="cart", to="carts##show", package="commerce")

    // Nested GET route within another package
    .get(name="editProfile", pattern="profile/edit", to="profiles##edit", package="extranet")

    // Nested resource routes
    .resources(name="users", nested=true)
        // Collection route (no ID in URL)
        .get(name="activated", to="users##activated", on="collection")
        // Member route (includes resource ID)
        .get(name="preferences", to="preferences##index", on="member")
    .end()
.end();
</cfscript>
























`````get:
The get() function returns the current value of a Wheels configuration setting or the default value for a specific function argument. It can be used to inspect global Wheels settings (like table name prefixes, pagination defaults, or other configuration values) or to check what the default argument would be for a particular Wheels function.

Examples
// Get the current value of a global Wheels setting
tablePrefix = get("tableNamePrefix");

// Get the default message for the `validatesConfirmationOf` function
confirmationMessageDefault = get(functionName="validatesConfirmationOf", name="message");

// Check the default value for the "null" argument in migrations
allowNullDefault = get(functionName="float", name="null");

// Retrieve the current default number of rows per page in pagination
perPageDefault = get("perPage");






















`````getAvailableMigrations:
The getAvailableMigrations() function scans the migration folder (by default /migrator/migrations/) and returns an array of all migration files it finds. Each item in the array contains information about the migration, including its version. While this function can be called from within your application, it is primarily intended for use via the Wheels CLI or GUI tools. It is useful for programmatically determining which migrations are available and what the latest migration version is.

Examples
// Get all available migrations in the default folder
migrations = application.wheels.migrator.getAvailableMigrations();

// Determine the latest migration version
if (ArrayLen(migrations)) {
    latestVersion = migrations[ArrayLen(migrations)].version;
} else {
    latestVersion = 0;
}

// Get available migrations from a custom folder
customMigrations = application.wheels.migrator.getAvailableMigrations(path="/custom/migrations");

// Loop through migrations and display their versions
for (var m in migrations) {
    writeOutput("Migration version: " & m.version & "<br>");
}




















`````getCurrentMigrationVersion:
The getCurrentMigrationVersion() function returns the version number of the latest migration that has been applied to the database. This is useful for determining the current schema state programmatically, though it is primarily intended for use via the Wheels CLI or GUI interface. You can use this function within your application to perform conditional logic based on the database version or to verify that the database is up-to-date.

Examples
// Get the current database migration version
currentVersion = application.wheels.migrator.getCurrentMigrationVersion();
writeOutput("Current DB version: " & currentVersion);

// Compare with the latest available migration version
migrations = application.wheels.migrator.getAvailableMigrations();
if (ArrayLen(migrations)) {
    latestVersion = migrations[ArrayLen(migrations)].version;
    if (currentVersion LT latestVersion) {
        writeOutput("Database is behind the latest migration.");
    } else {
        writeOutput("Database is up-to-date.");
    }
}

// Conditional logic based on migration version
if (currentVersion EQ "2023091501") {
    // perform tasks specific to this version
}



















`````getEmails:
The getEmails() function is primarily used in testing scenarios to retrieve information about the emails that were sent during the current request. It returns an array containing details of all sent emails, which allows you to verify the content, recipients, and other properties of the emails in your automated tests. This is especially useful for unit or functional tests where you want to assert that specific emails are being triggered by certain actions without actually sending them.

// Get all emails sent during the current request
emails = getEmails();

// Check if an email was sent to a specific recipient
for (var email in emails) {
    if (email.to EQ "user@example.com") {
        writeOutput("Email sent to user@example.com<br>");
    }
}

// Verify the subject of the last sent email
lastEmail = emails[ArrayLen(emails)];
writeOutput("Last email subject: " & lastEmail.subject);

// In a test case, assert that an email was sent
assertTrue(arrayLen(emails) GT 0, "No emails were sent during this request.");
assertEquals(lastEmail.to, "user@example.com", "Email recipient does not match expected value.");























`````getFiles:
The getFiles() function is primarily used in testing scenarios to retrieve information about files sent during the current request. It returns an array containing details of all files handled in the request, such as uploaded attachments or generated files. This allows you to inspect and verify file-related operations in automated tests without needing to access the file system directly.

// Get all files sent during the current request
files = getFiles();

// Check if a specific file was sent
for (var file in files) {
    if (file.name EQ "report.pdf") {
        writeOutput("File 'report.pdf' was sent.<br>");
    }
}

// Inspect properties of the last file sent
lastFile = files[ArrayLen(files)];
writeOutput("Last file name: " & lastFile.name);
writeOutput("Last file size: " & lastFile.size);

// In a test case, assert that at least one file was sent
assertTrue(arrayLen(files) GT 0, "No files were sent during this request.");
assertEquals(lastFile.name, "report.pdf", "Last file sent does not match expected file.");























`````getRedirect:
The getRedirect() function is primarily used in testing scenarios to determine whether the current request has performed a redirect. It returns a structure containing information about the redirect, such as the target URL and the HTTP status code. This allows you to verify redirect behavior in automated tests without actually sending the user to another page.

// Get redirect information for the current request
redirectInfo = getRedirect();

// Check if a redirect occurred
if (structKeyExists(redirectInfo, "url")) {
    writeOutput("Redirected to: " & redirectInfo.url);
    writeOutput("HTTP status: " & redirectInfo.status);
} else {
    writeOutput("No redirect occurred.");
}

// In a test case, assert that a redirect happened
assertTrue(structKeyExists(redirectInfo, "url"), "Expected a redirect but none occurred.");
assertEquals(redirectInfo.url, "/login", "Redirect URL does not match expected URL.");





















`````getRoutes:
The getRoutes() function returns all the routes that have been defined in the application via the mapper() function. It provides a programmatic way to inspect the routing table, including route names, URL patterns, controllers, actions, and other metadata. This is useful for debugging, generating dynamic links, or performing logic based on the routes that exist in your application.

// Get all defined routes
allRoutes = getRoutes();

// Loop through routes and display their patterns
for (var r in allRoutes) {
    writeOutput("Route name: " & r.name & "<br>");
    writeOutput("Pattern: " & r.pattern & "<br>");
    writeOutput("Controller: " & r.controller & "<br>");
    writeOutput("Action: " & r.action & "<br><br>");
}

// Get a specific route by name
postRoute = allRoutes["post"];
writeOutput("Post route URL pattern: " & postRoute.pattern);

// Debugging: list all routes in JSON format
writeOutput(serializeJson(allRoutes));
























`````getTableNamePrefix:
The getTableNamePrefix() function returns the table name prefix that is set for the current model. This is useful when your database tables share a common prefix, and you need to construct queries dynamically or perform operations that require the full table name. By using this function, you ensure consistency and avoid hardcoding table prefixes in your queries.

// Get the table name prefix for the current model
prefix = model("user").getTableNamePrefix();
writeOutput("Table prefix: " & prefix);

// Use the table prefix in a custom query
<cffunction name="getDisabledUsers" returntype="query">
    <cfquery datasource="#get('dataSourceName')#" name="local.disabledUsers">
        SELECT *
        FROM #model("user").getTableNamePrefix()#users
        WHERE disabled = 1
    </cfquery>
    <cfreturn local.disabledUsers>
</cffunction>

// Another example: dynamically construct table name
tableName = model("order").getTableNamePrefix() & "orders";
writeOutput("Full table name: " & tableName);
























`````globalHelperFunction:
Remove this function as it is only an asset function in the core tests.





























`````hasChanged:
The hasChanged() function checks whether a property (or any property if none is specified) on a model object has been modified since it was last loaded from the database. It returns true if the property has been changed but not yet saved, or if the object is new and does not yet exist in the database. This is useful for detecting unsaved changes and conditionally performing logic before persisting the object.

// Get a member object and change the email property
member = model("member").findByKey(params.memberId);
member.email = params.newEmail;

// Check if the email property has changed
if (member.hasChanged("email")) {
    writeOutput("Email has changed. Updating database...");
}

// Check if any property has changed
if (member.hasChanged()) {
    writeOutput("There are unsaved changes in this member object.");
}

// Using a dynamic helper function
if (member.emailHasChanged()) {
    writeOutput("Email was modified using the dynamic helper method.");
}

// New object example
newMember = model("member").init();
newMember.firstName = "Alice";
if (newMember.hasChanged()) {
    writeOutput("This is a new member and changes exist that are not yet saved.");
}
























`````hasErrors:
The hasErrors() function checks whether a model object has any validation or other errors. It returns true if the object contains errors, or if a specific property or named error is provided, it checks only that subset. This is useful for validating objects before saving them to the database or displaying error messages to the user.

// Get a post object
post = model("post").findByKey(params.postId);

// Check if the object has any errors
if (post.hasErrors()) {
    writeOutput("There are errors. Redirecting to the edit form...");
    redirectTo(action="edit", id=post.id);
}

// Check if a specific property has errors
if (post.hasErrors("title")) {
    writeOutput("The title field contains errors.");
}

// Check if a specific named error exists
if (post.hasErrors(name="requiredTitle")) {
    writeOutput("The post is missing a required title.");
}

// Conditional save only if no errors exist
if (!post.hasErrors()) {
    post.save();
    writeOutput("Post saved successfully.");
}




















`````hasMany:
The hasMany() function sets up a one-to-many association between the current model and another model. This allows you to easily fetch, join, and manage related records in a relational way while following Wheels conventions.

// Basic one-to-many association
// A Post has many Comments
hasMany("comments");

// Specifying a shortcut for a many-to-many relationship
// A Reader has many Subscriptions and a shortcut to Publications
hasMany(name="subscriptions", shortcut="publications");

// Dependent delete: remove all associated comments when the post is deleted
hasMany(name="comments", dependent="deleteAll");

// Non-conventional shortcut through associations
// In models/Customer.cfc
hasMany(name="subscriptions", shortcut="magazines", through="publication,subscriptions");

// In models/Subscription.cfc
belongsTo("customer");
belongsTo("publication");

// In models/Publication.cfc
hasMany("subscriptions");























`````hasManyCheckBox:
The hasManyCheckBox() helper generates the correct form elements for managing a hasMany or many-to-many association. It creates checkboxes for linking records together (e.g., a Book with many Authors).

You can also pass styling, labels, wrappers, and error handling arguments to customize the output.

1. Basic usage (Books → Authors)

Loop through all authors and render checkboxes for associating them with the current book.

<cfloop query="authors">
    #hasManyCheckBox(
        objectName="book",
        association="bookAuthors",
        keys="#book.key()#,#authors.id#",
        label=authors.fullName
    )#
</cfloop>

2. Custom label placement

Place the label after the checkbox instead of before.

<cfloop query="categories">
    #hasManyCheckBox(
        objectName="post",
        association="postCategories",
        keys="#post.key()#,#categories.id#",
        label=categories.name,
        labelPlacement="after"
    )#
</cfloop>

3. Wrapping checkboxes in extra HTML (prepend/append)

Use prepend and append to wrap checkboxes in a <div> with a custom class.

<cfloop query="tags">
    #hasManyCheckBox(
        objectName="article",
        association="articleTags",
        keys="#article.key()#,#tags.id#",
        label=tags.name,
        prepend='<div class="tag-option">',
        append='</div>'
    )#
</cfloop>

4. Styling error states

Highlight checkboxes when validation fails (e.g., at least one must be selected).

<cfloop query="roles">
    #hasManyCheckBox(
        objectName="user",
        association="userRoles",
        keys="#user.key()#,#roles.id#",
        label=roles.name,
        errorElement="span",
        errorClass="error-highlight"
    )#
</cfloop>

5. Nested associations with shortcuts

When you have a many-to-many shortcut (e.g., Student → Courses through Enrollments).

<cfloop query="courses">
    #hasManyCheckBox(
        objectName="student",
        association="enrollments",
        keys="#student.key()#,#courses.id#",
        label=courses.title
    )#
</cfloop>
























`````hasManyRadioButton:
This helper generates radio buttons for managing a hasMany or one-to-many association, where you want the user to pick one option (e.g., default address, primary contact method, preferred category).

1. Basic usage (Author → Default Address)

Pick one address as the author’s default.

<cfloop query="addresses">
    #hasManyRadioButton(
        objectName="author",
        association="authorsDefaultAddresses",
        property="defaultAddressId",
        keys="#author.key()#,#addresses.id#",
        tagValue="#addresses.id#",
        label=addresses.title
    )#
</cfloop>

2. Pre-check default radio if property is blank

If no address is selected yet, pre-check the "Home" option.

<cfloop query="addresses">
    #hasManyRadioButton(
        objectName="author",
        association="authorsDefaultAddresses",
        property="defaultAddressId",
        keys="#author.key()#,#addresses.id#",
        tagValue="#addresses.id#",
        label=addresses.title,
        checkIfBlank=(addresses.title EQ "Home")
    )#
</cfloop>

3. Style with extra HTML attributes

Add class and id for custom styling.

<cfloop query="paymentMethods">
    #hasManyRadioButton(
        objectName="user",
        association="userPaymentMethods",
        property="defaultPaymentMethodId",
        keys="#user.key()#,#paymentMethods.id#",
        tagValue="#paymentMethods.id#",
        label=paymentMethods.name,
        class="radio-option",
        id="paymentMethod_#paymentMethods.id#"
    )#
</cfloop>

4. Radio buttons for selecting preferred language

Force one choice for localization settings.

<cfloop query="languages">
    #hasManyRadioButton(
        objectName="profile",
        association="profileLanguages",
        property="preferredLanguageId",
        keys="#profile.key()#,#languages.id#",
        tagValue="#languages.id#",
        label=languages.name
    )#
</cfloop>

5. Inline labels with icons

Add icons to labels with HTML.

<cfloop query="themes">
    #hasManyRadioButton(
        objectName="account",
        association="accountThemes",
        property="themeId",
        keys="#account.key()#,#themes.id#",
        tagValue="#themes.id#",
        label='<i class="fa fa-paint-brush"></i> #themes.displayName#',
        encode=false
    )#
</cfloop>
























`````hasOne:
The hasOne() function defines a one-to-one relationship between two models.
It means each instance of this model is linked to exactly one record in another model.
By default, Wheels infers table and key names, but you can customize them with arguments like foreignKey, joinKey, and joinType.

1. Basic one-to-one association

A User has one Profile.
The profiles table has userId as the foreign key.

// In models/User.cfc
hasOne("profile");


Usage:

user = model("user").findByKey(1);
profile = user.profile; // fetches the profile linked to the user

2. Strict inner join

Force that every Employee must have one PayrollRecord.

// In models/Employee.cfc
hasOne(name="payrollRecord", joinType="inner");


If there is no matching payrollRecord, the employee will not appear in queries using this association.

3. Auto-delete dependent record

Delete the Profile when the User is deleted.

// In models/User.cfc
hasOne(name="profile", dependent="delete");


Usage:

user = model("user").findByKey(2);
user.delete(); // also deletes the associated profile

4. Custom foreign key

If the foreign key doesn’t follow Wheels’ naming conventions.
For example, Driver has one License, but the foreign key column is driver_ref.

// In models/Driver.cfc
hasOne(name="license", foreignKey="driver_ref");

5. Using joinKey for non-standard PK

If the Company table uses companyCode instead of id as the primary key, and the Address table has companyCode as the foreign key:

// In models/Company.cfc
hasOne(name="address", joinKey="companyCode");




























`````hasProperty:
The hasProperty() function checks if a given property exists on a model object.
It’s useful for safely validating whether a field is defined before accessing it, especially in dynamic code or when working with user input.

This method also provides dynamic helpers (e.g., object.hasEmail()) for convenience.

1. Basic usage with existing property
employee = model("employee").new();
employee.firstName = "Alice";

writeOutput(employee.hasProperty("firstName")); // true

2. Checking a property that does not exist
employee = model("employee").new();

writeOutput(employee.hasProperty("middleName")); // false

3. Using the dynamic helper
employee = model("employee").new();
employee.email = "alice@example.com";

// Equivalent to hasProperty("email")
if (employee.hasEmail()) {
    writeOutput("Email property exists!");
}

4. Before using a property safely
user = model("user").findByKey(1);

// Avoid runtime errors by checking
if (user.hasProperty("phoneNumber")) {
    writeOutput(user.phoneNumber);
} else {
    writeOutput("No phone number property defined.");
}

5. Iterating over user input safely
formFields = ["firstName", "lastName", "unknownField"];
employee = model("employee").new();

for (field in formFields) {
    if (employee.hasProperty(field)) {
        writeOutput("Property exists: #field#<br>");
    } else {
        writeOutput("Invalid property: #field#<br>");
    }
}
























`````hiddenField:
The hiddenField() function generates a hidden <input type="hidden"> tag for a given model object and property.
It’s commonly used to store identifiers or other values that need to persist across form submissions without being visible to the user.

You can also pass extra HTML attributes such as id, class, or rel for customization.

1. Basic usage with object and property
<!--- Hidden field for user.id --->
#hiddenField(objectName="user", property="id")#


Generates something like:

<input id="user-id" name="user.id" type="hidden" value="123">

2. Adding extra HTML attributes
#hiddenField(
    objectName="user",
    property="sessionToken",
    id="custom-token",
    class="hidden-tracker"
)#

<input id="custom-token" name="user.sessionToken" type="hidden" value="abc123" class="hidden-tracker">

3. Nested association (hasOne or belongsTo)
#hiddenField(
    objectName="order",
    property="id",
    association="customer"
)#


If an order has a customer, this binds the hidden field to order.customer.id.

4. Nested hasMany with position
#hiddenField(
    objectName="order",
    property="id",
    association="items",
    position="1"
)#


Binds to the id of the second item in the order’s items collection.

5. Explicitly disabling encoding
#hiddenField(
    objectName="search",
    property="redirectUrl",
    encode=false
)#


Useful if you’re storing raw values (e.g., URLs) that shouldn’t be URL-encoded.



























`````hiddenFieldTag:
The hiddenFieldTag() function generates a hidden <input type="hidden"> tag using a plain name/value pair.
Unlike hiddenField(), this helper does not tie to a model object — it’s meant for raw form fields where you control the name and value manually.

You can also pass extra attributes (id, class, rel, etc.), which will be included in the generated HTML tag.

1. Basic usage
#hiddenFieldTag(name="userId", value=user.id)#


Generates:

<input id="userId" name="userId" type="hidden" value="123">

2. With additional attributes
#hiddenFieldTag(
    name="sessionToken",
    value="abc123",
    id="token-field",
    class="hidden-tracker"
)#

<input id="token-field" name="sessionToken" type="hidden" value="abc123" class="hidden-tracker">

3. Without specifying a value (empty by default)
#hiddenFieldTag(name="csrfToken")#

<input id="csrfToken" name="csrfToken" type="hidden" value="">

4. Disabling encoding
#hiddenFieldTag(
    name="redirectUrl",
    value="https://example.com/?a=1&b=2",
    encode=false
)#

<input id="redirectUrl" name="redirectUrl" type="hidden" value="https://example.com/?a=1&b=2">

5. Inside a form
#startFormTag(action="processLogin")#
    #hiddenFieldTag(name="returnTo", value="/dashboard")#
    <input type="text" name="username">
    <input type="password" name="password">
    <input type="submit" value="Login">
#endFormTag()#


Ensures the returnTo value is silently submitted along with the login form.




























`````highlight:
The highlight() helper searches the given text for one or more phrases and wraps all matches in an HTML tag (default: <span>). This is useful for search results or emphasizing certain keywords dynamically.

1. Basic usage (default <span class="highlight">)
#highlight(text="You searched for: Wheels", phrases="Wheels")#


Output:

You searched for: <span class="highlight">Wheels</span>

2. Highlight multiple phrases
#highlight(
    text="ColdFusion and Wheels make development fun.",
    phrases="ColdFusion,Wheels"
)#


Output:

<span class="highlight">ColdFusion</span> and <span class="highlight">Wheels</span> make development fun.

3. Use a custom delimiter for multiple phrases
#highlight(
    text="Apples | Oranges | Bananas",
    phrases="Apples|Bananas",
    delimiter="|"
)#


Output:

<span class="highlight">Apples</span> | Oranges | <span class="highlight">Bananas</span>

4. Use a different HTML tag
#highlight(
    text="Important: Read the documentation carefully.",
    phrases="Important",
    tag="strong"
)#


Output:

<strong class="highlight">Important</strong>: Read the documentation carefully.

5. Custom CSS class
#highlight(
    text="This is critical information.",
    phrases="critical",
    class="alert-text"
)#


Output:

This is <span class="alert-text">critical</span> information.

























`````hourSelectTag:
Builds and returns a <select> form control for choosing an hour of the day. By default, hours are shown in 24-hour format (00–23), but you can switch to 12-hour format with an accompanying AM/PM dropdown.

1. Basic 24-hour select
#hourSelectTag(name="meetingHour")#


Output (simplified):

<select name="meetingHour">
  <option value="00">00</option>
  <option value="01">01</option>
  ...
  <option value="23">23</option>
</select>

2. Pre-select an hour
#hourSelectTag(name="meetingHour", selected="14")#


Output (simplified):

<option value="14" selected="selected">14</option>

3. Include a blank option
#hourSelectTag(name="meetingHour", includeBlank="- Select Hour -")#


Output (simplified):

<option value="">- Select Hour -</option>
<option value="00">00</option>
...

4. Use 12-hour format with AM/PM
#hourSelectTag(name="meetingHour", twelveHour=true, selected="3")#


Output (simplified):

<select name="meetingHour">
  <option value="01">01</option>
  <option value="02">02</option>
  <option value="03" selected="selected">03</option>
  ...
  <option value="12">12</option>
</select>

<select name="meetingHourMeridian">
  <option value="AM">AM</option>
  <option value="PM">PM</option>
</select>

5. Add a label before the field
#hourSelectTag(name="meetingHour", label="Select Hour", labelPlacement="before")#


Output (simplified):

<label for="meetingHour">Select Hour</label>
<select name="meetingHour">...</select>


























`````humanize:
Converts a camel-cased or underscored string into more readable, human-friendly text by inserting spaces and capitalizing words. You can also specify words that should be replaced or kept in a specific format.

1. Basic camelCase conversion
#humanize("wheelsIsAFramework")#


Output:

Wheels Is A Framework

2. Handle acronyms with except
#humanize("wheelsIsACfmlFramework", "CFML")#


Output:

Wheels Is A CFML Framework

3. Underscore-separated strings
#humanize("user_profile_settings")#


Output:

User Profile Settings

4. PascalCase strings
#humanize("ThisIsPascalCase")#


Output:

This Is Pascal Case

5. Multiple exceptions
#humanize("apiResponseForJsonAndXml", "API JSON XML")#


Output:

API Response For JSON And XML



























`````hyphenize:
Converts camelCase or PascalCase strings into lowercase hyphen-separated strings.
Useful for generating URL-friendly slugs, CSS class names, or readable identifiers.

1. Basic camelCase string
#hyphenize("myBlogPost")#


Output:

my-blog-post

2. PascalCase string
#hyphenize("UserProfileSettings")#


Output:

user-profile-settings

3. Single word (no change)
#hyphenize("Dashboard")#


Output:

dashboard

4. Already hyphenated string (stays lowercase)
#hyphenize("already-hyphenized")#


Output:

already-hyphenized

5. Underscore-separated string
#hyphenize("user_profile_settings")#


Output:

user-profile-settings


























`````imageTag:
Generates an HTML <img> tag.

If the image exists in the local images folder, Wheels will automatically include width, height, and alt attributes.

If the image is remote (full URL provided), Wheels uses the given path as-is.

Any extra arguments (e.g. class, id, data-*) will be added as HTML attributes.

1. Basic usage (local image)
#imageTag("logo.png")#


Output:

<img src="/images/logo.png" alt="Logo" width="120" height="40">


(Width, height, and alt are auto-detected if the file exists locally.)

2. Remote image with custom alt text
#imageTag(source="http://cfwheels.org/images/logo.png", alt="ColdFusion on Wheels")#


Output:

<img src="http://cfwheels.org/images/logo.png" alt="ColdFusion on Wheels">

3. Adding CSS classes
#imageTag(source="logo.png", class="brand-logo")#


Output:

<img src="/images/logo.png" alt="Logo" width="120" height="40" class="brand-logo">

4. With explicit host and protocol
#imageTag(source="logo.png", onlyPath=false, host="cdn.myapp.com", protocol="https")#


Output:

<img src="https://cdn.myapp.com/images/logo.png" alt="Logo" width="120" height="40">

5. Custom HTML attributes (data attribute, id)
#imageTag(source="avatar.png", id="userAvatar", data-userid="42")#


Output:

<img src="/images/avatar.png" alt="Avatar" width="80" height="80" id="userAvatar" data-userid="42">


























`````includeContent:
Outputs the content for a specific section in a layout.

Works together with contentFor() to define and then inject content into layouts.

Typically used for head, sidebar, footer, or other pluggable layout sections.

If the requested section hasn’t been defined, it will either return nothing or the provided defaultValue.

1. Basic usage with contentFor() in a view
<!--- views/blog/post.cfm --->
<cfoutput>
    <h1>#post.title#</h1>
    <p>#post.body#</p>
    <!--- Define extra metadata for the layout --->
    #contentFor(head='<meta name="robots" content="noindex,nofollow">')#
</cfoutput>

<!--- views/layout.cfm --->
<html>
  <head>
    <title>My Blog</title>
    #includeContent("head")#
  </head>
  <body>
    #includeContent()#
  </body>
</html>


Result:

The <meta> tag is injected into the <head> of the layout.

The body content is output where #includeContent()# appears.

2. Multiple contentFor() definitions for the same section
<!--- views/blog/post.cfm --->
#contentFor(head='<meta name="robots" content="noindex,nofollow">')#
#contentFor(head='<meta name="author" content="wheelsdude@wheelsify.com">')#

<!--- layout --->
<head>
  <title>My Blog</title>
  #includeContent("head")#
</head>


Result:

<head>
  <title>My Blog</title>
  <meta name="robots" content="noindex,nofollow">
  <meta name="author" content="wheelsdude@wheelsify.com">
</head>

3. Using defaultValue when section is not defined
<!--- layout --->
<head>
  <title>My Blog</title>
  #includeContent(name="head", defaultValue="<meta name='description' content='Default description'>")#
</head>


If no view sets contentFor("head"), the layout will output:

<meta name='description' content='Default description'>

4. Custom sections (sidebar)
<!--- views/blog/post.cfm --->
#contentFor(sidebar='<p>Related Posts:</p><ul><li>Another post</li></ul>')#

<!--- layout --->
<body>
  <main>
    #includeContent()#
  </main>
  <aside>
    #includeContent("sidebar", defaultValue="<p>No related posts</p>")#
  </aside>
</body>


Result:

If a sidebar is defined, it’s shown.

If not, the fallback text appears.

5. Nested layout usage

If you’re using multiple layouts, includeContent() can bubble up content defined in views to the correct parent layout section.

<!--- child layout --->
<div class="page">
  #includeContent()#
</div>

<!--- parent layout --->
<html>
  <head>
    <title>Nested Layout Example</title>
    #includeContent("head")#
  </head>
  <body>
    #includeContent()#
  </body>
</html>


























`````includedInObject:
Checks if the specified IDs are part of a hasMany association on the given parent object.

Useful in forms or conditionals when you need to determine if an associated record already exists.

Works by comparing the given keys against the parent’s association join records.

The order of keys must match the database column order in the join table.

1. Basic subscription check (join table)
// Check if the customer is subscribed to the Swimsuit Edition
if (!includedInObject(
    objectName="customer",
    association="subscriptions",
    keys="#customer.key()#,#swimsuitEdition.id#"
)) {
    assignSalesman(customer);
}


Use case: Before assigning a salesman, confirm that the customer isn’t already subscribed.

2. Pre-checking a checkbox in a form
<!--- views/customers/edit.cfm --->
<cfoutput>
  <label>
    <input type="checkbox" 
           name="customer[subscriptionIds]" 
           value="#magazine.id#" 
           <cfif includedInObject(objectName="customer", association="subscriptions", keys="#customer.id#,#magazine.id#")>checked</cfif>> 
    #magazine.title#
  </label>
</cfoutput>


Use case: Automatically check boxes for subscriptions the customer already has.

3. Handling many-to-many relationships (tags example)
<!--- views/posts/_form.cfm --->
<cfloop array="#allTags#" index="tag">
  <label>
    <input type="checkbox" 
           name="post[tagIds]" 
           value="#tag.id#" 
           <cfif includedInObject(objectName="post", association="tags", keys="#post.id#,#tag.id#")>checked</cfif>> 
    #tag.name#
  </label>
</cfloop>


Use case: In a blog post form, show all available tags and pre-check the ones already linked to the post.

4. Custom business logic (prevent duplicate assignment)
// Only assign mentor if the student isn't already enrolled in the course
if (!includedInObject(
    objectName="student",
    association="courses",
    keys="#student.id#,#course.id#"
)) {
    student.assignMentor(mentor);
}


Use case: Prevents duplicate course enrollment.

5. Nested forms with hasMany association
<!--- views/orders/_form.cfm --->
<cfloop array="#products#" index="product">
  <label>
    <input type="checkbox" 
           name="order[productIds]" 
           value="#product.id#" 
           <cfif includedInObject(objectName="order", association="products", keys="#order.id#,#product.id#")>checked</cfif>> 
    #product.name#
  </label>
</cfloop>


Use case: Editing an order while automatically reflecting products already linked to it.




























`````includeLayout:
Includes the contents of another layout file. Typically used when a child layout wants to include a parent layout, or to nest layouts for consistent site structure.

Basic Example

Include a parent layout from within a child layout:

<!--- In a child layout, e.g., views/layouts/admin.cfm --->
<cfsavecontent variable="sidebarContent">
    <ul>
        #includePartial("adminSidebar")#
    </ul>
</cfsavecontent>

<!--- Pass content to the layout --->
contentFor(sidebar=sidebarContent);

<!--- Include the main site layout --->
#includeLayout("/layout.cfm")#


Explanation:

cfsavecontent captures content into a variable.

contentFor maps that content to a named section in the layout.

includeLayout then renders the parent layout, which can include #includeContent("sidebar")# to output the child-provided content.

Example with Default Layout
<!--- Child layout does not specify a layout, so it uses the default --->
#includeLayout()#


Explanation:

If no name argument is provided, Wheels defaults to including views/layout.cfm.

Example for Nested Layouts
<!--- In views/layouts/dashboard.cfm --->
<cfsavecontent variable="headerContent">
    <h1>Dashboard</h1>
</cfsavecontent>

contentFor(header=headerContent);

<!--- Include the site-wide parent layout --->
#includeLayout("/layout.cfm")#



























`````includePartial:
Includes a partial view file in the current view. Works similarly to <cfinclude> but with Wheels-specific lookups, caching, and support for passing model objects, queries, or arrays.

Basic Examples

Include a partial in the current controller’s view folder

<!--- If in "sessions" controller, includes views/sessions/_login.cfm --->
#includePartial("login")#


Include a partial from the shared folder

<!--- Includes views/shared/_button.cfm --->
#includePartial(partial="/shared/button")#

Using Queries or Arrays

Loop through a query and render partial for each record

<cfset posts = model("post").findAll()>
#includePartial(posts)#


Override template file for a query

#includePartial(partial="/shared/post", query=posts)#


Pass a single model instance

<cfset post = model("post").findByKey(params.key)>
#includePartial(post)#
#includePartial(partial="/shared/post", object=post)#


Pass an array of model objects

<cfset posts = model("post").findAll(returnAs="objects")>
#includePartial(posts)#
#includePartial(partial="/shared/post", objects=posts)#

Advanced Usage

Grouped query with spacer

<cfset posts = model("post").findAll()>
#includePartial(posts, group="category", spacer="<hr>")#


Cache the partial for 30 minutes

#includePartial(partial="login", cache=30)#


Render partial without a layout

#includePartial(partial="/shared/post", layout=false)#

























`````integer:
Adds one or more integer columns to a table definition during a migration. You can optionally specify a limit, default value, and whether the column allows NULL.

Examples

Add a single integer column age

<cfset t.integer("age")>


Add multiple integer columns height and weight

<cfset t.integer("height,weight")>


Add an integer column quantity with a default value of 0

<cfset t.integer("quantity", default=0)>


Add an integer column priority that cannot be null

<cfset t.integer("priority", null=false)>


Add an integer column rating with a limit of 2 digits (smallint)

<cfset t.integer("rating", limit=2)>


Add multiple columns with different limits (comma-separated)

<cfset t.integer("smallValue,mediumValue,bigValue", limit=1)> <!--- All columns share same limit --->



























`````invokeWithTransaction:
Runs a specified model method inside a single database transaction. This ensures that all database operations within the method are treated as a single atomic unit: either all succeed or all fail.

1. Define a method to run inside a transaction

public boolean function transferFunds(
    required any personFrom,
    required any personTo,
    required numeric amount
) {
    if (arguments.personFrom.withdraw(arguments.amount) 
        && arguments.personTo.deposit(arguments.amount)) {
        return true;
    } else {
        return false;
    }
}


2. Execute it within a transaction

local.david = model("Person").findOneByName("David");
local.mary = model("Person").findOneByName("Mary");

// Run transferFunds inside a transaction and commit changes
invokeWithTransaction(
    method="transferFunds",
    personFrom=local.david,
    personTo=local.mary,
    amount=100
);

Variations

Rollback instead of committing

invokeWithTransaction(
    method="transferFunds",
    personFrom=local.david,
    personTo=local.mary,
    amount=100,
    transaction="rollback"
);


This runs all database operations but does not persist changes.

Skip transaction handling

invokeWithTransaction(
    method="transferFunds",
    personFrom=local.david,
    personTo=local.mary,
    amount=100,
    transaction="none"
);


Executes the method without wrapping it in a transaction.

Custom isolation level

invokeWithTransaction(
    method="transferFunds",
    personFrom=local.david,
    personTo=local.mary,
    amount=100,
    isolation="serializable"
);




























`````isAjax:
Checks if the current request was made via JavaScript (AJAX) rather than a standard browser page load. This is useful when you want to return JSON or partial content instead of a full HTML page.

Usage
<cfif isAjax()>
    <!--- Return JSON response for AJAX requests --->
    <cfset returnJSON({ success = true, message = "This is an AJAX request" })>
<cfelse>
    <!--- Render full HTML page for normal requests --->
    <cfset view("fullPage")>
</cfif>

Example in a Controller Action
component extends="Controller" {

    function checkStatus() {
        if (isAjax()) {
            returnJSON({ status = "ok", time = now() });
        } else {
            flashInsert(msg="Page loaded normally");
            redirectTo("home");
        }
    }

}

























`````isClass:
Determines whether the method is being called at the class level (on the model itself) or on an instance of the model. This is useful when the same function can be invoked either on a model object or directly on the model class.

Example Usage
component extends="Model" {

    // Determine if a member is an admin
    public boolean function memberIsAdmin(required numeric id) {
        if (isClass()) {
            // Called on the model class, fetch instance by id
            return this.findByKey(arguments.id).admin;
        } else {
            // Called on an instance of the model
            return this.admin;
        }
    }

}

How It Works
// Class-level call
isAdmin = model("Member").memberIsAdmin(id=5); // isClass() = true

// Instance-level call
member = model("Member").findByKey(5);
isAdmin = member.memberIsAdmin(); // isClass() = false


Class-level (isClass() = true): The method is called directly on the model, so you might need to fetch a specific instance using a primary key.

Instance-level (isClass() = false): The method is called on an object instance, so you can directly use instance properties.



























`````isDelete:
Checks if the current HTTP request method is DELETE. This is useful for RESTful controllers where different logic is executed based on the request type.

Example Usage
component extends="Controller" {

    public void function destroy() {
        if (isDelete()) {
            // Perform deletion logic
            model("Post").deleteByKey(params.id);
            flashInsert(success="Post deleted successfully.");
            redirectTo(action="index");
        } else {
            // Handle non-DELETE request
            flashInsert(error="Invalid request method.");
            redirectTo(action="index");
        }
    }

}

























`````isGet:
Checks if the current HTTP request method is GET. Useful for controlling logic depending on whether a page is being displayed or data is being requested via GET.

component extends="Controller" {

    public void function show() {
        if (isGet()) {
            // Display a form or data
            post = model("Post").findByKey(params.id);
            render(view="show", post=post);
        } else {
            // Handle non-GET request (e.g., POST, DELETE)
            flashInsert(error="Invalid request method.");
            redirectTo(action="index");
        }
    }

}


























`````isHead:
Checks if the current HTTP request method is HEAD. HEAD requests are similar to GET requests but do not return a message body, only the headers. This is often used for checking metadata like content length or existence without transferring the actual content.

component extends="Controller" {

    public void function checkFile() {
        if (isHead()) {
            // Respond with headers only, no content
            setResponseHeader("Content-Length", "1234");
        } else {
            // Handle normal GET or other requests
            fileData = model("File").findByKey(params.id);
            render(view="show", file=fileData);
        }
    }

}























`````isInstance:
Checks whether the current context is an instance of a model object rather than a class-level context. This is useful when a method could be called either on a class or an instance, and you want to behave differently depending on which it is.

component extends="Model" {

    // Determine if a member is an admin
    public boolean function memberIsAdmin(required numeric id) {
        if (isInstance()) {
            // Called on an instance, use its own properties
            return this.admin;
        } else {
            // Called on the class, fetch the object by id
            return this.findByKey(arguments.id).admin;
        }
    }

}


























`````isNew:
Determines whether the current model object represents a new record (not yet saved to the database) or an existing record. This is useful for conditional logic in callbacks, validation, or saving routines.

Example Usage
<cfscript>
    // Create a new employee object (not saved yet)
    employee = model("employee").new();

    // Check if the object is new
    if (employee.isNew()) {
        writeOutput("This employee has not been saved to the database yet.");
    } else {
        writeOutput("This employee already exists in the database.");
    }
</cfscript>


Behavior:

Returns true if the object does not have a matching database record yet.

Returns false if the object corresponds to an existing record in the database.

Typical Use Case:

In beforeSave callbacks, to perform actions only when creating a new record, not updating an existing one.

Example:

public void function beforeSave() {
    if (isNew()) {
        // Set default properties only for new records
        this.joinedDate = now();
    }
}



























`````isOptions:
Checks whether the current HTTP request was made using the OPTIONS method. Useful in REST APIs or CORS preflight requests.

<cfscript>
if (isOptions()) {
    // Handle CORS preflight or respond to OPTIONS request
    writeOutput("This is an OPTIONS request.");
} else {
    writeOutput("This is a different type of request.");
}
</cfscript>






















`````isPatch:
Checks whether the current HTTP request was made using the PATCH method. Useful when building RESTful APIs where PATCH is used to partially update resources.

<cfscript>
if (isPatch()) {
    // Handle partial update logic
    writeOutput("This is a PATCH request.");
} else {
    writeOutput("This is a different type of request.");
}
</cfscript>

























`````isPersisted:
Determines whether a model object already exists in the database or has been loaded from the database. This is different from isNew(), which checks if an object has never been saved.

<cfscript>
employee = model("employee").findByKey(123);

if (employee.isPersisted()) {
    writeOutput("This employee exists in the database.");
} else {
    writeOutput("This employee has not been saved yet.");
}

// Creating a new object
newEmployee = model("employee").new();

if (!newEmployee.isPersisted()) {
    writeOutput("This is a new object, not yet persisted.");
}
</cfscript>



























`````isPost:
Checks whether the current HTTP request is a POST request (usually from a form submission).

<cfscript>
if (isPost()) {
    writeOutput("This request was submitted via POST.");
} else {
    writeOutput("This request is not a POST request.");
}
</cfscript>























`````isPut:
Checks whether the current HTTP request is a PUT request. PUT requests are typically used to update existing resources in RESTful APIs.

<cfscript>
if (isPut()) {
    writeOutput("This request is a PUT request.");
} else {
    writeOutput("This request is not a PUT request.");
}
</cfscript>


























`````isSecure:
Checks whether the current request is made over a secure connection (HTTPS). Returns true if the connection is secure, otherwise false.

<cfscript>
// Redirect non-secure requests to HTTPS
if (!isSecure()) {
    redirectTo(protocol="https");
} else {
    writeOutput("You are on a secure connection.");
}
</cfscript>























`````javaScriptIncludeTag:
Generates <script> tags for including JavaScript files. Can handle local files in the javascripts folder or external URLs. Supports multiple files and optional placement in the HTML <head>.

<head>
    <!--- Single local file --->
    #javaScriptIncludeTag("main")#

    <!--- Multiple local files --->
    #javaScriptIncludeTag("blog,accordion")#

    <!--- External JavaScript file --->
    #javaScriptIncludeTag("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js")#

    <!--- Force a script to appear in the head --->
    #javaScriptIncludeTag(source="tabs", head=true)#
</head>




























`````key:
Returns the value of the primary key for a model object. Useful for dynamic programming or when working with composite keys.

If the model has a single primary key (e.g., id), object.key() is equivalent to object.id.

For composite keys, it returns a list of all primary key values.

1. Single Primary Key
<!--- Assume Employee model has primary key `id` --->
employee = model("employee").findByKey(42);

<cfoutput>
Employee ID: #employee.key()# <!--- Equivalent to employee.id --->
</cfoutput>

2. Dynamic Key Retrieval
<!--- Useful when you don’t know the name of the primary key --->
anyEmployee = model("employee").findByKey(params.key);

primaryKey = anyEmployee.key();
writeOutput("Primary key value is: " & primaryKey);

3. Composite Primary Key
<!--- Assume Subscription model has composite keys: customerId, publicationId --->
subscription = model("subscription").findByKey(customerId=3, publicationId=7);

<cfoutput>
Composite Keys: #subscription.key()# <!--- Outputs: "3,7" --->
</cfoutput>

4. Use in Links or Forms
<cfset employee = model("employee").findByKey(42)>

<!--- Generate a link with dynamic primary key --->
<a href="#linkTo(action='edit', id=employee.key())#">Edit Employee</a>

<!--- Hidden field for a form --->
#hiddenField(objectName="employee", property="id")#

5. Passing Keys in Nested Relationships
<!--- Suppose a `bookAuthors` association exists --->
book = model("book").findByKey(15);

<cfloop array="#book.bookAuthors#" index="author">
    <cfoutput>
        Author Key: #author.key()# <br>
    </cfoutput>
</cfloop>
































`````linkTo:
Creates an <a> link to another page in your application. Can use routes or controller/action/key combinations. Supports external URLs, query parameters, anchors, and HTML attributes.

1. Basic link using controller/action
#linkTo(text="Log Out", controller="account", action="logout")#
<!--- Outputs: <a href="/account/logout">Log Out</a> --->

2. Current controller shortcut
#linkTo(text="Log Out", action="logout")#
<!--- If already in account controller, outputs: <a href="/account/logout">Log Out</a> --->

3. Link with a key
#linkTo(text="View Post", controller="blog", action="post", key=99)#
<!--- Outputs: <a href="/blog/post/99">View Post</a> --->

4. Link with query parameters
#linkTo(text="View Settings", action="settings", params="show=all&sort=asc")#
<!--- Outputs: <a href="/account/settings?show=all&amp;sort=asc">View Settings</a> --->

5. Using a named route
#linkTo(text="Joe's Profile", route="userProfile", userName="joe")#
<!--- Outputs: <a href="/user/joe">Joe's Profile</a> --->

6. External link
#linkTo(text="ColdFusion Framework", href="http://cfwheels.org/")#
<!--- Outputs: <a href="http://cfwheels.org/">ColdFusion Framework</a> --->

7. Adding HTML attributes
#linkTo(text="Delete Post", action="delete", key=99, class="delete", id="delete-99")#
<!--- Outputs: <a class="delete" href="/blog/delete/99" id="delete-99">Delete Post</a> --->

8. Adding an anchor
#linkTo(text="Go to Section", controller="blog", action="post", key=42, anchor="comments")#
<!--- Outputs: <a href="/blog/post/42#comments">Go to Section</a> --->

9. Override protocol, host, or port
#linkTo(text="Secure Link", controller="account", action="login", protocol="https", host="example.com", port=443)#
<!--- Outputs: <a href="https://example.com:443/account/login">Secure Link</a> --->































`````mailTo:
Creates a clickable mailto: link for sending an email. The link text defaults to the email address unless a name is provided.

1. Basic mailto link
#mailTo(emailAddress="webmaster@yourdomain.com")#
<!--- Outputs: <a href="mailto:webmaster@yourdomain.com">webmaster@yourdomain.com</a> --->

2. Mailto link with custom name
#mailTo(emailAddress="webmaster@yourdomain.com", name="Contact our Webmaster")#
<!--- Outputs: <a href="mailto:webmaster@yourdomain.com">Contact our Webmaster</a> --->

3. Mailto link with special characters (encoding)
#mailTo(emailAddress="support+help@yourdomain.com", name="Support Team")#
<!--- Outputs: <a href="mailto:support+help@yourdomain.com">Support Team</a> --->



























`````mapper:
Returns the mapper object used to configure your application’s routes. This is typically used in config/routes.cfm to define all routes for your application via chained methods such as .resources(), .namespace(), .get(), .post(), etc.

Example: Basic Usage
<cfscript>
mapper()
    .resources("posts")  // generates standard RESTful routes for posts
    .get(name="about", pattern="about-us", to="pages##about") // custom GET route
    .namespace("admin") // group routes under admin namespace
        .resources("users") // RESTful routes for admin users
    .end();
</cfscript>


.resources() – Automatically generates RESTful routes for a resource (index, show, create, update, delete).

.get() / .post() / .put() / .delete() – Custom HTTP method routes.

.namespace() – Allows grouping routes under a URL prefix and controller subfolder.

Example: Disable format mapping
mapper(mapFormat=false)
    .resources("reports");


This will prevent automatic generation of .json or .xml endpoints for the resource.




























`````maximum:
Calculates the maximum value of a numeric property in a model. Internally uses the SQL MAX() function. If no records match the query, you can use the ifNull argument to return a default value instead of null or blank.

1. Maximum value for all records:

highestSalary = model("employee").maximum("salary");


2. Maximum value with a WHERE condition:

highestSalary = model("employee").maximum(
    property="salary", 
    where="departmentId=#params.departmentId#"
);


3. Maximum value with a default if no records found:

highestSalary = model("employee").maximum(
    property="salary", 
    where="salary > #params.minSalary#", 
    ifNull=0
);


4. Maximum value including associations (example with nested join):

highestAlbumSales = model("album").maximum(
    property="sales",
    include="artist(genre)"
);


5. Maximum value grouped by a column:

maxSalaryByDept = model("employee").maximum(
    property="salary",
    group="departmentId"
);





























`````member:
Scopes routes within a nested resource that require the primary key as part of the URL pattern.

A member route always acts on a specific resource instance, so the generated URL will contain the resource’s ID.

Example
<cfscript>
mapper()
    // Standard RESTful routes for photos
    .resources(name="photos", nested=true)
        // Create a member route that requires an ID
        .member()
            .get("preview") // maps GET /photos/:id/preview → photos.preview
        .end()
    .end()
.end();
</cfscript>


Resulting Route:

GET /photos/1/preview → calls the preview action in the photos controller.

More Examples

1. Adding multiple member actions:

<cfscript>
mapper()
    .resources(name="articles")
        .member()
            .get("share")     // GET /articles/:id/share
            .post("publish")  // POST /articles/:id/publish
        .end()
    .end()
.end();
</cfscript>


2. Member route inside a nested resource:

<cfscript>
mapper()
    .resources(name="users", nested=true)
        .resources(name="orders")
            .member()
                .get("invoice") // GET /users/:userId/orders/:id/invoice
            .end()
        .end()
    .end()
.end();
</cfscript>



























`````migrateTo:
Migrates the database schema to a specified version.

This function is primarily intended for programmatic database migrations, but the recommended usage is via the CLI or Wheels GUI interface.

<cfscript>
// Migrate database to a specific version
result = application.wheels.migrator.migrateTo("2025092401");

// Output the result message
writeOutput(result);
</cfscript>





























`````migrateToLatest:
Migrates the database schema to the latest available migration version.

This is a shortcut for migrateTo(version) without needing to specify a version explicitly.

<cfscript>
// Migrate database to the latest version
result = application.wheels.migrator.migrateToLatest();

// Output the result message
writeOutput(result);
</cfscript>





























`````mimeTypes:
Returns the associated MIME type for a given file extension. Useful when serving files dynamically or setting response headers.

1. Basic Known Extension
<cfscript>
// Get the MIME type for a known extension
mimeType = mimeTypes("jpg");
writeOutput(mimeType); // Outputs: "image/jpeg"
</cfscript>

2. Unknown Extension With Fallback
<cfscript>
// Use a fallback for unknown file types
mimeType = mimeTypes("abc", fallback="text/plain");
writeOutput(mimeType); // Outputs: "text/plain"
</cfscript>

3. Dynamic Extension From User Input
<cfscript>
params.type = "pdf";
mimeType = mimeTypes(extension=params.type);
writeOutput(mimeType); // Outputs: "application/pdf"
</cfscript>

4. Serving a File Download
<cfscript>
fileName = "report.xlsx";
fileExt = listLast(fileName, ".");
cfheader(name="Content-Disposition", value="attachment; filename=#fileName#");
cfcontent(type=mimeTypes(fileExt), file="#expandPath('./files/' & fileName)#");
</cfscript>


Automatically sets the correct MIME type when serving a file.

5. Conditional Logic Based on MIME Type
<cfscript>
fileExt = "mp3";
mimeType = mimeTypes(fileExt);

if (left(mimeType, 5) == "audio") {
    writeOutput("Playing audio file...");
} else {
    writeOutput("Cannot play this file type.");
}
</cfscript>
































`````minimum:
Calculates the minimum value for a specified property in a model using SQL's MIN() function. This can be used to find the lowest value of a numeric property across all records or with conditions. You can also include associations, handle soft-deleted records, provide fallback values, and group results.

1. Basic Minimum Value
<cfscript>
// Get the lowest salary among all employees
lowestSalary = model("employee").minimum("salary");
writeOutput("Lowest Salary: " & lowestSalary);
</cfscript>


Explanation:
Finds the lowest value of the salary property across all employees.

2. Minimum Value with Condition
<cfscript>
// Get the lowest salary for employees in a specific department
deptId = 5;
lowestSalary = model("employee").minimum(
    property="salary",
    where="departmentId=#deptId#"
);
writeOutput("Lowest Salary in Department #deptId#: " & lowestSalary);
</cfscript>


Explanation:
Filters the query using the where clause to only consider employees in department 5.

3. Minimum Value with Range and Fallback
<cfscript>
// Get the lowest salary within a range and fallback to 0 if no records
lowestSalary = model("employee").minimum(
    property="salary",
    where="salary BETWEEN #params.min# AND #params.max#",
    ifNull=0
);
writeOutput("Lowest Salary in range: " & lowestSalary);
</cfscript>


Explanation:
Returns 0 if there are no employees with a salary in the specified range.

4. Including Associations
<cfscript>
// Get the lowest product price including related categories
lowestPrice = model("product").minimum(
    property="price",
    include="category"
);
writeOutput("Lowest Product Price: " & lowestPrice);
</cfscript>


Explanation:
Includes the category association in the SQL query to allow filtering or joining data from related tables.

5. Include Soft-Deleted Records
<cfscript>
// Include soft-deleted employees in the calculation
lowestSalary = model("employee").minimum(
    property="salary",
    includeSoftDeletes=true
);
writeOutput("Lowest Salary including soft-deleted employees: " & lowestSalary);
</cfscript>





























`````minuteSelectTag:
Builds and returns a <select> dropdown for the minutes of an hour (0–59). You can customize the selected value, increment steps (e.g., 5, 10, 15 minutes), label placement, and include a blank option. Useful for forms where users pick a time.

1. Basic Minute Select
<cfoutput>
    #minuteSelectTag(name="minuteOfMeeting", selected=params.minuteOfMeeting)#
</cfoutput>


Explanation:
Generates a standard minute dropdown (0–59) and pre-selects the value from params.minuteOfMeeting.

2. 15-Minute Intervals
<cfoutput>
    #minuteSelectTag(name="minuteOfMeeting", selected=params.minuteOfMeeting, minuteStep=15)#
</cfoutput>


Explanation:
Only shows 0, 15, 30, 45 as minute options.

3. Include Blank Option
<cfoutput>
    #minuteSelectTag(name="minuteOfMeeting", includeBlank="- Select Minute -")#
</cfoutput>


Explanation:
Adds a blank option at the top with custom text "- Select Minute -".

4. Using Label
<cfoutput>
    #minuteSelectTag(name="minuteOfMeeting", label="Select Minute")#
</cfoutput>


Explanation:
Adds a label Select Minute around the select field (default placement is around).

5. Custom Label Placement
<cfoutput>
    #minuteSelectTag(name="minuteOfMeeting", label="Minute", labelPlacement="after")#
</cfoutput>



























`````model:
The model() function returns a reference to a specific model defined in your application, allowing you to call class-level methods on it. This is useful when you want to access database records or invoke model methods without instantiating a new object first.

1. Find a record by primary key
<cfset authorObject = model("author").findByKey(1)>
<cfoutput>
    Author Name: #authorObject.name#
</cfoutput>


Explanation:
Retrieves the author record with primary key 1 and stores it in authorObject.

2. Find all records
<cfset allAuthors = model("author").findAll()>
<cfloop array="#allAuthors#" index="author">
    #author.name#<br>
</cfloop>


Explanation:
Gets all authors from the database and loops through them.

3. Using dynamic finders
<cfset author = model("author").findOneByEmail("joe@example.com")>
<cfoutput>
    Author ID: #author.key()#
</cfoutput>


Explanation:
Uses a dynamic finder method findOneByEmail to get a single record by email.

4. Calling class-level custom methods
<cfset topAuthors = model("author").getTopAuthors(5)>
<cfloop array="#topAuthors#" index="author">
    #author.name# (#author.postsCount# posts)<br>
</cfloop>


Explanation:
Calls a custom class-level method getTopAuthors that returns the top 5 authors with the most posts.

5. Accessing associations
<cfset author = model("author").findByKey(1, include="posts")>
<cfoutput>
    #author.name# wrote #arrayLen(author.posts)# posts.
</cfoutput>




























`````monthSelectTag:
The monthSelectTag() helper generates a <select> dropdown for selecting a month. You can customize its options, labels, and display format. Unlike dateSelect, this function focuses only on the month portion.

1. Basic usage
<cfoutput>
    #monthSelectTag(name="monthOfBirthday", selected=params.monthOfBirthday)#
</cfoutput>


Explanation:
Displays a standard month dropdown with full month names and selects the month stored in params.monthOfBirthday.

2. Display months as numbers
<cfoutput>
    #monthSelectTag(name="monthOfHire", selected=3, monthDisplay="numbers")#
</cfoutput>


Explanation:
Dropdown shows 1–12 instead of month names, pre-selecting March.

3. Display months as abbreviations
<cfoutput>
    #monthSelectTag(name="monthOfEvent", selected="Jun", monthDisplay="abbreviations")#
</cfoutput>


Explanation:
Dropdown shows Jan, Feb, Mar, …, Dec, with June pre-selected.

4. Include a blank option
<cfoutput>
    #monthSelectTag(name="monthOfAppointment", includeBlank="- Select Month -")#
</cfoutput>


Explanation:
Adds a first option as - Select Month - so the user can leave it empty.

5. Custom label and wrapping
<cfoutput>
    #monthSelectTag(
        name="monthOfSubscription",
        label="Subscription Month:",
        labelPlacement="before"
    )#
</cfoutput>





























`````namespace:
The namespace() function in Wheels is used to group controllers and routes under a specific namespace (subfolder/package). It also prepends the namespace to route names and can modify the URL path. This is useful for organizing APIs, versioning, or modular applications.

Namespaces can be nested for hierarchical routing, e.g., /api/v1/... and /api/v2/....

1. Nested API versioning
<cfscript>
mapper()
    .namespace("api")
        .namespace("v2")
            // Route name: apiV2Products
            // URL: /api/v2/products/1234
            // Controller: api.v2.Products
            .resources("products")
        .end()

        .namespace("v1")
            // Route name: apiV1Users
            // URL: /api/v1/users
            // Controller: api.v1.Users
            .get(name="users", to="users##index")
        .end()
    .end()
.end();
</cfscript>


Explanation:

/api/v2/products/1234 → api.v2.Products controller, RESTful resource route.

/api/v1/users → api.v1.Users controller, GET action index.

Namespaces help version APIs cleanly and avoid route conflicts.

2. Custom package and path
<cfscript>
mapper()
    .namespace(name="foo", package="foos", path="foose")
        // Route name: fooBars
        // URL: /foose/bars
        // Controller: foos.Bars
        .post(name="bars", to="bars##create")
    .end()
.end();
</cfscript>


Explanation:

package="foos" tells Wheels to look for the Bars.cfc controller inside the foos folder.

path="foose" changes the URL path prefix. The route URL becomes /foose/bars instead of /foo/bars.

The route name becomes fooBars for programmatic reference.

3. Combining multiple namespaces
<cfscript>
mapper()
    .namespace("admin")
        .get(name="dashboard", to="dashboard##index") // /admin/dashboard
        .namespace("users")
            .resources("accounts") // /admin/users/accounts/...
        .end()
    .end()
.end();
</cfscript>


Explanation:

/admin/dashboard → admin dashboard page.

/admin/users/accounts/123 → admin.users.Accounts controller, RESTful routes.

Nested namespaces allow for logical grouping and modular URLs.
































`````nestedProperties:
The nestedProperties() method allows nested objects, arrays, or structs associated with a model to be automatically set from incoming params or other generated data. This is particularly useful when you have hasMany or belongsTo associations and want to manage them directly when saving the parent object.

Using nestedProperties(), you can:

Automatically save child objects when the parent object is saved.

Allow deletion of nested objects via a _delete flag.

Reject saving if specific properties in the nested object are blank.

Sort nested objects by a numeric property

1. Basic nested association with auto-save
// models/User.cfc
function config(){
    hasMany("groupEntitlements");

    // Allow nested save of `groupEntitlements` when user is saved
    nestedProperties(association="groupEntitlements");
}

// Controller code
user = model("User").findByKey(1);
user.groupEntitlements = [
    {groupId=1, role="admin"},
    {groupId=2, role="editor"}
];
user.save(); 
// Both the user and nested groupEntitlements are saved automatically

2. Allow deletion of nested objects
function config(){
    hasMany("groupEntitlements");

    // Enable deletion via `_delete` flag
    nestedProperties(association="groupEntitlements", allowDelete=true);
}

// Example params
params.user.groupEntitlements = [
    {id=10, _delete=true},
    {groupId=3, role="viewer"}
];

user = model("User").findByKey(params.user.id);
user.setProperties(params.user);
user.save();
// The first nested object (id=10) is deleted, the second is saved

3. Reject if blank
function config(){
    hasMany("addresses");

    // Reject saving any address that has blank 'city' or 'zip'
    nestedProperties(association="addresses", rejectIfBlank="city,zip");
}

// Example
params.user.addresses = [
    {street="123 Main St", city="", zip="90210"}
];

user = model("User").findByKey(1);
user.setProperties(params.user);
user.save(); 
// Save fails because 'city' is blank

4. Sorting nested objects
function config(){
    hasMany("tasks");

    // Use 'position' property to sort tasks
    nestedProperties(association="tasks", sortProperty="position");
}

// Example
params.user.tasks = [
    {name="Task 1", position=2},
    {name="Task 2", position=1}
];

user = model("User").findByKey(1);
user.setProperties(params.user);
user.save(); 
// Tasks will be stored sorted by position: Task 2, Task 1





























`````new:
The new() method creates a new instance of a model in memory based on the supplied properties. The object is not saved to the database—it only exists in memory until you call .save() on it.

You can pass properties to new() in two ways:

As a struct using the properties argument.

As named arguments directly in the method call.

You can also control behavior such as whether callbacks are triggered or explicit timestamps are allowed.

1. Create a new object with no properties
// Creates a new author object in memory
newAuthor = model("author").new();
writeDump(newAuthor); // object exists, not saved to database

2. Create a new object from a struct
authorStruct = {
    firstName = "Jane",
    lastName = "Smith",
    email = "jane.smith@example.com"
};

// Pass the struct to `new()`
newAuthor = model("author").new(authorStruct);
writeDump(newAuthor);

3. Create a new object using named arguments
// Directly pass properties as arguments
newAuthor = model("author").new(
    firstName="John",
    lastName="Doe",
    email="john.doe@example.com"
);
writeDump(newAuthor);

4. Scoped creation for associations
// If a customer has many orders, you can create a new order scoped to that customer
aCustomer = model("customer").findByKey(params.customerId);

// newOrder internally calls model("order").new(customerId=aCustomer.id)
anOrder = aCustomer.newOrder(shipping="express");
writeDump(anOrder);

5. Disable callbacks
// Create object without triggering callbacks
newAuthor = model("author").new(firstName="Alice", lastName="Wonder", callbacks=false);

6. Allow explicit timestamps
// You can manually set createdAt and updatedAt fields
newAuthor = model("author").new(
    firstName="Bob",
    lastName="Builder",
    allowExplicitTimestamps=true,
    createdAt=createDate(2025,9,24),
    updatedAt=createDate(2025,9,24)
);






























`````obfuscateParam:
The obfuscateParam() method obfuscates a value, typically used to hide sensitive information like primary key IDs when passing them in URLs. This helps prevent users from easily guessing sequential IDs or sensitive values.

1. Obfuscate a numeric primary key
// Primary key value
id = 99;

// Obfuscate it before sending in the URL
obfuscatedId = obfuscateParam(id);
writeOutput(obfuscatedId); 
// Output: (some encoded string, e.g., "a9f3d2")

2. Obfuscate a string value
// Obfuscate an email address
email = "user@example.com";
obfuscatedEmail = obfuscateParam(email);
writeOutput(obfuscatedEmail); 
// Output: (obfuscated string)

3. Use obfuscated value in a link
// Pass obfuscated ID in a linkTo helper
userId = 42;
#linkTo(text="View Profile", controller="user", action="profile", key=obfuscateParam(userId))#


Output:

<a href="/user/profile/a1b2c3d4">View Profile</a>

4. Obfuscate values for forms
// Include obfuscated value as a hidden form field
userId = 17;
#hiddenFieldTag(name="userId", value=obfuscateParam(userId))#


Output:

<input type="hidden" name="userId" value="x9y8z7">





























`````onlyProvides:
The onlyProvides() method is used in a controller action to specify which formats the action should respond with. This allows you to restrict the response types for a particular action, even if a global provides() setting exists in the controller's config() function.

1. Restrict an action to HTML only
function show() {
    // This action will only respond with HTML
    onlyProvides("html");

    // normal processing
    user = model("user").findByKey(params.id);
    set("user", user);
}

2. Restrict an action to JSON and XML
function data() {
    // Only allow JSON or XML responses
    onlyProvides("json,xml");

    records = model("order").findAll();
    set("orders", records);
}

3. Override global provides setting
component extends="Controller" {

    function config() {
        // Globally allow HTML and JSON
        provides("html,json");
    }

    function exportCsv() {
        // Override global, allow only CSV for this action
        onlyProvides("csv");

        orders = model("order").findAll();
        set("orders", orders);
    }
}



























`````onMissingMethod:
The onMissingMethod() method is not intended to be called directly. It is used internally by the model system to handle dynamic finders and other dynamic method calls on model objects. For example, methods like:

findOneByEmail("test@example.com")
findAllByStatus("active")

do not exist explicitly in the model class but are interpreted dynamically via onMissingMethod().

1. Dynamic finder: findOneByEmail
user = model("user").findOneByEmail("joe@example.com");


Internally, Wheels interprets this as:

onMissingMethod(
    missingMethodName="findOneByEmail",
    missingMethodArguments={arg1="joe@example.com"}
);

2. Dynamic finder with multiple fields: findAllByStatusAndRole
admins = model("user").findAllByStatusAndRole("active","admin");


Internally, Wheels interprets this as:

onMissingMethod(
    missingMethodName="findAllByStatusAndRole",
    missingMethodArguments={arg1="active", arg2="admin"}
);

3. Custom handling (advanced)

You can override onMissingMethod() in your model to provide custom dynamic behavior if needed:

component extends="Model" {

    public any function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
        if (listFirst(missingMethodName,"By")=="findCustom") {
            return "Handled dynamically: " & missingMethodName;
        }
        return super.onMissingMethod(missingMethodName, missingMethodArguments);
    }
}
























`````package:
The package() method scopes the controllers for any routes defined inside its block to a specific subfolder (package) without adding the package name to the URL. This is useful for organizing your controllers in subfolders while keeping the URL structure clean.

1. Simple package
<cfscript>
mapper()
    .package("public")
        // Example URL: /products/1234
        // Controller:  public.Products
        .resources("products")
    .end()
.end();
</cfscript>


Explanation:
All routes inside .package("public") will point to controllers inside the public folder (e.g., public.Products). The URL does not include public; /products/1234 is clean.

2. Nested package
<cfscript>
mapper()
    .resources(name="users", nested=true)
        // Nested routes scoped to the `users` package
        .package("users")
            // Example URL: /users/4321/profile
            // Controller:  users.Profiles
            .resource("profile")
        .end()
    .end()
.end();
</cfscript>
























`````packageSetup:
The packageSetup() function is a callback in Wheels’ legacy testing framework. It runs once before the first test case in the test package. Use it to perform setup tasks that are shared across all tests in the package, such as initializing data, creating test records, or configuring environment settings.

component extends="WheelsTestCase" {

    function packageSetup() {
        // Run once before any test in this package
        
        // Create a test user
        model("user").new(username="testuser", email="test@example.com").save();

        // Initialize test data
        application.testConfig = {
            siteName: "Wheels Test"
        };
    }

    function testUserCreation() {
        var user = model("user").findOneByUsername("testuser");
        assertNotNull(user, "Test user should exist");
    }

    function testConfigValue() {
        assertEquals(application.testConfig.siteName, "Wheels Test");
    }
}






















`````packageTeardown:
The packageTeardown() function is a callback in Wheels’ legacy testing framework. It runs once after the last test case in the test package. Use it to perform cleanup tasks that are shared across all tests in the package, such as deleting test records, resetting application state, or clearing cached data.

component extends="WheelsTestCase" {

    function packageSetup() {
        // Run once before any test in this package
        model("user").new(username="testuser", email="test@example.com").save();
    }

    function packageTeardown() {
        // Run once after all tests in this package

        // Delete test user
        var user = model("user").findOneByUsername("testuser");
        if (user) {
            user.delete();
        }

        // Clear test configuration
        structClear(application.testConfig);
    }

    function testUserExists() {
        var user = model("user").findOneByUsername("testuser");
        assertNotNull(user, "Test user should exist");
    }
}























`````pagination:
The pagination() function returns metadata about a paginated query. It provides information such as the current page, total number of pages, and total number of records. This is useful when building paginated listings in your views.

Example 1: Basic Pagination
<!--- Retrieve paginated authors --->
<cfset allAuthors = model("author").findAll(page=1, perPage=25, order="lastName", handle="authorsData")>

<!--- Get pagination info --->
<cfset paginationData = pagination("authorsData")>

<cfoutput>
    Current Page: #paginationData.currentPage#<br>
    Total Pages: #paginationData.totalPages#<br>
    Total Records: #paginationData.totalRecords#
</cfoutput>


Output:

Current Page: 1
Total Pages: 10
Total Records: 250

Example 2: Using default handle
<cfset allPosts = model("post").findAll(page=2, perPage=10)>

<!--- Uses default handle 'query' --->
<cfset paginationData = pagination()>

<cfoutput>
    Current Page: #paginationData.currentPage#<br>
    Total Pages: #paginationData.totalPages#<br>
    Total Records: #paginationData.totalRecords#
</cfoutput>
























`````paginationLinks:
paginationLinks() generates HTML links for paginated queries, making it easy to navigate between pages. It uses linkTo() internally, so you can pass route names or controller/action/key combinations along with any other HTML attributes. If multiple paginated queries exist, use the handle argument to specify which one to generate links for.

Example 1: Basic Pagination Links
<!--- Controller --->
param name="params.page" type="integer" default="1";
authors = model("author").findAll(page=params.page, perPage=25, order="lastName");

<!--- View --->
<ul>
    <cfoutput query="authors">
        <li>#EncodeForHtml(firstName)# #EncodeForHtml(lastName)#</li>
    </cfoutput>
</ul>

<cfoutput>
    #paginationLinks(route="authors")#
</cfoutput>


This will display links to navigate through author pages.

Example 2: Custom Window Size
<cfoutput>
    #paginationLinks(route="authors", windowSize=5)#
</cfoutput>


Shows 5 pages before and after the current page instead of the default 2.

Example 3: Multiple Paginated Queries
<!--- Controller --->
authors = model("author").findAll(handle="authQuery", page=5, order="id");

<!--- View --->
<ul>
    <cfoutput>
        #paginationLinks(
            route="authors",
            handle="authQuery",
            prependToLink="<li>",
            appendToLink="</li>"
        )#
    </cfoutput>
</ul>


If multiple paginated queries exist, handle ensures the correct one is used.

Example 4: Pagination with Routes
<!--- Route setup in config/routes.cfm --->
mapper()
    .get(name="paginatedCommentListing", pattern="blog/[year]/[month]/[day]/[page]", to="blogs##stats")
    .get(name="commentListing", pattern="blog/[year]/[month]/[day]", to="blogs##stats")
.end();

<!--- Controller --->
param name="params.page" type="integer" default="1";
comments = model("comment").findAll(page=params.page, order="createdAt");

<!--- View --->
<ul>
    <cfoutput>
        #paginationLinks(
            route="paginatedCommentListing",
            year=2009,
            month="feb",
            day=10
        )#
    </cfoutput>
</ul>



























`````passwordField:
passwordField() generates an HTML <input type="password"> field bound to a model object. It is useful for creating forms that are tied directly to model properties. This helper automatically handles associations, nested properties, labels, and error styling, reducing manual markup.

Example 1: Basic Password Field
<cfoutput>
    #passwordField(label="Password", objectName="user", property="password")#
</cfoutput>


Output:

<label>Password</label>
<input type="password" name="user[password]" id="user_password">

Example 2: Password Field for a Nested Association
<fieldset>
    <legend>Passwords</legend>
    <cfloop from="1" to="#ArrayLen(user.passwords)#" index="i">
        #passwordField(
            label="Password ##i#", 
            objectName="user", 
            association="passwords", 
            position=i, 
            property="password"
        )#
    </cfloop>
</fieldset>


This generates password fields for each associated password object within user.passwords.

Output (simplified for 2 items):

<fieldset>
    <legend>Passwords</legend>
    <label>Password 1</label>
    <input type="password" name="user[passwords][1][password]" id="user_passwords_1_password">

    <label>Password 2</label>
    <input type="password" name="user[passwords][2][password]" id="user_passwords_2_password">
</fieldset>

Example 3: Custom Label Placement and Error Handling
<cfoutput>
    #passwordField(
        label="Enter Your Password",
        objectName="user",
        property="password",
        labelPlacement="before",
        errorClass="input-error",
        prepend="<div class='input-group'>",
        append="</div>"
    )#
</cfoutput>

























`````passwordFieldTag:
passwordFieldTag() generates an HTML <input type="password"> field for use in forms. Unlike passwordField(), which is bound to a model object, this helper works with a simple name and value. It supports labels, custom HTML wrapping, and XSS-safe encoding.

Example 1: Basic Password Field
<cfoutput>
    #passwordFieldTag(label="Password", name="password", value="")#
</cfoutput>


Output:

<label>Password</label>
<input type="password" name="password" value="">

Example 2: Label Placement Before Input
<cfoutput>
    #passwordFieldTag(label="Password", name="password", labelPlacement="before")#
</cfoutput>


Output:

<label>Password</label>
<input type="password" name="password">

Example 3: Wrapping Input with Custom HTML
<cfoutput>
    #passwordFieldTag(
        label="Enter Password",
        name="password",
        prepend="<div class='input-group'>",
        append="</div>"
    )#
</cfoutput>


Output:

<div class='input-group'>
    <label>Enter Password</label>
    <input type="password" name="password">
</div>

Example 4: Custom Label Decoration
<cfoutput>
    #passwordFieldTag(
        label="Password",
        name="password",
        prependToLabel="<strong>",
        appendToLabel="</strong>"
    )#
</cfoutput>


Output:

<label><strong>Password</strong></label>
<input type="password" name="password">




























`````patch:
patch() creates a route that responds to the HTTP PATCH method, which is typically used to partially update resources. This is ideal for actions that modify specific attributes of a record rather than replacing it entirely (which would normally use PUT).

It works like other route helpers (get(), post(), put(), etc.) but restricts the route to PATCH requests.

1. Basic PATCH Route
mapper()
    .patch(name="updateBlogPost", controller="blog", action="update")
.end();


URL: /update-blog-post

Controller: Blog.cfc

Action: update

HTTP Method: PATCH

2. Route with Dynamic URL Segments
mapper()
    .patch(name="ghostStory", pattern="ghosts/[ghostKey]/stories/[key]", to="stories##update")
.end();


URL Example: /ghosts/666/stories/616

Controller: Stories.cfc

Action: update

Segments: ghostKey and key are dynamic and passed to the action as params.ghostKey and params.key.

3. Route in a Package/Subfolder
mapper()
    .patch(name="preferences", to="preferences##update", package="users")
.end();


URL: /preferences

Controller: users.Preferences.cfc

Action: update

4. Nested Resource – Collection PATCH
mapper()
    .resources(name="subscribers", nested=true)
        .patch(name="launch", to="subscribers##update", on="collection")
    .end()
.end();


URL Example: /subscribers/3209/launch

Controller: Subscribers.cfc

Action: update

Purpose: Operates on the entire collection of subscribers, not an individual member.

5. Nested Resource – Member PATCH
mapper()
    .resources(name="subscribers", nested=true)
        .patch(name="discontinue", to="subscribers##discontinue", on="member")
    .end()
.end();




























`````pluginNames:
pluginNames() returns a list of all installed Wheels plugins in your application. This can be useful if you want to check for the presence of a plugin before calling its functionality, or to display available plugins dynamically.

1. Check if a specific plugin is installed
<cfif ListFindNoCase("scaffold", pluginNames())>
    <cfoutput>
        The Scaffold plugin is installed!
    </cfoutput>
<cfelse>
    <cfoutput>
        Scaffold plugin is not installed.
    </cfoutput>
</cfif>

2. List all installed plugins
<cfoutput>
Installed Plugins: #pluginNames()#
</cfoutput>


Output Example:

Installed Plugins: scaffold, admin, seo, blog

3. Loop through all installed plugins
<cfloop list="#pluginNames()#" index="plugin">
    <cfoutput>
        Plugin: #plugin#<br>
    </cfoutput>
</cfloop>


Output Example:

Plugin: scaffold
Plugin: admin
Plugin: seo
Plugin: blog

4. Conditional logic based on multiple plugins
<cfset plugins = pluginNames()>

<cfif ListFindNoCase("scaffold", plugins) AND ListFindNoCase("seo", plugins)>
    <cfoutput>
        Both Scaffold and SEO plugins are installed.
    </cfoutput>
</cfif>

























`````pluralize:
The pluralize() function is used to generate the plural form of a given word. If only a word is passed in, it will return the plural version according to the built-in rules of Wheels. You can also pass in a numeric count to decide whether the word should be pluralized or left in singular form. By default, when a count is provided, the returned value will include both the number and the correct form of the word. Wheels automatically handles irregular words (like "child" → "children", "foot" → "feet") and uncountable words (like "equipment" or "information") that do not follow standard pluralization rules. If needed, you can customize or extend the rules using get("uncountables") / set("uncountables", newList) and get("irregulars") / set("irregulars", newList).

<!--- Basic pluralization --->
#pluralize("person")#
<!--- Returns: "people" --->

<!--- Pluralization with count (count = 1, so singular is returned) --->
#pluralize(word="car", count=1)#
<!--- Returns: "1 car" --->

<!--- Pluralization with count (count = 5, so plural is returned) --->
#pluralize(word="car", count=5)#
<!--- Returns: "5 cars" --->

<!--- Suppressing the count in the result --->
#pluralize(word="dog", count=3, returnCount=false)#
<!--- Returns: "dogs" --->

<!--- Irregular plural (child → children) --->
#pluralize("child")#
<!--- Returns: "children" --->

<!--- Uncountable word stays the same --->
#pluralize("equipment")#
<!--- Returns: "equipment" --->

<!--- With count and uncountable word --->
#pluralize(word="equipment", count=2)#
<!--- Returns: "2 equipment" --->


























`````post:
The post() function defines a route that responds only to HTTP POST requests. It is most commonly used to handle actions that create database records, such as creating users, orders, or other resources. You can define the route with a simple controller and action combination or use the to argument for shorthand. Routes can be customized further with a name (for referencing in helpers), a pattern (to override the generated URL), or a package (to scope the controller without affecting the URL). Nested resources are supported, and you can distinguish between member and collection routes using the on argument. In cases where you want the route to redirect rather than process through a controller, you can set the redirect argument.

<cfscript>
mapper()
    // Basic route with "to"
    // Example URL: /posts
    // Controller:  Posts
    // Action:      create
    .post(name="posts", to="posts##create")

    // Route with explicit controller/action
    // Example URL: /articles
    // Controller:  Articles
    // Action:      create
    .post(name="articles", controller="articles", action="create")

    // Custom pattern
    // Example URL: /oauth/token.json
    // Controller:  Tokens
    // Action:      create
    .post(name="authenticate", pattern="oauth/token.json", to="tokens##create")

    // Using a package (controller is users/Preferences.cfc)
    // Example URL: /preferences
    .post(name="preferences", to="preferences##create", package="users")

    // Example with redirect (bypasses controller/action)
    // Example URL: /legacy-create
    .post(name="legacyCreate", pattern="legacy-create", redirect="/new-endpoint")

    // Nested resources (collection-level route)
    .resources(name="customers", nested=true)
        // Example URL: /customers/leads
        // Controller:  Leads
        // Action:      create
        .post(name="leads", to="leads##create", on="collection")

        // Example URL: /customers/3209/cancel
        // Controller:  Cancellations
        // Action:      create
        .post(name="cancel", to="cancellations##create", on="member")
    .end()
.end();
</cfscript>





























`````primaryKey:
The primaryKey() function returns the name of the primary key column for the table mapped to a given model. Wheels determines this automatically by introspecting the database. If the table uses a single primary key, the function returns that key’s name as a string. For tables with composite primary keys, the function will return a list of all keys. You can optionally pass in the position argument to retrieve a specific key from a composite set. This function is also available as the alias primaryKeys().

// Example 1: Get the primary key of a simple table
// For employees table with id as primary key
keyName = model("employee").primaryKey();
// Returns: "id"

// Example 2: Alias usage
keyName = model("employee").primaryKeys();
// Returns: "id"

// Example 3: Composite primary key table (e.g., order_products with order_id + product_id)
keys = model("orderProduct").primaryKey();
// Returns: "order_id,product_id"

// Example 4: Fetching just the first key in a composite set
firstKey = model("orderProduct").primaryKey(position=1);
// Returns: "order_id"

// Example 5: Fetching the second key in a composite set
secondKey = model("orderProduct").primaryKey(position=2);
// Returns: "product_id"


























`````primaryKey:
The primaryKey() function is used inside migration table definitions to define a primary key for the table. By default, it creates a single-column integer primary key, but you can customize the data type, size, precision, and whether it should auto-increment. If you need composite primary keys, you can call this method multiple times within the same table definition. Additionally, you can configure references to other tables, along with cascading behaviors for updates and deletes.

migrate = {

    up = function() {
        createTable("users", function(table) {
            // Basic auto-incrementing integer primary key
            table.primaryKey(name="id", autoIncrement=true);
            table.string("email");
        });

        createTable("products", function(table) {
            // Primary key with custom type
            table.primaryKey(name="sku", type="string", limit=20);
            table.string("title");
        });

        createTable("order_items", function(table) {
            // Composite primary keys (order_id + product_id)
            table.primaryKey(name="order_id", type="integer");
            table.primaryKey(name="product_id", type="integer");
            table.integer("quantity");
        });

        createTable("sessions", function(table) {
            // UUID primary key
            table.primaryKey(name="session_id", type="uuid");
            table.datetime("created_at");
        });

        createTable("payments", function(table) {
            // Primary key with foreign key reference
            table.primaryKey(name="payment_id", autoIncrement=true);
            table.integer("order_id", references="orders.id", onDelete="cascade");
        });
    },

    down = function() {
        dropTable("users");
        dropTable("products");
        dropTable("order_items");
        dropTable("sessions");
        dropTable("payments");
    }
};



























`````primaryKeys:
The primaryKeys() function is an alias for primaryKey(). While both functions behave the same way, primaryKeys() is especially useful for readability when working with tables that use composite primary keys. It returns the name of the primary key column for the model’s underlying table. If the table uses multiple keys, a comma-delimited list of all keys is returned. You can also pass in the optional position argument to fetch a single key from a composite set.

// Example 1: Get the primary key of a simple table
// Employees table has "id" as primary key
keyNames = model("employee").primaryKeys();
// Returns: "id"

// Example 2: Composite primary keys (order_products table with order_id + product_id)
keys = model("orderProduct").primaryKeys();
// Returns: "order_id,product_id"

// Example 3: Get only the first key in a composite primary key
firstKey = model("orderProduct").primaryKeys(position=1);
// Returns: "order_id"

// Example 4: Get only the second key in a composite primary key
secondKey = model("orderProduct").primaryKeys(position=2);
// Returns: "product_id"

// Example 5: Using alias for clarity in multi-key situations
// This makes it more obvious the table has multiple keys
keys = model("orderProduct").primaryKeys();
// Easier to read than using model("orderProduct").primaryKey()



























`````processAction:
The processAction() function executes a specific action within the controller. While it is technically available in all controllers, it is primarily intended for testing purposes. In normal application flow, Wheels handles action execution automatically via processRequest(), so developers rarely need to call processAction() directly. However, in unit tests, it can be useful for simulating controller behavior, verifying filters, or isolating action logic without going through the full request lifecycle.

The optional includeFilters argument allows you to control whether before filters, after filters, or no filters at all should run when invoking the action. By default, all filters execute unless explicitly restricted.

// Example 1: Run an action with default behavior (all filters applied)
result = processAction("show");
// Executes the "show" action of the current controller with before/after filters

// Example 2: Run an action but only apply "before" filters
result = processAction("edit", includeFilters="before");
// Useful for testing preconditions without running the full action

// Example 3: Run an action but only apply "after" filters
result = processAction("update", includeFilters="after");
// Useful for testing cleanup logic that runs post-action

// Example 4: Run an action without any filters
result = processAction("delete", includeFilters=false);
// Skips before/after filters, only executes the "delete" action

// Example 5: Simulating in a test case
it("should process the show action without filters", function() {
    var controller = controller("users");
    var success = controller.processAction("show", includeFilters=false);
    expect(success).toBeTrue();
});

























`````processRequest:
The processRequest() function simulates a full controller request by creating a controller instance and executing a specific action based on the parameters provided. The controller and action are determined by the params struct, which must include at least the controller and action keys. This function is primarily designed for testing purposes, where it allows developers to mimic HTTP requests and observe responses without needing to go through the full web server stack.

By default, the function returns the rendered output of the action as a string. However, if you set the returnAs argument to "struct", you will receive a structured response containing detailed request information, including body, emails, files, flash, redirect, status, and type. You can also control the HTTP method, apply or skip filters, and wrap database changes in a transaction that rolls back at the end of the request to keep your test data clean.

// Example 1: Simple request, returns rendered output as string
result = processRequest(params={controller="users", action="show", id=5});
// Returns: rendered HTML for the users/show action

// Example 2: Simulate a POST request
result = processRequest(
    params={controller="users", action="create", name="Alice"},
    method="post"
);
// Returns: rendered output of the create action

// Example 3: Get a detailed struct response instead of just body
result = processRequest(
    params={controller="sessions", action="create", email="test@example.com"},
    method="post",
    returnAs="struct"
);
// Returns struct with keys: body, emails, files, flash, redirect, status, type

// Example 4: Automatically roll back database changes
result = processRequest(
    params={controller="orders", action="create", product_id=42},
    method="post",
    rollback=true
);
// Data is inserted during the request but rolled back afterward

// Example 5: Skip all filters
result = processRequest(
    params={controller="users", action="delete", id=10},
    includeFilters=false
);
// Runs delete action without before/after filters

// Example 6: Run only "before" filters (useful for testing filter logic)
result = processRequest(
    params={controller="users", action="edit", id=10},
    includeFilters="before"
);




























`````properties:
The properties() function returns a structure containing all the properties of a model object, where the keys are the property (column) names and the values are the current values for that object. This is useful when you want to inspect all the attributes of a record at once, serialize data, or debug object state. By default, properties() includes nested or associated properties (such as related objects). You can control this behavior using the returnIncluded argument to exclude them if you only want the direct properties of the object.

// Example 1: Get all properties for a user object
user = model("user").findByKey(1);
props = user.properties();
// Returns struct with all properties, e.g. {id=1, firstName="Alice", lastName="Smith", email="alice@example.com", ...}

// Example 2: Exclude nested/associated properties
user = model("user").findByKey(1);
props = user.properties(returnIncluded=false);
// Returns struct with only direct table columns, e.g. {id=1, firstName="Alice", lastName="Smith", email="alice@example.com"}

// Example 3: Iterate through properties
user = model("user").findByKey(2);
props = user.properties();
for (key in props) {
    writeOutput("#key#: #props[key]#<br>");
}
// Prints each property name and its value

// Example 4: Convert properties to JSON for API output
user = model("user").findByKey(3);
props = user.properties(returnIncluded=false);
jsonData = serializeJSON(props);
// Returns: {"id":3,"firstName":"John","lastName":"Doe","email":"john@example.com"}

// Example 5: Using with associations (if returnIncluded=true)
// A user with associated profile object might return:
// {id=4, firstName="Sara", lastName="Lee", profile={bio="Developer", website="example.com"}}



























`````property:
The property() function lets you customize how model properties map to database columns or SQL expressions. By default, Wheels automatically maps a model’s property name to the column with the same name in the table. However, when your database uses non-standard column names, calculated values, or requires custom behavior, you can use property() to override the default mapping.

This method also supports options for customizing labels, default values, validation behavior, and whether or not the property is included in queries.

// Example 1: Map property to a differently named column
// Database column is STR_USERS_FNAME, but we want to use firstName in CFML
property(name="firstName", column="STR_USERS_FNAME");

// Example 2: Map property to a calculated SQL expression
// Concatenate two columns into a single property
property(name="fullName", sql="STR_USERS_FNAME + ' ' + STR_USERS_LNAME");

// Example 3: Assign a custom label for forms and error messages
property(name="firstName", label="First name(s)");

// Example 4: Set a default value for new records
property(name="firstName", defaultValue="Dave");

// Example 5: Exclude property from SELECT queries
// Useful for virtual/computed properties you don’t want fetched from the DB
property(name="tempValue", select=false);

// Example 6: Override data type explicitly
property(name="isActive", dataType="boolean");

// Example 7: Disable automatic validations for a column
property(name="notes", automaticValidations=false);

// Example 8: Combine multiple options
// Map database column, set label, and provide default
property(
    name="status",
    column="USR_STATUS_CODE",
    label="Account Status",
    defaultValue="pending"
);




























`````propertyIsBlank:
The propertyIsBlank() function checks whether a given property on a model object is either:

Not defined on the model, or

Defined but set to an empty string ("").

This is the inverse of propertyIsPresent() which checks that a property both exists and has a non-empty value.

This function is especially useful in validations, conditional logic, and form handling when distinguishing between "no value" and "value present."

// Example 1: Basic usage
user = model("user").new();
isBlank = user.propertyIsBlank("firstName"); // returns true if firstName is not set

// Example 2: Property exists but is empty
user = model("user").new(firstName="");
isBlank = user.propertyIsBlank("firstName"); // true

// Example 3: Property exists with value
user = model("user").new(firstName="Salman");
isBlank = user.propertyIsBlank("firstName"); // false

// Example 4: Checking property that doesn’t exist on the model
isBlank = user.propertyIsBlank("nonexistentProperty"); // true

// Example 5: Using in validation logic
if (user.propertyIsBlank("email")) {
    writeOutput("Email is required.");
}























`````propertyIsPresent:
The propertyIsPresent() function checks whether a given property on a model object:

Exists on the model, and

Is not a blank string ("").

This is the inverse of propertyIsBlank() which checks that a property is either missing or empty.

// Example 1: Property exists with a value
employee = model("employee").new();
employee.firstName = "Dude";
writeOutput(employee.propertyIsPresent("firstName")); // true

// Example 2: Property exists but is blank
employee.firstName = "";
writeOutput(employee.propertyIsPresent("firstName")); // false

// Example 3: Property does not exist on the model
writeOutput(employee.propertyIsPresent("nonexistentProperty")); // false

// Example 4: Conditional logic
if (!employee.propertyIsPresent("email")) {
    writeOutput("Email is required.");
}


























`````propertyNames:
The propertyNames() function returns a list of all property names associated with a model. The list is ordered by the columns’ ordinal positions as they exist in the underlying database table. In addition to actual table columns, the list also includes any calculated properties defined through the property()
 method, which may be derived from SQL expressions or mapped column names.

This is useful when you need to dynamically work with all of a model’s attributes without hardcoding them, such as generating dynamic forms, building custom serializers, or inspecting ORM mappings.

// Example 1: Get property names for the User model
propNames = model("user").propertyNames();
writeOutput(propNames);
// Output: id,firstName,lastName,email,createdAt,updatedAt

// Example 2: Loop through property names
for (prop in listToArray(model("employee").propertyNames())) {
    writeOutput("Property: #prop#<br>");
}

// Example 3: Check if a property exists in the list
if (listFindNoCase(model("order").propertyNames(), "totalAmount")) {
    writeOutput("Order model has a totalAmount property.");
}

// Example 4: Including calculated properties
// In the model configuration:
property(name="fullName", sql="firstName + ' ' + lastName");

// propertyNames() will now include "fullName"
writeOutput(model("user").propertyNames());
// Output: id,firstName,lastName,email,createdAt,updatedAt,fullName

























`````protectedProperties:
The protectedProperties() function is used to protect one or more model properties from being set or modified through mass assignment operations. Mass assignment occurs when values are assigned to a model in bulk, such as through create(), update(), or updateAll() using a struct of data. By marking certain properties as protected, you can prevent accidental or malicious changes to sensitive fields (such as id, role, or passwordHash).

This method is typically called in the model’s config() function to define rules that apply across the entire model.

// Example 1: Protecting multiple properties
// In models/User.cfc
function config() {
    protectedProperties("firstName,lastName");
}

// Now, mass assignment will ignore these:
user = model("user").new({firstName="John", lastName="Doe", email="test@example.com"});
writeDump(user);
// firstName and lastName will remain blank, only email is set.


// Example 2: Protecting sensitive fields
// Prevent id and role from being mass assigned
function config() {
    protectedProperties("id,role");
}

// This ensures a malicious user cannot override the primary key or escalate their role
user.updateAll({id=999, role="admin", email="safe@example.com"});
// Only "email" will be updated.


// Example 3: Dynamic usage
function config() {
    // Combine static protection with conditional logic
    if (get("environment") == "production") {
        protectedProperties("passwordHash,lastLoginIp");
    }
}




























`````protectsFromForgery:
The protectsFromForgery() function enables protection against Cross-Site Request Forgery (CSRF) attacks in Wheels. When enabled, all incoming POST requests must include a valid authenticity token, either in the params.authenticityToken parameter or in the X-CSRF-Token HTTP header. If the token is missing or invalid, the request will be blocked based on the handling mode you choose.

It is recommended to call this method inside your base Controller.cfc so that CSRF protection applies across the entire application by default. You can then fine-tune its behavior for specific actions using the only and except arguments.

// Example 1: Protect all POST requests globally
// In controllers/Controller.cfc
function config() {
    protectsFromForgery();
}

// Example 2: Abort requests silently instead of throwing an error
function config() {
    protectsFromForgery(with="abort");
}

// Example 3: Apply CSRF protection only on create and update actions
function config() {
    protectsFromForgery(only="create,update");
}

// Example 4: Exclude the "webhook" action from CSRF protection
function config() {
    protectsFromForgery(except="webhook");
}

// Example 5: Ignore CSRF protection (not recommended, but useful for debugging)
function config() {
    protectsFromForgery(with="ignore");
}





























`````provides:
The provides() function defines the response formats that a controller can return. Clients can request a specific format in three ways:

Through a URL parameter called format (e.g., ?format=json)

By appending the format as an extension to the URL (e.g., /users/1.json) when URL rewriting is enabled

Through the Accept header in the HTTP request

By specifying the supported formats, you ensure that your controller can automatically render the response in the requested format, such as html, json, xml, csv, pdf, or xls. If no format is requested or supported, the controller defaults to html.

// Example 1: Provide HTML, XML, and JSON responses
function config() {
    provides("html,xml,json");
}

// Example 2: Provide only JSON and CSV
function config() {
    provides("json,csv");
}

// Example 3: Default behavior (HTML only)
function config() {
    provides(); // equivalent to provides("html")
}

// Example 4: Handling requested format in the action
function show() {
    // Wheels automatically detects the requested format and renders accordingly
    render(data=model("user").findByKey(params.id));
}

// Example 5: Using format extension in URL
// Requesting /users/10.json returns JSON
// Requesting /users/10.xml returns XML





























`````put:
The put() function creates a route that matches a URL requiring an HTTP PUT request. This is primarily used for exposing actions that update existing database records. While PUT is fully supported, consider using the patch() matcher for partial updates, as it is often more appropriate in RESTful applications.

Like other routing helpers in Wheels, put() allows you to define the route’s name, URL pattern, associated controller and action, and other options such as redirecting, scoping within nested resources, and referencing a controller in a package/subfolder.

<cfscript>
mapper()
    // Example 1: Nested resource update
    // Route: /ghosts/666/stories/616
    // Controller: Stories, Action: update
    .put(
        name="ghostStory",
        pattern="ghosts/[ghostKey]/stories/[key]",
        to="stories##update"
    )

    // Example 2: Simple resource update
    // Route: /goblins
    // Controller: Goblins, Action: update
    .put(name="goblins", controller="goblins", action="update")

    // Example 3: Update route with package/subfolder
    // Route: /preferences, Controller: users.Preferences, Action: update
    .put(name="preferences", to="preferences##update", package="users")

    // Example 4: Nested collection action
    // Route: /subscribers/3209/launch
    .resources(name="subscribers", nested=true)
        .put(name="launch", to="subscribers##update", on="collection")
    .end()
.end();
</cfscript>



























`````radioButton:
The radioButton() function generates an HTML radio button for a form, based on a model object’s property. It can handle simple properties as well as nested properties through associations, making it ideal for forms that work with both individual objects and collections.

You can customize the radio button with additional attributes, labels, and error handling options. It automatically reflects the object’s current property value, so if the property matches the tagValue, the radio button will be marked as checked.

This function helps you build dynamic forms safely and easily, with support for encoding to prevent XSS attacks, error highlighting, and custom HTML wrapping.

<!-- Example 1: Basic radio buttons for gender -->
<cfoutput>
<fieldset>
    <legend>Gender</legend>
    #radioButton(objectName="user", property="gender", tagValue="m", label="Male")#<br>
    #radioButton(objectName="user", property="gender", tagValue="f", label="Female")#
</fieldset>
</cfoutput>

<!-- Example 2: Radio buttons for nested association (committee members) -->
<cfoutput>
<cfloop from="1" to="#ArrayLen(committee.members)#" index="i">
    <div>
        <h3>#committee.members[i].fullName#:</h3>
        <div>
            #radioButton(
                objectName="committee",
                association="members",
                position=i,
                property="gender",
                tagValue="m",
                label="Male"
            )#<br>
            #radioButton(
                objectName="committee",
                association="members",
                position=i,
                property="gender",
                tagValue="f",
                label="Female"
            )#
        </div>
    </div>
</cfloop>
</cfoutput>

<!-- Example 3: Custom HTML wrapping and label placement -->
#radioButton(
    objectName="user",
    property="subscription",
    tagValue="premium",
    label="Premium Plan",
    prepend="<div class='radio-wrapper'>",
    append="</div>",
    labelPlacement="aroundRight"
)#





























`````radioButtonTag:
The radioButtonTag() function generates a standard HTML <input type="radio"> element based on the supplied name and value. Unlike radioButton(), this function works directly with form tags rather than binding to a model object. It is useful for simple forms or when you need fine-grained control over the HTML attributes.

You can customize the radio button with labels, label placement, HTML wrapping, and encoding to prevent XSS attacks. The generated radio button will be marked as checked if the checked argument is true.

<!-- Example 1: Basic radio buttons for gender -->
<cfoutput>
<fieldset>
    <legend>Gender</legend>
    #radioButtonTag(name="gender", value="m", label="Male", checked=true)#<br>
    #radioButtonTag(name="gender", value="f", label="Female")#
</fieldset>
</cfoutput>

<!-- Example 2: Label before radio button -->
#radioButtonTag(name="subscription", value="premium", label="Premium Plan", labelPlacement="before")#

<!-- Example 3: Custom HTML wrappers -->
#radioButtonTag(
    name="newsletter",
    value="yes",
    label="Subscribe",
    prepend="<div class='radio-wrapper'>",
    append="</div>",
    labelPlacement="aroundRight"
)#




























`````raised:
The raised() function is used in legacy Wheels testing to catch errors or exceptions raised by a given CFML expression. It evaluates the expression and, if an error occurs, returns the type of the error. This is especially useful when writing tests to ensure that specific operations correctly trigger exceptions under invalid or unexpected conditions.

By using raised(), you can assert that your code behaves safely and predictably when encountering errors.

// Example 1: Testing for a specific exception
// Assume updateUser() should throw an error if email is invalid
errorType = raised('model("user").updateUser({email="invalid-email"})');
assertEquals(errorType, "Wheels.InvalidEmailException");

// Example 2: Using raised() in a test case
function testInvalidPassword() {
    var errorType = raised('model("user").login(username="jdoe", password="wrong")');
    writeOutput("Caught error type: " & errorType);
    // Output: Caught error type: Wheels.InvalidPassword
}

// Example 3: Catching any error
var errorType = raised('1 / 0'); // Division by zero
writeOutput(errorType);
// Output: CFDivideByZeroException






























`````redirectTo:
The redirectTo() function is used to redirect the browser to another page, action, controller, route, or back to the referring page. Internally, it uses Wheels’ URLFor() function to construct the URL and the <cflocation> tag (or equivalent in your CFML engine) to perform the actual redirect.

You can redirect to internal routes or controllers, pass keys and query parameters, include anchors, override protocol, host, or port, and even delay the redirect until after your action code executes. This function ensures URLs are safely encoded and properly formatted for the redirect.

<!-- Example 1: Redirect to an action after saving -->
if (user.save()) {
    redirectTo(action="saveSuccessful");
}

<!-- Example 2: Redirect to a secure checkout page with parameters -->
redirectTo(
    controller="checkout",
    action="start",
    params="type=express",
    protocol="https"
);

<!-- Example 3: Redirect to a named route and pass a route parameter -->
redirectTo(route="profile", screenName="Joe");

<!-- Example 4: Redirect back to the referring page -->
redirectTo(back=true);

<!-- Example 5: Redirect to an external URL -->
redirectTo(url="https://example.com/welcome");































`````redoMigration:
The redoMigration() function allows you to rerun a specific database migration version. This can be useful for testing migrations, correcting issues in a migration, or resetting a schema change during development.

While it can be called directly from your application code, it is generally recommended to use this function via the CommandBox CLI or the Wheels GUI migration interface, as these provide safer execution and logging.

// Example 1: Rerun a specific migration version
result = redoMigration(version="202509250915_create_users_table");
writeOutput(result); // Returns status or log of the migration rerun

// Example 2: Using redoMigration in a script for testing
if (environment() == "development") {
    redoMigration(version="202509250920_add_email_index");
}

// Example 3: Rerun latest migration (if version not specified)
result = redoMigration();
writeOutput(result);


























`````references:
The references() function is used when defining a table schema to add reference columns that act as foreign keys, linking the table to other tables in the database. It automatically creates integer columns for the references and sets up foreign key constraints, helping maintain referential integrity.

You can customize the behavior of these reference columns, including whether they allow nulls, default values, or support polymorphic associations. You can also define actions for ON UPDATE and ON DELETE events.

// Example 1: Basic reference column
tableDefinition.references("userId");

// Example 2: Multiple references with nulls allowed
tableDefinition.references("userId,orderId", null=true);

// Example 3: Reference with default value
tableDefinition.references("statusId", default=1);

// Example 4: Polymorphic reference (used in polymorphic associations)
tableDefinition.references("referenceableId", polymorphic=true);

// Example 5: Custom foreign key actions
tableDefinition.references(
    "customerId",
    onUpdate="CASCADE",
    onDelete="SET NULL"
);























`````reload:
The reload() function refreshes the property values of a model object from the database. This is useful when an object’s values might have changed in the database due to other operations or external processes. By calling reload(), you ensure that your object reflects the current state of the corresponding database record.

// Example 1: Reload after a database update
employee = model("employee").findByKey(params.key);

// Call a method that modifies the database directly
employee.someCallThatChangesValuesInTheDatabase();

// Refresh the object to reflect the latest database values
employee.reload();

// Now employee properties are up-to-date
writeDump(employee);
cfml
Copy code
// Example 2: Reload inside a workflow after an external update
project = model("project").findByKey(42);

// Suppose another process updates project status in the database
externalUpdateProjectStatus(42);

// Reload to ensure object has latest status
project.reload();
writeOutput("Updated status: " & project.status);























`````removeColumn:
The removeColumn() function is used to delete a column from a database table within a migration CFC. This is useful when you need to remove obsolete or incorrectly added columns during schema evolution. Optionally, you can also remove a reference column by specifying its referenceName.

Since this function modifies the database schema, it should only be used inside a migration file to ensure proper version control and rollback capability.

// Example 1: Remove a single column from a table
removeColumn(table="users", columnName="middleName");

// Example 2: Remove a foreign key reference column
removeColumn(table="orders", referenceName="customerId");

// Example 3: Remove multiple columns in separate calls
removeColumn(table="products", columnName="oldPrice");
removeColumn(table="products", columnName="discountRate");



























`````removeIndex:
The removeIndex() function is used to delete an index from a database table within a migration CFC. Indexes are typically added to improve query performance, but there are scenarios where an index becomes unnecessary or needs to be replaced. Using removeIndex() allows you to safely remove an index while maintaining database integrity.

This function should only be called inside migration files to ensure proper version control and rollback capability.

// Example 1: Remove an index from the members table
removeIndex(table="members", indexName="members_username");

// Example 2: Remove an index from the orders table
removeIndex(table="orders", indexName="orders_createdAt_idx");

// Example 3: Remove multiple indexes in separate calls
removeIndex(table="products", indexName="products_name_idx");
removeIndex(table="products", indexName="products_category_idx");
























`````removeRecord:
The removeRecord() function is used to delete specific records from a database table within a migration CFC. This is useful when you need to clean up obsolete data, remove test data, or correct records as part of a schema migration.

You can optionally provide a where clause to target specific rows. If no where clause is provided, the behavior depends on the database; usually, no records are removed unless explicitly specified. This function should only be used inside migration files to ensure controlled and reversible changes.

// Example 1: Remove a specific record by ID
removeRecord(table="users", where="id = 42");

// Example 2: Remove multiple records matching a condition
removeRecord(table="orders", where="status = 'cancelled'");

// Example 3: Remove all records from a table (use with caution)
removeRecord(table="temporary_data", where="1=1");




























`````renameColumn:
The renameColumn() function is used to change the name of an existing column in a database table within a migration CFC. This is useful when you need to standardize column names, correct naming mistakes, or improve clarity in your database schema.

This function should only be used inside migration files to maintain proper version control and rollback capability. Renaming a column preserves the existing data and column type while updating the schema.

// Example 1: Rename a column in the users table
renameColumn(table="users", columnName="username", newColumnName="user_name");

// Example 2: Rename a column in the orders table
renameColumn(table="orders", columnName="createdAt", newColumnName="order_created_at");

// Example 3: Rename multiple columns in separate migration calls
renameColumn(table="products", columnName="oldPrice", newColumnName="price_old");
renameColumn(table="products", columnName="discountRate", newColumnName="discount_percent");
























`````renameTable:
The renameTable() function is used to change the name of an existing database table within a migration CFC. This is helpful when you want to standardize table names, correct naming mistakes, or improve clarity in your database schema.

This operation preserves all the existing data, indexes, and constraints in the table while updating its name. Since it modifies the schema, it should be used within a migration file to ensure proper version control and rollback capability.

// Example 1: Rename the users table
renameTable(oldName="users", newName="app_users");

// Example 2: Rename the orders table
renameTable(oldName="orders", newName="customer_orders");

// Example 3: Rename multiple tables in separate migration calls
renameTable(oldName="products_old", newName="products");
renameTable(oldName="temp_data", newName="archived_data");




























`````renderNothing:
The renderNothing() function instructs the controller to render an empty response when an action completes. Unlike using cfabort, which stops request processing immediately, renderNothing() ensures that any after filters associated with the action still execute.

You can optionally provide an HTTP status code to indicate the type of response being returned. This is useful for APIs or endpoints that need to signal a specific status without returning a body.

// Example 1: Render an empty page with default status (200 OK)
renderNothing();

// Example 2: Render nothing with a 204 No Content status
renderNothing(status="204");

// Example 3: Use renderNothing in an API endpoint after deleting a resource
function deleteResource() {
    resource = model("resource").findByKey(params.id);
    resource.delete();
    renderNothing(status="204");
}






























`````renderPartial:
The renderPartial() function instructs the controller to render a partial view when an action completes. Partials are reusable view fragments, typically prefixed with an underscore (e.g., _comment.cfm). This function allows you to render these fragments either directly to the client or capture them as a string for further processing.

You can control caching, layouts, HTTP status codes, and data-loading behavior, making it flexible for both full-page updates and AJAX responses.

// Example 1: Render a partial in the current controller's view folder
renderPartial("comment");

// Example 2: Render a partial from the shared folder
renderPartial("/shared/comment");

// Example 3: Render a partial without a layout
renderPartial("/shared/comment", layout=false);

// Example 4: Render a partial and return it as a string
commentHtml = renderPartial("comment", returnAs="string");

// Example 5: Render a partial with caching for 15 minutes
renderPartial("comment", cache=15);

// Example 6: Render a partial with a custom HTTP status code
renderPartial("comment", status="202");

























`````renderText:
The renderText() function instructs the controller to output plain text as the response when an action completes. Unlike rendering a view or partial, this sends the specified text directly to the client. This is especially useful for APIs, AJAX responses, or simple status messages.

You can also provide an HTTP status code to control the response status.

// Example 1: Render a simple message
renderText("Done!");

// Example 2: Render serialized product data as JSON
products = model("product").findAll();
renderText(SerializeJson(products));

// Example 3: Render a message with a custom HTTP status code
renderText("Unauthorized access", status=401);

// Example 4: Use in an API endpoint
function checkStatus() {
    if (someCondition()) {
        renderText("OK", status=200);
    } else {
        renderText("Error", status=500);
    }
}



























`````renderView:
The renderView() function instructs the controller to render a specific view template when an action completes. It determines which view file to display and which layout (if any) to wrap around it.

Unlike executing a different action directly, this function only loads the corresponding view template. You can render views from the current action, a different action in the same controller, or even a view in another controller. Additional options such as caching, layouts, hiding debug info, and returning the output as a string make it flexible for APIs, AJAX responses, or template manipulation.

// Example 1: Render a view page for a different action within the same controller
renderView(action="edit");

// Example 2: Render a view page for a different controller and action
renderView(controller="blog", action="new");

// Example 3: Render a specific template from a different folder
renderView(template="/blog/new");

// Example 4: Render the current action view without a layout and cache it for 60 minutes
renderView(layout=false, cache=60);

// Example 5: Load a layout from a different folder within views
renderView(layout="/layouts/blog");

// Example 6: Return the rendered view as a string for further processing
myView = renderView(returnAs="string");

// Example 7: Render a view and force a 202 HTTP status code
renderView(action="edit", status="202");




























`````renderWith:
The renderWith() function instructs the controller to render the given data in the format requested by the client. If the requested format is json or xml, Wheels automatically converts the data into the appropriate format. For other formats—or to override automatic formatting—you can create a view template matching the requested format, such as nameofaction.json.cfm, nameofaction.xml.cfm, or nameofaction.pdf.cfm.

This function is especially useful in APIs, AJAX endpoints, or situations where you need to respond dynamically in multiple formats based on client preferences. You can also control caching, layout, HTTP status codes, and whether to return the result as a string for further processing.

// Example 1: Render all products in the requested format (json, xml, etc.)
products = model("product").findAll();
renderWith(products);

// Example 2: Render a JSON error message with a 403 status code
msg = {
    "status" : "Error",
    "message": "Not Authenticated"
};
renderWith(data=msg, status=403);

// Example 3: Render with a custom layout
products = model("product").findAll();
renderWith(data=products, layout="/layouts/api");

// Example 4: Render a view template from a different controller
data = model("order").findAll();
renderWith(data=data, controller="orders", action="list");

// Example 5: Capture the output as a string instead of sending it to the client
output = renderWith(data=products, returnAs="string");




























`````resetCycle:
The resetCycle() function resets a named cycle, allowing it to start from the first value the next time it is called. In Wheels, cycle() is often used to alternate values in a repeated pattern, such as CSS classes for table rows, positions, or emphasis levels. By calling resetCycle(), you ensure that the cycle begins again from its initial value, which is useful when looping through nested structures or when a new grouping starts.

<!-- Example 1: Resetting a cycle for row colors in a grouped query -->
<cfoutput query="employees" group="departmentId">
    <div class="#cycle(values="even,odd", name="row")#">
        <ul>
            <cfoutput>
                <li class="#cycle(values="president,vice-president,director,manager,specialist,intern", name="position")#">
                    #categories.categoryName#
                </li>
                <!-- Reset the 'position' cycle for the next iteration -->
                <cfset resetCycle("position")>
            </cfoutput>
        </ul>
    </div>
</cfoutput>

<!-- Example 2: Resetting the default cycle -->
<cfset resetCycle()>



























`````resource:
The resource() function in Wheels is used to create a group of routes for a singular resource, exposing the full CRUD lifecycle without including a primary key in the URL. Singular resources are typically used for entities tied to the session, application, or another resource, such as a user's profile or a site-wide settings page.

Unlike resources() which generates routes for collections (including URLs with primary keys), resource() focuses on a single entity, providing routes for actions such as show, new, create, edit, update, and delete. You can customize the generated routes using options like controller, path, only, except, and nested. Additional options allow overriding singular/plural naming, adding constraints, supporting shallow nesting, and enabling format mapping for URLs (like .json or .xml).

<cfscript>
// Default singular resource for checkout
mapper().resource("checkout");

// Custom controller for authentication
mapper().resource(name="auth", controller="sessions.auth");

// Generate only specific routes
mapper().resource(name="profile", only="show,edit,update");

// Exclude certain routes
mapper().resource(name="cart", except="new,create,edit,delete");

// Nested resource example
mapper().resource(name="preferences", only="index", nested=true)
    .get(name="editPassword", to="passwords##edit")
    .patch(name="password", to="passwords##update")
    .resources("foods")
.end();

// Custom path
mapper().resource(name="blogPostOptions", path="blog-post/options");
</cfscript>




























`````resources:
The resources() function in Wheels is used to create a group of routes for a collection of resources, exposing the full CRUD lifecycle for multiple records. Plural resources typically represent database tables or collections, like posts, users, or orders. Unlike resource() (which is singular and doesn’t include a primary key in the URL), resources() generates routes for all standard actions including index, show, new, create, edit, update, and delete.

For actions that operate on a specific record (show, edit, update, delete), the URL includes the primary key of the resource. This method allows nesting of resources to reflect hierarchical relationships, like stories having heroes and villains as nested resources. You can also customize the generated routes using options like controller, path, only, except, shallow nesting, constraints, and optional format mapping.

<cfscript>
// Default collection resource
mapper().resources("admins");

// Custom controller mapping
mapper().resources(name="authors", controller="users");

// Generate only specific actions
mapper().resources(name="products", only="index,show,edit,update");

// Exclude a route
mapper().resources(name="orders", except="delete");

// Nested resources
mapper().resources(name="stories", nested=true)
    .resources("heroes")
    .resources("villains")
.end();

// Custom URL path
mapper().resources(name="blogPostsOptions", path="blog-posts/options");
</cfscript>



























`````response:
The response() function returns the content that Wheels is preparing to send back to the client for the current request. This can include the output generated by renderView(), renderPartial(), renderText(), or any other rendering function that has been called during the request lifecycle. Essentially, response() lets you inspect or manipulate the final output before it is sent to the client, which can be particularly useful in testing, debugging, or middleware-style functions.

<cfscript>
// Render a view for the current action
renderView(action="show");

// Capture the response content
wheelsResponse = response();

// Log or inspect the response
writeDump(wheelsResponse);
</cfscript>
cfml
Copy code
<cfscript>
// Render some text directly
renderText("Hello, Wheels!");

// Access the response content
wheelsResponse = response(); // Returns "Hello, Wheels!"
</cfscript>




























`````root:
The root() function defines a route that matches the root of the current context. This could be the root of the entire application (like the home page) or the root of a namespaced section of your routes. It is commonly used to map a controller action to the main entry point of your application or a subsection of it. You can specify the controller and action either using the to argument (controller##action) or by passing controller and action separately. Optionally, mapFormat can be set to true to allow a format suffix like .json or .xml in the URL.

1. Application Home Page
Map the root of the application (/) to a controller action:

<cfscript>
mapper()
    .root(to="dashboards##show")
.end();
</cfscript>


Explanation:
When a user visits /, the request is routed to the show action of the dashboards controller.

2. Root of a Namespaced Section (API)
Map /api to an API controller:

<cfscript>
mapper()
    .namespace("api")
        .root(controller="apis", action="index")
    .end();
</cfscript>


Explanation:
Visiting /api calls the index action of the apis controller. This is useful for API endpoints where you want a clean root for a namespace.

3. Root with Optional Format
Enable clients to request JSON or XML directly:

<cfscript>
mapper()
    .namespace("api")
        .root(controller="apis", action="index", mapFormat=true)
    .end();
</cfscript>


Explanation:
Requests to /api.json or /api.xml automatically format the response in the requested format.

4. Root for Nested Resources
Use root() inside a nested scope:

<cfscript>
mapper()
    .namespace("admin")
        .root(controller="dashboard", action="index")
    .end();
.end();
</cfscript>


Explanation:
Visiting /admin triggers the index action of the dashboard controller. This helps organize admin-specific routes under a clear namespace.

5. Multiple Namespaced Roots
Define separate roots for different sections of your application:

<cfscript>
mapper()
    .namespace("api")
        .root(controller="apis", action="index")
    .end()

    .namespace("reports")
        .root(controller="reports", action="overview")
    .end()

    // Default application root
    .root(to="home##show")
.end();
</cfscript>


Explanation:

/api → apis#index

/reports → reports#overview

/ → home#show

This setup provides clean, organized entry points for multiple application sections.



























`````save:
The save() function persists the current model object to the database. Wheels determines whether to perform an INSERT (for new objects) or UPDATE (for existing objects) automatically.

It returns:

true if the object was successfully saved.

false if the object failed validation or could not be saved.

save() also respects callbacks, validations, and parameterization by default, but these behaviors can be customized with optional arguments.

1. Basic Save (Automatic INSERT/UPDATE)

<cfscript>
user = model("user").new();
user.firstName = "Alice";
user.lastName = "Smith";
user.email = "alice@example.com";

if(user.save()){
    writeOutput("User saved successfully!");
} else {
    writeOutput("Error saving user. Please check validations.");
}
</cfscript>


Explanation:

Wheels will automatically determine if an INSERT or UPDATE is needed.

Validations and callbacks are executed by default.

2. Save Without Validations

<cfscript>
user = model("user").findByKey(1);
user.firstName = ""; // Normally fails validation

// Save without running validations
user.save(validate=false);
</cfscript>


Explanation:
Useful when you know the data is already clean, or when making programmatic updates that may temporarily violate validations.

3. Save Using Specific cfqueryparam Columns

<cfscript>
user = model("user").new();
user.firstName = "Bob";
user.lastName = "Jones";
user.email = "bob@example.com";

// Only parameterize the `email` field
user.save(parameterize="email");
</cfscript>


Explanation:

Enhances performance or compatibility when some columns do not require cfqueryparam.

4. Save Within a Transaction

<cfscript>
user = model("user").new();
user.firstName = "Charlie";
user.lastName = "Brown";
user.email = "charlie@example.com";

// Attempt to save, but roll back instead of committing
user.save(transaction="rollback");
</cfscript>


Explanation:

Useful in tests or batch operations where you want to execute the query without permanently modifying the database.

5. Save and Handle Callbacks Manually

<cfscript>
user = model("user").new();
user.firstName = "Dana";
user.lastName = "White";
user.email = "dana@example.com";

// Save without triggering beforeSave/afterSave callbacks
user.save(callbacks=false);
</cfscript>


Explanation:

Avoid running callbacks if you only want to persist data quickly or bypass custom logic.





























`````scope:
The scope() function in Wheels is used to define a block of routes that share common parameters, such as controller, package, path, or naming prefixes. All routes defined inside a scope() block inherit these parameters unless explicitly overridden.

This is particularly useful for:

Grouping routes under the same controller or package.

Adding a common URL prefix to multiple routes.

Applying shallow routing to nested resources.

Reducing repetition and improving maintainability of route definitions.

1. Set a default controller for multiple routes

<cfscript>
mapper()
    .scope(controller="freeForAll")
        .get(name="bananas", action="bananas")
        .root(action="index")
    .end()
.end();
</cfscript>


Explanation:
All routes inside the scope() block will use the freeForAll controller.

2. Apply a package/subfolder to multiple resources

<cfscript>
mapper()
    .scope(package="public")
        .resource(name="search", only="show,create")
    .end()
.end();
</cfscript>


Explanation:

All routes inside this scope will reference controllers inside the public package/subfolder.

3. Add a common URL path prefix

<cfscript>
mapper()
    .scope(path="phones")
        .get(name="newest", to="phones##newest")
        .get(name="sortOfNew", to="phones##sortOfNew")
    .end()
.end();
</cfscript>


Explanation:

All routes inside this scope will be prefixed with /phones/ in the URL.

Example URLs: /phones/newest and /phones/sort-of-new.

4. Combine controller and path scoping

<cfscript>
mapper()
    .scope(controller="products", path="shop")
        .get(name="featured", action="featured")
        .get(name="sale", action="sale")
    .end()
.end();
</cfscript>


Explanation:

All routes use the products controller and have a /shop/ prefix.

Generated URLs: /shop/featured → products##featured, /shop/sale → products##sale.

5. Use constraints for route variables

<cfscript>
mapper()
    .scope(path="users", constraints={userId="\d+"})
        .get(name="profile", pattern="[userId]/profile", action="show")
    .end()
.end();
</cfscript>



























`````secondSelectTag:
The secondSelectTag() function generates an HTML <select> form control populated with seconds (0–59) for a minute. You can bind it to a form parameter or manually set a selected value, control the step interval, include a blank option, and customize labels and HTML attributes.

This is especially useful for time selection forms, like setting the seconds for a scheduled task or timestamp input.

1. Basic select for seconds (0–59)

<cfoutput>
#secondSelectTag(name="secondsToLaunch")#
</cfoutput>


Result: A <select> element with options 0, 1, 2, …, 59.

2. Pre-select a second based on a parameter

<cfoutput>
#secondSelectTag(name="secondsToLaunch", selected=params.secondsToLaunch)#
</cfoutput>


If params.secondsToLaunch = 30, the option 30 will be selected.

3. Only show 15-second intervals

<cfoutput>
#secondSelectTag(name="secondsToLaunch", selected=params.secondsToLaunch, secondStep=15)#
</cfoutput>


Result: Options: 0, 15, 30, 45.

4. Include a blank option with custom text

<cfoutput>
#secondSelectTag(name="secondsToLaunch", includeBlank="- Select Seconds -")#
</cfoutput>


Adds a first option like <option value="">- Select Seconds -</option>.

5. Add a label around the select control

<cfoutput>
#secondSelectTag(name="secondsToLaunch", label="Launch Second", labelPlacement="around")#
</cfoutput>


Result:

<label>Launch Second
  <select name="secondsToLaunch">...</select>
</label>


























`````select:
The select() helper builds and returns an HTML <select> element bound to a model object property. It automatically handles nested associations, labels, options, and error highlighting. You can provide a list of options as a query, array of objects, or simple array, and customize labels, HTML attributes, and encoding.

It is especially useful for forms where a user must select a value from a predefined list that is related to a database model.

1. Basic select bound to a model property

<cfscript>
authors = model("author").findAll();
</cfscript>

<!--- View code --->
#select(objectName="book", property="authorId", options=authors)#


Automatically binds book.authorId to the selected option.

Uses the first column as value and display text if valueField and textField are not specified.

2. Using valueField and textField

#select(
    objectName="book",
    property="authorId",
    options=authors,
    valueField="id",
    textField="authorfullname"
)#


Required when options is an array of objects or query.

id will be used for option values, authorfullname for display text.

3. Include blank option

#select(
    objectName="book",
    property="authorId",
    options=authors,
    valueField="id",
    textField="authorfullname",
    includeBlank="- Select Author -"
)#


Adds a blank option at the top of the list.

4. Nested hasMany association

<cfloop from="1" to="#ArrayLen(shipments.orders)#" index="i">
    #select(
        label="Order #shipments.orders[i].orderNum#",
        objectName="shipment",
        association="orders",
        position=i,
        property="statusId",
        options=statuses,
        valueField="id",
        textField="name"
    )#
</cfloop>


Generates a <select> for each associated order within shipments.orders.

Properly handles nested objects and maintains binding to shipment.orders[i].statusId.

5. Custom label and placement

#select(
    objectName="book",
    property="authorId",
    options=authors,
    valueField="id",
    textField="authorfullname",
    label="Choose Author",
    labelPlacement="before"
)#


The label appears before the <select> element instead of the default wrapping.


























`````selectTag:
The selectTag() helper builds an HTML <select> element using a name and a set of options. Unlike select(), it does not require a model object and is not bound to a property. It is useful for standalone select controls or when you want full manual control over the field.

1. Basic selectTag with a query

<cfscript>
cities = model("city").findAll();
</cfscript>

<!--- View code --->
#selectTag(name="cityId", options=cities)#


Uses the first column of the query for both values and labels if valueField/textField not specified.

2. SelectTag with valueField and textField

#selectTag(
    name="cityId",
    options=cities,
    valueField="id",
    textField="name"
)#


Explicitly sets option values to id and display text to name.

Required when the options collection is an array of objects or query with multiple columns.

3. Including a blank option

#selectTag(
    name="cityId",
    options=cities,
    valueField="id",
    textField="name",
    includeBlank="- Select a City -"
)#


Adds a blank line at the top of the <select> dropdown.

4. Multiple selection

#selectTag(
    name="cityIds",
    options=cities,
    valueField="id",
    textField="name",
    multiple=true
)#


Generates a multi-select <select> element.

5. Custom label and HTML wrapping

#selectTag(
    name="cityId",
    options=cities,
    valueField="id",
    textField="name",
    label="Choose a City",
    labelPlacement="before",
    prepend="<div class='input-group'>",
    append="</div>"
)#


Places a label before the select field and wraps it in custom HTML.




























`````sendEmail:
sendEmail() is a helper that sends emails using a template with optional layouts. It wraps around <cfmail> and integrates with Wheels view templates, allowing you to pass variables to the template for dynamic content. You can also attach files or write the email content to a file without sending it.

1. Basic email to a new user

newMember = model("member").findByKey(params.member.id);

sendEmail(
    to=newMember.email,
    template="welcomeEmail",
    subject="Thank You for Joining!",
    recipientName=newMember.name,
    startDate=newMember.startDate
);


Sends a welcome email using the welcomeEmail template.

Template can reference recipientName and startDate.

2. Multipart email (HTML + text)

sendEmail(
    to="user@example.com",
    template=["welcomeEmailText", "welcomeEmailHTML"],
    subject="Welcome!",
    detectMultipart=true
);


Wheels detects which template is text vs HTML automatically.

3. Email with a layout

sendEmail(
    to="user@example.com",
    template="newsletter",
    layout="emailLayout",
    subject="Monthly Newsletter",
    userName="Salman"
);


Wraps the newsletter template inside the emailLayout template.

4. Email with attachments

sendEmail(
    to="user@example.com",
    template="reportEmail",
    subject="Your Monthly Report",
    file=["report.pdf", "summary.xlsx"]
);


Attaches files stored in the files folder.

5. Write email to a file without sending

sendEmail(
    to="user@example.com",
    template="testEmail",
    subject="Testing Email",
    writeToFile="#expandPath('./tmp/testEmail.eml')#",
    deliver=false
);


Useful for debugging templates without actually sending the email.




























`````sendFile:
sendFile() sends a file to the client. By default, it serves files from the files folder in your project or a path relative to it. You can control how the file is presented to the user (download dialog vs inline display), set the content type, rename it for the client, or even delete it from the server after delivery.

1. Send a file for download from the files folder

sendFile(file="wheels_tutorial_20081028_J657D6HX.pdf");


Sends the file for download using its original name.

Default disposition is attachment, so the browser shows a download dialog.

2. Rename the file for the client

sendFile(
    file="wheels_tutorial_20081028_J657D6HX.pdf",
    name="Tutorial.pdf"
);


User sees Tutorial.pdf in the download dialog instead of the original filename.

3. Send a file located outside the web root

sendFile(
    file="../../tutorials/wheels_tutorial_20081028_J657D6HX.pdf"
);


Works with relative or absolute paths outside the files folder.

4. Inline display instead of download

sendFile(
    file="brochure.pdf",
    disposition="inline",
    type="application/pdf"
);


PDF opens directly in the browser instead of triggering a download dialog.

Setting the type ensures the browser interprets the file correctly.

5. Delete file after sending

sendFile(
    file="temporary_report.xlsx",
    deleteFile=true
);


Sends the file to the client and then deletes it from the server.

Useful for temporary or dynamically generated files.




























`````set:
The set() function is used to configure global settings or set default argument values for Wheels functions. It can be applied to core functions, helpers, and even migrations. This allows you to define a standard behavior across your application without repeating arguments every time a function is called.

1. Set a global configuration value

// Set URL rewriting mode to Partial across the app
set(URLRewriting="Partial");


This affects how URLs are generated application-wide.

Other global settings (like caching or logging) can also be set in a similar way.

2. Set default values for a view helper

// Set default arguments for the `buttonTo` helper
set(
    functionName="buttonTo",
    onlyPath=true,
    host="",
    protocol="",
    port=0,
    text="",
    confirm="",
    image="",
    disable=""
);


Whenever buttonTo() is called, these defaults will be applied unless explicitly overridden.

Simplifies repetitive calls with common argument values.

3. Set default markup for form helpers

// Customize `textField` helper globally
set(
    functionName="textField",
    labelPlacement="before",
    prependToLabel="<div>",
    append="</div>",
    appendToLabel="<br>"
);


All calls to textField() will use these defaults, creating consistent HTML markup.

Useful for standardizing forms and styling across the application.

4. Configure a default for a migration helper

// Set default behavior for `references` in migrations
set(
    functionName="references",
    null=true,
    foreignKey=true,
    onDelete="cascade",
    onUpdate="cascade"
);


All calls to references() in migrations will automatically use these defaults unless overridden.

Helps maintain consistent database schema behavior.

5. Combine global settings with function defaults

// Global URL rewriting plus default helper settings
set(URLRewriting="Full");
set(functionName="radioButton", labelPlacement="aroundRight", encode=true);


Combines app-wide configuration with helper-level defaults.

Reduces repetitive code and enforces consistency.



























`````setFilterChain:
The setFilterChain() function provides a low-level way to define the complete filter chain for a controller. Unlike the higher-level beforeFilter() and afterFilter() methods, this lets you explicitly specify the sequence of filters, their scope, and the actions they apply to, all in a single configuration.

Filters are functions that run before, after, or around actions to handle tasks such as authentication, logging, or IP restrictions.

Example 1: Basic filter chain
// Set filter chain directly
setFilterChain([
    {through="restrictAccess"}, // runs for all actions by default
    {through="isLoggedIn, checkIPAddress", except="home, login"}, // exclude certain actions
    {type="after", through="logConversion", only="thankYou"} // after filter for specific action
]);


First filter: restrictAccess runs before all actions.

Second filter: isLoggedIn and checkIPAddress run before all actions except home and login.

Third filter: logConversion runs after the thankYou action only.

Example 2: Using only and except with different filter types
setFilterChain([
    {through="authenticateUser", only="edit, update, delete"}, // only for sensitive actions
    {through="trackActivity", except="index, show"},           // for most actions except viewing
    {type="after", through="sendAnalytics"}                   // after all actions
]);


Demonstrates selective filtering with only and except.

Can combine before (default) and after filters in the same chain.

Example 3: Multiple filters in one chain struct
setFilterChain([
    {through="validateSession, checkPermissions", only="admin, settings"},
    {through="logRequest"},
    {type="after", through="cleanupTempFiles"}
]);


Multiple filters can run together (validateSession and checkPermissions).

Mix of before and after filters ensures proper order and execution context.





























`````setPagination:
The setPagination() function allows you to define a pagination handle for a custom query so that you can easily generate paginated links and manage page offsets in your views. It’s useful when you want manual or database-driven pagination instead of relying on built-in model queries.

This works in combination with the pagination() function to retrieve pagination metadata (like startRow, endRow, maxRows) and paginationLinks() to render links in your view.

Example 1: CFML handles pagination

Model code:

function myCustomQuery(required numeric page, numeric perPage=25){
    local.customQuery = QueryExecute("SELECT * FROM users", [], { datasource=get('dataSourceName') });
    
    setPagination(
        totalRecords = local.customQuery.RecordCount,
        currentPage = arguments.page,
        perPage = arguments.perPage,
        handle = "myCustomQueryHandle"
    );

    return local.customQuery;
}


Controller code:

function list(){
    param name="params.page" default="1";
    param name="params.perPage" default="25";

    allUsers = model("user").myCustomQuery(page=params.page, perPage=params.perPage);
    paginationData = pagination("myCustomQueryHandle"); // get metadata
}


View code using cfloop:

<ul>
<cfloop query="allUsers" startrow="#paginationData.startrow#" endrow="#paginationData.endrow#">
    <li>#allUsers.firstName# #allUsers.lastName#</li>
</cfloop>
</ul>
#paginationLinks(handle="myCustomQueryHandle")#


View code using cfoutput:

<ul>
<cfoutput query="allUsers" startrow="#paginationData.startrow#" maxrows="#paginationData.maxrows#">
    <li>#allUsers.firstName# #allUsers.lastName#</li>
</cfoutput>
</ul>
#paginationLinks(handle="myCustomQueryHandle")#

Example 2: Database handles pagination (more efficient)

Model code:

function myCustomQuery(required numeric page, numeric perPage=25){
    local.customQueryCount = QueryExecute(
        "SELECT COUNT(*) AS theCount FROM users",
        [], { datasource=get('dataSourceName') }
    );

    local.offset = (arguments.page-1) * arguments.perPage;

    local.customQuery = QueryExecute(
        "SELECT * FROM users LIMIT ? OFFSET ?",
        [arguments.perPage, local.offset],
        { datasource=get('dataSourceName') }
    );

    setPagination(
        totalRecords = local.customQueryCount.theCount,
        currentPage = arguments.page,
        perPage = arguments.perPage,
        handle = "myCustomQueryHandle"
    );

    return local.customQuery;
}


Controller code:

function list(){
    param name="params.page" default="1";
    param name="params.perPage" default="25";

    allUsers = model("user").myCustomQuery(page=params.page, perPage=params.perPage);
}


View code (cfloop or cfoutput):

<ul>
<cfloop query="allUsers">
    <li>#allUsers.firstName# #allUsers.lastName#</li>
</cfloop>
</ul>

#paginationLinks(handle="myCustomQueryHandle")#




























`````setPrimaryKey:
The setPrimaryKey() function allows you to define which property (or properties) of a model represent the primary key in the database. This is crucial for Wheels to correctly handle CRUD operations, updates, and record lookups.

For single-column primary keys, pass the property name as a string.

For composite primary keys (multiple columns together form the key), pass a comma-separated list of property names.

Alias: setPrimaryKeys()

Example 1: Single primary key
component extends="Model" {

    function config() {
        // The primary key for this table is `userID`
        setPrimaryKey("userID");
    }

}


Effect: Wheels will use the userID column to identify records for findByKey(), update(), delete(), etc.

Example 2: Composite primary key
component extends="Model" {

    function config() {
        // The combination of `orderID` and `productID` uniquely identifies a record
        setPrimaryKey("orderID,productID");
    }

}


Effect: Wheels treats the combination of orderID and productID as the unique key for CRUD operations.

Example 3: Using the alias setPrimaryKeys()
component extends="Model" {

    function config() {
        // Alias works the same as `setPrimaryKey()`
        setPrimaryKeys("customerID");
    }

}


Effect: Wheels will behave exactly the same as using setPrimaryKey().




























`````setPrimaryKeys:
setPrimaryKeys() is an alias for setPrimaryKey(), intended to make code more readable when defining composite primary keys.

For single-column primary keys, it works the same as setPrimaryKey().

For composite primary keys, you pass a comma-separated list of property names.

Example 1: Single primary key
component extends="Model" {

    function config() {
        // Using the alias for a single primary key
        setPrimaryKeys("userID");
    }

}


Effect: Identical to setPrimaryKey(). Wheels will use userID for record operations.

Example 2: Composite primary key
component extends="Model" {

    function config() {
        // Composite key: combination of customerId and publicationId
        setPrimaryKeys("customerId,publicationId");
    }

}


Effect: Wheels treats customerId + publicationId as the unique identifier for CRUD operations (findByKey(), update(), delete()).




























`````setProperties:
setProperties() allows you to set multiple properties of a model object at once. It is useful when you want to update a model with a structure (struct) of key/value pairs instead of assigning each property individually.

The keys of the struct should match the property names of the model.

You can also pass named arguments directly instead of a struct.

Example 1: Using a struct (common scenario with form submission)
// Controller code: retrieve user from database
user = model("user").findByKey(1);

// Set properties from a submitted form
user.setProperties(params.user);

// Save the updated user
user.save();


Effect: All keys in params.user that match the user model’s properties will be updated.

Example 2: Using named arguments
user = model("user").findByKey(1);

// Set properties directly using named arguments
user.setProperties(
    firstName="John",
    lastName="Doe",
    email="john.doe@example.com"
);

// Save changes
user.save();

Example 3: Using with validations
user = model("user").findByKey(2);

// Set multiple properties, skipping one intentionally
user.setProperties({
    firstName = "Jane",
    lastName = "Smith"
});

// Only save if validations pass
if(user.save()){
    writeOutput("User updated successfully!");
} else {
    writeDump(user.errors);
}


Effect: Only firstName and lastName are updated; any other properties remain unchanged. Validations are enforced unless validate=false is passed to save().


























`````setResponse:
setResponse() allows you to manually set the content that Wheels will send back to the client for a given request. Unlike renderView() or renderText(), which automatically generate output from templates or data, setResponse() gives you full control over the response content.

Example 1: Sending plain text
function myAction() {
    setResponse("This is a custom response sent directly to the client.");
}


Effect: The browser will display exactly:
This is a custom response sent directly to the client.

Example 2: Sending JSON content
function getUserData() {
    user = model("user").findByKey(1);
    
    // Convert the user object to JSON
    jsonData = serializeJson(user);
    
    // Set the JSON response
    setResponse(jsonData);
}


Effect: The client receives a JSON representation of the user object. You can also set the response content type using cfheader if needed:

cfheader(name="Content-Type", value="application/json");

Example 3: Sending HTML content
function showCustomHtml() {
    htmlContent = "<h1>Welcome!</h1><p>This is a custom HTML response.</p>";
    setResponse(htmlContent);
}


Effect: The client will render the HTML directly.


























`````setTableNamePrefix:
setTableNamePrefix() allows you to add a prefix to the table name used by a model when performing SQL queries. This is useful if your database uses a consistent naming convention, such as tblUsers instead of Users.

By default, Wheels infers the table name from the model name (e.g., User → users). Using a prefix ensures that all queries automatically reference the correctly prefixed table.

Example 1: Basic prefix
// In models/User.cfc
function config(){
    // All queries will now target 'tblUsers' instead of 'users'
    setTableNamePrefix("tbl");
}


Effect:

user = model("user").findByKey(1);


Generates SQL similar to:

SELECT * FROM tblUsers WHERE userID = 1

Example 2: Using a custom prefix for multiple models
// models/Product.cfc
function config(){
    setTableNamePrefix("tbl");
}

// models/Order.cfc
function config(){
    setTableNamePrefix("tbl");
}


All queries for Product and Order will now reference tblProducts and tblOrders automatically.


























`````setup:
The setup() function is a callback used in Wheels legacy testing framework. It runs before every individual test case within a test suite. This allows you to prepare the test environment, initialize objects, or reset state before each test executes.

Example 1: Basic setup for a test suite
component extends="TestCase" {

    // Will run before every test case
    function setup() {
        // Initialize a new user object before each test
        variables.user = model("user").init();
    }

    function testUserCreation() {
        variables.user.firstName = "John";
        variables.user.lastName = "Doe";

        expect(variables.user.save()).toBeTrue();
    }

    function testUserEmailValidation() {
        variables.user.email = "invalid-email";

        expect(variables.user.valid()).toBeFalse();
        assertHasErrors(variables.user, "email");
    }
}


Explanation:

setup() ensures that variables.user is reset before each test, so tests are independent.

Example 2: Reset database table before each test
component extends="TestCase" {

    function setup() {
        // Delete all records in the users table before each test
        model("user").deleteAll();
    }

    function testUserInsert() {
        newUser = model("user").init(firstName="Alice", lastName="Smith");
        expect(newUser.save()).toBeTrue();
    }

    function testUserCount() {
        count = model("user").count();
        expect(count).toBe(0); // Will always pass due to setup()
    }
}


Explanation:

setup() ensures a clean database state before each test case runs.































`````setVerificationChain:
setVerificationChain() allows you to define the entire verification chain for a controller in a low-level, structured way. Verification chains are used to validate requests, ensuring they meet specific requirements (like HTTP method, parameters, or types) before the controller action executes.

Instead of defining individual verifies() calls in each action, you can use setVerificationChain() to set all verifications at once.

Example 1: Basic verification chain
component extends="Controller" {

    function init() {
        // Set verification rules for multiple actions
        setVerificationChain([
            {only="handleForm", post=true},
            {only="edit", get=true, params="userId", paramsTypes="integer"}
        ]);
    }

    function handleForm() {
        // Action logic here
    }

    function edit() {
        // Action logic here
    }
}


Explanation:

handleForm must be accessed via POST.

edit must be accessed via GET and requires a userId parameter of type integer.

Example 2: Adding custom error handling
component extends="Controller" {

    function init() {
        setVerificationChain([
            {only="edit", get=true, params="userId", paramsTypes="integer", handler="index", error="Invalid userId"},
            {only="delete", post=true, params="id", paramsTypes="integer", error="Missing or invalid id"}
        ]);
    }

    function edit() { /* edit logic */ }
    function delete() { /* delete logic */ }
}


Explanation:

If the userId parameter for edit is invalid, the request is redirected to index with the error message.

delete must be accessed via POST and requires a valid id.



























`````simpleFormat:
simpleFormat() takes plain text and converts newline (\n) and carriage return characters (\r\n) into HTML <br> and <p> tags for display in a browser.
This is particularly useful for rendering user-submitted text (like blog posts, comments, or descriptions) in a way that respects the author’s formatting.

By default, the text is wrapped in a <p> element and URL parameters are encoded for safety.

Example 1: Typical usage
#simpleFormat(post.bodyText)#


If post.bodyText =

This is the first line.

This is the second paragraph.


Output:

<p>This is the first line.</p>

<p>This is the second paragraph.</p>

Example 2: Demonstrating line breaks
<cfsavecontent variable="comment">
I love this post!

Here's why:
* Short
* Succinct
* Awesome
</cfsavecontent>

#simpleFormat(comment)#


Output:

<p>I love this post!</p>

<p>Here's why:<br>
* Short<br>
* Succinct<br>
* Awesome</p>

Example 3: Disable paragraph wrapping
<cfsavecontent variable="bio">
Hello, I’m Salman.
I write about ColdFusion and backend development.
</cfsavecontent>

#simpleFormat(bio, wrap=false)#


Output:

Hello, I’m Salman.<br>
I write about ColdFusion and backend development.


(No <p> tags, only <br> for newlines.)

Example 4: Handling user input safely

When you’re rendering user-submitted text in HTML attributes, simpleFormat() alone is not enough:

<!-- Incorrect usage in an attribute -->
<div title="#simpleFormat(userInput)#">...</div>


Instead, combine with EncodeForHtmlAttribute():

<div title="#EncodeForHtmlAttribute(simpleFormat(userInput))#">...</div>





























`````singularize:
singularize() converts a plural word into its singular form.
It uses Wheels’ built-in inflection rules, handling common English pluralization cases as well as irregular words.

This is useful when dynamically generating model names, table names, or working with resource naming conventions.

Example 1: Simple plural → singular
#singularize("languages")#


Output:

language

Example 2: Words ending in -ies
#singularize("companies")#


Output:

company

Example 3: Words ending in -es
#singularize("boxes")#


Output:

box

Example 4: Irregular plural
#singularize("children")#


Output:

child

Example 5: When used in a controller/model context
// Suppose you have a resource named "users"
// Wheels might call `singularize("users")` internally to map to the `User` model
userModelName = singularize("users");
writeOutput(userModelName); // Outputs: User

























`````startFormTag:
startFormTag() builds and returns an opening <form> tag.
The form’s action URL is automatically generated following the same rules as urlFor().

You can pass standard Wheels routing arguments (controller, action, route, key, params) as well as custom HTML attributes (id, class, rel, etc.).
Use this in combination with endFormTag() to wrap your form controls.

Example 1: Basic form for create action
#startFormTag(action="create")#
    #textFieldTag(name="firstName")#
    #submitTag(value="Save")#
#endFormTag()#


Output:

<form action="/users/create" method="post">
    <input type="text" name="firstName">
    <input type="submit" value="Save">
</form>

Example 2: Form with file upload
#startFormTag(action="upload", multipart=true)#
    #fileFieldTag(name="profilePicture")#
    #submitTag(value="Upload")#
#endFormTag()#

Example 3: Using a named route
#startFormTag(route="registerUser")#
    #textFieldTag(name="email")#
    #passwordFieldTag(name="password")#
    #submitTag(value="Register")#
#endFormTag()#

Example 4: Passing keys and params
#startFormTag(controller="posts", action="edit", key=42, params="draft=true")#
    #textAreaTag(name="content")#
    #submitTag(value="Update Post")#
#endFormTag()#


Generates a form pointing to:

/posts/edit/42?draft=true

Example 5: Custom attributes
#startFormTag(action="search", id="searchForm", class="inline-form")#
    #textFieldTag(name="q")#
    #submitTag(value="Search")#
#endFormTag()#


























`````string:
The string() function is used inside a migration’s createTable() or changeTable() block to add one or more string (VARCHAR) columns to a database table.

It supports specifying default values, nullability, and a maximum length (limit).

Example 1: Add a simple string column
createTable("users", function(table) {
    table.string("username");
});


Creates a username column of type string.

Example 2: Limit the length of the string
createTable("users", function(table) {
    table.string("email", limit=255);
});


Creates an email column with a maximum length of 255 characters.

Example 3: Set default values
createTable("products", function(table) {
    table.string("status", default="active");
});


Adds a status column with a default value of "active".

Example 4: Multiple columns in one call
createTable("profiles", function(table) {
    table.string("firstName,lastName");
});


Creates two string columns: firstName and lastName.

Example 5: Nullable vs non-nullable
createTable("settings", function(table) {
    table.string("configKey", null=false);
    table.string("configValue", null=true);
});


configKey must always have a value (NOT NULL).

configValue can be left NULL.


























`````stripLinks:
The stripLinks() function removes all <a> tags (hyperlinks) from an HTML string while preserving the inner text.
This is useful when you want to display content without clickable links but still retain the text inside them.

Example 1: Remove links but keep text
#stripLinks('<strong>Wheels</strong> is a framework for <a href="http://www.adobe.com/products/coldfusion">ColdFusion</a>.')#


Output:

<strong>Wheels</strong> is a framework for ColdFusion.

Example 2: Strip links from user-submitted content
userComment = '<p>Check out <a href="http://spam.com">this link</a>!</p>';
#stripLinks(userComment)#


Output:

<p>Check out this link!</p>

Example 3: Encoding URLs (optional)
#stripLinks('<a href="http://example.com/page?param=value&another=1">Example</a>', encode=false)#


Output:

Example


























`````stripTags:
The stripTags() function removes all HTML tags from a string, leaving only the raw text content.
Use this when you need to sanitize HTML by completely removing formatting and markup.

Example 1: Remove all tags from a string
#stripTags('<strong>Wheels</strong> is a framework for <a href="http://www.adobe.com/products/coldfusion">ColdFusion</a>.')#


Output:

Wheels is a framework for ColdFusion.

Example 2: Sanitize user input
userInput = '<script>alert("xss")</script>Normal text';
#stripTags(userInput)#


Output:

Normal text

Example 3: With encoding
#stripTags('<a href="http://example.com/page?param=value&another=1">Example</a>')#


Output:

Example























`````styleSheetLinkTag:
The styleSheetLinkTag() function generates one or more <link> tags for including CSS stylesheets in your application.
By default, it looks in the stylesheets folder of your app but can also handle external URLs or place stylesheets directly in the <head> section when needed.

Example 1: Single local stylesheet
#styleSheetLinkTag("styles")#


Output:

<link href="/stylesheets/styles.css" rel="stylesheet" type="text/css" media="all" />

Example 2: Multiple stylesheets
#styleSheetLinkTag("blog,comments")#


Output:

<link href="/stylesheets/blog.css" rel="stylesheet" type="text/css" media="all" />
<link href="/stylesheets/comments.css" rel="stylesheet" type="text/css" media="all" />

Example 3: Print-specific stylesheet
#styleSheetLinkTag(sources="print", media="print")#


Output:

<link href="/stylesheets/print.css" rel="stylesheet" type="text/css" media="print" />

Example 4: External stylesheet (e.g., CDN)
#styleSheetLinkTag("https://cdn.example.com/ui.css")#


Output:

<link href="https://cdn.example.com/ui.css" rel="stylesheet" type="text/css" media="all" />

Example 5: Forcing a stylesheet into <head>
#styleSheetLinkTag(sources="tabs", head=true)#


























`````submitTag:
The submitTag() function generates a submit button form control (<input type="submit"> by default, or <input type="image"> if you specify an image).
You can customize the button text, use an image, or add extra HTML attributes (such as class, id, or rel).

Example 1: Default submit button
#startFormTag(action="save")#
    #submitTag()#
#endFormTag()#


Output:

<form action="/save" method="post">
    <input type="submit" value="Save changes" />
</form>

Example 2: Custom button label
#submitTag(value="Register Now")#


Output:

<input type="submit" value="Register Now" />

Example 3: Submit button with CSS class and ID
#submitTag(value="Update Profile", class="btn btn-primary", id="updateBtn")#


Output:

<input type="submit" value="Update Profile" class="btn btn-primary" id="updateBtn" />

Example 4: Submit as an image button
#submitTag(image="submit-icon.png", value="Submit Form")#


Output:

<input type="image" src="/images/submit-icon.png" alt="Submit Form" />

Example 5: Wrapping with prepend and append
#submitTag(
    value="Send Message",
    prepend="<div class='form-actions'>",
    append="</div>"
)#


Output:

<div class='form-actions'>
    <input type="submit" value="Send Message" />
</div>

























`````sum:
The sum() function calculates the total of all values for a given property (column) using SQL’s SUM() function.
It’s typically used to aggregate numeric values across a set of records (e.g., summing salaries, prices, or quantities).

You can add filtering with where, group results with group, or join associations using include.
If no records are found, use the ifNull argument to return a safe default (commonly 0 for numeric sums).

Example 1: Basic sum

Get the total of all salaries:

allSalaries = model("employee").sum("salary");

Example 2: With filtering (where)

Get the sum of salaries for employees in Australia:

allAustralianSalaries = model("employee").sum(
    property="salary",
    include="country",
    where="countryname='Australia'"
);

Example 3: With ifNull safeguard

Always return a numeric result, even if no records are found:

salarySum = model("employee").sum(
    property="salary",
    where="salary BETWEEN #params.min# AND #params.max#",
    ifNull=0
);

Example 4: Sum with grouping

Get the total salary per department:

salariesByDept = model("employee").sum(
    property="salary",
    group="departmentId"
);


Output (query result):

departmentId	sum
1	45000
2	60000
Example 5: Distinct sum

Avoid counting duplicate salaries:

uniqueSalaries = model("employee").sum(
    property="salary",
    distinct=true
);


























`````table:
The table() function is used to tell Wheels which database table a model should connect to. Normally, Wheels automatically maps a model name to a plural table name (for example, a model named User maps to the users table). However, when your database uses custom naming conventions that do not match the Wheels defaults, you can override the mapping by explicitly specifying the table name with table(). If you want a model to not be tied to any database table at all, you can set table(false). This is useful for models that are used purely for logic, service layers, or scenarios where the model acts as a data wrapper without persistence.

Basic override for custom table name

// In models/User.cfc
function config() {
    // Tell Wheels to use the `tbl_USERS` table instead of the default `users`.
    table("tbl_USERS");
}


Using a table with a completely different name

// In models/Order.cfc
function config() {
    // Map the Order model to a table named `sales_transactions`.
    table("sales_transactions");
}


Disabling table mapping for a non-database model

// In models/Notification.cfc
function config() {
    // This model will not connect to any table.
    table(false);
}


Working with legacy naming conventions

// In models/Product.cfc
function config() {
    // The database uses uppercase with prefixes for tables.
    table("LEGACY_PRODUCTS_TABLE");
}


Example with schema-qualified table

// In models/Invoice.cfc
function config() {
    // Explicitly set schema and table if needed.
    table("accounting.invoices");
}





























`````tableName:
The tableName() function returns the name of the database table that a model is mapped to. Wheels automatically determines the table name based on its naming convention, where a singular model name maps to a plural table name (for example, a model named User maps to the users table). If the table has been explicitly overridden using the table() function in the model’s config(), then tableName() will return the custom mapping instead. This function is useful when you want to programmatically check or log the database table a model is connected to, especially in projects with mixed or legacy naming conventions.

Checking the default mapping

// In a controller or anywhere you need to check
defaultTable = model("user").tableName();
// Returns "users"


Checking a custom-mapped model

// In models/User.cfc
function config() {
    table("tbl_USERS");
}

// Later in code
customTable = model("user").tableName();
// Returns "tbl_USERS"


Using in debugging or logging

// Log which table a model points to for troubleshooting
writeDump(model("order").tableName());


Schema-qualified table name

// In models/Invoice.cfc
function config() {
    table("accounting.invoices");
}

// Later in code
schemaTable = model("invoice").tableName();
// Returns "accounting.invoices"






























`````teardown:
The teardown() function is a callback that executes after every test case when using Wheels’ legacy testing framework. It is typically used to clean up any data, variables, or state changes made during a test, ensuring that each test runs in isolation and does not interfere with subsequent tests. This helps maintain reliability and consistency across the test suite. If defined, teardown() runs automatically after each test case without requiring manual calls.

Basic cleanup after tests

// In tests/models/UserTest.cfc
function teardown() {
    // Remove temporary data created during the test
    queryExecute("DELETE FROM users WHERE email LIKE 'testuser%@example.com'");
}


Resetting application variables

// In tests/controllers/SessionTest.cfc
function teardown() {
    // Clear session values to avoid leaking between tests
    structClear(session);
}


Rolling back test data with transactions

// In tests/models/OrderTest.cfc
function teardown() {
    // Roll back the transaction started in setup
    transaction action="rollback";
}


Cleaning up mock objects or stubs

// In tests/services/NotificationServiceTest.cfc
function teardown() {
    // Reset mock services after each test
    variables.mockService.reset();
}



























`````testExample:
this is an example test so need to remove it.



























`````text:
The text() function is used within a migration to add one or more text columns to a database table definition. Text columns are designed for storing larger amounts of character data compared to standard string or varchar columns. This function allows you to define the column name, set a default value, and control whether the column allows null values. If multiple column names are passed in, the same options apply to all of them.

Adding a single text column

// In a migration file
t.text("description");


Adding multiple text columns at once

// Creates both summary and notes columns as text types
t.text("summary,notes");


Specifying a default value

// Adds a column with a default placeholder text
t.text(columnNames="details", default="N/A");


Requiring non-null values

// Adds a text column that must always have a value
t.text(columnNames="bio", null=false);


Combining options

// Adds a column with a default value and disallows nulls
t.text(columnNames="comments", default="No comments provided", null=false);





























`````textArea:
The textArea() function builds and returns an HTML <textarea> form control for a given model object and property. It is commonly used when you need a larger text input field, such as for descriptions, comments, or notes. The function automatically binds the value of the specified property from the object to the textarea. You can also pass additional attributes like class, id, or rel to customize the generated HTML. When working with nested forms or associations, you can specify the association and position arguments to bind the field to related objects. Wheels also provides options to add labels, control label placement, prepend or append HTML around the field, and handle error display automatically.

Basic textarea with label

#textArea(label="Overview", objectName="article", property="overview")#


This generates a textarea for the overview property of the article object with a label displayed by default.

Customizing with HTML attributes

#textArea(
    label="Comments", 
    objectName="post", 
    property="comments", 
    class="form-control", 
    id="commentsBox", 
    rows="5", 
    cols="50"
)#


Here the textarea is given a Bootstrap class, custom ID, and defined rows and columns.

Using with nested associations

<fieldset>
    <legend>Screenshots</legend>
    <cfloop from="1" to="#ArrayLen(site.screenshots)#" index="i">
        #fileField(label="File #i#", objectName="site", association="screenshots", position=i, property="file")#
        #textArea(label="Caption #i#", objectName="site", association="screenshots", position=i, property="caption")#
    </cfloop>
</fieldset>


This example shows a hasMany association where each screenshot has its own caption field.

Controlling label placement

#textArea(
    label="Details", 
    objectName="project", 
    property="details", 
    labelPlacement="before"
)#


Places the label before the textarea rather than wrapping around it.

Prepending and appending HTML

#textArea(
    label="Notes", 
    objectName="task", 
    property="notes", 
    prepend="<div class='input-wrapper'>", 
    append="</div>"
)#


Wraps the textarea inside a custom <div> for styling.

Handling validation errors

#textArea(
    label="Description", 
    objectName="product", 
    property="description", 
    errorElement="div", 
    errorClass="input-error"
)#




























`````textAreaTag:
The textAreaTag() function builds and returns an HTML <textarea> form control based only on the supplied field name, rather than being tied to a specific model object. It is useful when you want to generate a standalone text area not bound to an object, such as for ad-hoc forms, search boxes, or generic input fields. You can set the initial content of the textarea, add a label, and pass in additional attributes like class, id, or rel. Options are also available to control label placement, prepend or append HTML wrappers, and configure whether output should be encoded for XSS protection.

Basic textarea with label

#textAreaTag(label="Description", name="description", content=params.description)#


Generates a textarea with the value from params.description and a label displayed around it.

Textarea with custom attributes

#textAreaTag(
    label="Notes", 
    name="notes", 
    class="form-control", 
    id="notesBox", 
    rows="6", 
    cols="60"
)#


Adds custom styling, ID, and row/column attributes to the textarea.

Textarea without label

#textAreaTag(name="feedback", content="Enter your feedback here...")#


Creates a textarea without a label and with default placeholder text.

Custom label placement

#textAreaTag(
    label="Comments", 
    name="comments", 
    labelPlacement="before"
)#


Places the label before the textarea instead of wrapping it.

Prepending and appending HTML

#textAreaTag(
    label="Message", 
    name="message", 
    prepend="<div class='input-wrapper'>", 
    append="</div>"
)#





























`````textField:
The textField() function builds and returns an HTML <input type="text"> form control that is bound to a model object and one of its properties. By default, it will populate the value of the field from the property on the object. You can pass additional attributes such as class, id, or rel to customize the rendered tag. When working with nested associations or hasMany relationships, you can use the association and position arguments to bind the field to related properties. Wheels also supports automatically generating and placing labels, wrapping controls with custom HTML, and marking fields with errors when validation fails. The type argument lets you adjust the input type for use with HTML5 attributes like email, tel, or url.

Basic text field with label

#textField(label="First Name", objectName="user", property="firstName")#


Generates a labeled text field bound to the firstName property of the user object.

Using a custom input type

#textField(
    label="Email Address", 
    objectName="user", 
    property="email", 
    type="email"
)#


Creates an email input field using HTML5 validation.

Adding CSS classes and attributes

#textField(
    label="Phone", 
    objectName="contact", 
    property="phoneNumber", 
    class="form-control", 
    placeholder="Enter phone number"
)#


Renders a styled text field with a placeholder.

Nested form with hasMany association

<fieldset>
    <legend>Phone Numbers</legend>
    <cfloop from="1" to="#ArrayLen(contact.phoneNumbers)#" index="i">
        #textField(
            label="Phone ##i#", 
            objectName="contact", 
            association="phoneNumbers", 
            position=i, 
            property="phoneNumber"
        )#
    </cfloop>
</fieldset>


Creates multiple fields for a hasMany relationship (e.g., multiple phone numbers for one contact).

Prepending and appending HTML wrappers

#textField(
    label="Website", 
    objectName="company", 
    property="website", 
    prepend="<div class='field-wrapper'>", 
    append="</div>"
)#


Wraps the text field with custom HTML for layout purposes.

Handling validation errors

#textField(
    label="Username", 
    objectName="user", 
    property="username", 
    errorElement="div", 
    errorClass="input-error"
)#




























`````textFieldTag:
Builds and returns a string containing an HTML text field form control based on the supplied name.

Pass any additional arguments (e.g. class, rel, id) and the generated tag will also include those values as HTML attributes.

Examples
<!--- Basic usage with label, name, and value --->
#textFieldTag(label="Search", name="q", value=params.q)#

<!--- Email input with placeholder and custom class --->
#textFieldTag(name="email", label="Email Address", type="email", class="form-control", placeholder="you@example.com")#

<!--- Label placed after the input --->
#textFieldTag(name="username", label="Username", labelPlacement="after")#

<!--- Wrapped with prepend/append for Bootstrap styling --->
#textFieldTag(name="price", label="Price", prepend="<div class='input-group'>", append="</div>", prependToLabel="<span class='icon'>$</span>")#



























`````time:
Adds one or more TIME columns to a table definition in a migration.

// Add a simple time column
t.time("startTime")

// Add multiple time columns
t.time("opensAt, closesAt")

// Add a time column with a default value
t.time(columnNames="reminderAt", default="09:00:00")

// Add a nullable time column
t.time(columnNames="lunchBreak", null=true)
























`````timeAgoInWords:
Returns a human-friendly string describing the approximate time difference between two dates (defaults to comparing against the current time).

// Example in a controller
aWhileAgo = DateAdd("d", -90, Now());

// Example in a view (outputs: "3 months")
#timeAgoInWords(aWhileAgo)#

// Including seconds (outputs: "less than 5 seconds")
#timeAgoInWords(DateAdd("s", -3, Now()), includeSeconds=true)#

// Comparing two specific dates
past = CreateDateTime(2024, 01, 01, 12, 0, 0);
future = CreateDateTime(2024, 06, 01, 12, 0, 0);
// Outputs: "5 months"
#timeAgoInWords(fromTime=past, toTime=future)#



























`````timeSelect:
The timeSelect() function builds and returns three select form controls for hours, minutes, and seconds, based on the supplied object name and property. It is useful when you want users to input a time in a structured way without manually typing values. You can configure it to display only specific units (such as hours and minutes), control step intervals for minutes or seconds, display in 12-hour format with AM/PM, and customize labels, error handling, and additional HTML wrapping. By default, the three selects are ordered as hour, minute, and second, but you can change this order or exclude parts completely.

<!--- Basic usage: create hour, minute, and second selects for a property --->
#timeSelect(objectName="business", property="openUntil")#

<!--- Only display hour and minute selectors --->
#timeSelect(objectName="business", property="openUntil", order="hour,minute")#

<!--- Limit minutes to 15-minute intervals (00, 15, 30, 45) --->
#timeSelect(objectName="appointment", property="dateTimeStart", minuteStep=15)#

<!--- Use 12-hour format with AM/PM --->
#timeSelect(objectName="event", property="startTime", twelveHour=true)#

<!--- Add a blank option at the top --->
#timeSelect(objectName="schedule", property="startTime", includeBlank="- Select Time -")#

<!--- Customize the label and append helper text --->
#timeSelect(objectName="meeting", property="endTime", label="End Time", append="(select carefully)")#




























`````timeSelectTags:
The timeSelectTags() function builds and returns three <select> form controls for hours, minutes, and seconds based on the supplied name. This is the tag-based version of timeSelect(), meaning it does not bind to a model object but instead works with raw form field names. You can control the order of the selects, limit minute and second intervals, display in 12-hour format with AM/PM, and include custom labels, error handling, and HTML wrappers.

<!--- Basic usage: creates hour, minute, and second selects --->
#timeSelectTags(name="timeOfMeeting", selected=params.timeOfMeeting)#

<!--- Only show hour and minute selects --->
#timeSelectTags(name="timeOfMeeting", selected=params.timeOfMeeting, order="hour,minute")#

<!--- Show 15-minute intervals --->
#timeSelectTags(name="reminderTime", minuteStep=15)#

<!--- Display in 12-hour format with AM/PM --->
#timeSelectTags(name="eventStart", twelveHour=true)#

<!--- Include a blank option --->
#timeSelectTags(name="timeSlot", includeBlank="- Select Time -")#

<!--- Add a label and append helper text --->
#timeSelectTags(name="appointmentEnd", label="End Time", append="(HH:MM:SS)")#































`````timestamp:
The timestamp() function is used inside migrations to add one or more TIMESTAMP (or DATETIME) columns to a table definition. It lets you specify default values, whether the column allows NULL, and even override the underlying SQL type through the columnType argument. This is especially useful when you need to track creation and update times or work with custom timestamp fields.

// Add a basic timestamp column
t.timestamp("createdAt")

// Add multiple timestamp columns
t.timestamp("createdAt, updatedAt")

// Add a timestamp column with a default value
t.timestamp(columnNames="createdAt", default="CURRENT_TIMESTAMP")

// Add a nullable timestamp column
t.timestamp(columnNames="deletedAt", null=true)

// Override column type to use TIMESTAMP instead of DATETIME
t.timestamp(columnNames="syncedAt", columnType="timestamp")




























`````timestamps:
The timestamps() function is a shortcut for adding Wheels’ convention-based automatic timestamp and soft delete columns to a table definition during migrations. Instead of defining each field manually, this function quickly sets up the standard fields that are commonly used across models to track record lifecycle and soft deletion. By default, it adds createdAt, updatedAt, and deletedAt columns with appropriate types, making your migrations more concise and consistent.

// Add createdAt, updatedAt, and deletedAt columns to the users table
t.timestamps()

// Use with other column definitions in the same migration
t.string("name")
t.timestamps()

// Combine with associations or other fields
t.integer("roleId")
t.timestamps()



























`````timeUntilInWords:
The timeUntilInWords() function returns a human-readable string describing the approximate time difference between the current date (or another starting point you provide) and a future date. It is the inverse of timeAgoInWords(), focusing on how long until something happens instead of how long ago it occurred. You can optionally include seconds for more precise descriptions.

// Example in a controller
aLittleAhead = DateAdd("d", 365, Now());

// Example in a view (outputs: "about 1 year")
#timeUntilInWords(aLittleAhead)#

// Including seconds (outputs: "less than 5 seconds")
#timeUntilInWords(DateAdd("s", 3, Now()), includeSeconds=true)#

// Comparing between two specific dates
fromDate = CreateDateTime(2024, 01, 01, 12, 0, 0);
toDate   = CreateDateTime(2024, 06, 01, 12, 0, 0);
// Outputs: "5 months"
#timeUntilInWords(toTime=toDate, fromTime=fromDate)#



























`````titleize:
The titleize() function converts a string so that the first letter of each word is capitalized, producing a cleaner, title-like appearance. It is useful for formatting headings, labels, or any text that should follow title case conventions.

// Basic usage
#titleize("Wheels is a framework for ColdFusion")#
// Output: "Wheels Is A Framework For ColdFusion"

// Works with single words
#titleize("hello")#
// Output: "Hello"

// Works with multiple words including numbers
#titleize("coldfusion 2025 features")#
// Output: "Coldfusion 2025 Features"

// Can be used in views for dynamic labels
<h1>#titleize(article.title)#</h1>





























`````toggle:
The toggle() function inverts the current boolean value of a specified property on a model object. If the property is true, it becomes false, and vice versa. An error will be thrown if the property cannot be interpreted as a boolean. By default, the object is saved automatically after toggling the property, but you can disable automatic saving by passing save=false. The function returns a boolean indicating whether the save operation was successful when saving is enabled, or returns the object itself if save is disabled.

// Fetch a user object and toggle a boolean property
user = model("user").findByKey(58);
isSuccess = user.toggle("isActive");
// Returns true if saved successfully, false otherwise

// Disable automatic saving
user = model("user").findByKey(58);
user.toggle("isActive", save=false);
// Returns the user object without saving

// Use a dynamic helper method for convenience
user = model("user").findByKey(58);
isSuccess = user.toggleIsActive();
// Returns whether the save was successful





























`````truncate:
The truncate() function shortens a given text string to a specified length and appends a replacement string (by default "...") at the end to indicate truncation. It is useful for displaying previews of longer text in UIs, summaries, or reports while keeping the output concise.

// Truncate text to 20 characters, default truncation string "..."
#truncate(text="Wheels is a framework for ColdFusion", length=20)#
/* Output: "Wheels is a fra..." */

// Use a custom truncation string
#truncate(text="Wheels is a framework for ColdFusion", truncateString=" (more)")#
/* Output: "Wheels is a framework (more)" */

// Short text does not get truncated
#truncate(text="Short text", length=20)#
/* Output: "Short text" */

// Display in a view for previews
<p>#truncate(article.content, 100)#</p>


































`````uniqueidentifier:
The uniqueidentifier() function is used inside migrations to add one or more UUID (Universally Unique Identifier) columns to a table definition. These columns are useful for generating globally unique keys for records instead of relying on auto-incrementing integers. By default, the function uses newid() to populate the column with a UUID, and you can also configure whether the column allows NULL.

// Add a single UUID column
t.uniqueidentifier("uuid")

// Add multiple UUID columns
t.uniqueidentifier("uuid, externalId")

// Add a UUID column with default UUID generation
t.uniqueidentifier(columnNames="uuid", default="newid()")

// Add a nullable UUID column
t.uniqueidentifier(columnNames="optionalUuid", null=true)































`````up:
The up() function defines the actions to migrate your database schema forward. It is called when applying a migration and is typically paired with the down() function, which rolls back the migration. All schema changes, such as creating tables, adding columns, or setting up indexes, should be placed inside up(). Wrapping your migration code in a transaction block ensures that changes are either fully applied or rolled back in case of errors.

function up() {
    transaction {
        try {
            // Create a new table with convention-based timestamp columns
            t = createTable(name='myTable');
            t.timestamps();
            t.create();
        } catch (any e) {
            local.exception = e;
        }

        // Rollback if there was an error, otherwise commit
        if (StructKeyExists(local, "exception")) {
            transaction action="rollback";
            throw(
                errorCode="1",
                detail=local.exception.detail,
                message=local.exception.message,
                type="any"
            );
        } else {
            transaction action="commit";
        }
    }
}































`````update:
The update() function updates an existing model object with the supplied properties and saves the changes to the database. It returns true if the save was successful and false otherwise. You can pass properties directly as named arguments or as a struct. Additional options allow you to control validation, callbacks, transactions, parameterization, cache reloading, and explicit timestamp handling. This method also works seamlessly with associations, making it possible to update related objects in hasOne or hasMany relationships.

// Update a single property and save
post = model("post").findByKey(33);
post.update(title="New version of Wheels just released");

// Update multiple properties, including from a URL or form
post = model("post").findByKey(params.key);
post.update(title="New version of Wheels just released", properties=params.post);

// Update a hasOne associated object
author = model("author").findByKey(params.authorId); 
bio = model("bio").findByKey(params.bioId); 
author.setBio(bio); // calls bio.update internally

// Update a hasMany association (add or remove related objects)
anOwner = model("owner").findByKey(params.ownerId); 
aCar = model("car").findByKey(params.carId); 
anOwner.addCar(aCar); // calls car.update(ownerId=anOwner.id)

aPost = model("post").findByKey(params.postId); 
aComment = model("comment").findByKey(params.commentId); 
aPost.removeComment(aComment); // calls comment.update(postId="")

// Toggle a boolean property (convenience dynamic helper)
user = model("user").findByKey(58); 
isSuccess = user.toggle("isActive"); // returns save result
isSuccess = user.toggleIsActive();    // same using dynamic helper
































`````updateAll:
The updateAll() function updates one or more properties for all records that match a given where condition. Property names and values can be passed either as named arguments or as a struct. By default, the objects are not instantiated, meaning that validations and callbacks are skipped. You can enable full instantiation and callback execution by setting instantiate=true. This method returns the number of records that were successfully updated. It also supports advanced query options like joins via include, soft-delete handling, parameterization, transactions, and index hints.

// Update all posts that are unpublished
recordsUpdated = model("post").updateAll(
    published=1,
    publishedAt=Now(),
    where="published=0"
);

// Scoped update for a hasMany association (removing all comments)
post = model("post").findByKey(params.postId);
post.removeAllComments(); 
// Internally calls: model("comment").updateAll(postId="", where="postId=#post.id#")

// Update all users and force validations and callbacks
recordsUpdated = model("user").updateAll(
    properties={isActive=true},
    instantiate=true,
    validate=true
);

// Using index hints for MySQL
recordsUpdated = model("user").updateAll(
    properties={isVerified=true},
    where="isVerified=0",
    useIndex={user="idx_users_isVerified"}
);































`````updateByKey:
The updateByKey() function fetches a model object using its primary key and updates it with the supplied properties or named arguments. It automatically saves the object if validations pass. The function returns true if the object was found and updated successfully, and false if the object could not be found or the save failed. This method is useful for quickly updating a single record by its key without first manually fetching it. Additional options allow control over validation, callbacks, transactions, cache reloading, and soft-delete handling.

// Update a record by key using a struct of properties
result = model("post").updateByKey(33, params.post);
// Returns true if the update was successful

// Update a record by key using named arguments
result = model("post").updateByKey(
    key=33,
    title="New version of Wheels just released",
    published=1
);

// Include soft-deleted records in the update
result = model("user").updateByKey(
    key=42,
    properties={isActive=true},
    includeSoftDeletes=true
);

// Disable validation and callbacks
result = model("post").updateByKey(
    key=33,
    properties={title="Force Update"},
    validate=false,
    callbacks=false
);
































`````updateOne:
The updateOne() function retrieves a single model object based on the supplied arguments and updates it with the specified properties. It returns true if an object was found and updated successfully, and false if no object matched the criteria or the update failed. This method is useful when you want to update a single record that matches a certain condition without fetching multiple records. By default, objects are not instantiated, so validations and callbacks are applied only if enabled. Additional options allow control over query ordering, transactions, cache reloading, index hints, and inclusion of soft-deleted records.

// Update a single property on the most recently released product
result = model("product").updateOne(
    order="releaseDate DESC",
    new=1
);

// Scoped update for a hasOne association (removing a profile)
aUser = model("user").findByKey(params.userId);
aUser.removeProfile(); 
// Internally calls: model("profile").updateOne(where="userId=#aUser.id#", userId="")































`````updateProperty:
The updateProperty() function updates a single property on a model object and saves the record immediately without running the normal validation procedures. This method is particularly useful for quickly updating flags or boolean values on existing records where full validation is not necessary. You can control transaction behavior, parameterization, and callback execution when using this method.

// Update a single property on an existing product
product = model("product").findByKey(56);
product.updateProperty("new", 1);

// Update a boolean flag without callbacks or validations
user = model("user").findByKey(42);
user.updateProperty(property="isActive", value=false, callbacks=false);




























`````updateRecord:
The updateRecord() function allows you to update an existing record in a database table directly from within a migration CFC. This function is particularly useful when you need to modify data as part of a schema migration, such as setting default values, correcting legacy data, or updating specific records based on certain conditions. The function requires the table name and optionally allows a where clause to target specific rows.

// Update the `active` column to 0 for all admin users in a migration
updateRecord(
    table="users",
    where="admin = 1",
    active=0
);

// Update a specific product record by ID
updateRecord(
    table="products",
    where="id = 42",
    price=19.99,
    stock=100
);



























`````URLFor:
The URLFor() function generates an internal URL based on the supplied arguments. It can create URLs using a named route, or by specifying a controller and action directly. Additional options let you include keys, query parameters, anchors, and override protocol, host, or port. By default, the function returns a relative URL, but you can configure it to return a fully qualified URL. URL parameters are automatically encoded for safety, but for HTML attribute safety, further encoding is recommended.

// Generate the URL for the logOut action on the account controller
#urlFor(controller="account", action="logOut")#
// Example output: /account/log-out

// Generate a URL with an anchor
#urlFor(action="comments", anchor="comment10")#
// Example output: /comments#comment10

// Generate a URL using a named route with parameters
#urlFor(route="product", categorySlug="accessories", productSlug="battery-charger")#
// Example output: /accessories/battery-charger





























`````usesLayout:
The usesLayout() function is used inside a controller's config() function to specify which layout template should be applied to the controller or specific actions. You can define a default layout for the entire controller, specify layouts only for certain actions, exclude specific actions from using a layout, or even provide a custom function to determine which layout to use dynamically. This allows fine-grained control over your page structure and helps maintain consistent design while accommodating exceptions.

// Use a layout for the entire controller except for a specific AJAX action
usesLayout(template="myLayout", except="myAjax");

// Use a custom layout only for certain actions, default layout for the rest
usesLayout(template="myLayout", only="termsOfService,shippingPolicy");

// Define a function that determines which layout to display dynamically
// The function should return the layout name or true to use the default
usesLayout("setLayout");




























`````valid:
The valid() function runs all validations defined on a model object and returns true if the object passes validation, or false if it fails. While Wheels automatically validates objects when they are saved to the database, this method allows you to check an object's validity without saving it, which is useful for conditional logic, form previews, or API input validation.

// Create a new user object and validate it without saving
user = model("user").new(params.user);

if (user.valid) {
    // The user object passed all validations
    // Proceed with further logic or display success
} else {
    // The user object failed validation
    // Handle errors accordingly
}






























`````validate:
The validate() function is used to register one or more validation methods that will be executed on a model object before it is saved to the database. This allows you to define custom validation logic beyond the built-in validations like presence or uniqueness. You can also control when the validation runs (on create, update, or both) and under what conditions using condition and unless.

Examples
// Basic usage: register a method to validate objects before saving
function config() {
    validate("checkPhoneNumber");
}

function checkPhoneNumber() {
    // Make sure area code is '614'
    return Left(this.phoneNumber, 3) == "614";
}

// Register multiple validation methods
function config() {
    validate("checkPhoneNumber, checkEmailFormat");
}

function checkEmailFormat() {
    // Ensure email contains '@'
    return Find("@", this.email);
}

// Conditional validation using `condition`
function config() {
    // Only validate phone numbers if the user is in the US
    validate("checkPhoneNumber", condition="this.country == 'US'");
}

// Skip validation under certain conditions using `unless`
function config() {
    // Skip phone number validation if the user is a guest
    validate("checkPhoneNumber", unless="this.isGuest");
}

// Run validation only on create or update
function config() {
    // Validate email only when creating a new record
    validate("checkEmailFormat", when="onCreate");

    // Validate password only on update
    validate("checkPasswordStrength", when="onUpdate");
}





























`````validateOnCreate:
The validateOnCreate() function registers one or more validation methods that will be executed only when a new object is being inserted into the database. This is useful for rules that should apply strictly at creation and not during updates. You can also control whether the validation runs using the condition and unless arguments.

Examples
// Basic usage: validate new objects before insertion
function config() {
    validateOnCreate("checkPhoneNumber");
}

function checkPhoneNumber() {
    // Ensure area code is '614'
    return Left(this.phoneNumber, 3) == "614";
}

// Register multiple methods for validation on creation
function config() {
    validateOnCreate("checkPhoneNumber, checkEmailFormat");
}

function checkEmailFormat() {
    // Ensure email contains '@'
    return Find("@", this.email);
}

// Conditional validation using `condition`
function config() {
    // Only validate phone number if the country is US
    validateOnCreate("checkPhoneNumber", condition="this.country == 'US'");
}

// Skip validation under certain conditions using `unless`
function config() {
    // Skip phone number validation if user is a guest
    validateOnCreate("checkPhoneNumber", unless="this.isGuest");
}





























`````validateOnUpdate:
The validateOnUpdate() function registers one or more validation methods that will be executed only when an existing object is being updated in the database. This allows you to enforce rules that apply strictly to updates, without affecting the creation of new records. You can also control whether the validation runs using the condition and unless arguments.

Examples
// Basic usage: validate existing objects before update
function config() {
    validateOnUpdate("checkPhoneNumber");
}

function checkPhoneNumber() {
    // Ensure area code is '614'
    return Left(this.phoneNumber, 3) == "614";
}

// Register multiple methods for validation on update
function config() {
    validateOnUpdate("checkPhoneNumber, checkEmailFormat");
}

function checkEmailFormat() {
    // Ensure email contains '@'
    return Find("@", this.email);
}

// Conditional validation using `condition`
function config() {
    // Only validate phone number if the country is US
    validateOnUpdate("checkPhoneNumber", condition="this.country == 'US'");
}

// Skip validation under certain conditions using `unless`
function config() {
    // Skip phone number validation if the user is an admin
    validateOnUpdate("checkPhoneNumber", unless="this.isAdmin");
}
































`````validatesConfirmationOf:
The validatesConfirmationOf() function is used to ensure that the value of a given property matches a corresponding confirmation property. This is commonly used for fields like password or email, where users are asked to enter the value twice for confirmation. The confirmation property is temporary and never saved to the database. By convention, the confirmation property name is the original property name with "Confirmation" appended (e.g., passwordConfirmation for password). You can customize when the validation occurs, provide a custom message, or enforce case sensitivity.

Examples
// Validate password confirmation on user creation
validatesConfirmationOf(
    property="password",
    when="onCreate",
    message="Your password and its confirmation do not match. Please try again."
);

// Validate multiple fields at once: password and email
validatesConfirmationOf(
    properties="password,email",
    when="onCreate",
    message="Fields must match their confirmation."
);

// Case-sensitive validation
validatesConfirmationOf(
    property="password",
    caseSensitive=true,
    message="Password and confirmation must match exactly, including case."
);

// Conditional validation using `condition`
validatesConfirmationOf(
    property="email",
    condition="this.isNewsletterSubscriber",
    message="Email confirmation required for newsletter subscription."
);

// Skip validation for admin users using `unless`
validatesConfirmationOf(
    property="password",
    unless="this.isAdmin",
    message="Admins do not need to confirm their password."
);




























`````validatesExclusionOf:
The validatesExclusionOf() function ensures that the value of a specified property is not included in a given list of disallowed values. This is commonly used to prevent reserved words, restricted entries, or disallowed values from being saved to the database. You can specify when the validation should run, allow blank values to skip validation, or conditionally run it.

Examples
// Prevent users from selecting certain programming languages
validatesExclusionOf(
    property="coolLanguage",
    list="php,fortran",
    message="Haha, you can not be serious. Try again, please."
);

// Validate multiple properties at once
validatesExclusionOf(
    properties="username,email",
    list="admin,root,system",
    message="This value is reserved. Please choose another."
);

// Only apply validation on object creation
validatesExclusionOf(
    property="username",
    list="admin,root",
    when="onCreate",
    message="Username is reserved and cannot be used."
);

// Skip validation if the property is blank
validatesExclusionOf(
    property="nickname",
    list="boss,chief",
    allowBlank=true
);

// Conditional validation using `condition`
validatesExclusionOf(
    property="category",
    list="deprecated,legacy",
    condition="this.isArchived",
    message="Archived items cannot use deprecated categories."
);

// Skip validation for admin users using `unless`
validatesExclusionOf(
    property="role",
    list="banned,guest",
    unless="this.isAdmin",
    message="This role is restricted for regular users."
);


























`````validatesFormatOf:
The validatesFormatOf() function is used to ensure that the value of a property matches a specific format. You can validate against a regular expression using regEx or use built-in CFML validation types via the type argument (e.g., email, creditcard, date, URL). This validation is commonly used for email addresses, phone numbers, credit card numbers, and custom patterns.

Examples
// Validate that a credit card number is correct
validatesFormatOf(property="cc", type="creditcard");

// Validate that a US zipcode matches 5 or 9 digit format
validatesFormatOf(property="zipcode", type="zipcode");

// Ensure that an email ends with `.se` when IP check returns true and today is not Sunday
validatesFormatOf(
    property="email",
    regEx="^.*@.*\.se$",
    condition="ipCheck()",
    unless="DayOfWeek() eq 1",
    message="Sorry, you must have a Swedish email address to use this website."
);

// Validate that a username contains only letters, numbers, or underscores
validatesFormatOf(
    property="username",
    regEx="^[a-zA-Z0-9_]+$",
    message="Username can only contain letters, numbers, and underscores."
);

// Validate multiple properties at once using built-in CFML types
validatesFormatOf(
    properties="phone,email",
    type="telephone,email",
    allowBlank=true
);

// Validate only when updating an existing object
validatesFormatOf(
    property="ssn",
    type="social_security_number",
    when="onUpdate",
    message="Invalid SSN format for updating records."
);






























`````validatesInclusionOf:
The validatesInclusionOf() function ensures that a property’s value exists in a predefined list of allowed values. It is commonly used for dropdowns, radio buttons, or any scenario where only specific values are acceptable.

Examples
// Ensure that the user selects either "Wheels" or "Rails" as their framework
validatesInclusionOf(
    property="frameworkOfChoice",
    list="wheels,rails",
    message="Please try again, and this time, select a decent framework!"
);

// Validate multiple properties at once
validatesInclusionOf(
    properties="frameworkOfChoice,editorChoice",
    list="wheels,rails,vsCode,sublime",
    message="Invalid selection."
);

// Only validate when creating a new object
validatesInclusionOf(
    property="subscriptionType",
    list="free,premium,enterprise",
    when="onCreate",
    message="You must choose a valid subscription type."
);

// Skip validation if property is blank
validatesInclusionOf(
    property="preferredLanguage",
    list="cfml,python,javascript",
    allowBlank=true
);

// Conditionally validate only for users in Europe
validatesInclusionOf(
    property="currency",
    list="EUR,GBP,CHF",
    condition="this.region eq 'Europe'",
    message="Invalid currency for European users."
);





























`````validatesLengthOf:
The validatesLengthOf() function ensures that a property’s value meets specific length requirements. You can enforce exact length, maximum, minimum, or a range of lengths using the exactly, maximum, minimum, and within arguments.

Examples
// Ensure that `firstName` and `lastName` are no more than 50 characters
validatesLengthOf(
    properties="firstName,lastName",
    maximum=50,
    message="Please shorten your [property] please (50 characters max)."
);

// Ensure `password` is between 4 and 20 characters
validatesLengthOf(
    property="password",
    within="4,20",
    message="The password length must be between 4 and 20 characters."
);

// Ensure `username` is exactly 8 characters
validatesLengthOf(
    property="username",
    exactly=8,
    message="Username must be exactly 8 characters."
);

// Only validate if `region` is 'US'
validatesLengthOf(
    property="zipCode",
    exactly=5,
    condition="this.region eq 'US'",
    message="US zip codes must be exactly 5 digits."
);

// Skip validation if property is blank
validatesLengthOf(
    property="nickname",
    maximum=15,
    allowBlank=true
);































`````validatesNumericalityOf:
The validatesNumericalityOf() function ensures that a property’s value is numeric. You can also enforce additional constraints such as integer-only values, odd/even numbers, and comparison limits (greaterThan, lessThan, etc.).

Examples
// Score must be an integer, but allow blank values
validatesNumericalityOf(
    property="score",
    onlyInteger=true,
    allowBlank=true,
    message="Please enter a correct score."
);

// Age must be a number greater than or equal to 18
validatesNumericalityOf(
    property="age",
    greaterThanOrEqualTo=18,
    message="You must be at least 18 years old."
);

// Price must be a positive number less than 1000
validatesNumericalityOf(
    property="price",
    greaterThan=0,
    lessThan=1000,
    message="Price must be between 0 and 1000."
);

// Ensure a number is odd and an integer
validatesNumericalityOf(
    property="lotteryNumber",
    odd=true,
    onlyInteger=true,
    message="Lottery number must be an odd integer."
);

// Validate only when a specific condition is true
validatesNumericalityOf(
    property="discount",
    greaterThanOrEqualTo=0,
    lessThanOrEqualTo=50,
    condition="this.isOnSale()",
    message="Discount must be between 0 and 50 for sale items."
);


































`````validatesPresenceOf:
The validatesPresenceOf() function ensures that the specified property (or properties) exists and is not blank. It is commonly used to enforce required fields before saving an object to the database.

Examples
// Ensure the `emailAddress` property is not blank
validatesPresenceOf("emailAddress");

// Ensure multiple properties are present
validatesPresenceOf("firstName,lastName,emailAddress");

// Use a custom error message for missing email
validatesPresenceOf(
    property="emailAddress",
    message="Email is required to create your account."
);

// Validate only on create, not on update
validatesPresenceOf(
    properties="password",
    when="onCreate",
    message="Password is required when registering a new user."
);

// Conditional validation based on a method
validatesPresenceOf(
    properties="discountCode",
    condition="this.isOnSale()",
    message="Discount code must be present for sale items."
);
































`````validatesUniquenessOf:
The validatesUniquenessOf() function ensures that the value of a specified property is unique within the database table. It is particularly useful for properties such as usernames, email addresses, or any field that must not have duplicates.

When creating a new record, it checks that no other record exists with the same value. When updating, it disregards the record itself and checks for uniqueness against other records.

Examples
// Ensure that usernames are unique across all users
validatesUniquenessOf(
    property="username",
    message="Sorry, that username is already taken."
);

// Ensure that email addresses are unique
validatesUniquenessOf(
    property="emailAddress",
    message="This email has already been registered."
);

// Allow the same username in different accounts but unique within an account
validatesUniquenessOf(
    property="username",
    scope="accountId",
    message="This username is already used in this account."
);

// Only enforce uniqueness if the user is active
validatesUniquenessOf(
    property="username",
    condition="this.isActive",
    message="Active users must have a unique username."
);

// Skip uniqueness check if the field is blank
validatesUniquenessOf(
    property="nickname",
    allowBlank=true,
    message="Nickname must be unique if supplied."
);































`````validationTypeForProperty:
The validationTypeForProperty() function returns the type of validation that Wheels would apply for a given property. This is useful if you want to dynamically inspect a model's property type or apply logic based on the property's expected format.

// Create a new employee object
employee = model("employee").new();

// Assume 'firstName' is a varchar(50) column
// This will output: "string"
#employee.validationTypeForProperty("firstName")#

// Assume 'hireDate' is a datetime column
// This will output: "date"
#employee.validationTypeForProperty("hireDate")#

// Assume 'salary' is a numeric column
// This will output: "numeric"
#employee.validationTypeForProperty("salary")#





























`````verificationChain:
The verificationChain() function returns an array of all verifications (filters, before-actions, or checks) that are configured for the current controller, in the order they will be executed. This allows you to inspect, modify, or reorder the verifications dynamically.

// Get the current verification chain for this controller
myVerificationChain = verificationChain();

// Remove the first verification from the chain
ArrayDeleteAt(myVerificationChain, 1);

// Set the modified verification chain back to the controller
setVerificationChain(myVerificationChain);




























`````verifies:
The verifies() function instructs a Wheels controller to check that certain criteria are met before executing an action. This is useful for enforcing request types, required parameters, session/cookie values, or custom verifications.

All undeclared arguments are automatically passed to a redirectTo() call if a handler is not specified.

1. Enforce POST request for a specific action:

// Only the handleForm action must be POST
verifies(only="handleForm", post=true);


2. Ensure a GET request and that a parameter exists with a type check:

// The edit action must be GET and have a numeric userId in params
verifies(only="edit", get=true, params="userId", paramsTypes="integer");


3. Use a custom handler function for failed verifications:

// If verification fails, call myCustomFunction in the controller
verifies(only="edit", get=true, params="userId", paramsTypes="integer", handler="myCustomFunction");


4. Redirect and show flash error if verification fails:

// Instead of a handler, redirect to index action and show an error message
verifies(
    only="edit", 
    get=true, 
    params="userId", 
    paramsTypes="integer", 
    action="index", 
    error="Invalid userId"
);






























`````wildcard:
The wildcard() function automatically generates dynamic routes for your controllers using placeholders like [controller], [action], and optionally [key] or [format]. This allows you to quickly map standard URL patterns to controllers and actions without explicitly defining every route.

1. Basic wildcard routing (controller and action, GET only):

mapper()
    .wildcard()
.end();


This generates routes like:

/posts           -> posts/index
/posts/show      -> posts/show
/users           -> users/index
/users/edit      -> users/edit


2. Enable [key] pattern for resource-style URLs:

mapper()
    .wildcard(mapKey=true)
.end();


Generates:

/posts/1         -> posts/show with key=1
/users/42/edit   -> users/edit with key=42


3. Enable optional format (e.g., .json, .xml):

mapper()
    .wildcard(mapFormat=true)
.end();


Generates:

/posts.json           -> posts/index format=json
/posts/show.xml       -> posts/show format=xml
/users/42.json/edit   -> users/edit key=42 format=json


4. Support multiple HTTP methods:

mapper()
    .wildcard(methods="get,post")
.end();


⚠️ Warning: Allowing POST via wildcard can be dangerous if not combined with verifies() in your controller to ensure only authorized requests can modify data.

5. Full example combining key and format:

mapper()
    .wildcard(mapKey=true, mapFormat=true, methods="get,post")
.end();


Generates routes like:

/posts/1.json         -> posts/show key=1 format=json
/users/42/edit.xml    -> users/edit key=42 format=xml































`````wordTruncate:
Truncates a string by words instead of characters. After the specified number of words, it replaces the remaining text with a truncation string (defaults to "...").

1. Basic truncation (default truncate string "..."):

#wordTruncate(text="Wheels is a framework for ColdFusion", length=4)#


Output:

Wheels is a framework...


2. Truncate with a custom string:

#wordTruncate(text="Wheels is a framework for ColdFusion", length=3, truncateString=" (more)")#


Output:

Wheels is a (more)


3. Using with shorter text than length (no truncation applied):

#wordTruncate(text="Hello world", length=5)#


Output:

Hello world


4. Dynamic usage in a view:

<cfoutput>
    #wordTruncate(text=post.content, length=10)#
</cfoutput>


This is useful for showing previews of long content while preserving word boundaries.

































`````yearSelectTag:
Generates a <select> form control with a range of years, making it easy to create date-of-birth selectors or other year-based dropdowns.

1. Basic year dropdown:

#yearSelectTag(name="yearOfBirthday", selected=params.yearOfBirthday)#


Output:

<select name="yearOfBirthday">
  <option value="2018">2018</option>
  ...
  <option value="2028">2028</option>
</select>


2. Custom range (past 50 years, at least 18 years ago):

fiftyYearsAgo = Year(Now()) - 50;
eighteenYearsAgo = Year(Now()) - 18;

#yearSelectTag(
    name="yearOfBirthday", 
    selected=params.yearOfBirthday, 
    startYear=fiftyYearsAgo, 
    endYear=eighteenYearsAgo
)#


Output: A <select> with years from fiftyYearsAgo to eighteenYearsAgo.

3. Include a blank option:

#yearSelectTag(name="graduationYear", includeBlank="- Select Year -")#


Output: Dropdown starts with an empty option labeled "- Select Year -".

4. Add label with custom placement:

#yearSelectTag(
    name="yearOfHiring",
    label="Hiring Year",
    labelPlacement="aroundRight"
)#


Output: The label wraps the <select> on the right side.






























`````setFlashStorage:
Dynamically sets the storage mechanism for flash messages during the current request lifecycle. Flash messages are temporary messages (e.g., success or error notifications) that persist across requests.

1. Set flash storage to cookie for the current controller only:

setFlashStorage("cookie");


Effect: Flash messages will now be stored in cookies only for the current controller. Other controllers remain unaffected.

2. Set flash storage to session for both controller and application:

setFlashStorage("session", true);


Effect: Flash messages will now be stored in session globally, so all controllers in the application will use session storage for flash messages.
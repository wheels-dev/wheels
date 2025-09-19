# Model Testing

## Description
Comprehensive guide to testing CFWheels models, including validation testing, association testing, business logic testing, and callback testing.

## Model Test Structure

### Basic Test Template
```cfm
/**
 * UserTest - Test User model functionality
 */
component extends="wheels.Test" {

    function setup() {
        // Set up test data before each test
        variables.validUserData = {
            username = "testuser",
            email = "test@example.com",
            firstname = "Test",
            lastname = "User",
            password = "SecurePass123!",
            passwordConfirmation = "SecurePass123!"
        };
    }

    function teardown() {
        // Clean up test data after each test
        model("User").deleteAll(where="email LIKE '%test%'");
    }

    // Test methods go here
}
```

### Test Organization
```
tests/
├── models/
│   ├── UserTest.cfc
│   ├── PostTest.cfc
│   ├── OrderTest.cfc
│   └── ProductTest.cfc
├── fixtures/
│   ├── users.yml
│   └── posts.yml
└── support/
    └── TestHelper.cfc
```

## Validation Testing

### Testing Presence Validations
```cfm
function test_user_requires_email() {
    local.user = model("User").new(variables.validUserData);
    local.user.email = "";

    assert(!local.user.valid(), "User should be invalid without email");
    assert(local.user.hasErrors("email"), "User should have email error");

    // Test specific error message
    local.errors = local.user.errorsOn("email");
    assert(arrayLen(local.errors) > 0, "Should have email errors");
}

function test_user_requires_username() {
    local.user = model("User").new(variables.validUserData);
    local.user.username = "";

    assert(!local.user.valid(), "User should be invalid without username");
    assert(local.user.hasErrors("username"), "User should have username error");
}

function test_user_valid_with_all_required_fields() {
    local.user = model("User").new(variables.validUserData);

    assert(local.user.valid(), "User should be valid with all required fields");
    assert(!local.user.hasErrors(), "User should have no errors");
}
```

### Testing Format Validations
```cfm
function test_validates_email_format() {
    local.user = model("User").new(variables.validUserData);

    // Test invalid email formats
    local.invalidEmails = ["invalid", "test@", "@example.com", "test.example.com"];

    for (local.email in local.invalidEmails) {
        local.user.email = local.email;
        assert(!local.user.valid(), "User should be invalid with email: #local.email#");
        assert(local.user.hasErrors("email"), "User should have email error for: #local.email#");
    }

    // Test valid email
    local.user.email = "valid@example.com";
    assert(local.user.valid(), "User should be valid with correct email format");
}

function test_validates_phone_format() {
    local.user = model("User").new(variables.validUserData);

    // Test invalid phone formats
    local.user.phone = "123-456";
    assert(!local.user.valid(), "User should be invalid with incomplete phone");

    local.user.phone = "abc-def-ghij";
    assert(!local.user.valid(), "User should be invalid with non-numeric phone");

    // Test valid phone format
    local.user.phone = "(555) 123-4567";
    assert(local.user.valid(), "User should be valid with correct phone format");
}
```

### Testing Uniqueness Validations
```cfm
function test_user_requires_unique_email() {
    // Create first user
    local.firstUser = model("User").create(variables.validUserData);
    assert(local.firstUser.valid(), "First user should be valid");

    // Try to create second user with same email
    variables.validUserData.username = "testuser2";
    local.secondUser = model("User").new(variables.validUserData);

    assert(!local.secondUser.valid(), "Second user should be invalid with duplicate email");
    assert(local.secondUser.hasErrors("email"), "User should have email uniqueness error");
}

function test_user_requires_unique_username() {
    // Create first user
    local.firstUser = model("User").create(variables.validUserData);

    // Try to create second user with same username
    variables.validUserData.email = "different@example.com";
    local.secondUser = model("User").new(variables.validUserData);

    assert(!local.secondUser.valid(), "Second user should be invalid with duplicate username");
    assert(local.secondUser.hasErrors("username"), "User should have username uniqueness error");
}
```

### Testing Length Validations
```cfm
function test_validates_password_length() {
    local.user = model("User").new(variables.validUserData);

    // Test password too short
    local.user.password = "short";
    local.user.passwordConfirmation = "short";
    assert(!local.user.valid(), "User should be invalid with short password");
    assert(local.user.hasErrors("password"), "User should have password length error");

    // Test valid password length
    local.user.password = "LongEnoughPassword123!";
    local.user.passwordConfirmation = "LongEnoughPassword123!";
    assert(local.user.valid(), "User should be valid with long enough password");
}

function test_validates_username_length() {
    local.user = model("User").new(variables.validUserData);

    // Test username too short
    local.user.username = "ab";
    assert(!local.user.valid(), "User should be invalid with short username");

    // Test username too long
    local.user.username = repeatString("a", 51);
    assert(!local.user.valid(), "User should be invalid with long username");

    // Test valid username length
    local.user.username = "validuser";
    assert(local.user.valid(), "User should be valid with appropriate username length");
}
```

### Testing Confirmation Validations
```cfm
function test_password_confirmation() {
    local.user = model("User").new(variables.validUserData);
    local.user.passwordConfirmation = "DifferentPassword123!";

    assert(!local.user.valid(), "User should be invalid when passwords don't match");
    assert(local.user.hasErrors("password"), "User should have password confirmation error");
}

function test_password_confirmation_success() {
    local.user = model("User").new(variables.validUserData);
    // passwordConfirmation already matches in validUserData

    assert(local.user.valid(), "User should be valid when passwords match");
    assert(!local.user.hasErrors("password"), "User should not have password errors when they match");
}
```

## Custom Validation Testing

### Testing Custom Validation Methods
```cfm
function test_password_strength_validation() {
    local.user = model("User").new(variables.validUserData);

    // Test weak passwords
    local.weakPasswords = [
        "password",      // No numbers, uppercase, or special chars
        "PASSWORD",      // No lowercase, numbers, or special chars
        "password123",   // No uppercase or special chars
        "Password",      // No numbers or special chars
        "Pass123"        // Too short
    ];

    for (local.weak in local.weakPasswords) {
        local.user.password = local.weak;
        local.user.passwordConfirmation = local.weak;
        assert(!local.user.valid(), "User should be invalid with weak password: #local.weak#");
        assert(local.user.hasErrors("password"), "Should have password strength error for: #local.weak#");
    }

    // Test strong password
    local.user.password = "StrongPass123!";
    local.user.passwordConfirmation = "StrongPass123!";
    assert(local.user.valid(), "User should be valid with strong password");
}

function test_username_format_validation() {
    local.user = model("User").new(variables.validUserData);

    // Test invalid usernames
    local.invalidUsernames = ["user@name", "user name", "user%name", "admin"];

    for (local.invalid in local.invalidUsernames) {
        local.user.username = local.invalid;
        assert(!local.user.valid(), "User should be invalid with username: #local.invalid#");
        assert(local.user.hasErrors("username"), "Should have username format error for: #local.invalid#");
    }

    // Test valid usernames
    local.validUsernames = ["username", "user_name", "user-name", "user123"];

    for (local.valid in local.validUsernames) {
        local.user.username = local.valid;
        assert(local.user.valid(), "User should be valid with username: #local.valid#");
    }
}
```

## Association Testing

### Testing hasMany Associations
```cfm
function test_user_has_many_posts() {
    local.user = model("User").create(variables.validUserData);
    local.post1 = model("Post").create(title="Post 1", content="Content 1", authorid=local.user.id);
    local.post2 = model("Post").create(title="Post 2", content="Content 2", authorid=local.user.id);

    local.posts = local.user.posts();
    assert(local.posts.recordCount == 2, "User should have 2 posts");

    // Test association methods
    assert(local.user.hasPost(), "User should have posts");
    assert(local.user.postCount() == 2, "User post count should be 2");
}

function test_user_has_many_comments() {
    local.user = model("User").create(variables.validUserData);
    local.post = model("Post").create(title="Test Post", content="Content", authorid=local.user.id);
    local.comment1 = model("Comment").create(content="Comment 1", userid=local.user.id, postid=local.post.id);
    local.comment2 = model("Comment").create(content="Comment 2", userid=local.user.id, postid=local.post.id);

    local.comments = local.user.comments();
    assert(local.comments.recordCount == 2, "User should have 2 comments");
}
```

### Testing belongsTo Associations
```cfm
function test_post_belongs_to_user() {
    local.user = model("User").create(variables.validUserData);
    local.post = model("Post").create(title="My Post", content="Content", authorid=local.user.id);

    local.author = local.post.author();
    assert(isObject(local.author), "Post should have an author");
    assert(local.author.id == local.user.id, "Post author should be the correct user");
    assert(local.author.username == local.user.username, "Author username should match");
}

function test_comment_belongs_to_post_and_user() {
    local.user = model("User").create(variables.validUserData);
    local.post = model("Post").create(title="Test Post", content="Content", authorid=local.user.id);
    local.comment = model("Comment").create(
        content="Great post!",
        userid=local.user.id,
        postid=local.post.id
    );

    local.commentPost = local.comment.post();
    local.commentUser = local.comment.user();

    assert(isObject(local.commentPost), "Comment should belong to a post");
    assert(local.commentPost.id == local.post.id, "Comment should belong to correct post");

    assert(isObject(local.commentUser), "Comment should belong to a user");
    assert(local.commentUser.id == local.user.id, "Comment should belong to correct user");
}
```

### Testing Many-to-Many Associations
```cfm
function test_user_can_have_roles() {
    local.user = model("User").create(variables.validUserData);
    local.adminRole = model("Role").create(name="admin", description="Administrator");
    local.userRole = model("Role").create(name="user", description="Regular User");

    // Add roles to user
    local.user.addRole("admin");
    local.user.addRole("user");

    local.roles = local.user.roles();
    assert(local.roles.recordCount == 2, "User should have 2 roles");

    // Test role checking methods
    assert(local.user.hasRole("admin"), "User should have admin role");
    assert(local.user.hasRole("user"), "User should have user role");
    assert(!local.user.hasRole("moderator"), "User should not have moderator role");

    // Remove role
    local.user.removeRole("user");
    assert(local.user.hasRole("admin"), "User should still have admin role");
    assert(!local.user.hasRole("user"), "User should no longer have user role");
}
```

## Business Logic Testing

### Testing Model Methods
```cfm
function test_full_name_generation() {
    local.user = model("User").new(variables.validUserData);
    local.fullName = local.user.getFullName();

    assert(local.fullName == "Test User", "Full name should combine first and last name");

    // Test with missing last name
    local.user.lastname = "";
    assert(local.user.getFullName() == "Test", "Should return first name only when last name missing");

    // Test with missing first name
    local.user.firstname = "";
    local.user.lastname = "User";
    assert(local.user.getFullName() == "User", "Should return last name only when first name missing");

    // Test fallback to username
    local.user.firstname = "";
    local.user.lastname = "";
    assert(local.user.getFullName() == local.user.username, "Should fallback to username");
}

function test_is_admin_method() {
    local.user = model("User").create(variables.validUserData);
    local.adminRole = model("Role").create(name="administrator");
    local.userRole = model("Role").create(name="user");

    // Test non-admin user
    local.user.addRole("user");
    assert(!local.user.isAdmin(), "User with user role should not be admin");

    // Test admin user
    local.user.addRole("administrator");
    assert(local.user.isAdmin(), "User with administrator role should be admin");
}
```

### Testing Authentication Methods
```cfm
function test_authenticate_with_valid_credentials() {
    // Create user (password will be hashed by callback)
    local.user = model("User").create(variables.validUserData);

    // Test authentication
    local.result = model("User").authenticate("test@example.com", "SecurePass123!");

    assert(local.result.success, "Authentication should succeed with valid credentials");
    assert(isObject(local.result.user), "Result should include user object");
    assert(local.result.user.id == local.user.id, "Should return correct user");
}

function test_authenticate_with_invalid_password() {
    // Create user
    local.user = model("User").create(variables.validUserData);

    // Test with wrong password
    local.result = model("User").authenticate("test@example.com", "WrongPassword");

    assert(!local.result.success, "Authentication should fail with invalid password");
    assert(structKeyExists(local.result, "error"), "Result should include error message");
}

function test_authenticate_with_nonexistent_user() {
    local.result = model("User").authenticate("nonexistent@example.com", "AnyPassword");

    assert(!local.result.success, "Authentication should fail for nonexistent user");
    assert(structKeyExists(local.result, "error"), "Result should include error message");
}

function test_password_verification() {
    local.user = model("User").create(variables.validUserData);

    assert(local.user.verifyPassword("SecurePass123!"), "Should verify correct password");
    assert(!local.user.verifyPassword("WrongPassword"), "Should not verify incorrect password");
}
```

## Callback Testing

### Testing Creation Callbacks
```cfm
function test_password_encryption_on_save() {
    local.user = model("User").new(variables.validUserData);
    local.originalPassword = local.user.password;

    local.user.save();

    // Password should be cleared and hash should be set
    assert(local.user.password == "", "Plain text password should be cleared");
    assert(len(local.user.passwordHash) > 0, "Password hash should be set");
    assert(local.user.passwordHash != local.originalPassword, "Hash should be different from original");
}

function test_email_verification_token_generation() {
    local.user = model("User").create(variables.validUserData);

    assert(len(local.user.emailVerificationToken) > 0, "Should generate email verification token");
    assert(!local.user.getIsEmailVerified(), "Email should not be verified initially");

    // Test email verification
    local.result = local.user.verifyEmail(local.user.emailVerificationToken);
    assert(local.result, "Email verification should succeed with valid token");
    assert(local.user.getIsEmailVerified(), "Email should be verified after token validation");
}

function test_slug_generation() {
    local.post = model("Post").create(
        title="This is a Test Post",
        content="Test content",
        authorid=1
    );

    assert(local.post.slug == "this-is-a-test-post", "Slug should be generated from title");

    // Test slug uniqueness
    local.post2 = model("Post").create(
        title="This is a Test Post",
        content="Different content",
        authorid=1
    );

    assert(local.post2.slug == "this-is-a-test-post-1", "Duplicate slug should have number appended");
}
```

### Testing Update Callbacks
```cfm
function test_timestamp_updates() {
    local.user = model("User").create(variables.validUserData);
    local.originalUpdatedAt = local.user.updatedat;

    // Wait a moment to ensure timestamp difference
    sleep(1000);

    local.user.update(firstname="Updated");

    assert(local.user.updatedat > local.originalUpdatedAt, "Updated timestamp should be newer");
}

function test_cache_clearing_on_update() {
    local.user = model("User").create(variables.validUserData);

    // Set up cache
    cachePut("user_#local.user.id#_stats", {postCount: 5});

    local.user.update(firstname="Updated");

    // Cache should be cleared by callback
    assert(!cacheKeyExists("user_#local.user.id#_stats"), "Cache should be cleared after update");
}
```

## Custom Finder Testing

### Testing Custom Finder Methods
```cfm
function test_active_finder() {
    // Create active and inactive users
    local.activeUser = model("User").create(variables.validUserData);

    variables.validUserData.username = "inactive";
    variables.validUserData.email = "inactive@test.com";
    variables.validUserData.isactive = false;
    local.inactiveUser = model("User").create(variables.validUserData);

    local.activeUsers = model("User").findActive();

    // Check results
    local.foundActive = false;
    local.foundInactive = false;

    for (local.user in local.activeUsers) {
        if (local.user.id == local.activeUser.id) local.foundActive = true;
        if (local.user.id == local.inactiveUser.id) local.foundInactive = true;
    }

    assert(local.foundActive, "Active finder should include active user");
    assert(!local.foundInactive, "Active finder should not include inactive user");
}

function test_find_by_email() {
    local.user = model("User").create(variables.validUserData);

    local.foundUser = model("User").findByEmail("test@example.com");
    assert(isObject(local.foundUser), "Should find user by email");
    assert(local.foundUser.id == local.user.id, "Should find correct user");

    local.notFound = model("User").findByEmail("nonexistent@example.com");
    assert(!isObject(local.notFound), "Should not find nonexistent user");
}
```

## Complex Workflow Testing

### Testing Password Reset Workflow
```cfm
function test_password_reset_workflow() {
    local.user = model("User").create(variables.validUserData);

    // Generate reset token
    local.result = local.user.generatePasswordResetToken();
    assert(local.result, "Password reset token generation should succeed");
    assert(len(local.user.passwordResetToken) > 0, "Should have reset token");
    assert(isDate(local.user.passwordResetExpires), "Should have expiry date");

    // Reset password with valid token
    local.resetResult = local.user.resetPassword(local.user.passwordResetToken, "NewSecurePass123!");
    assert(local.resetResult.success, "Password reset should succeed with valid token");

    // Verify old password no longer works
    local.authResult = model("User").authenticate(local.user.email, "SecurePass123!");
    assert(!local.authResult.success, "Old password should no longer work");

    // Verify new password works
    local.authResult = model("User").authenticate(local.user.email, "NewSecurePass123!");
    assert(local.authResult.success, "New password should work");
}

function test_account_locking_after_failed_attempts() {
    local.user = model("User").create(variables.validUserData);

    // Simulate 5 failed login attempts
    for (local.i = 1; local.i <= 5; local.i++) {
        model("User").authenticate(local.user.email, "WrongPassword");
    }

    // Reload user to get updated data
    local.user.reload();

    assert(local.user.getIsLocked(), "Account should be locked after 5 failed attempts");
    assert(local.user.failedloginattempts >= 5, "Should track failed attempts");

    // Test that even correct password fails when locked
    local.result = model("User").authenticate(local.user.email, "SecurePass123!");
    assert(!local.result.success, "Authentication should fail when account is locked");
}
```

## Test Utilities and Helpers

### Test Data Factory
```cfm
// /tests/support/TestHelper.cfc
component {

    function createUser(struct overrides = {}) {
        local.defaultData = {
            username = "testuser" & randRange(1000, 9999),
            email = "test#randRange(1000, 9999)#@example.com",
            firstname = "Test",
            lastname = "User",
            password = "SecurePass123!",
            passwordConfirmation = "SecurePass123!"
        };

        structAppend(local.defaultData, arguments.overrides);

        return model("User").create(local.defaultData);
    }

    function createPost(struct overrides = {}) {
        local.defaultData = {
            title = "Test Post #randRange(1000, 9999)#",
            content = "This is test content for the post.",
            status = "published"
        };

        if (!structKeyExists(arguments.overrides, "authorid")) {
            local.author = createUser();
            local.defaultData.authorid = local.author.id;
        }

        structAppend(local.defaultData, arguments.overrides);

        return model("Post").create(local.defaultData);
    }
}
```

### Using Test Fixtures
```yml
# /tests/fixtures/users.yml
john:
  username: johndoe
  email: john@example.com
  firstname: John
  lastname: Doe

jane:
  username: janedoe
  email: jane@example.com
  firstname: Jane
  lastname: Doe
```

```cfm
// Load fixtures in test
function setup() {
    fixtures("users");
}

function test_something() {
    local.john = users("john");
    // Test using john fixture
}
```

## Performance Testing

### Testing Query Performance
```cfm
function test_eager_loading_performance() {
    // Create test data
    for (local.i = 1; local.i <= 10; local.i++) {
        local.user = createUser();
        for (local.j = 1; local.j <= 5; local.j++) {
            createPost(authorid=local.user.id);
        }
    }

    // Test without eager loading (N+1 problem)
    local.startTime = getTickCount();
    local.users = model("User").findAll();
    for (local.user in local.users) {
        local.posts = local.user.posts(); // Causes N+1 queries
    }
    local.slowTime = getTickCount() - local.startTime;

    // Test with eager loading
    local.startTime = getTickCount();
    local.users = model("User").findAll(include="posts");
    local.fastTime = getTickCount() - local.startTime;

    assert(local.fastTime < local.slowTime, "Eager loading should be faster than N+1 queries");
}
```

## Test Organization Best Practices

1. **Group Related Tests**: Use descriptive test method names and group related functionality
2. **Use Setup/Teardown**: Clean up test data to avoid test interdependencies
3. **Test Edge Cases**: Include boundary conditions and error scenarios
4. **Mock External Dependencies**: Don't test external services in unit tests
5. **Use Factories**: Create consistent test data with factories
6. **Test Business Logic**: Focus on testing the model's business logic, not framework features
7. **Performance Awareness**: Include performance tests for critical operations

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Validations](./validations.md)
- [Model Associations](./associations.md)
- [Model Callbacks](./callbacks.md)
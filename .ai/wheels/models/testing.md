# Model Testing

## Description
Comprehensive guide to testing CFWheels models using TestBox 5 with modern BDD (Behavior Driven Development) syntax. This guide covers validation testing, association testing, business logic testing, and callback testing using `describe()`, `it()`, and `expect()` patterns.

## TestBox BDD Model Test Structure

### Modern Test Template (TestBox 5)
```cfm
/**
 * UserModelSpec - Test User model functionality using BDD
 */
component extends="wheels.Testbox" {

    function run() {
        describe("User Model", () => {

            beforeEach(() => {
                // Set up test data before each test
                variables.validUserData = {
                    username: "testuser_" & createUUID(),
                    email: "test_" & createUUID() & "@example.com",
                    firstname: "Test",
                    lastname: "User",
                    password: "SecurePass123!",
                    passwordConfirmation: "SecurePass123!"
                };
            });

            afterEach(() => {
                // Clean up test data after each test
                model("User").deleteAll(where="email LIKE '%test_%@example.com'");
            });

            // BDD test specs go here
        });
    }
}
```

### TestBox BDD Test Organization
```
tests/
├── specs/
│   ├── models/
│   │   ├── UserModelSpec.cfc
│   │   ├── PostModelSpec.cfc
│   │   ├── OrderModelSpec.cfc
│   │   └── ProductModelSpec.cfc
│   ├── controllers/
│   └── functions/
├── _assets/
├── populate.cfm
├── routes.cfm
└── runner.cfm
```

## Validation Testing with BDD

### Testing Presence Validations
```cfm
describe("User Presence Validations", () => {

    it("should be invalid without email", () => {
        var user = model("User").new(variables.validUserData);
        user.email = "";

        expect(user.valid()).toBeFalse();
        expect(user.hasErrors("email")).toBeTrue();

        var errors = user.errorsOn("email");
        expect(arrayLen(errors)).toBeGT(0);
    });

    it("should be invalid without username", () => {
        var user = model("User").new(variables.validUserData);
        user.username = "";

        expect(user.valid()).toBeFalse();
        expect(user.hasErrors("username")).toBeTrue();
    });

    it("should be valid with all required fields", () => {
        var user = model("User").new(variables.validUserData);

        expect(user.valid()).toBeTrue();
        expect(user.hasErrors()).toBeFalse();
    });

});
```

### Testing Format Validations
```cfm
describe("Email Format Validation", () => {

    it("should reject invalid email formats", () => {
        var user = model("User").new(variables.validUserData);
        var invalidEmails = ["invalid", "test@", "@example.com", "test.example.com"];

        for (var email in invalidEmails) {
            user.email = email;
            expect(user.valid()).toBeFalse("Email '#email#' should be invalid");
            expect(user.hasErrors("email")).toBeTrue("Should have error for email: #email#");
        }
    });

    it("should accept valid email format", () => {
        var user = model("User").new(variables.validUserData);
        user.email = "valid@example.com";

        expect(user.valid()).toBeTrue();
        expect(user.hasErrors("email")).toBeFalse();
    });

});

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
describe("Email Uniqueness Validation", () => {

    it("should reject duplicate email addresses", () => {
        // Create first user
        var firstUser = model("User").create(variables.validUserData);
        expect(firstUser.valid()).toBeTrue();

        // Try to create second user with same email
        variables.validUserData.username = "testuser2_" & createUUID();
        var secondUser = model("User").new(variables.validUserData);

        expect(secondUser.valid()).toBeFalse();
        expect(secondUser.hasErrors("email")).toBeTrue();
    });

});

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

## Association Testing with BDD

### Testing hasMany Associations
```cfm
describe("User Post Associations", () => {

    it("should have many posts", () => {
        var user = model("User").create(variables.validUserData);
        var post1 = model("Post").create({
            title: "Post 1",
            content: "Content 1",
            authorId: user.id
        });
        var post2 = model("Post").create({
            title: "Post 2",
            content: "Content 2",
            authorId: user.id
        });

        var posts = user.posts();
        expect(posts.recordCount).toBe(2);

        // Test association methods
        expect(user.hasPost()).toBeTrue();
        expect(user.postCount()).toBe(2);
    });

});

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
describe("Post User Associations", () => {

    it("should belong to a user", () => {
        var user = model("User").create(variables.validUserData);
        var post = model("Post").create({
            title: "My Post",
            content: "Content",
            authorId: user.id
        });

        var author = post.author();
        expect(author).toBeInstanceOf("User");
        expect(author.id).toBe(user.id);
        expect(author.username).toBe(user.username);
    });

});

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

## Business Logic Testing with BDD

### Testing Model Methods
```cfm
describe("User Business Logic", () => {

    describe("Full Name Generation", () => {

        it("should combine first and last name", () => {
            var user = model("User").new(variables.validUserData);
            var fullName = user.getFullName();

            expect(fullName).toBe("Test User");
        });

        it("should return first name only when last name is missing", () => {
            var user = model("User").new(variables.validUserData);
            user.lastname = "";

            expect(user.getFullName()).toBe("Test");
        });

        it("should return last name only when first name is missing", () => {
            var user = model("User").new(variables.validUserData);
            user.firstname = "";
            user.lastname = "User";

            expect(user.getFullName()).toBe("User");
        });

        it("should fallback to username when both names are missing", () => {
            var user = model("User").new(variables.validUserData);
            user.firstname = "";
            user.lastname = "";

            expect(user.getFullName()).toBe(user.username);
        });

    });

});

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

    describe("Authentication", () => {

        it("should authenticate with valid credentials", () => {
            // Create user (password will be hashed by callback)
            var user = model("User").create(variables.validUserData);

            // Test authentication
            var result = model("User").authenticate(user.email, "SecurePass123!");

            expect(result.success).toBeTrue();
            expect(result.user).toBeInstanceOf("User");
            expect(result.user.id).toBe(user.id);
        });

        it("should reject invalid password", () => {
            // Create user
            var user = model("User").create(variables.validUserData);

            // Test with wrong password
            var result = model("User").authenticate(user.email, "WrongPassword");

            expect(result.success).toBeFalse();
            expect(result).toHaveKey("error");
        });

        it("should reject nonexistent user", () => {
            var result = model("User").authenticate("nonexistent@example.com", "AnyPassword");

            expect(result.success).toBeFalse();
            expect(result).toHaveKey("error");
        });

    });

function test_password_verification() {
    local.user = model("User").create(variables.validUserData);

    assert(local.user.verifyPassword("SecurePass123!"), "Should verify correct password");
    assert(!local.user.verifyPassword("WrongPassword"), "Should not verify incorrect password");
}
```

## Callback Testing with BDD

### Testing Creation Callbacks
```cfm
describe("User Creation Callbacks", () => {

    it("should encrypt password on save", () => {
        var user = model("User").new(variables.validUserData);
        var originalPassword = user.password;

        user.save();

        // Password should be cleared and hash should be set
        expect(user.password).toBe("");
        expect(len(user.passwordHash)).toBeGT(0);
        expect(user.passwordHash).notToBe(originalPassword);
    });

});

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

## TestBox BDD Test Utilities and Helpers

### BDD Test Data Factory
```cfm
// /tests/_assets/TestHelper.cfc
component {

    function createUser(struct overrides = {}) {
        var defaultData = {
            username: "testuser_" & createUUID(),
            email: "test_" & createUUID() & "@example.com",
            firstname: "Test",
            lastname: "User",
            password: "SecurePass123!",
            passwordConfirmation: "SecurePass123!"
        };

        structAppend(defaultData, arguments.overrides, true);

        return model("User").create(defaultData);
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

### Using BDD Test Data Setup
```cfm
// Modern approach using beforeEach/afterEach
describe("User Tests with Test Data", () => {

    beforeEach(() => {
        // Create test data for each test
        variables.testUsers = {
            john: createUser({
                username: "johndoe",
                email: "john@example.com",
                firstname: "John",
                lastname: "Doe"
            }),
            jane: createUser({
                username: "janedoe",
                email: "jane@example.com",
                firstname: "Jane",
                lastname: "Doe"
            })
        };
    });

    afterEach(() => {
        // Clean up test data
        for (var user in variables.testUsers) {
            variables.testUsers[user].delete();
        }
    });

    it("should work with test data", () => {
        var john = variables.testUsers.john;
        expect(john.firstname).toBe("John");
    });

});
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

## TestBox BDD Test Organization Best Practices

### 1. Use Descriptive BDD Structure
```cfm
describe("User Model", () => {
    describe("Validation", () => {
        it("should require email address", () => { ... });
        it("should validate email format", () => { ... });
    });

    describe("Authentication", () => {
        it("should authenticate valid credentials", () => { ... });
        it("should reject invalid passwords", () => { ... });
    });
});
```

### 2. Use Lifecycle Methods for Clean Tests
```cfm
beforeEach(() => {
    // Fresh data for each test
    variables.testUser = createUser();
});

afterEach(() => {
    // Clean up after each test
    if (structKeyExists(variables, "testUser")) {
        variables.testUser.delete();
    }
});
```

### 3. Test Edge Cases with Clear Expectations
```cfm
it("should handle edge case with null values", () => {
    var user = model("User").new({ email: null });
    expect(user.valid()).toBeFalse();
    expect(user.hasErrors("email")).toBeTrue();
});
```

### 4. Use MockBox for External Dependencies
```cfm
beforeEach(() => {
    variables.mockEmailService = createMock("EmailService");
    variables.mockEmailService.$("sendEmail").returns(true);
    application.emailService = variables.mockEmailService;
});
```

### 5. Focus on Business Logic
- Test model methods, not framework features
- Test validations, associations, and custom logic
- Use clear, readable expectations
- Group related functionality with nested describe blocks

## Modern TestBox Resources

For comprehensive TestBox 5 documentation:
- [TestBox BDD Documentation](https://testbox.ortusbooks.com/v5.x/getting-started/testbox-bdd-primer)
- [TestBox Expectations](https://testbox.ortusbooks.com/v5.x/getting-started/testbox-bdd-primer/expectations)
- [MockBox Documentation](https://testbox.ortusbooks.com/v5.x/mocking/mockbox)
- [TestBox Life-cycle Methods](https://testbox.ortusbooks.com/v5.x/digging-deeper/life-cycle-methods)

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Validations](./validations.md)
- [Model Associations](./associations.md)
- [Model Callbacks](./callbacks.md)
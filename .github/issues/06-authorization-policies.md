# [Feature] Authorization System with Policies

**Priority:** #6 — Structured authorization beyond ad-hoc filters
**Labels:** `enhancement`, `feature-request`, `security`

## Summary

Add a policy-based authorization system that provides structured, testable, reusable authorization logic — replacing ad-hoc controller filter checks with declarative policy classes that answer "can this user perform this action on this resource?"

## Justification

### Ad-hoc authorization doesn't scale

Currently, Wheels authorization looks like this:

```cfm
// Scattered across controllers — inconsistent, untestable, duplicated
private function checkOwnership() {
    var post = model("Post").findByKey(params.key);
    if (post.userId != session.userId && session.role != "admin") {
        flashInsert(error="Not authorized");
        redirectTo(route="posts");
    }
}
```

Problems:
- **Scattered** — Authorization logic lives in dozens of controller filters
- **Duplicated** — Same checks copy-pasted across controllers
- **Untestable** — Can't unit test authorization without hitting controllers
- **Inconsistent** — Each developer implements checks differently
- **Invisible** — No central place to audit "who can do what"

### Competitors have structured solutions

| Framework | Authorization System | Key Feature |
|-----------|---------------------|-------------|
| **Laravel** | Gates + Policies | `$this->authorize('update', $post)` — automatic policy resolution |
| **Rails** | Pundit (de facto standard) | `authorize @post, :update?` — convention-based policies |
| **AdonisJS 6** | Bouncer | `bouncer.authorize('editPost', post)` — decorator-based |
| **Django** | Permissions + django-rules | `has_perm('blog.change_post')` — model-level permissions |
| **Phoenix** | BodyGuard / LetMe | `authorize(conn, :update, post)` — plug-based |
| **Wheels** | **Nothing** | Ad-hoc `if` statements in controller filters |

### Auth without authorization is incomplete

Issue #1 (Authentication Generator) establishes "who is this user?" — but authorization answers "what can this user do?" Without a structured authorization system, the auth generator only solves half the problem.

## Specification

### Policy Definition

```cfm
// app/policies/PostPolicy.cfc
component extends="wheels.Policy" {

    // Can this user view this post?
    boolean function view(required any user, required any post) {
        // Published posts are visible to everyone
        if (post.isPublished()) return true;
        // Drafts only visible to the author
        return post.userId == user.id;
    }

    // Can this user create posts?
    boolean function create(required any user) {
        return user.role != "banned";
    }

    // Can this user update this post?
    boolean function update(required any user, required any post) {
        return post.userId == user.id || user.isAdmin();
    }

    // Can this user delete this post?
    boolean function delete(required any user, required any post) {
        return user.isAdmin() || (post.userId == user.id && post.isDraft());
    }

    // Before filter — runs before all checks (super-admin bypass)
    boolean function before(required any user) {
        if (user.isSuperAdmin()) return true;
        // Return nothing to continue to specific check
    }
}
```

### Controller Integration

```cfm
// app/controllers/Posts.cfc
component extends="Controller" {

    function config() {
        super.config();
        // Automatic policy authorization
        filters(through="loadPost", only="show,edit,update,delete");
    }

    function show() {
        authorize("view", post);  // Checks PostPolicy.view()
        renderView();
    }

    function edit() {
        authorize("update", post);  // Checks PostPolicy.update()
        renderView();
    }

    function create() {
        authorize("create", model("Post"));  // Class-level check
        post = model("Post").create(params.post);
        if (post.hasErrors()) {
            renderView(action="new");
        } else {
            redirectTo(route="post", key=post.id);
        }
    }

    function update() {
        authorize("update", post);
        post.update(params.post);
        redirectTo(route="post", key=post.id);
    }

    function delete() {
        authorize("delete", post);
        post.delete();
        redirectTo(route="posts");
    }

    private function loadPost() {
        post = model("Post").findByKey(params.key);
    }
}
```

### View Integration

```cfm
// In views — conditionally show UI elements based on authorization
<cfparam name="post" default="">

<cfif can("update", post)>
    #linkTo(text="Edit", route="editPost", key=post.id)#
</cfif>

<cfif can("delete", post)>
    #linkTo(text="Delete", route="post", key=post.id, method="delete",
        confirm="Are you sure?")#
</cfif>

<cfif cannot("create", model("Post"))>
    <p>You don't have permission to create posts.</p>
</cfif>
```

### Gates (Simple Authorization Rules)

```cfm
// config/authorization.cfm — for simple checks that don't need a full policy
gate(name="accessDashboard", callback=function(user) {
    return ArrayFindNoCase(["admin", "editor"], user.role);
});

gate(name="manageUsers", callback=function(user) {
    return user.isAdmin();
});

// Usage in controllers
function dashboard() {
    authorizeGate("accessDashboard");
    renderView();
}

// Usage in views
<cfif gate("manageUsers")>
    #linkTo(text="Manage Users", route="users")#
</cfif>
```

### Policy Auto-Resolution

```cfm
// Convention: model("Post") → app/policies/PostPolicy.cfc
// Convention: model("User") → app/policies/UserPolicy.cfc

// authorize() automatically resolves the policy based on the model:
authorize("update", post);
// Equivalent to: new app.policies.PostPolicy().update(currentUser(), post)

// Explicit policy override when needed:
authorize("update", post, policy="AdminPostPolicy");
```

### Authorization Responses (Not Just Boolean)

```cfm
// Policies can return messages explaining denial
boolean function delete(required any user, required any post) {
    if (user.isBanned()) {
        deny("Your account has been suspended.");
    }
    if (post.userId != user.id) {
        deny("You can only delete your own posts.");
    }
    return true;
}

// Controller catches the denial message
try {
    authorize("delete", post);
} catch (wheels.AuthorizationException e) {
    flashInsert(error=e.message);  // "You can only delete your own posts."
    redirectTo(back=true);
}
```

### Testing Policies

```cfm
// tests/policies/PostPolicyTest.cfc
component extends="wheels.WheelsTest" {
    function run() {
        describe("PostPolicy", function() {
            it("allows authors to update their own posts", function() {
                var user = factory("User").create();
                var post = factory("Post").create(userId=user.id);
                var policy = new app.policies.PostPolicy();

                expect(policy.update(user, post)).toBeTrue();
            });

            it("denies non-authors from updating posts", function() {
                var author = factory("User").create();
                var other = factory("User").create();
                var post = factory("Post").create(userId=author.id);
                var policy = new app.policies.PostPolicy();

                expect(policy.update(other, post)).toBeFalse();
            });

            it("allows admins to update any post", function() {
                var admin = factory("User").admin().create();
                var post = factory("Post").create();
                var policy = new app.policies.PostPolicy();

                expect(policy.update(admin, post)).toBeTrue();
            });
        });
    }
}
```

### Generator Command

```bash
# Generate a policy for a model
wheels generate policy Post

# Output: app/policies/PostPolicy.cfc
# Pre-populates with view, create, update, delete methods
```

### Files Generated / Modified

| Component | File | Purpose |
|-----------|------|---------|
| **Base class** | `wheels/Policy.cfc` | Base policy with `before()`, `deny()` helpers |
| **Gate registry** | `wheels/authorization/GateRegistry.cfc` | Simple gate definitions |
| **Controller mixin** | `wheels/controller/Authorization.cfc` | `authorize()`, `authorizeGate()` |
| **View helpers** | `wheels/view/Authorization.cfc` | `can()`, `cannot()`, `gate()` |
| **Exception** | `wheels/exceptions/AuthorizationException.cfc` | Denial with message |
| **Config** | `config/authorization.cfm` | Gate definitions |
| **Generator** | `wheels generate policy` | CLI scaffolding |
| **Directory** | `app/policies/` | Convention for policy files |

## Impact Assessment

- **Security:** Centralized, auditable authorization replaces scattered ad-hoc checks
- **Testability:** Policies are plain CFCs — easily unit tested without HTTP
- **Maintainability:** Single source of truth for "who can do what"
- **Developer experience:** Declarative `authorize()` call vs. manual `if` statements

## References

- Laravel Authorization: https://laravel.com/docs/authorization
- Rails Pundit: https://github.com/varvet/pundit
- AdonisJS Bouncer: https://docs.adonisjs.com/guides/authorization
- Django Permissions: https://docs.djangoproject.com/en/5.0/topics/auth/default/#permissions

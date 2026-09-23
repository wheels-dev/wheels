---
name: Wheels Test Generator
description: Generate WheelsTest BDD specs for Wheels models, controllers, and integration tests. Use when creating tests for models (validations, associations), controllers (actions, filters), or integration workflows. Ensures comprehensive test coverage with proper setup/teardown and Wheels testing conventions.
---

# Wheels Test Generator

## When to Use This Skill

Activate automatically when:
- User requests to create tests/specs
- User wants to test a model, controller, or workflow
- User mentions: test, spec, WheelsTest, BDD, describe, it, expect
- After generating models/controllers (proactive testing)

## Model Spec Template

Specs live in `tests/specs/` and extend `wheels.WheelsTest`.

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Post", () => {
            it("requires a title", () => {
                var post = model("Post").new(title = "");
                expect(post.valid()).toBeFalse();
                expect(post.hasErrors("title")).toBeTrue();
            });

            it("deletes its comments with it", () => {
                var post = model("Post").create(title = "Test", content = "Content");
                var comment = model("Comment").create(postId = post.id, content = "Comment");
                expect(post.comments().recordCount).toBe(1);
                post.delete();
                expect(IsObject(model("Comment").findByKey(comment.id))).toBeFalse();
            });
        });
    }
}
```

Assign finder results to a local (`var post`), never to a variable named `model` - that shadows the `model()` function for the rest of the spec.

## Request Spec Template

Exercise controllers through a request, not by instantiating them:

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Posts", () => {
            it("lists posts", () => {
                $testClient().get("/posts").assertOk();
            });
        });
    }
}
```

## Related Skills

- **wheels-model-generator**: Creates models to test
- **wheels-controller-generator**: Creates controllers to test


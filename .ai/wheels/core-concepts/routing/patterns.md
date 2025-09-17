# Route Patterns

## Description
URL patterns define the structure of routes with optional parameters that map to controller actions.

## Key Points
- Parameters enclosed in `[squareBrackets]`
- Parameters become available in `params` struct
- First matching route wins
- More specific patterns should come first
- Avoid using `.` in patterns

## Code Sample
```cfm
mapper()
    // Parameters: key and slug required
    .get(name="postWithSlug", pattern="posts/[key]/[slug]", to="posts##show")

    // Parameter: key only
    .get(name="post", pattern="posts/[key]", to="posts##show")

    // No parameters
    .get(name="posts", pattern="posts", to="posts##index")

    // Optional parameters with constraints
    .get(name="search", pattern="search/[category]/[page]", to="search##index")
.end();

// In controller - parameters available as:
// params.key, params.slug, params.category, params.page
```

## Usage
1. Define patterns with literal strings and `[parameters]`
2. Parameters become keys in `params` struct
3. Order patterns from most to least specific
4. Use descriptive parameter names
5. Access in controller via `params.parameterName`

## Related
- [Routing Basics](./basics.md)
- [HTTP Methods](./http-methods.md)
- [Controller Parameters](../../controllers/params/verification.md)

## Important Notes
- Route matching stops at first match
- Parameters are always strings
- Special characters like `.` should be avoided
- Use query strings for complex parameter patterns
- Pattern `/posts/[key]/[slug]` won't match `/posts/123`
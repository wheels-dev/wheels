# Route Model Binding

Auto-resolves model instances from `params.key` during dispatch.

## Enable

```cfm
// Per-route
.resources(name="users", binding=true)

// Global
set(routeModelBinding=true);

// Explicit model name
.resources(name="writers", binding="Author")
```

## Behavior

- Convention: controller `posts` → model `Post` → `params.post`
- Calls `model("Post").findByKey(params.key)`
- Throws `Wheels.RecordNotFound` if record not found (renders 404)
- Silently skips if model class doesn't exist
- Skips routes without `params.key` (index, create)
- `params.key` is preserved alongside the resolved model
- Per-route `binding=false` overrides global `true`

## Setting

`routeModelBinding` — default: `false`

## Where in dispatch

Runs in `$createParams()` after `$deobfuscateParams`, before `$createNestedParamStruct`.
Method: `$resolveRouteModelBinding(params, route)` in `Dispatch.cfc`.

# wheels-hotwire

A Wheels package that ships [Hotwire](https://hotwired.dev) infrastructure: Turbo Drive, Turbo Frames, Turbo Streams, Stimulus helpers, and Hotwire Native mobile support. This is the **interaction layer** — it has zero opinions about CSS or visual design. Pair it with [wheels-basecoat](../basecoat/README.md), your own design system, or none at all.

## Requirements

- Wheels 3.0+
- Lucee 5+ or Adobe ColdFusion 2018+

## Installation

```bash
# Activate the package
cp -r packages/hotwire vendor/hotwire

# Restart or reload your app
wheels reload
```

All `turbo*`, `hotwire*`, `stimulus*`, and `is*` helpers become available in views and controllers via the package mixin system.

## Configuration

Hotwire has no `set()`-style application settings. The only helper with knobs is `hotwireIncludes()`:

```cfml
#hotwireIncludes(
    turbo = true,
    stimulus = true,
    turboVersion = "8",
    stimulusVersion = "3",
    turboCacheControl = "no-preview"
)#
```

| Argument | Default | Description |
|---|---|---|
| `turbo` | `true` | Include the Turbo ES module (`@hotwired/turbo`). |
| `stimulus` | `true` | Include the Stimulus ES module and start a global `window.Stimulus` Application. |
| `turboVersion` | `"8"` | Turbo major version served from jsDelivr. |
| `stimulusVersion` | `"3"` | Stimulus major version served from jsDelivr. |
| `turboCacheControl` | `"no-preview"` | Value for the `<meta name="turbo-cache-control">` tag. Pass an empty string to omit the tag. |

## Usage

### 1. Include Turbo + Stimulus in your layout

```cfm
<!-- app/views/layout.cfm -->
<!DOCTYPE html>
<html>
<head>
    <title>My App</title>
    #hotwireIncludes()#
</head>
<body>
    #includeContent()#
</body>
</html>
```

### 2. Opt a controller into Turbo Stream responses

Detect the request, then respond with one or more streams using `renderTurboStream()`:

```cfm
component extends="Controller" {

    function create() {
        comment = model("Comment").create(params.comment);

        if (isHotwireRequest()) {
            // `content` is any HTML string — render a partial to a string first,
            // or build markup inline as shown here.
            renderTurboStream([
                turboStreamAppend(target="comments-list", content="<li>#comment.body#</li>"),
                turboStreamUpdate(target="comment-count", content="#model('Comment').count()# comments")
            ]);
            return;
        }

        redirectTo(action="index");
    }
}
```

Available stream actions map 1:1 to the Turbo spec: `turboStreamAppend`, `turboStreamPrepend`, `turboStreamReplace`, `turboStreamUpdate`, `turboStreamRemove`, `turboStreamBefore`, `turboStreamAfter`, `turboStreamRefresh`. `renderTurboStream()` sets the `text/vnd.turbo-stream.html` content type and aborts for you.

### 3. Use Turbo Frames for scoped updates

```cfm
<!-- app/views/posts/show.cfm -->
#turboFrame(id="post-#post.id#")#
    <h1>#post.title#</h1>
    <p>#post.body#</p>
    #linkTo(text="Edit", route="editPost", key=post.id)#
#turboFrameEnd()#

<!-- Lazy-loaded frame -->
#turboFrame(id="recent-activity", src=urlFor(controller="activity"), loading="lazy")#
    <p>Loading…</p>
#turboFrameEnd()#
```

### 4. Stimulus controller conventions

Place Stimulus controllers in `public/controllers/` (or wherever your asset pipeline serves JS from) and register them against the global `window.Stimulus` application started by `hotwireIncludes()`:

```js
// public/controllers/clipboard_controller.js
import { Controller } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3/+esm";

export default class extends Controller {
    static targets = ["source"];
    copy() { navigator.clipboard.writeText(this.sourceTarget.value); }
}

window.Stimulus.register("clipboard", (await import("/controllers/clipboard_controller.js")).default);
```

Use the Stimulus convenience helpers to build data attributes without string-concat bugs:

```cfm
<div #stimulusController("clipboard")#>
    <input #stimulusTarget(controller="clipboard", name="source")# value="Copy me" />
    <button #stimulusAction("click->clipboard##copy")#>Copy</button>
</div>
```

Available helpers: `stimulusController`, `stimulusAction`, `stimulusTarget`, `stimulusValue`.

### 5. Hotwire Native navigation

When a request comes from a Turbo Native iOS/Android shell, redirect through the special interception paths instead of a normal HTTP redirect. Each helper falls through to `redirectTo()` on web requests, so the same controller code works for both clients:

```cfm
function create() {
    post = model("Post").create(params.post);

    // Native: dismiss/pop. Web: redirect to index.
    recedeOrRedirectTo(route="posts");
}

function update() {
    post = model("Post").findByKey(params.key);
    post.update(params.post);

    // Native: refresh current screen. Web: redirect to show.
    refreshOrRedirectTo(route="post", key=post.id);
}
```

Available helpers: `recedeOrRedirectTo` (pops), `refreshOrRedirectTo` (reloads), `resumeOrRedirectTo` (no-op). Detect native requests directly with `hotwireNativeApp()`.

### 6. Path configuration endpoint (Native)

Serve a JSON document controlling navigation behavior in native apps:

```cfm
// In a controller action routed at GET /native/config
function config() {
    hotwireNativePathConfiguration(
        settings = {
            tabs: [
                {title: "Home", path: "/dashboard", icon: "house"},
                {title: "Orders", path: "/orders", icon: "list.clipboard"}
            ]
        }
        // Sensible default rules are applied if `rules` is omitted —
        // see hotwireNativePathConfiguration() for the defaults.
    );
}
```

## Request detection

| Helper | Returns true when |
|---|---|
| `isHotwireRequest()` | `Accept` header contains `text/vnd.turbo-stream.html` |
| `isTurboFrameRequest()` | `Turbo-Frame` request header is present |
| `turboFrameRequestId()` | Returns the requesting frame's id (or `""`) |
| `hotwireNativeApp()` | `User-Agent` contains `Turbo Native` |

## Deactivating

```bash
rm -rf vendor/hotwire
wheels reload
```

## Reference

- `packages/hotwire/CLAUDE.md` — markup reference, helper inventory, naming conventions
- `packages/hotwire/.ai/ARCHITECTURE.md` — detailed architecture notes
- [Hotwire](https://hotwired.dev) — upstream documentation for Turbo, Stimulus, and Hotwire Native

## License

MIT

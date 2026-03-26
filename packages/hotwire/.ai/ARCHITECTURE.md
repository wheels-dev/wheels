# Hotwire + Wheels: From Concept to Plugin Architecture

## Part 1: Understanding Hotwire (The Web Side)

### The Philosophy — It's What You Already Believe

Peter, here's the thing: Hotwire is essentially the formal articulation of what Wheels has always been about. Wheels sends HTML from the server. Rails sends HTML from the server. The problem both frameworks faced is that the JavaScript world spent a decade telling everyone they needed to stop doing that and build JSON APIs + SPAs instead.

Hotwire is 37signals saying: "No. The server should send HTML. Here are the tools that make that approach feel as fast and interactive as an SPA."

It's three libraries plus a mobile framework, each solving a specific problem:

| Library | Problem It Solves |
|---------|------------------|
| **Turbo Drive** | Full page reloads feel slow |
| **Turbo Frames** | Updating one section shouldn't re-render the whole page |
| **Turbo Streams** | Sometimes you need to update multiple unrelated sections at once |
| **Stimulus** | Sometimes you need a tiny bit of client-side JS |
| **Hotwire Native** | Your web app should also be your mobile app |

Let me walk through each one with Wheels-specific examples.

---

### Turbo Drive — The Zero-Effort Win

**What it does:** Turbo Drive intercepts every link click and form submission on your page. Instead of the browser doing a full page reload, Turbo Drive fetches the new page in the background via `fetch()`, then swaps out the `<body>` and merges the `<head>`. The JavaScript `window` and `document` objects persist.

**What this means practically:** Your Wheels app instantly feels like a single-page application. No more white flash between pages. The browser doesn't re-parse CSS, re-execute JavaScript, or re-render the chrome. Navigation feels nearly instant.

**What you have to do:** Add one `<script>` tag to your layout. That's it.

```html
<!--- layouts/application.cfm --->
<head>
    <script type="module">
        import hotwire from "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8/dist/turbo.es2017.esm.js"
    </script>
</head>
```

**What it does behind the scenes:**

1. User clicks `<a href="/contacts/42">` 
2. Turbo Drive intercepts the click
3. Makes `GET /contacts/42` via fetch
4. Server returns a full HTML page (your normal Wheels response)
5. Turbo Drive swaps the `<body>`, merges the `<head>`
6. Updates the browser URL bar via the History API
7. The user sees an instant page transition

For form submissions, the same thing happens — Turbo Drive intercepts the `<form>` submit, sends it via fetch, and handles the redirect response by fetching and swapping that page too.

**Bonus:** Turbo Drive also pre-fetches links on hover (after 100ms), so by the time the user actually clicks, the response is often already cached. This makes pages feel like they load in ~0ms.

**Caveats for Wheels:** Any JavaScript in your layouts that expects to run on full page load needs to be written in a way that handles Turbo Drive's body-swap. Event listeners attached to `document` are fine (they persist). Event listeners attached to specific DOM elements that get swapped need to use event delegation or Stimulus controllers. This is the main migration cost — existing inline JS or jQuery plugins that assume full page loads.

---

### Turbo Frames — Partial Page Updates Without an API

**What it does:** Turbo Frames let you designate a section of your page as an independent context. Links and forms inside a frame only update that frame — the rest of the page stays untouched.

**Why this matters for Wheels:** Today in Wheels, if you want to edit a record inline (without leaving the page), you'd need to write custom AJAX, a JSON endpoint, and client-side rendering logic. With Turbo Frames, you wrap the section in a `<turbo-frame>` tag, and Wheels just renders a normal HTML response — Turbo extracts the matching frame from the response and swaps it.

**Concrete example — inline editing a contact:**

```html
<!--- views/contacts/index.cfm --->
<h1>Contacts</h1>

<cfoutput query="contacts">
<turbo-frame id="contact_#contacts.id#">
    <div class="contact-row">
        <span>#contacts.name#</span>
        <span>#contacts.email#</span>
        <a href="/contacts/#contacts.id#/edit">Edit</a>
    </div>
</turbo-frame>
</cfoutput>
```

```html
<!--- views/contacts/edit.cfm --->
<turbo-frame id="contact_#contact.id#">
    <form action="/contacts/#contact.id#" method="post">
        <input type="text" name="contact[name]" value="#contact.name#">
        <input type="email" name="contact[email]" value="#contact.email#">
        <button type="submit">Save</button>
        <a href="/contacts">Cancel</a>
    </form>
</turbo-frame>
```

**What happens:**

1. User clicks "Edit" on contact #5
2. Turbo intercepts the click, sees it's inside `<turbo-frame id="contact_5">`
3. Fetches `GET /contacts/5/edit`
4. Server renders the full edit page (with layout and everything)
5. Turbo extracts *only* the `<turbo-frame id="contact_5">` from the response
6. Swaps it into the existing page — the edit form appears inline
7. User submits the form — same thing happens in reverse
8. Server processes the update, redirects to index
9. Turbo fetches the index, extracts the matching frame, swaps it back

**The server has no idea this is happening.** It renders full pages every time. Turbo Frames handle the extraction client-side. This is the magic — you don't need special endpoints, partials, or JSON. Your existing Wheels views work with minimal changes (just add the `<turbo-frame>` wrappers).

**Lazy loading frames:** You can also use frames to lazy-load parts of the page:

```html
<!--- A sidebar that loads independently --->
<turbo-frame id="recent_activity" src="/dashboard/activity" loading="lazy">
    <p>Loading activity...</p>
</turbo-frame>
```

This means the main page renders instantly, and the sidebar loads asynchronously. For Miranda, imagine a production dashboard where the summary loads instantly and the detailed charts lazy-load in parallel.

---

### Turbo Streams — Multi-Target Updates

**What it does:** While Frames update a single frame, Streams let you update multiple unrelated parts of the page in a single response. They use a simple HTML format with eight actions: `append`, `prepend`, `replace`, `update`, `remove`, `before`, `after`, and `refresh`.

**When you need Streams instead of Frames:**
- A form submission needs to update a list AND a counter AND clear itself
- A delete action needs to remove an item AND update a total
- A real-time update needs to push content to multiple sections

**How it works with form submissions:** When your server responds to a form POST with `Content-Type: text/vnd.turbo-stream.html`, Turbo processes the stream actions instead of doing a normal redirect.

```html
<!--- Response from POST /contacts (after creating a new contact) --->
<cfcontent type="text/vnd.turbo-stream.html">

<!--- Append the new contact to the list --->
<turbo-stream action="append" target="contacts_list">
    <template>
        <turbo-frame id="contact_#newContact.id#">
            <div class="contact-row">
                <span>#newContact.name#</span>
                <span>#newContact.email#</span>
            </div>
        </turbo-frame>
    </template>
</turbo-stream>

<!--- Update the contact count in the header --->
<turbo-stream action="update" target="contact_count">
    <template>
        #totalContacts# contacts
    </template>
</turbo-stream>

<!--- Clear the form --->
<turbo-stream action="replace" target="new_contact_form">
    <template>
        <turbo-frame id="new_contact_form">
            <form action="/contacts" method="post">
                <input type="text" name="contact[name]" placeholder="Name">
                <button type="submit">Add</button>
            </form>
        </turbo-frame>
    </template>
</turbo-stream>
```

One response, three DOM updates, zero JavaScript. The server decides what changes — the client just executes.

**Over WebSockets/SSE:** Streams can also be delivered over WebSocket or Server-Sent Events for real-time updates. This is how you'd build a live production dashboard in Miranda — the server pushes Turbo Stream HTML fragments over SSE when machine status changes:

```html
<!--- SSE push when machine #3 goes offline --->
<turbo-stream action="replace" target="machine_3_status">
    <template>
        <span class="status-offline">OFFLINE</span>
    </template>
</turbo-stream>
```

No JavaScript, no WebSocket client code, no state management. Just HTML pushed from the server.

---

### Stimulus — The Minimal JavaScript Layer

**What it does:** Stimulus is a tiny framework for the JavaScript you *do* need — things like toggling visibility, copying to clipboard, dismissing alerts, or managing complex form interactions that don't warrant a server round-trip.

**The philosophy:** Stimulus doesn't render HTML. It attaches behavior to HTML that already exists on the page. It uses data attributes to connect HTML elements to JavaScript controllers.

**How it works:**

```html
<!--- In your Wheels view --->
<div data-controller="toggle">
    <button data-action="click->toggle#switch">Show Details</button>
    <div data-toggle-target="content" class="hidden">
        <p>These are the details...</p>
    </div>
</div>
```

```javascript
// toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content"]
    
    switch() {
        this.contentTarget.classList.toggle("hidden")
    }
}
```

**The naming convention:**
- `data-controller="toggle"` → looks for `toggle_controller.js`
- `data-action="click->toggle#switch"` → on click, call the `switch()` method on the toggle controller
- `data-toggle-target="content"` → exposes this element as `this.contentTarget` in the controller

**Why this matters for Wheels:** Stimulus controllers are reusable, composable, and completely decoupled from your backend. A `toggle` controller works everywhere. A `clipboard` controller works everywhere. You build a small library of these and use them via data attributes in your CFML views. No build step required if you use import maps or a CDN.

**Stimulus + Turbo work together perfectly** because Stimulus watches for DOM mutations. When Turbo swaps in new HTML (via Drive, Frames, or Streams), Stimulus automatically connects controllers to the new elements. No manual initialization needed.

---

### The Progressive Enhancement Hierarchy

The key mental model for Hotwire adoption is progressive enhancement:

```
HTML (your existing Wheels views)
  → add Turbo Drive (instant SPA feel, zero effort)
    → add Turbo Frames (partial page updates where useful)
      → add Turbo Streams (multi-target updates, real-time)
        → add Stimulus (client-side behavior when needed)
```

You can stop at any level. Turbo Drive alone transforms the perceived performance of any Wheels app. Most apps only need Drive + Frames for 90% of their interactivity needs.

---

## Part 2: Why Hotwire Benefits Wheels Even Without Mobile

### 1. It's the Modern Answer to "Should I Use a JavaScript Framework?"

Every Wheels developer building a new app faces the question: do I need React/Vue/Angular? Hotwire gives Wheels a clear answer: **No.** You keep writing CFML views, add Turbo, and you get SPA-like interactivity without:
- A separate frontend build pipeline
- A JSON API layer
- Duplicated business logic
- A JavaScript developer on the team

This is a competitive advantage for Wheels against both other CFML frameworks (which have no story here) and against Django/Rails competitors (where Django is also adopting Hotwire).

### 2. It Aligns With the HTMX Work Already Done

The Wheels community already has an HTMX plugin. Hotwire/Turbo is philosophically identical — both send HTML over the wire. But Turbo has a much larger ecosystem, active corporate sponsorship (37signals), native mobile support, and the Stimulus companion library. The HTMX plugin validates that the Wheels community wants this pattern. A Hotwire plugin is the more complete version.

### 3. It Makes Wheels AI-Friendly by Default

This connects directly to your `.ai` folder work and CLAUDE.md strategy. An AI agent (like Claude Code) working on a Wheels + Hotwire app doesn't need to context-switch between CFML and a JavaScript SPA framework. It writes CFML views with Turbo Frame annotations. The interactivity comes from the markup patterns, not from complex JavaScript state management. This dramatically reduces the cognitive load and context size for AI-assisted development.

### 4. It Creates the Foundation for Mobile

Even if someone never builds a mobile app, building their Wheels app with Turbo Frames means their pages are already decomposed into independent, URL-addressable segments. If they later decide to go mobile with Hotwire Native, those framed segments become individual mobile screens with zero additional work.

---

## Part 3: The wheels-hotwire Plugin Architecture

### Plugin Structure

```
wheels-hotwire/
├── CLAUDE.md                      # AI context for Claude Code
├── events/
│   └── onapplicationstart.cfm     # Plugin initialization
├── controllers/
│   └── HotwireController.cfc      # Base controller mixin
├── helpers/
│   ├── TurboStreamHelper.cfc      # turboStream() view helper
│   ├── TurboFrameHelper.cfc       # turboFrame() view helper  
│   └── HotwireNativeHelper.cfc    # hotwireNativeApp() detection
├── views/
│   └── hotwire/
│       ├── _turbo_includes.cfm    # Script tags for layout inclusion
│       └── pathConfiguration.cfm  # Native path config JSON endpoint
├── config/
│   ├── settings.cfm               # Plugin defaults
│   └── path-configuration.json    # Default Hotwire Native path rules
├── assets/
│   └── stimulus/
│       └── controllers/           # Bundled Stimulus controllers
│           ├── bridge/            # Bridge Components for Native
│           │   ├── nav_button_controller.js
│           │   ├── menu_controller.js
│           │   └── form_controller.js
│           ├── toggle_controller.js
│           ├── clipboard_controller.js
│           ├── autosave_controller.js
│           └── flash_controller.js
└── tests/
```

### Core Feature: Turbo Integration

#### Layout Helper — `turboIncludes()`

Drop this into your `<head>` and Turbo Drive is active immediately:

```html
<!--- layouts/application.cfm --->
<html>
<head>
    #turboIncludes()#
    <!--- Outputs:
    <meta name="turbo-cache-control" content="no-preview">
    <script type="module">
        import * as Turbo from "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8/+esm"
    </script>
    --->
</head>
```

Options: `turboIncludes(drive=true, cacheControl="no-preview", stimulus=true)`

#### Turbo Frame View Helper — `turboFrame()`

Generates `<turbo-frame>` tags from Wheels conventions:

```html
<!--- Instead of manually writing turbo-frame tags: --->
#turboFrame(id="contact_#contact.id#")#
    <div class="contact-row">
        #contact.name# — #linkTo(text="Edit", action="edit", key=contact.id)#
    </div>
#turboFrameEnd()#

<!--- Lazy-loaded frame: --->
#turboFrame(id="activity_feed", src="/dashboard/activity", loading="lazy")#
    <p>Loading...</p>
#turboFrameEnd()#

<!--- Frame that targets the whole page on click: --->
#turboFrame(id="sidebar_item", target="_top")#
    ...
#turboFrameEnd()#
```

#### Turbo Stream View Helper — `turboStream()`

Generates Turbo Stream responses:

```cfml
<!--- In your controller: --->
<cffunction name="create">
    <cfset contact = model("contact").create(params.contact)>
    
    <cfif isHotwireRequest()>
        <!--- Respond with Turbo Streams --->
        <cfset renderTurboStream([
            turboStreamAppend(target="contacts_list", 
                              partial="contacts/_contact", 
                              contact=contact),
            turboStreamUpdate(target="contact_count", 
                              content="#model('contact').count()# contacts"),
            turboStreamReplace(target="new_contact_form", 
                               partial="contacts/_form")
        ])>
    <cfelse>
        <!--- Normal redirect for non-Turbo requests --->
        <cfset redirectTo(action="index")>
    </cfif>
</cffunction>
```

The `renderTurboStream()` function sets `Content-Type: text/vnd.turbo-stream.html` and renders the stream elements.

#### Request Detection — `isHotwireRequest()`

Turbo requests include an `Accept` header with `text/vnd.turbo-stream.html`. The plugin provides detection helpers:

```cfml
<!--- In any controller: --->
isHotwireRequest()        <!--- true if the request accepts Turbo Streams --->
isTurboFrameRequest()     <!--- true if X-Turbo-Frame header is present --->
turboFrameRequestId()     <!--- returns the frame ID being requested --->
hotwireNativeApp()        <!--- true if User-Agent contains "Turbo Native" --->
```

For frame requests, the plugin can automatically skip the layout (since Turbo only extracts the matching frame anyway, but sending a bare frame is more efficient):

```cfml
<!--- In events/onApplicationStart.cfm or a base controller --->
<cfif isTurboFrameRequest()>
    <cfset usesLayout(false)>
</cfif>
```

### Core Feature: Hotwire Native Support

#### Mobile Detection & Conditional Rendering

The key helper for Hotwire Native is detecting the native User-Agent and conditionally hiding web-only chrome:

```html
<!--- layouts/application.cfm --->
<cfif NOT hotwireNativeApp()>
    <nav class="main-nav">
        <!--- Desktop navigation - hidden in native app --->
        #linkTo(text="Home", route="root")#
        #linkTo(text="Contacts", controller="contacts")#
    </nav>
</cfif>

<div id="main-content">
    #includeContent()#
</div>

<cfif NOT hotwireNativeApp()>
    <footer>
        <!--- Desktop footer - hidden in native app --->
    </footer>
</cfif>
```

In the native app, the navigation bar is provided by the native iOS/Android shell. Your Wheels views just render the content.

#### Server-Side Navigation Helpers

These are the commands that tell the native app how to handle navigation after form submissions:

```cfml
<!--- After a successful form submission in a modal: --->
<cffunction name="create">
    <cfset contact = model("contact").create(params.contact)>
    
    <cfif hotwireNativeApp()>
        <!--- Dismiss the modal and go back --->
        <cfset recedeOrRedirectTo(action="index")>
    <cfelse>
        <cfset redirectTo(action="index")>
    </cfif>
</cffunction>

<!--- The three navigation commands: --->
recedeOrRedirectTo(...)   <!--- Pop/dismiss current screen (e.g., close modal after save) --->
refreshOrRedirectTo(...)  <!--- Refresh current screen in place --->
resumeOrRedirectTo(...)   <!--- Do nothing, resume where you are --->
```

These work by redirecting to special path-based routes that the native app intercepts. On the web, they redirect normally. On native, the app catches the redirect URL and performs the native navigation action.

#### Path Configuration Endpoint

The plugin serves a JSON file that tells the native app how to handle different URL patterns:

```cfml
<!--- Registered as GET /hotwire/native/path-configuration.json --->
<cffunction name="pathConfiguration">
    <cfset renderWith(
        data={
            "settings": {
                "screenshots_enabled": true,
                "tabs": [
                    {"title": "Dashboard", "path": "/dashboard", "icon": "house"},
                    {"title": "Orders", "path": "/orders", "icon": "list.clipboard"},
                    {"title": "Settings", "path": "/settings", "icon": "gear"}
                ]
            },
            "rules": [
                {
                    "patterns": [".*"],
                    "properties": {
                        "context": "default",
                        "pull_to_refresh_enabled": true
                    }
                },
                {
                    "patterns": ["/new$", "/edit$"],
                    "properties": {
                        "context": "modal",
                        "pull_to_refresh_enabled": false
                    }
                }
            ]
        }
    )>
</cffunction>
```

Any URL ending in `/new` or `/edit` automatically opens as a native modal. Everything else pushes onto the navigation stack. And because this is served from the server, you can change this behavior *without an app store update*.

#### Bridge Components (Stimulus Controllers for Native)

Bridge Components are Stimulus controllers that communicate with the native iOS/Android shell. They let you trigger native UI elements from your server-rendered HTML:

```html
<!--- A "Save" button that appears in the native navigation bar --->
<div data-controller="bridge--nav-button"
     data-bridge--nav-button-title-value="Save"
     data-bridge--nav-button-side-value="right"
     data-action="bridge--nav-button:connect->form#submit">
</div>

<!--- A native share sheet triggered from your HTML --->
<a href="#" 
   data-controller="bridge--menu"
   data-bridge--menu-items-value='[{"title":"Share","icon":"square.and.arrow.up"}]'>
   Share
</a>
```

The Wheels plugin would bundle the common Bridge Component Stimulus controllers so developers don't have to write Swift/Kotlin to get native buttons, menus, and form handling.

### Configuration

```cfml
<!--- config/settings.cfm --->
<cfset set(
    hotwireTurboCDN = "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8/+esm",
    hotwireStimulusCDN = "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3/+esm",
    hotwireNativeEnabled = true,
    hotwirePathConfigRoute = "/hotwire/native/v1/path-configuration",
    hotwireRecedeRoute = "/hotwire/native/recede",
    hotwireRefreshRoute = "/hotwire/native/refresh",
    hotwireResumeRoute = "/hotwire/native/resume",
    hotwireSkipLayoutForFrameRequests = true,
    hotwireTurboStreamContentType = "text/vnd.turbo-stream.html"
)>
```

---

## Part 4: Implementation Roadmap

### Phase 1: Turbo Drive (Week 1)

Minimum viable plugin — just the script inclusion and request detection helpers. Any Wheels app gets instant SPA-like performance by adding `turboIncludes()` to their layout.

**Deliverables:**
- `turboIncludes()` helper
- `isHotwireRequest()` / `isTurboFrameRequest()` detection
- Automatic layout skipping for frame requests
- Documentation + demo app

### Phase 2: Turbo Frames & Streams (Weeks 2-3)

View helpers for generating frame and stream markup. Turbo Stream response rendering.

**Deliverables:**
- `turboFrame()` / `turboFrameEnd()` helpers
- `turboStreamAppend/Prepend/Replace/Update/Remove()` helpers
- `renderTurboStream()` controller method
- Partial rendering support for stream templates

### Phase 3: Stimulus Integration (Week 3-4)

Bundled Stimulus controllers for common UI patterns. Import map or asset pipeline integration.

**Deliverables:**
- `stimulusIncludes()` helper with controller auto-loading
- 5-6 bundled controllers (toggle, clipboard, flash, autosave, tabs, modal)
- CFML tag helpers that generate the correct data attributes
- Controller generator (CLI or scaffolding)

### Phase 4: Hotwire Native (Weeks 5-8)

The mobile layer. Path configuration serving, native detection, navigation helpers, Bridge Components.

**Deliverables:**
- `hotwireNativeApp()` detection
- `recedeOrRedirectTo()` / `refreshOrRedirectTo()` / `resumeOrRedirectTo()`
- Path configuration endpoint and JSON builder
- Bridge Component Stimulus controllers
- Template iOS app shell project (Swift, ~100 lines)
- Template Android app shell project (Kotlin, ~100 lines)
- Documentation: "From Wheels web app to App Store in a weekend"

---

## Part 5: What This Means for Wheels Strategically

### The Story You Can Tell

"Wheels is the only CFML framework with built-in mobile app support. Add the Hotwire plugin, write your views once, and deploy to web, iOS, and Android from one codebase. No JSON API. No React Native. No separate frontend team."

No other CFML framework can say this. ColdBox can't. FW/1 can't. And it's not just a sales pitch — it's architecturally true. The same CFML views, the same models, the same validations, the same controller logic. Turbo Frames on web become individual screens in the native app. The path configuration controls native navigation from the server.

### The Ecosystem Play

Hotwire has been adopted by Symfony (PHP), Django (Python), Flask, Spring Boot, and .NET. By building a first-class Wheels integration, you position Wheels alongside these frameworks in the Hotwire ecosystem. The community at hotwire.io already lists frameworks from multiple languages. Adding Wheels/CFML to that list raises Wheels' visibility beyond the CFML world.

### The AI-Development Multiplier

Claude Code generating a Wheels + Hotwire app needs to understand:
- CFML (it already does)
- HTML with Turbo Frame/Stream annotations (simple markup patterns)
- Stimulus controllers (small, formulaic JS files)

Compare this to Claude Code generating a Wheels + React Native app, which would need to understand CFML, JSON API design, React, React Native, navigation libraries, state management, TypeScript, and native build tooling. The Hotwire approach reduces the AI-development surface area by an order of magnitude.

---

## Part 6: Basecoat UI Integration — The Design System Layer

### The Real Problem Basecoat Solves

People don't adopt React because they love `useState`. They adopt it because shadcn/ui makes everything they build look professionally designed. Basecoat gives us the exact same design tokens, color system, and component aesthetics — but as pure CSS classes on plain HTML. No React, no build step, no virtual DOM. A `<button class="btn">` in Basecoat is visually identical to a shadcn `<Button>` in React.

Basecoat uses:
- **Semantic CSS classes**: `btn`, `btn-secondary`, `btn-destructive`, `btn-outline`, `btn-ghost`, `card`, `badge`, `input`, `table`, `tabs`, `dialog`, `form`
- **Size variants via compound classes**: `btn-sm`, `btn-lg`, `btn-sm-icon-outline`
- **Native HTML elements**: `<dialog>` for modals, `<details>` for accordions, `<select>` for selects
- **Minimal vanilla JS**: only for interactive components (dropdowns, comboboxes, toasts) — via Alpine.js
- **shadcn/ui theme compatibility**: CSS variables match shadcn's theming system exactly, so any shadcn theme works

This is a perfect match for CFML's server-rendered view model. Basecoat already provides Jinja and Nunjucks macros as a reference implementation for server-side helpers — our CFML helpers follow the same pattern.

### Plugin Integration Architecture

The wheels-hotwire plugin bundles Basecoat as its design system layer alongside Turbo and Stimulus:

```
wheels-hotwire/
├── assets/
│   ├── basecoat/
│   │   ├── basecoat.css          # Basecoat Tailwind plugin output
│   │   └── basecoat.js           # Alpine.js interactive components
│   ├── turbo/
│   │   └── turbo.es2017.esm.js
│   └── stimulus/
│       └── stimulus.esm.js
├── helpers/
│   ├── BasecoatHelper.cfc        # UI component helpers
│   ├── TurboHelper.cfc           # Turbo Frame/Stream helpers
│   └── HotwireNativeHelper.cfc   # Native detection helpers
```

The single layout include gives you the full stack:

```html
<!--- layouts/application.cfm --->
<html>
<head>
    #hotwireIncludes()#
    <!--- Outputs Tailwind, Basecoat CSS, Turbo, Stimulus, and Alpine.js --->
</head>
<body>
    #includeContent()#
</body>
</html>
```

---

### Component Helper API Reference

Every helper generates correct Basecoat HTML markup with proper ARIA attributes, Turbo Frame integration, and Stimulus/Alpine.js wiring. The helpers are designed so Claude Code can generate an entire CRUD interface from simple function calls.

#### Buttons

```cfml
<!--- Basic variants --->
#uiButton(text="Save")#
<!--- <button class="btn">Save</button> --->

#uiButton(text="Cancel", variant="outline")#
<!--- <button class="btn-outline">Cancel</button> --->

#uiButton(text="Delete", variant="destructive", size="sm")#
<!--- <button class="btn-sm-destructive">Delete</button> --->

<!--- As a link (renders <a> instead of <button>) --->
#uiButton(text="View Details", href="/contacts/42", variant="secondary")#
<!--- <a href="/contacts/42" class="btn-secondary">View Details</a> --->

<!--- With Wheels linkTo integration --->
#uiLinkButton(text="Edit", action="edit", key=contact.id, variant="outline", size="sm")#
<!--- Delegates to linkTo() but wraps output in Basecoat button classes --->

<!--- Loading state --->
#uiButton(text="Saving...", variant="outline", loading=true, disabled=true)#
<!--- <button class="btn-outline" disabled><svg class="animate-spin">...</svg> Saving...</button> --->

<!--- Icon button --->
#uiButton(icon="trash", variant="destructive", size="sm", ariaLabel="Delete contact")#
<!--- <button class="btn-sm-icon-destructive" aria-label="Delete contact"><svg>...</svg></button> --->
```

Variants: `primary` (default), `secondary`, `destructive`, `outline`, `ghost`, `link`  
Sizes: `sm`, `md` (default), `lg`  
Options: `icon`, `loading`, `disabled`, `href` (renders `<a>`), `class` (additional classes)

#### Cards

```cfml
#uiCard()#
    #uiCardHeader(title="Team Members", description="Manage your team and their roles.")#
    #uiCardContent()#
        <!--- Your content here --->
        <p>Alice Smith — Admin</p>
        <p>Bob Jones — Editor</p>
    #uiCardContentEnd()#
    #uiCardFooter()#
        #uiButton(text="Add Member", variant="outline", size="sm")#
    #uiCardFooterEnd()#
#uiCardEnd()#

<!--- Generates: --->
<!--- <div class="card">
         <div class="card-header">
             <h3>Team Members</h3>
             <p>Manage your team and their roles.</p>
         </div>
         <div class="card-content">...</div>
         <div class="card-footer">...</div>
     </div> --->
```

#### Badges

```cfml
#uiBadge(text="Active")#
<!--- <span class="badge">Active</span> --->

#uiBadge(text="Overdue", variant="destructive")#
<!--- <span class="badge-destructive">Overdue</span> --->

#uiBadge(text="Draft", variant="outline")#
<!--- <span class="badge-outline">Draft</span> --->

#uiBadge(text="v3.1.0", variant="secondary")#
<!--- <span class="badge-secondary">v3.1.0</span> --->
```

#### Alerts

```cfml
#uiAlert(
    title="Heads up!",
    description="Basecoat components are accessible by default.",
    variant="default"
)#

#uiAlert(
    title="Error",
    description="Your session has expired. Please log in again.",
    variant="destructive"
)#
```

#### Dialogs (Modals)

This is the component where the helper really pays for itself — a Basecoat dialog requires ~25 lines of HTML with proper ARIA attributes, unique IDs, and close handlers. The helper reduces it to a block call:

```cfml
#uiDialog(
    id="edit-contact",
    title="Edit Contact",
    description="Make changes to the contact record.",
    trigger="Edit",
    triggerVariant="outline",
    maxWidth="425px"
)#
    <!--- Your dialog content goes here --->
    <cfoutput>
    #startFormTag(action="update", key=contact.id, class="form grid gap-4")#
        #uiField(label="Name", name="contact[name]", value=contact.name)#
        #uiField(label="Email", name="contact[email]", type="email", value=contact.email)#
    #endFormTag()#
    </cfoutput>
#uiDialogFooter()#
    #uiButton(text="Cancel", variant="outline", close=true)#
    #uiButton(text="Save Changes", close=true)#
#uiDialogEnd()#

<!--- Generates the full <dialog> element with:
      - Unique IDs for aria-labelledby/describedby
      - Trigger button with showModal() onclick
      - Backdrop click-to-close
      - Close X button with SVG icon
      - Proper header/section/footer structure --->
```

**Turbo Frame integration** — dialogs play beautifully with Turbo Frames. Wrap the dialog content in a frame and the form submission happens inline:

```cfml
#turboFrame(id="contact_#contact.id#_dialog")#
    #uiDialog(id="edit-#contact.id#", title="Edit Contact", trigger="Edit", triggerVariant="ghost")#
        #startFormTag(action="update", key=contact.id, class="form grid gap-4")#
            #uiField(label="Name", name="contact[name]", value=contact.name)#
        #endFormTag()#
    #uiDialogFooter()#
        #uiButton(text="Save", close=true)#
    #uiDialogEnd()#
#turboFrameEnd()#
```

#### Form Fields

The `uiField()` helper wraps Basecoat's field pattern — label, input, description, and error message — into a single call that integrates with Wheels' error handling:

```cfml
<!--- Text input with label --->
#uiField(label="Full Name", name="contact[name]", value=contact.name)#
<!--- <div class="grid gap-2">
         <label for="contact-name">Full Name</label>
         <input type="text" id="contact-name" name="contact[name]" value="..." class="input" />
     </div> --->

<!--- With description and placeholder --->
#uiField(
    label="Email Address",
    name="contact[email]",
    type="email",
    value=contact.email,
    placeholder="name@example.com",
    description="We'll never share your email."
)#

<!--- With Wheels model error integration --->
#uiField(
    label="Username",
    name="user[username]",
    value=user.username,
    errorMessage=errorMessageOn(user, "username")
)#
<!--- If validation failed, renders with error styling:
     <div class="grid gap-2">
         <label for="user-username">Username</label>
         <input type="text" id="user-username" name="user[username]" 
                class="input border-destructive" aria-invalid="true" 
                aria-describedby="user-username-error" />
         <p id="user-username-error" class="text-sm text-destructive">
             Username has already been taken
         </p>
     </div> --->

<!--- Textarea --->
#uiField(label="Bio", name="user[bio]", type="textarea", value=user.bio, rows=4)#

<!--- Select --->
#uiField(
    label="Role",
    name="user[role]",
    type="select",
    value=user.role,
    options="Admin,Editor,Viewer"
)#

<!--- Checkbox --->
#uiField(label="Active", name="user[active]", type="checkbox", checked=user.active)#

<!--- Switch (toggle) --->
#uiField(label="Email notifications", name="user[notifications]", type="switch", checked=user.notifications)#
```

#### Complete Form Example

```cfml
#uiCard()#
    #uiCardHeader(title="New Contact", description="Add a contact to your address book.")#
    #uiCardContent()#
        #startFormTag(action="create", class="form grid gap-4")#
            #uiField(label="Name", name="contact[name]", placeholder="Full name", required=true)#
            #uiField(label="Email", name="contact[email]", type="email", placeholder="name@company.com")#
            #uiField(label="Phone", name="contact[phone]", type="tel")#
            #uiField(label="Role", name="contact[role]", type="select",
                     options="Customer,Vendor,Partner,Other")#
            #uiField(label="Notes", name="contact[notes]", type="textarea", rows=3)#
            #uiField(label="VIP", name="contact[vip]", type="switch",
                     description="Flag this contact for priority support.")#
        #endFormTag()#
    #uiCardContentEnd()#
    #uiCardFooter()#
        #uiButton(text="Cancel", variant="outline", href="/contacts")#
        #uiButton(text="Save Contact", type="submit")#
    #uiCardFooterEnd()#
#uiCardEnd()#
```

That entire form — with proper Basecoat styling, labels, field spacing, a card wrapper, and accessible markup — is ~15 lines of CFML. The equivalent raw HTML would be 80+ lines. The equivalent React + shadcn would be 60+ lines of JSX plus imports, plus a form schema, plus a submit handler.

#### Tables

```cfml
#uiTable()#
    #uiTableHeader()#
        #uiTableRow()#
            #uiTableHead(text="Name")#
            #uiTableHead(text="Email")#
            #uiTableHead(text="Role")#
            #uiTableHead(text="Status", class="text-right")#
        #uiTableRowEnd()#
    #uiTableHeaderEnd()#
    #uiTableBody()#
        <cfoutput query="contacts">
        #uiTableRow()#
            #uiTableCell(text=contacts.name, class="font-medium")#
            #uiTableCell(text=contacts.email)#
            #uiTableCell(text=contacts.role)#
            #uiTableCell(class="text-right")#
                #uiBadge(text=contacts.status,
                         variant=contacts.status eq "Active" ? "default" : "secondary")#
            #uiTableCellEnd()#
        #uiTableRowEnd()#
        </cfoutput>
    #uiTableBodyEnd()#
#uiTableEnd()#
```

#### Tabs

```cfml
#uiTabs(default="overview")#
    #uiTabList()#
        #uiTabTrigger(value="overview", text="Overview")#
        #uiTabTrigger(value="analytics", text="Analytics")#
        #uiTabTrigger(value="settings", text="Settings")#
    #uiTabListEnd()#

    #uiTabContent(value="overview")#
        <p>Dashboard overview content...</p>
    #uiTabContentEnd()#

    #uiTabContent(value="analytics")#
        <p>Analytics charts and data...</p>
    #uiTabContentEnd()#

    #uiTabContent(value="settings")#
        <p>Settings form...</p>
    #uiTabContentEnd()#
#uiTabsEnd()#
```

**With Turbo Frames for lazy-loaded tab content:**

```cfml
#uiTabs(default="overview")#
    #uiTabList()#
        #uiTabTrigger(value="overview", text="Overview")#
        #uiTabTrigger(value="analytics", text="Analytics")#
    #uiTabListEnd()#

    #uiTabContent(value="overview")#
        #turboFrame(id="tab-overview", src="/dashboard/overview", loading="lazy")#
            #uiSkeleton(lines=5)#
        #turboFrameEnd()#
    #uiTabContentEnd()#

    #uiTabContent(value="analytics")#
        #turboFrame(id="tab-analytics", src="/dashboard/analytics", loading="lazy")#
            #uiSkeleton(lines=5)#
        #turboFrameEnd()#
    #uiTabContentEnd()#
#uiTabsEnd()#
```

Each tab loads its content on demand via a Turbo Frame. The server renders a normal HTML page, Turbo extracts the matching frame. This pattern gives you a tabbed interface with lazy loading and zero JavaScript.

#### Dropdown Menus

```cfml
#uiDropdown(trigger="Actions", triggerVariant="outline")#
    #uiDropdownItem(text="Edit", href="/contacts/#contact.id#/edit")#
    #uiDropdownItem(text="Duplicate", href="/contacts/#contact.id#/duplicate")#
    #uiDropdownSeparator()#
    #uiDropdownItem(text="Delete", variant="destructive",
                    href="/contacts/#contact.id#",
                    method="delete",
                    confirm="Are you sure?")#
#uiDropdownEnd()#
```

#### Pagination

Integrates with Wheels' built-in pagination:

```cfml
<!--- In controller: --->
<cfset contacts = model("contact").findAll(page=params.page, perPage=20)>

<!--- In view: --->
#uiPagination(
    currentPage=pagination.currentPage,
    totalPages=pagination.totalPages,
    baseUrl="/contacts"
)#
```

#### Toast Notifications

```cfml
<!--- In controller after a successful action: --->
<cfset flashInsert(success="Contact saved successfully.")>

<!--- In layout: --->
<cfif flashKeyExists("success")>
    #uiToast(message=flash("success"), variant="default")#
</cfif>
<cfif flashKeyExists("error")>
    #uiToast(message=flash("error"), variant="destructive")#
</cfif>
```

#### Sidebar Navigation

For Miranda's MES interface or any app with sidebar navigation:

```cfml
#uiSidebar()#
    #uiSidebarHeader()#
        <img src="/images/logo.svg" alt="Miranda MES" class="h-8">
    #uiSidebarHeaderEnd()#

    #uiSidebarContent()#
        #uiSidebarGroup(label="Production")#
            #uiSidebarItem(text="Dashboard", href="/dashboard", icon="layout-dashboard",
                           active=(params.controller eq "dashboard"))#
            #uiSidebarItem(text="Work Orders", href="/workorders", icon="clipboard-list",
                           active=(params.controller eq "workorders"))#
            #uiSidebarItem(text="Machines", href="/machines", icon="cog",
                           active=(params.controller eq "machines"))#
        #uiSidebarGroupEnd()#

        #uiSidebarGroup(label="Inventory")#
            #uiSidebarItem(text="Parts", href="/parts", icon="package")#
            #uiSidebarItem(text="Receiving", href="/receiving", icon="truck")#
        #uiSidebarGroupEnd()#
    #uiSidebarContentEnd()#
#uiSidebarEnd()#
```

---

### Icon System

Basecoat uses Lucide icons (the same icon set shadcn/ui uses). The plugin bundles a `uiIcon()` helper:

```cfml
#uiIcon(name="trash", size=16)#
#uiIcon(name="plus", size=20, class="text-muted-foreground")#
#uiIcon(name="check-circle", size=24, strokeWidth=1.5)#
```

Icons are inlined as SVGs (no external font dependency, works offline, accessible). The helper maps icon names to SVG paths from the Lucide icon set.

---

### Theming

Basecoat is fully compatible with shadcn/ui themes. Themes are CSS variable overrides:

```css
/* In your app's CSS — or use shadcn's theme generator */
:root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --primary: 240 5.9% 10%;
    --primary-foreground: 0 0% 98%;
    --destructive: 0 84.2% 60.2%;
    /* ... */
}
```

The plugin ships with Basecoat's default theme (which matches shadcn's default) plus the "Claude" theme shown on basecoatui.com. You can generate custom themes using shadcn's theme builder at ui.shadcn.com/themes and drop the CSS variables into your Wheels app.

For CounterPro, you'd create a theme using the industrial blue / safety orange brand palette and every Basecoat component would inherit it automatically.

---

### How This All Fits Together — A Miranda Screen Example

Here's a complete Miranda MES production dashboard view using Hotwire + Basecoat:

```cfml
<!--- views/dashboard/index.cfm --->

<!--- Page header --->
<div class="flex items-center justify-between mb-6">
    <div>
        <h1 class="text-2xl font-bold tracking-tight">Production Dashboard</h1>
        <p class="text-muted-foreground">Real-time manufacturing overview</p>
    </div>
    #uiButton(text="New Work Order", href="/workorders/new", icon="plus")#
</div>

<!--- KPI cards — each in its own Turbo Frame for independent refresh --->
<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
    #turboFrame(id="kpi-oee", src="/dashboard/kpi/oee", loading="lazy")#
        #uiCard()#
            #uiCardHeader(title="OEE")#
            #uiCardContent()##uiSkeleton(lines=1)##uiCardContentEnd()#
        #uiCardEnd()#
    #turboFrameEnd()#

    #turboFrame(id="kpi-throughput", src="/dashboard/kpi/throughput", loading="lazy")#
        #uiCard()#
            #uiCardHeader(title="Throughput")#
            #uiCardContent()##uiSkeleton(lines=1)##uiCardContentEnd()#
        #uiCardEnd()#
    #turboFrameEnd()#

    #turboFrame(id="kpi-downtime", src="/dashboard/kpi/downtime", loading="lazy")#
        #uiCard()#
            #uiCardHeader(title="Downtime")#
            #uiCardContent()##uiSkeleton(lines=1)##uiCardContentEnd()#
        #uiCardEnd()#
    #turboFrameEnd()#

    #turboFrame(id="kpi-quality", src="/dashboard/kpi/quality", loading="lazy")#
        #uiCard()#
            #uiCardHeader(title="Quality Rate")#
            #uiCardContent()##uiSkeleton(lines=1)##uiCardContentEnd()#
        #uiCardEnd()#
    #turboFrameEnd()#
</div>

<!--- Active work orders table — refreshes via Turbo Streams on SSE --->
<turbo-stream-source src="/dashboard/stream">
#uiCard()#
    #uiCardHeader(title="Active Work Orders")#
    #uiCardContent()#
        #uiTable()#
            #uiTableHeader()#
                #uiTableRow()#
                    #uiTableHead(text="WO ##")#
                    #uiTableHead(text="Part")#
                    #uiTableHead(text="Machine")#
                    #uiTableHead(text="Progress")#
                    #uiTableHead(text="Status")#
                    #uiTableHead(text="", class="w-[50px]")#
                #uiTableRowEnd()#
            #uiTableHeaderEnd()#
            #uiTableBody(id="workorders-list")#
                <cfoutput query="activeOrders">
                #uiTableRow(id="wo-#activeOrders.id#")#
                    #uiTableCell(text=activeOrders.orderNumber, class="font-mono font-medium")#
                    #uiTableCell(text=activeOrders.partName)#
                    #uiTableCell(text=activeOrders.machineName)#
                    #uiTableCell()#
                        #uiProgress(value=activeOrders.percentComplete)#
                    #uiTableCellEnd()#
                    #uiTableCell()#
                        #uiBadge(text=activeOrders.status,
                                 variant=activeOrders.status eq "Running" ? "default" : "secondary")#
                    #uiTableCellEnd()#
                    #uiTableCell()#
                        #uiDropdown(trigger="...", triggerVariant="ghost", triggerSize="sm")#
                            #uiDropdownItem(text="View", href="/workorders/#activeOrders.id#")#
                            #uiDropdownItem(text="Pause", href="/workorders/#activeOrders.id#/pause", method="post")#
                        #uiDropdownEnd()#
                    #uiTableCellEnd()#
                #uiTableRowEnd()#
                </cfoutput>
            #uiTableBodyEnd()#
        #uiTableEnd()#
    #uiCardContentEnd()#
#uiCardEnd()#
</turbo-stream-source>
```

This single view gives you:
- 4 KPI cards that lazy-load independently via Turbo Frames
- A live-updating work order table via Server-Sent Events + Turbo Streams
- Dropdown action menus on every row
- Progress bars and status badges
- A "New Work Order" button
- Full Basecoat styling that looks identical to a React + shadcn dashboard
- Zero JavaScript written by the developer
- Works on Hotwire Native mobile with no changes (the sidebar collapses, cards stack vertically)

And the whole thing is a `.cfm` file that Claude Code can generate and iterate on in seconds.

---

### Updated Implementation Roadmap

| Phase | Weeks | Deliverable |
|-------|-------|-------------|
| **1: Turbo Drive + Basecoat CSS** | 1-2 | `hotwireIncludes()`, Basecoat CSS bundling, theme configuration, `uiButton()`, `uiCard()`, `uiBadge()`, `uiAlert()` |
| **2: Turbo Frames + Form Components** | 3-4 | `turboFrame()`, `uiField()`, `uiDialog()`, `uiTable()`, `uiPagination()`, frame request detection, layout skipping |
| **3: Turbo Streams + Interactive Components** | 5-6 | `renderTurboStream()`, `uiTabs()`, `uiDropdown()`, `uiToast()`, `uiSidebar()`, SSE stream source helpers |
| **4: Stimulus + Icons** | 7-8 | Bundled Stimulus controllers, `uiIcon()` with Lucide icons, Stimulus includes/auto-loading |
| **5: Hotwire Native** | 9-12 | `hotwireNativeApp()` detection, navigation helpers, path configuration endpoint, Bridge Components, template iOS/Android shell projects |

### The Updated Story

"Wheels is the only CFML framework with a complete modern frontend story. Basecoat gives you shadcn/ui-quality design. Hotwire gives you SPA-like interactivity. Hotwire Native gives you mobile. All from CFML views with zero JavaScript framework overhead. Write `#uiButton()#` instead of `<Button variant="outline" />` — same visual result, no React required."

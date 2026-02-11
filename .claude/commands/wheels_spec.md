# /wheels_spec - Analyze Requirements and Generate Specification

## Description
Parse a natural language request into a detailed implementation specification for a Wheels application feature. Present the spec for user approval before any code is written.

## Usage
```
/wheels_spec [description of what to build]
```

## Examples
```
/wheels_spec create a blog with posts and comments
/wheels_spec add user authentication with login/logout
/wheels_spec build a product catalog with categories and search
```

## Workflow

### Step 1: Understand Existing State

Before planning anything, understand what already exists.

**Check for previous specs:**
```
Glob(pattern=".specs/*.md")
```
If `.specs/` exists and has files, read `current.md` to understand what models, controllers, views, and routes already exist. This prevents recreating things that are already built.

**Scan existing codebase:**
```
Glob(pattern="app/models/*.cfc")
Glob(pattern="app/controllers/*.cfc")
Glob(pattern="app/views/**/*.cfm")
Read("config/routes.cfm")
```

Build a mental model of what exists:
- Which models are defined and what associations do they have?
- Which controllers exist and what actions do they handle?
- Which views are in place?
- What routes are configured?

### Step 2: Parse the User Request

Extract from the natural language description:
- **Entities**: What data models are needed (User, Post, Comment, Product, etc.)
- **Relationships**: How entities relate (Post hasMany Comments, User belongsTo Role)
- **CRUD scope**: Which resources need full CRUD vs partial (Comments might only need create/delete)
- **Special features**: Authentication, file upload, email, API endpoints, search
- **Frontend preferences**: Tailwind, Bootstrap, Alpine.js, HTMX, or plain HTML

Categorize each component as:
- **NEW**: Does not exist yet, must be created
- **MODIFY**: Exists but needs changes (e.g., add an association to an existing model)
- **EXISTS**: Already in place, no changes needed

### Step 3: Generate the Specification

Create a structured specification covering all components. The spec must be concrete enough that `/wheels_build` can implement it without ambiguity.

#### 3a: Database Schema

For each NEW or MODIFIED table, specify:
- Table name
- Column names, types, constraints (allowNull, default, limit)
- Indexes (which columns, unique or not)
- Foreign keys (references, on delete behavior)
- Whether timestamps() are needed

Column type reference:
- `string` - varchar, use `limit` for max length
- `text` - long text content
- `integer` - whole numbers, use for foreign keys
- `decimal` - use `precision` and `scale` for money
- `boolean` - true/false with default
- `date` / `datetime` - date values
- `timestamps()` - creates createdAt and updatedAt

#### 3b: Models

For each model, specify:
- **Associations**: Full function signatures with all named parameters
  ```
  hasMany(name="comments", dependent="delete")
  belongsTo(name="post")
  ```
- **Validations**: Which properties, what rules
  ```
  validatesPresenceOf("title,content")
  validatesUniquenessOf(property="slug")
  validatesLengthOf(property="title", minimum=3, maximum=200)
  validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$")
  ```
- **Callbacks**: When they fire and what they do
  ```
  beforeValidationOnCreate("generateSlug")
  ```
- **Custom methods**: Name, purpose, return value

#### 3c: Controllers

For each controller, specify:
- **Actions**: Which actions (index, show, new, create, edit, update, delete, custom)
- **Filters**: Which filter functions, which actions they apply to
  ```
  filters(through="findPost", only="show,edit,update,delete")
  ```
- **Parameter verification**:
  ```
  verifies(only="show,edit,update,delete", params="key", paramsTypes="integer")
  ```
- **Flash messages**: Success/error messages for each action
- **Redirects**: Where each action redirects on success/failure

#### 3d: Views

For each view file, specify:
- **Filename**: e.g., `app/views/posts/index.cfm`
- **Purpose**: What the view displays
- **Data dependencies**: What variables it expects (set via `cfparam`)
- **Key elements**: Forms, lists, links, interactive components
- **Association access pattern**: How to access related data in loops

View checklist for forms:
- Field labels
- Validation error display for each field
- CSRF token (via `authenticityToken()` or form helpers)
- Submit and Cancel buttons

#### 3e: Routes

Specify route changes needed in `config/routes.cfm`:
- Resource routes: `.resources("posts")`
- Root route: `.root(to="posts##index", method="get")`
- Custom named routes if any
- Route ordering (resources before wildcard)

#### 3f: Sample Data (if applicable)

If the feature benefits from seed data:
- How many records
- What fields populated
- Relationships between seed records

#### 3g: Test Plan

List what needs testing:
- Model validations (presence, uniqueness, format, length)
- Model associations (create, access, dependent delete)
- Controller actions (each returns expected status)
- View rendering (pages load without errors)
- Route mapping (URLs resolve correctly)

### Step 4: Present for Approval

Format the spec as readable markdown and present it to the user. Include:

1. Summary of what will be built (NEW components) and what will be modified (MODIFY components)
2. The full specification from Step 3
3. An ordered task list showing the implementation sequence
4. Estimated scope (number of files to create/modify)

End with:
```
Please review this specification:
- Type "approve" to proceed with implementation (use /wheels_build)
- Describe any changes you want and I will revise the spec
- Ask questions about any part
```

### Step 5: Save the Spec

Once the user approves:

1. Create `.specs/` directory if it doesn't exist
2. Generate filename: `YYYYMMDD-HHMMSS-feature-description.md` (use kebab-case for feature description)
3. Write the spec file with this header:
```markdown
# Feature Specification: [Feature Name]

**Created:** [timestamp]
**Status:** approved

## User Request
"[original request verbatim]"

## Previous Specs
- [list any previous specs referenced, or "None"]

## Builds On
- [list existing components this feature depends on]

[Full specification content from Step 3]
```
4. Create/update `.specs/current.md` as a copy (not symlink) pointing to this content

After saving, tell the user:
```
Spec saved to .specs/[filename].md
Run /wheels_build to implement this specification.
```

## What This Command Does NOT Do

- Does not generate any code
- Does not run migrations
- Does not create models, controllers, or views
- Does not modify routes
- Does not run tests

This command only analyzes, plans, and documents. Use `/wheels_build` to implement and `/wheels_validate` to verify.

## Handling Revisions

If the user requests changes after seeing the spec:
1. Update the relevant sections
2. Re-present the full updated spec
3. Wait for approval again
4. Only save to `.specs/` after final approval

## Integration with Other Commands

- **Output**: A saved `.specs/*.md` file that `/wheels_build` reads as its input
- **Input to /wheels_build**: The spec provides the exact blueprint for implementation
- **Input to /wheels_validate**: The spec provides the checklist for what to verify

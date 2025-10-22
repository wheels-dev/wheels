# /new-spec - Create New Feature Specification

Create a new feature specification following a systematic, interactive workflow that ensures completeness before implementation begins.

## Purpose

Generate comprehensive specification documents (spec.md and technical-spec.md) through guided questions, validate for completeness, and prepare for task breakdown.

## Workflow

### Phase 1: Requirements Gathering

Ask the user a series of questions to understand the feature:

**Question 1: Feature Overview**
```
What feature are you building?

Please describe it in 1-2 sentences.
```

**Question 2: User Need/Problem**
```
What problem does this solve for users?

What value does it provide?
```

**Question 3: Acceptance Criteria**
```
How will you know this feature is complete and working?

List 3-5 specific criteria.
```

**Question 4: Frontend Stack** (if applicable)
```
What frontend stack should be used?

Options:
1. Tailwind CSS + Alpine.js + HTMX (recommended - modern, responsive)
2. Bootstrap + jQuery (traditional, well-supported)
3. Basic/Plain CSS (minimal dependencies)
4. Other (please specify)

Choice:
```

**Question 5: Special Requirements** (optional)
```
Are there any special requirements?

Examples:
- Authentication/authorization
- File uploads
- Email notifications
- API endpoints
- Search functionality
- Real-time updates

List any that apply:
```

### Phase 2: Context Loading

Load existing project context to understand what already exists:

```javascript
// Read CLAUDE.md to understand project state
Read("CLAUDE.md")

// Check for existing specs
Glob(pattern=".claude/specs/*/spec.md")

// If specs exist, read recent ones to avoid duplication
Read(".claude/specs/[most-recent]/spec.md")
Read(".claude/specs/[most-recent]/technical-spec.md")
```

### Phase 3: Specification Generation

Using the gathered requirements and project context, generate two comprehensive documents:

#### spec.md Structure
```markdown
# Feature Specification: [Feature Name]

**Created:** [timestamp]
**Status:** draft
**Estimated Time:** [estimate based on complexity]

## User Request
"[original user description verbatim]"

## Previous Specs
[List of related/prerequisite specs with links]

## This Spec Builds On
[List of existing components that will be used/modified]

## Problem Statement
[What problem this solves]

## User Stories
- As a [role], I want [feature], so that [benefit]
- [Additional user stories]

## Acceptance Criteria
1. [Specific, testable criterion]
2. [Another criterion]
3. [And another]

## Scope
**Included:**
- [Feature/component included]
- [Another included item]

**Excluded:**
- [Feature/component explicitly out of scope]

## Success Metrics
- [How success will be measured]

## Components to Add
- [Model name] model
- [Controller name] controller
- [View names] views
- [Other components]

## Components to Modify
[If building on existing features]
- [Component name]: [what will change]

## Dependencies
- [External dependencies if any]
- [Internal dependencies on other features]

## Risks and Mitigation
- **Risk**: [potential issue]
  **Mitigation**: [how to address]

## Future Enhancements
[Features that could be added later but are out of scope now]
```

#### technical-spec.md Structure
```markdown
# Technical Specification: [Feature Name]

**Created:** [timestamp]
**Related Spec:** [link to spec.md]

## Database Schema

### Tables

**[TableName]:**
```
Column         | Type        | Constraints
---------------|-------------|----------------------------
id             | integer     | PRIMARY KEY, AUTO_INCREMENT
[columnName]   | [type]      | [constraints]
createdAt      | datetime    | NOT NULL
updatedAt      | datetime    | NOT NULL
```

**Indexes:**
- PRIMARY KEY (id)
- INDEX idx_[column] ([column])
- UNIQUE INDEX idx_[column]_unique ([column])

**Foreign Keys:**
- FOREIGN KEY ([column]Id) REFERENCES [table](id) ON DELETE [CASCADE|SET NULL]

### Migrations Required
1. Create [table] table with columns and indexes
2. [Additional migration if needed]

## Models

### [ModelName] Model
**File:** app/models/[ModelName].cfc

**Configuration:**
- Table: [tableName]
- Primary Key: id

**Associations:**
- hasMany(name="[plural]", dependent="delete")
- belongsTo(name="[singular]")
- hasManyThrough(name="[plural]", through="[joinModel]")

**Validations:**
- validatesPresenceOf(properties="[field1],[field2]")
- validatesUniquenessOf(properties="[field]")
- validatesLengthOf(property="[field]", minimum=X, maximum=Y)
- validatesFormatOf(property="[field]", regEx="[pattern]")

**Methods:**
- [methodName]([params]) - [description]

**Callbacks:**
- before[Action]("[methodName]")
- after[Action]("[methodName]")

## Controllers

### [ControllerName] Controller
**File:** app/controllers/[ControllerName].cfc

**Actions:**
- index() - [description]
- show() - [description]
- new() - [description]
- create() - [description]
- edit() - [description]
- update() - [description]
- delete() - [description]

**Filters:**
- find[Model]() - Private filter for show/edit/update/delete actions

**Parameter Verification:**
- key must be integer for show/edit/update/delete
- [other verification]

**Flash Messages:**
- Success: "[message]"
- Error: "[message]"

## Views

### Layout
**File:** app/views/layout.cfm

**Elements:**
- HTML5 structure
- [Frontend stack] via CDN
- Navigation (links to: [list pages])
- Flash message display area
- Mobile-responsive

### [Resource] Views

#### index.cfm
**Purpose:** List/grid of all [resources]

**Elements:**
- Query loop (NOT array loop)
- recordCount check for empty state
- Link to show page for each item
- Link to new page
- [Frontend stack] styling

**Query Handling:**
```cfm
<cfif resources.recordCount>
    <cfloop query="resources">
        #linkTo(controller="[controller]", action="show", key=resources.id, text=resources.[field])#
    </cfloop>
</cfif>
```

#### show.cfm
**Purpose:** Detail view of single [resource]

**Elements:**
- Display all key properties
- Display associated records
- Edit and delete links
- Back to list link

**Association Handling:**
```cfm
<cfset assocRecords = model("[Model]").findByKey([resource].id).association()>
<cfif assocRecords.recordCount>
    <cfloop query="assocRecords">
        [display]
    </cfloop>
</cfif>
```

#### new.cfm
**Purpose:** Form to create new [resource]

**Form Elements:**
- startFormTag (includes CSRF automatically)
- Text fields with labels
- Validation error displays
- Submit and cancel buttons

**Validation Error Pattern:**
```cfm
#textField(objectName="[resource]", property="[field]", label=false)#
<cfif [resource].hasErrors("[field]")>
    <p class="error">##[resource].allErrors("[field]")[1]#</p>
</cfif>
```

#### edit.cfm
**Purpose:** Form to update existing [resource]

**Form Elements:**
- Same as new.cfm but with pre-populated values
- Uses structKeyExists() for safe property access

## Routes

**Root:**
```cfm
root(to="[controller]##[action]", method="get");
```

**Resources:**
```cfm
resources("[resourceName]");
```

**Custom Routes** (if needed):
```cfm
get("[path]").to("[controller]##[action]", name="[routeName]");
```

## Frontend Stack

**Libraries:**
- [Library name] [version] - [purpose]

**Key Features:**
- [Interactive element] using [library]
- [Responsive behavior] using [CSS framework]

**CDN Links:**
```html
<link href="[CDN URL]" rel="stylesheet">
<script src="[CDN URL]"></script>
```

## Security Considerations

- **CSRF Protection**: Automatic via startFormTag()
- **SQL Injection**: Prevented by Wheels ORM
- **Input Validation**: Model validations + controller parameter verification
- **Authentication**: [if applicable, describe strategy]
- **Authorization**: [if applicable, describe strategy]
- **XSS Prevention**: Automatic HTML escaping in views

## Testing Strategy

### TestBox BDD Model Specs
**File:** tests/specs/models/[ModelName].cfc

**Test Coverage:**
- All validations (presence, uniqueness, length, format)
- All associations (hasMany, belongsTo, dependent delete)
- All custom methods
- All callbacks

### TestBox BDD Controller Specs
**File:** tests/specs/controllers/[ControllerName].cfc

**Test Coverage:**
- All actions (index, show, new, create, edit, update, delete)
- Filter behavior (findResource)
- Parameter verification
- Flash messages
- Redirects

### TestBox BDD Integration Specs
**File:** tests/specs/integration/[FeatureName]Workflow.cfc

**Test Coverage:**
- Complete CRUD workflow
- Form validation scenarios
- Error handling
- Edge cases

### Browser Testing
- Homepage/index page loads
- Show page displays correct data
- New form renders and submits
- Edit form pre-populates and updates
- Delete action works
- Responsive design works (mobile, tablet, desktop)

## Sample Data

[If seed data needed]
```cfm
// Migration seed data
execute("INSERT INTO [table] ([columns]) VALUES ([values])");
```

## Performance Considerations

- **Indexes**: [columns that need indexes for performance]
- **N+1 Queries**: Use `include` parameter in findAll/findByKey
- **Pagination**: [if applicable]

## API Documentation (if applicable)

**Endpoints:**
- GET /api/[resource] - [description]
- GET /api/[resource]/:id - [description]
- POST /api/[resource] - [description]

**Response Format:**
```json
{
  "success": true,
  "data": {},
  "message": ""
}
```

## Error Scenarios

**Scenario**: [description]
**Handling**: [how it's handled]
**User Message**: [what user sees]
```

### Phase 4: Validation

Invoke the spec-validator sub-agent to validate completeness:

```javascript
Task(
  subagent_type="Explore",
  description="Validate specification completeness",
  prompt="Use the spec-validator agent to validate the generated spec.md and technical-spec.md.

  Check for:
  - All 8 completeness categories
  - Consistency with CFWheels conventions
  - Anti-pattern prevention
  - CRITICAL: View coverage for all CRUD actions

  Load the spec-validator agent from .claude/agents/spec-validator.md and follow its validation checklist."
)
```

### Phase 5: Present for Review

Display the generated specifications and validation results:

```markdown
## 📋 Feature Specification Generated

I've created a comprehensive specification for: **[Feature Name]**

### Specification Files

**spec.md** - Feature Overview
- Problem statement
- User stories
- Acceptance criteria
- Components (models, controllers, views)
- Scope and dependencies

**technical-spec.md** - Technical Details
- Database schema with tables, indexes, foreign keys
- Model structure (validations, associations, methods)
- Controller actions and filters
- View structure with proper query handling
- Routes configuration
- Testing strategy
- Security considerations

### Validation Results

[Output from spec-validator]

---

### Next Steps

**Please review the specifications and respond:**

1. **"approve"** - Proceed to break down into tasks
2. **"change: [description]"** - Request modifications
3. **Ask questions** - Clarify any aspect of the spec

Once approved, I'll create the specification directory and prepare for task breakdown.
```

### Phase 6: Handle Response

**If user approves:**
1. Create timestamped directory: `.claude/specs/YYYYMMDD-HHMMSS-[feature-name]/`
2. Write spec.md to directory
3. Write technical-spec.md to directory
4. Update spec.md status to "approved"
5. Update CLAUDE.md active specifications section
6. Prompt: "Ready to break down into tasks? Run `/break-down-spec [feature-name]`"

**If user requests changes:**
1. Parse requested changes
2. Update specifications accordingly
3. Re-validate
4. Present updated version for review
5. Repeat until approved

**If user asks questions:**
1. Answer based on specification content
2. Clarify any ambiguities
3. Offer to update spec if needed

## Special Considerations

### Building on Existing Features

When user requests a feature that extends existing functionality:

1. **Load previous specs** to understand current state
2. **Identify what exists** vs. what's new
3. **Reference previous specs** in "This Spec Builds On" section
4. **List modifications** separately from new components
5. **Update CLAUDE.md** to show relationship between specs

### Feature Complexity Assessment

**Simple** (1-2 hours):
- Single model, basic CRUD
- No associations
- 3-4 views
- Standard validations

**Medium** (3-6 hours):
- 2-3 models with associations
- CRUD + custom actions
- 6-10 views
- Complex validations

**Large** (1+ days):
- Multiple models with complex associations
- Authentication/authorization
- API + web interface
- 10+ views
- Custom business logic

### Anti-Pattern Prevention in Specs

Ensure specifications explicitly address common issues:

✅ **Validations**: "Use plural properties parameter"
✅ **Associations**: "Use consistent argument style (all named)"
✅ **Views**: "Use query loops with recordCount, not array loops"
✅ **Forms**: "Include validation error displays for all fields"
✅ **Migrations**: "Use CFML date functions, not database-specific SQL"

## Example Invocation

```
User: /new-spec

Claude: What feature are you building? Please describe it in 1-2 sentences.

User: I want to add a blog to my site with posts and comments. Users should be able to create posts, and visitors can add comments.

Claude: What problem does this solve for users? What value does it provide?

User: It lets me share content with my audience and engage with them through comments.

Claude: How will you know this feature is complete and working? List 3-5 specific criteria.

User:
1. I can create, edit, and delete blog posts
2. Visitors can add comments to posts
3. Posts display with their comments
4. Everything works on mobile and desktop

Claude: What frontend stack should be used?
1. Tailwind CSS + Alpine.js + HTMX
2. Bootstrap + jQuery
3. Basic/Plain CSS
4. Other

User: 1

Claude: Are there any special requirements? (authentication, uploads, email, API, search, etc.)

User: No, keep it simple for now.

Claude: [Generates comprehensive spec.md and technical-spec.md]
Claude: [Validates using spec-validator]
Claude: [Presents for review]
```

## Success Criteria

A specification is ready for breakdown when:

✅ All 8 completeness categories addressed
✅ spec-validator returns "APPROVED FOR IMPLEMENTATION"
✅ User has approved the specification
✅ No critical issues or ambiguities remain
✅ Views are planned for all CRUD actions
✅ Testing strategy is comprehensive
✅ Anti-patterns are prevented in the design

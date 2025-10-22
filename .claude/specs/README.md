# Spec-Driven Development Workflow

This directory contains feature specifications for systematic, context-persistent development.

## Directory Structure

Each specification gets its own directory:

```
.claude/specs/
├── YYYYMMDD-HHMMSS-feature-name/
│   ├── spec.md              # Feature overview, user stories, acceptance criteria
│   ├── technical-spec.md    # Architecture, database schema, technical details
│   └── tasks.md             # Task breakdown with progress tracking
└── README.md                # This file
```

## Specification Lifecycle

### 1. Creation (`/new-spec`)
- Interactive requirements gathering
- Generates spec.md and technical-spec.md
- Validates with spec-validator agent
- User reviews and approves
- Status: `draft` → `approved`

### 2. Breakdown (`/break-down-spec [spec-name]`)
- Invokes task-analyzer agent
- Creates granular task breakdown (3-5 parent, 3-8 subtasks each)
- Generates tasks.md with YAML frontmatter
- Creates feature branch
- Status: `approved` → `ready`

### 3. Implementation (`/implement-task X.Y`)
- Loads task context
- Invokes appropriate skill
- Uses MCP tools for generation
- Tests immediately
- Marks complete only if tests pass
- Status: `ready` → `in-progress`

### 4. Completion (`/complete-spec [spec-name]`)
- Verifies all tasks complete
- Runs comprehensive testing
- Generates results report
- Calculates metrics
- Updates documentation
- Status: `in-progress` → `completed`

## Specification Format

### spec.md
Human-readable feature overview:
- User request (verbatim)
- Problem statement
- User stories
- Acceptance criteria
- Components to add/modify
- Dependencies and risks
- Success metrics

### technical-spec.md
Technical implementation details:
- Database schema (tables, indexes, foreign keys)
- Model structure (validations, associations, methods)
- Controller actions and filters
- View structure with proper patterns
- Routes configuration
- Frontend stack
- Security considerations
- Testing strategy

### tasks.md
Task tracking with YAML metadata:
```yaml
---
spec: feature-name
created: timestamp
status: ready|in-progress|completed
branch: feature/feature-name
session_id: feature-name-impl
last_updated: timestamp
---
```

Task hierarchy:
- Progress summary
- Parent tasks with status emoji (⏸️ ✅ 🔄 ⚠️)
- Subtasks with checkboxes ([ ] [x])
- Session notes
- Technical context

## Context Persistence

The system maintains context through **5 redundant layers**:

1. **Named Sessions**: `claude --session-id [feature-name]`
2. **CLAUDE.md**: Active specs, recent decisions
3. **tasks.md**: Task progress, session notes, completion timestamps
4. **Git History**: Structured commits with task references
5. **Hook Scripts**: Automatic session logging

Even if one layer is lost, others provide enough context to continue.

## Recovery

If you lose session context:

```bash
/restore-context
```

This rebuilds complete understanding from:
- CLAUDE.md (project state)
- tasks.md (task progress)
- Git history (what was implemented)
- File system (what exists)

## Example Workflow

```bash
# 1. Create specification
/new-spec
# Answer questions, review, approve

# 2. Break down into tasks
/break-down-spec blog-posts-comments
# Review task structure

# 3. Implement incrementally
/implement-task 1.1
/implement-task 1.2
# ... continue

# 4. Complete feature
/complete-spec blog-posts-comments
# Get comprehensive report
```

## Commands Reference

- `/new-spec` - Create new feature specification
- `/break-down-spec [name]` - Generate task breakdown
- `/implement-task X.Y` - Implement specific task
- `/restore-context` - Restore session context
- `/complete-spec [name]` - Finalize and report

## Agents

- **task-analyzer** - Creates optimal task breakdowns
- **test-runner** - Executes and analyzes tests
- **spec-validator** - Validates specification completeness

## Hooks

- **display-status.sh** - Shows status on session start
- **update-session-log.sh** - Logs session summary on exit

## Benefits

✅ **Never lose context** - Multi-layer persistence
✅ **Systematic development** - Clear task structure
✅ **Quality assurance** - Test-driven, validated
✅ **Audit trail** - Complete history
✅ **Team collaboration** - Shareable specifications
✅ **Learning** - Metrics improve estimates

## Notes

- Specifications are **version controlled** (commit to git)
- Each spec is **timestamped** for chronological ordering
- Specs can **reference previous specs** (incremental development)
- All tasks **test immediately** (no deferred testing)
- System works with **MCP tools** (required for this project)

For full documentation, see [CLAUDE.md](../CLAUDE.md).

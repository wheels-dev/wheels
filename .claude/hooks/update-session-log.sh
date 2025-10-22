#!/bin/bash
# Update CLAUDE.md with session summary when session ends

TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
CLAUDE_MD="CLAUDE.md"

# Find current task from active specs
CURRENT_TASK=$(find .claude/specs -name "tasks.md" -exec grep -l "status: in-progress" {} \; 2>/dev/null | head -n 1)

if [ -n "$CURRENT_TASK" ]; then
    # Extract task info
    SPEC_DIR=$(dirname "$CURRENT_TASK")
    SPEC_NAME=$(basename "$SPEC_DIR" | sed 's/^[0-9]*-//')

    # Get currently in-progress task
    IN_PROGRESS_TASK=$(grep "🔄" "$CURRENT_TASK" | head -n 1 | sed 's/^[[:space:]]*-[[:space:]]*\[🔄\][[:space:]]*//')

    # Get modified files
    MODIFIED_FILES=$(git status --short 2>/dev/null | head -n 5 | tr '\n' ', ' | sed 's/,$//')

    # Append to CLAUDE.md
    echo "" >> "$CLAUDE_MD"
    echo "### Session $TIMESTAMP" >> "$CLAUDE_MD"
    echo "**Spec**: $SPEC_NAME" >> "$CLAUDE_MD"
    if [ -n "$IN_PROGRESS_TASK" ]; then
        echo "**Current task**: $IN_PROGRESS_TASK" >> "$CLAUDE_MD"
    fi
    if [ -n "$MODIFIED_FILES" ]; then
        echo "**Modified**: $MODIFIED_FILES" >> "$CLAUDE_MD"
    fi
else
    # No active spec, just log that session ended
    echo "" >> "$CLAUDE_MD"
    echo "### Session $TIMESTAMP" >> "$CLAUDE_MD"
    echo "**Status**: No active specification" >> "$CLAUDE_MD"
fi

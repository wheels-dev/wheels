#!/bin/bash
# Display development status when session starts

echo "=== 📋 Development Status ==="
echo ""

# Find active specs
ACTIVE_SPECS=$(find .claude/specs -name "tasks.md" -exec grep -l "status: in-progress\|status: ready" {} \; 2>/dev/null)

if [ -z "$ACTIVE_SPECS" ]; then
    echo "✅ No active specifications"
    echo ""
    echo "Ready to start a new feature!"
    echo "Run: /new-spec"
else
    for TASK_FILE in $ACTIVE_SPECS; do
        SPEC_DIR=$(dirname "$TASK_FILE")
        SPEC_NAME=$(basename "$SPEC_DIR" | sed 's/^[0-9]*-//')

        # Get status
        STATUS=$(grep "^status:" "$TASK_FILE" | awk '{print $2}')

        # Count completed vs total tasks
        TOTAL=$(grep -c "^- \[" "$TASK_FILE" 2>/dev/null || echo "0")
        COMPLETED=$(grep -c "^- \[x\]" "$TASK_FILE" 2>/dev/null || echo "0")

        # Get current task
        CURRENT=$(grep "🔄" "$TASK_FILE" | head -n 1 | sed 's/^[[:space:]]*-[[:space:]]*\[🔄\][[:space:]]*//')

        echo "📌 Spec: $SPEC_NAME"
        echo "   Status: $STATUS"
        echo "   Progress: $COMPLETED/$TOTAL tasks"
        if [ -n "$CURRENT" ]; then
            echo "   Current: $CURRENT"
        fi
        echo ""
    done

    echo "Commands:"
    echo "  /restore-context  - Restore full context"
    echo "  /implement-task X.Y - Continue specific task"
fi

echo "=================================================="

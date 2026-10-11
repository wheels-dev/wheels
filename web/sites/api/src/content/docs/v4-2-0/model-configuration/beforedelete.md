---
title: beforeDelete()
description: "Registers method(s) that should be called before an object is deleted."
sidebar:
  label: beforeDelete()
  order: 0
---

## Signature

`beforeDelete()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an object is deleted.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single method to run before an object is deleted
// In models/Post.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeDelete(&quot;cleanUpAttachments&quot;);
    }

    private function cleanUpAttachments() {
        // Remove associated files from disk before the record is deleted
        fileDelete(expandPath(&quot;/uploads/#this.id#&quot;));
    }
}

// 2. Register multiple methods to run before deletion (comma-delimited list)
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeDelete(&quot;revokeTokens,archiveActivity&quot;);
    }

    private function revokeTokens() {
        model(&quot;Token&quot;).deleteAll(where=&quot;userId=#this.id#&quot;);
    }

    private function archiveActivity() {
        model(&quot;ActivityLog&quot;).updateAll(
            properties=&quot;archivedAt=NOW()&quot;,
            where=&quot;userId=#this.id#&quot;
        );
    }
}

// 3. Halt deletion by returning false from the callback
// In models/Order.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeDelete(&quot;preventIfShipped&quot;);
    }

    private function preventIfShipped() {
        // Returning false cancels the delete operation
        if (this.status eq &quot;shipped&quot;) {
            return false;
        }
    }
}
</code></pre>

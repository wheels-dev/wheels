# Blog Drafts

Unpublished blog posts wait here until they're ready to ship. CI does not pick up files in this folder — `web/content/blog/posts/` is the live source. Move a draft into `web/content/blog/posts/` to publish it (CI will deploy on the next push to develop).

Each draft carries a `publishedAt` date in its frontmatter that's the intended publication day. The deploy is still gated by a human moving the file; the date is what shows on the published article.

## Current queue

Scheduled for every-other-day cadence after the rate-limited API post (published 2026-05-15):

| Draft | Slot |
|---|---|
| `anatomy-of-a-wheels-package.md` | 2026-05-17 |
| `wheels-claude-stdio-mcp.md` | 2026-05-19 |
| `beyond-findall-scopes-enums-query-builder.md` | 2026-05-21 |

The companion social-post skeletons live in `../blog-skeletons/`. When you promote a draft, copy the social skeleton too.

## Publishing checklist

1. Review the draft for any references that need a final pass (cross-links to other posts in the series, date math in teaser lines).
2. `git mv docs/releases/blog-drafts/<post>.md web/content/blog/posts/<post>.md`
3. Commit on a feature branch, open a PR.
4. After the PR merges, the deploy workflow picks up the new file and ships to https://blog.wheels.dev.
5. Post the companion social skeleton(s) on the channels in their checklist.

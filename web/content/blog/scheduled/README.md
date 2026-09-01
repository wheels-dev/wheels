# Scheduled blog posts

Posts in this directory are **not** rendered by the blog site — the Astro
content loader only globs `web/content/blog/posts/`. They are the staging
area for scheduled publishing.

## How publishing works

The [Blog — Publish Scheduled Posts](../../.github/workflows/blog-publish-scheduled.yml)
workflow runs every morning at 06:00 UTC (and on `workflow_dispatch`). It
moves every post here whose `publishedAt` date is **today or earlier** (UTC)
into `web/content/blog/posts/`, commits as `wheels-bot[bot]`, and pushes.
That push triggers the existing blog deploy, which builds and publishes the
site.

Catch-up semantics are deliberate: if a run fails or is skipped, posts due
in the past publish on the next successful run instead of being stranded.

## Writing a scheduled post

- Same markdown + frontmatter as `web/content/blog/posts/` (see
  `web/sites/blog/src/content.config.ts` for the schema).
- Set `publishedAt` to the intended publication date, in UTC. The date
  *part* of the timestamp is what the publisher compares against today.
- Keep the `slug` unique across both directories.
- Do not edit `publishedAt` after a post has moved to `posts/` without good
  reason — the site sorts by it.

## Cover images

Covers for a series live under `web/sites/blog/public/blog-images/<series>/`
in both `.svg` (the editable source) and `.png` (rasterized at 1200x630, which
is what social/OG scrapers accept — SVG is not supported in `og:image`). Set
`coverImage` to the `.png` path. To regenerate the PNGs from a new SVG, render
with a headless browser at `--window-size=1200,630`, or `rsvg-convert`.

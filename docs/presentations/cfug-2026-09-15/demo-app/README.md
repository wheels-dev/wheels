# Demo app reference

The **target end-state** of the live build in [`../demo.md`](../demo.md) — the
files you *write by hand* during the talk. Everything else (controllers,
views, migrations, tests) is produced deterministically by `wheels generate`,
so this directory only captures what you actually type.

Use it to diff your rehearsal build against the finished shape:

```bash
diff app/models/Post.cfc docs/presentations/cfug-2026-09-15/demo-app/Post.cfc
```

`seeds.cfm` is optional — it pre-populates a couple of posts if you'd rather
start the demo with content on screen (`wheels seed`) instead of creating the
first post live.

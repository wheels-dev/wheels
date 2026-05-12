# Patch: Make existing `auto-update.yml` channel-aware

The existing `wheels-dev/homebrew-wheels/.github/workflows/auto-update.yml`
currently bumps `Formula/wheels.rb` on **every** `wheels-released` dispatch —
including snapshot releases. That contaminates the stable channel: anyone who
runs `brew install wheels` today actually lands on a snapshot, not the latest
GA tag.

The post-PR-2545 source repo now sends a `channel` field in the dispatch
payload (`stable` / `bleeding-edge` / `release-candidate`). We need the
existing workflow to **skip non-stable channels** so they get handled by the
parallel `bleeding-edge-update.yml` workflow instead.

## The patch

Add this block as the **first step** of the `check-updates` job, immediately
after `actions/checkout`:

```yaml
      # Skip non-stable channels — they're handled by bleeding-edge-update.yml.
      # The dispatch payload's `channel` field comes from the source repo
      # (wheels-dev/wheels release.yml). Empty/missing channel = legacy
      # dispatch from before the channel field was added; fall back to
      # version-string sniffing for backwards compatibility.
      - name: Channel filter (stable only)
        id: channel-filter
        env:
          DISPATCH_CHANNEL: ${{ github.event.client_payload.channel }}
          DISPATCH_VERSION: ${{ github.event.client_payload.version }}
        run: |
          # Manual triggers and cron always proceed (no dispatch payload).
          if [ "${{ github.event_name }}" != "repository_dispatch" ]; then
            echo "Non-dispatch trigger; proceeding with stable update."
            exit 0
          fi
          CHANNEL="${DISPATCH_CHANNEL:-}"
          # Backwards compat: if channel field is empty, sniff the version string.
          if [ -z "${CHANNEL}" ] && [ -n "${DISPATCH_VERSION:-}" ]; then
            if echo "${DISPATCH_VERSION}" | grep -qiE '\-snapshot[\.\+]'; then
              CHANNEL="bleeding-edge"
            elif echo "${DISPATCH_VERSION}" | grep -qE '\-rc\.'; then
              CHANNEL="release-candidate"
            else
              CHANNEL="stable"
            fi
          fi
          echo "Channel: ${CHANNEL:-stable (default)}"
          if [ "${CHANNEL}" = "bleeding-edge" ] || [ "${CHANNEL}" = "release-candidate" ]; then
            echo "Skipping — non-stable channels are handled by bleeding-edge-update.yml"
            exit 0
          fi
```

Replace this hard exit with `gh-action`'s `step-skip` mechanism if you want
to preserve subsequent steps' visibility in the run log. Right now the simple
`exit 0` means the job ends successfully and no formula bump happens —
exactly what we want for non-stable dispatches.

## Why not refactor into one channel-aware workflow

Could be done — and probably should be done as a follow-up cleanup. But for
the Tuesday GA window, a two-file split is lower-risk:
- Existing `auto-update.yml` keeps working exactly as before (just with a new
  early-exit gate for non-stable channels)
- New `bleeding-edge-update.yml` handles BE in isolation
- If something goes wrong with the BE flow, stable is unaffected

After Tuesday, refactor into one workflow with channel-aware variables
throughout (FORMULA_PATH, SOURCE_REPO).

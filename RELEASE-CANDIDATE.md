# Release Candidate Guide

This guide explains how to create and manage Release Candidates (RC) for Wheels before publishing final releases.

## What is a Release Candidate?

A Release Candidate is a beta version of software that has the potential to be a final release, unless significant bugs or issues are found. RCs allow the community to test the software before the final release.

## When to Create an RC

Create a Release Candidate when:
- Major version changes (e.g., 3.0.0)
- Significant new features or breaking changes
- You want community testing before final release
- Following a long development cycle

## RC Version Naming Convention

Release Candidates follow semantic versioning with an `-rc.X` suffix:
- `3.0.0-rc.1` - First release candidate
- `3.0.0-rc.2` - Second release candidate (if issues found in rc.1)
- `3.0.0-rc.3` - Third release candidate (if issues found in rc.2)
- `3.0.0` - Final release (after RCs are validated)

## Creating a Release Candidate

### Step 1: Create RC Branch

```bash
# Start from main or develop branch (wherever your release-ready code is)
git checkout main
git pull origin main

# Create RC branch with naming convention: release/VERSION-rc.X
git checkout -b release/3.0.0-rc.1
```

### Step 2: Update Version Numbers

Update version in all box.json files to include `-rc.1` suffix:

**Files to update:**
- `templates/base/src/box.json` → `"version": "3.0.0-rc.1"`
- `examples/starter-app/box.json` → `"version": "3.0.0-rc.1"`
- `core/box.json` → `"version": "3.0.0-rc.1"`

**Update dependencies:**
```json
"dependencies": {
    "wheels-core": "^3.0.0-rc.1"
}
```

### Step 3: Update CHANGELOG.md

Add RC section at the top of CHANGELOG.md:

```markdown
# [3.0.0-rc.1](https://github.com/wheels-dev/wheels/releases/tag/v3.0.0-rc.1) => 2025-10-07

**Release Candidate 1 for Wheels 3.0.0**

This is a pre-release version for community testing. Please report any issues to GitHub.

### What's New in 3.0.0
- [List major features and changes from 3.0.0 development]

### Known Issues
- [List any known issues that need testing]

### Testing Focus Areas
- [Specific areas you want testers to focus on]

---

# [3.0.0](https://github.com/wheels-dev/wheels/releases/tag/v3.0.0) => TBD
...
```

### Step 4: Commit and Push

```bash
git add .
git commit -m "Release Candidate 3.0.0-rc.1"
git push -u origin release/3.0.0-rc.1
```

### Step 5: Automated Build

Once pushed, GitHub Actions will automatically:
1. Validate RC version format
2. Build all packages
3. Publish to ForgeBox as prerelease
4. Create GitHub Prerelease with artifacts
5. Tag as `v3.0.0-rc.1`

## Testing the Release Candidate

### Installation

Users can install the RC from ForgeBox:

```bash
box install wheels@3.0.0-rc.1
box install wheels-core@3.0.0-rc.1
```

### Testing Checklist

Create a GitHub issue for RC testing with this checklist:

- [ ] Fresh installation on multiple CFML engines (Lucee 5, Lucee 6, ACF 2021, ACF 2023)
- [ ] Upgrade from 2.x to 3.0.0-rc.1
- [ ] Run full test suite
- [ ] Test major new features
- [ ] Test breaking changes don't break existing apps
- [ ] Verify documentation is accurate
- [ ] Check performance regressions
- [ ] Test plugins compatibility
- [ ] Verify CLI commands work
- [ ] Test database migrations
- [ ] Check for security vulnerabilities

## Handling Issues Found in RC

### Minor Issues (Documentation, Small Bugs)
1. Fix on the RC branch
2. Update RC number to `-rc.2`
3. Update CHANGELOG with fixes
4. Push to trigger new RC build

```bash
# On release/3.0.0-rc.1 branch
git add .
git commit -m "Fix: [issue description]"

# Update version to rc.2 in box.json files
# Update CHANGELOG.md

git commit -am "Release Candidate 3.0.0-rc.2"
git push
```

### Major Issues (Breaking Bugs)
1. Fix the issues
2. May need to create new RC or postpone release
3. Consider if issue requires version bump (3.0.1 instead of 3.0.0)

## Promoting RC to Final Release

Once RC has been thoroughly tested with no critical issues:

### Step 1: Update Versions to Final

On the RC branch:
```bash
# Remove -rc.X suffix from all box.json files
# Update to: "version": "3.0.0"
```

### Step 2: Update CHANGELOG

```markdown
# [3.0.0](https://github.com/wheels-dev/wheels/releases/tag/v3.0.0) => 2025-10-15

[Copy content from RC CHANGELOG, remove RC-specific notes]
```

### Step 3: Merge to Main

```bash
# Ensure all changes are committed
git add .
git commit -m "Prepare 3.0.0 final release"

# Merge to main
git checkout main
git merge release/3.0.0-rc.1
git push origin main
```

### Step 4: Automated Final Release

Pushing to main will automatically:
1. Build final release
2. Publish to ForgeBox (not as prerelease)
3. Create GitHub Release (not as prerelease)
4. Tag as `v3.0.0`

### Step 5: Post-Release

```bash
# Bump version for next development cycle
# Use the version-bump workflow:
# Go to GitHub Actions → Version Bump → Run workflow
# Input: 3.0.1-SNAPSHOT or 3.1.0-SNAPSHOT

# Or manually:
# Update box.json files to next SNAPSHOT version
# Add new section to CHANGELOG.md
```

## RC Communication

### Announcing the RC

Post announcement in:
- GitHub Discussions
- Wheels community forums
- Social media (Twitter, etc.)
- Mailing lists

Example announcement:
```
🎉 Wheels 3.0.0-rc.1 is now available for testing!

We need your help testing this major release before final publication.

Install: box install wheels@3.0.0-rc.1

Please report issues: https://github.com/wheels-dev/wheels/issues

Testing focus areas:
- [List key areas]

Thank you for helping make Wheels better!
```

### RC Timeline

Typical RC timeline:
- RC.1 released → 1-2 weeks of testing
- If issues found → RC.2 released → 1 week of testing
- If no major issues → Final release

## Best Practices

1. **Don't skip RCs for major releases** - Always do at least one RC for X.0.0 releases
2. **Give enough time for testing** - At least 1-2 weeks per RC
3. **Be transparent about known issues** - Document them in CHANGELOG
4. **Respond quickly to bug reports** - Triage within 24-48 hours
5. **Keep RCs separate from snapshots** - RCs are candidates for release, snapshots are ongoing development
6. **Test RCs yourself first** - Don't release broken RCs to community
7. **Communicate clearly** - Mark as "Release Candidate", not "Beta" or "Preview"

## Troubleshooting

### RC Build Failed
- Check GitHub Actions logs
- Verify version format includes `-rc.X`
- Ensure CHANGELOG has RC entry
- Check all box.json files updated

### ForgeBox Won't Accept RC
- Ensure version follows semver with prerelease identifier
- Check ForgeBox credentials in GitHub Secrets
- Verify package validation passed

### Users Can't Find RC
- RCs are marked as "prerelease" on ForgeBox and GitHub
- Users must explicitly request prerelease versions
- Provide clear installation instructions

## Questions?

If you have questions about the RC process:
- Open a GitHub Discussion
- Check GitHub Actions workflow logs
- Review previous RC releases for examples

---

🤖 This guide was created to ensure smooth Release Candidate workflows for Wheels.

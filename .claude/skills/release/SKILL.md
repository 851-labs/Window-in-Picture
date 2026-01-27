---
name: release
description: Release Window-in-Picture macOS app. Bumps version, updates changelog, creates git tag, monitors CI, verifies release assets, and updates Homebrew tap. Use when releasing a new version.
---

# Window-in-Picture Release Process

Follow these steps to ship a new macOS release for Window-in-Picture.

## Pre-flight Checks

Before starting:
1. Verify you're on the `main` branch
2. Ensure working tree is clean (no uncommitted changes)
3. Pull latest changes: `git pull origin main`

```bash
git status
git branch --show-current
```

## Step 1: Bump Version

Update versions in `Window-in-Picture.xcodeproj/project.pbxproj`:

- `MARKETING_VERSION` - Set to the new version (e.g., `1.0.24`)
- `CURRENT_PROJECT_VERSION` - Increment the integer by 1

Use the Edit tool to update both occurrences of each version field.

Commit the version bump:
```bash
git add Window-in-Picture.xcodeproj/project.pbxproj
git commit -m "chore: bump version to X.Y.Z"
```

## Step 2: Update Changelog

Check commits since the last tag:
```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Add release notes to `CHANGELOG.md` under a new version heading. Only include meaningful changes (features, fixes, docs). Skip version-bump-only entries.

Commit the changelog:
```bash
git add CHANGELOG.md
git commit -m "docs: update changelog for X.Y.Z"
```

## Step 3: Create and Push Tag

Create a git tag and push it to trigger the Release workflow:

```bash
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

## Step 4: Monitor CI

Watch the Release workflow:

```bash
gh run list --workflow Release --limit 1
gh run watch
```

If the workflow fails, inspect logs:
```bash
gh run view --log-failed
```

## Step 5: Verify Release Assets

Confirm the release has the required assets:

```bash
gh release view vX.Y.Z --json url,assets
```

Required assets:
- `Window-in-Picture.dmg`
- `appcast.xml`

## Step 6: Update Homebrew Tap

1. Download the DMG and compute SHA256:
   ```bash
   gh release download vX.Y.Z --pattern "*.dmg" --dir /tmp
   shasum -a 256 /tmp/Window-in-Picture.dmg
   ```

2. Update `851-labs/homebrew-tap` repository:
   - Edit `Casks/window-in-picture.rb`
   - Set `version "X.Y.Z"`
   - Set `sha256 "<computed-hash>"`

3. Commit and push the tap update

4. Validate the install:
   ```bash
   brew update
   brew upgrade --cask 851-labs/tap/window-in-picture
   ```

## Troubleshooting

### Notarization Delays

Notarization can take 10-45 minutes depending on Apple queue load. The CI logs show submission IDs.

Query notarization status (requires API credentials):
```bash
xcrun notarytool info <submission-id> \
  --key <AuthKey.p8> \
  --key-id <KEY_ID> \
  --issuer <ISSUER_ID> \
  --output-format json
```

### Sparkle Feed

The appcast URL for automatic updates:
```
https://github.com/851-labs/Window-in-Picture/releases/latest/download/appcast.xml
```

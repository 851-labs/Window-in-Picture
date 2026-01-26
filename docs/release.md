# Release Process

This document outlines how to ship a new macOS release for Window-in-Picture, including Sparkle updates and Homebrew distribution.

## Prerequisites

- Developer ID Application certificate installed (Keychain Access)
- App Store Connect API key created (Key ID, Issuer ID, `.p8`)
- Sparkle private key available (from Keychain or `generate_keys`)
- Homebrew tap repo: `851-labs/homebrew-tap`

## Local Environment Variables

Create `.env` from `.env.example`:

```
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
APP_STORE_CONNECT_KEY_ID="YOUR_KEY_ID"
APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
APP_STORE_CONNECT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
SPARKLE_PRIVATE_KEY="BASE64_KEY_FROM_SPARKLE_KEYCHAIN_ITEM_WITH_PADDING"
```

appdrop automatically loads `.env` from the repo root.

## Release Steps

### 1) Confirm Xcode + SDK

- Ensure your machine is running macOS 26 and Xcode 17+.
- Install `appdrop`: `brew install 851-labs/tap/appdrop`.
- CI currently uses `runs-on: macos-26`. `appdrop setup-ci` installs Sparkle tools when `SPARKLE_PRIVATE_KEY` is set.

### 2) Bump Version

Update versions in `Window-in-Picture.xcodeproj/project.pbxproj`:

- `MARKETING_VERSION` (e.g., `1.0.0`)
- `CURRENT_PROJECT_VERSION` (increment integer)

Commit the version bump.

### 3) Update Changelog

Add the release notes to `CHANGELOG.md` under a new version heading.
Only include meaningful changes (features, fixes, docs). Do not add version-bump-only entries.

To see commits since the previous tag:

```
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

```
git add CHANGELOG.md
git commit -m "docs: update changelog for x.y.z"
```

### 4) Create Tag

```
git tag v1.0.0
git push origin v1.0.0
```

This triggers the Release workflow.

### 5) Verify CI

Use GitHub CLI to confirm CI completion:

```
gh run list --workflow Release --limit 5
gh run watch <RUN_ID>
```

If it fails, inspect logs:

```
gh run view <RUN_ID> --log
```

### 6) Verify Release Assets

```
gh release view v1.0.0 --json url,assets
```

Ensure the release has:
- `window-in-picture.dmg`
- `appcast.xml`

### 7) Update Homebrew Tap

Update `851-labs/homebrew-tap` with the new version and SHA256:

```
cd ~/repos/851-labs/homebrew-tap
shasum -a 256 /path/to/window-in-picture.dmg
```

Edit `Casks/window-in-picture.rb`:

```
version "1.0.0"
sha256 "<sha256>"
```

Commit and push:

```
git add Casks/window-in-picture.rb
git commit -m "bump window-in-picture to 1.0.0"
git push
```

### 8) Validate Install

```
brew update
brew upgrade --cask 851-labs/tap/window-in-picture
```

## Troubleshooting

### Notarization delays

Notarization can take 10-45 minutes depending on Apple queue load. appdrop prints submission IDs, and you can query them:

```
xcrun notarytool info <submission-id> \
  --key <AuthKey.p8> \
  --key-id <KEY_ID> \
  --issuer <ISSUER_ID> \
  --output-format json
```

Fetch the detailed log:

```
xcrun notarytool log <submission-id> \
  --key <AuthKey.p8> \
  --key-id <KEY_ID> \
  --issuer <ISSUER_ID>
```

For faster local iteration, you can skip notarization:

```
appdrop release --no-notarize
```

## Sparkle Feed

The appcast URL is:

```
https://github.com/851-labs/Window-in-Picture/releases/latest/download/appcast.xml
```

Sparkle uses this feed to deliver updates.

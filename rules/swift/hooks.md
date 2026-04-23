# Swift + ARG Hooks

Swift-specific ARG hook considerations.

## Xcode and Build Commands

Swift/iOS commands that may trigger ARG:
- `xcodebuild archive` with distribution certificates: triggers code signing and provisioning
- `xcrun altool --upload-app` or `xcrun notarytool`: uploads to App Store Connect
- Fastlane `deliver` and `pilot` commands: automated distribution

## Swift Package Manager

- `swift package resolve` downloads packages from the internet
- `swift package update` may upgrade to newer versions with different behavior
- Local packages with `path:` dependencies run arbitrary Swift code

## Keychain and Security Framework

When working with iOS security APIs via the Bash tool or generated scripts:
- `security` CLI commands on macOS for certificate and keychain operations
- Importing certificates or private keys into the keychain
- Deleting keychain items

These are legitimate operations but sensitive enough to warrant review.

## Secrets in Swift Projects

Common locations:
- `.xcconfig` files referenced in Build Settings (may contain API keys)
- `Info.plist` with service endpoints or keys
- Build phase scripts with embedded credentials

Prefer `xcconfig` files excluded via `.gitignore` for development keys. Use a secrets manager for production keys fetched at runtime.

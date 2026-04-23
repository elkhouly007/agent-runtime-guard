---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Dart + ARG Hooks

Dart and Flutter-specific ARG hook considerations.

## Flutter Build Commands

Flutter commands that may trigger ARG:
- `flutter build ipa --release` with distribution provisioning: uploads to App Store
- `flutter build appbundle` followed by deployment scripts
- `fastlane` commands for automated deployment

## pub.dev and Package Security

- `dart pub get` from pubspec.yaml: downloads and executes build_runner scripts
- `dart run build_runner build`: executes code generation that runs Dart code
- Review new `pubspec.yaml` dependencies before `dart pub get` in unfamiliar projects

## Dart Native and FFI

Dart Native and FFI (Foreign Function Interface) can call C code:
- FFI calls to system libraries may trigger ARG if they invoke dangerous operations
- Dart Native binaries have access to the full file system
- Review FFI bindings before running code that invokes native libraries

## Platform Channel Commands

Flutter platform channel code runs native code (Kotlin/Swift/ObjC/Java). If generating or running native code via platform channels, apply the native-language hook considerations.

## Secrets in Flutter Projects

Common secret locations:
- `lib/config/` files with hardcoded API keys
- `google-services.json` and `GoogleService-Info.plist` (Firebase credentials)
- `android/key.properties` (signing keystore passwords)

All of these should be excluded from version control and stored in secure locations.

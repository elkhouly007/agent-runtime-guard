# Dart Security

Dart-specific security rules.

## Input Validation

- Validate all input at the boundary, especially from platform channels or external APIs.
- Use `RegExp` for format validation, but be aware of ReDoS on untrusted input.
- Sanitize HTML content before inserting into `WebView` with `loadHtmlString`.

## Serialization

- `json_serializable` or `freezed` for type-safe JSON deserialization. Avoid manual `json['key']` access which does not validate types.
- Validate the structure of deserialized objects before using them.
- Never deserialize untrusted data into objects with `fromJson` factories that do not validate input types.

## Flutter Security (when applicable)

- `flutter_secure_storage` for storing tokens and secrets, not SharedPreferences.
- Disable debug mode in production: `debugShowCheckedModeBanner: false`.
- Certificate pinning for apps communicating with sensitive APIs.
- Obfuscate code for release builds: `--obfuscate --split-debug-info=<path>`.

## Network Security

- Always use HTTPS. Dart `HttpClient` does not validate certificates by default — configure certificate validation explicitly.
- Certificate pinning via a custom `SecurityContext` for sensitive connections.
- Do not log request/response bodies that may contain user data or tokens.

## Secrets

- Never hardcode API keys or tokens in Dart source. They will be extractable from compiled apps.
- Use build flavors or environment-specific configuration files that are excluded from version control.
- For Flutter: use `dart-define` for build-time constants that are not secrets; use a backend for secrets.

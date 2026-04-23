# Swift Security

Swift-specific security rules.

## Secure Data Storage

- `Keychain` for sensitive data: tokens, passwords, private keys. Never UserDefaults for sensitive values.
- Data Protection API: set appropriate protection classes on files that contain sensitive data.
- Biometric authentication (`LAContext`) for high-security operations.

## Network Security

- App Transport Security (ATS) enabled by default — do not disable it.
- Certificate pinning via `URLSession` delegate for sensitive API communications.
- Validate server certificates: do not accept self-signed certs in production.
- Never log network responses that may contain user data or auth tokens.

## Input Validation

- Validate all user input before processing. Length limits, format checks, type constraints.
- Never interpolate user input into SQL strings. Use parameterized queries (Core Data, GRDB, SQLite.swift all support this).
- Sanitize content before displaying in WKWebView: `evaluateJavaScript` can execute arbitrary code.

## Cryptography

- `CryptoKit` for all cryptographic operations in Swift. Do not use `CommonCrypto` directly.
- `SymmetricKey` with AES-GCM for symmetric encryption.
- `P256` or `P384` for key agreement and signatures.
- `SHA256` or `SHA512` for hashing. `MD5` and `SHA1` only for non-security purposes (checksums).
- PBKDF2 (via `PKCS5.PBKDF2`) for password derivation.

## Secrets

- Never hardcode API keys in Swift source. They are extractable from compiled apps with standard tools.
- Use obfuscation tools or fetch keys from a backend endpoint (itself properly secured).
- For development: use `xcconfig` files not committed to git.

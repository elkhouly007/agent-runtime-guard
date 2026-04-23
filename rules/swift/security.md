---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Swift Security Rules

## OWASP Mobile Top 10 Coverage

| OWASP Mobile Category | Swift Risk | Fix |
|---|---|---|
| M1 Improper Platform Usage | Storing secrets in `UserDefaults`; skipping ATS | Keychain; enforce ATS |
| M2 Insecure Data Storage | Sensitive data in logs, temp files, or plain files | `FileProtectionType.complete`; wipe after use |
| M3 Insecure Communication | `NSAllowsArbitraryLoads: true`; self-signed certs | Enforce ATS; certificate pinning |
| M4 Insecure Auth | Weak tokens; biometric bypass via passcode fallback | `SecureEnclave`; restrict biometric policy |
| M5 Insufficient Cryptography | `arc4random`; CommonCrypto MD5 | CryptoKit; `SecRandomCopyBytes` |
| M9 Reverse Engineering | No binary protection; hardcoded secrets | Hardened Runtime; Keychain for secrets |

---

## Input Validation

```swift
// BAD — raw string from URL query passed directly to business logic
func handleDeepLink(_ url: URL) {
    let userID = url.queryParameters["id"] ?? ""
    loadProfile(userID: userID)  // unvalidated; could be empty or malicious
}

// GOOD — validate and type-convert at the boundary
func handleDeepLink(_ url: URL) {
    guard
        let idString = url.queryParameters["id"],
        let userID = Int(idString),
        userID > 0
    else {
        logger.warning("Invalid deep link received")
        return
    }
    loadProfile(userID: userID)
}

// BAD — Any in Codable; loses type safety
struct Response: Codable {
    let data: [String: Any]  // compiler cannot enforce field types
}

// GOOD — explicit Codable types; invalid JSON fails at decode
struct UserResponse: Codable {
    let id: Int
    let email: String
    let role: UserRole   // enum; rejects unknown values
}

enum UserRole: String, Codable {
    case admin, viewer, editor
}
```

- Use `guard` at every entry point (URL handlers, notification payloads, universal links).
- Prefer `Codable` with explicit types over `JSONSerialization` with `Any`.

---

## SQL Injection Prevention (Core Data / SQLite)

```swift
// BAD — string interpolation in NSPredicate format (SQL injection)
let predicate = NSPredicate(format: "name == '\(name)'")
request.predicate = predicate

// BAD — raw SQLite query built with string concatenation
let query = "SELECT * FROM users WHERE name = '\(name)'"

// GOOD — NSPredicate with argument array (safe substitution)
let request = NSFetchRequest<User>(entityName: "User")
request.predicate = NSPredicate(format: "name == %@ AND role == %@", name, role)
let users = try context.fetch(request)

// GOOD — SQLite.swift parameterized query
import SQLite

let usersTable = Table("users")
let nameColumn = Expression<String>("name")

let filtered = usersTable.filter(nameColumn == name)
let users = try db.prepare(filtered).map { row in row[nameColumn] }
```

Never use string interpolation (`\(variable)`) in NSPredicate format strings with untrusted input.

---

## Keychain and Secrets

```swift
// BAD — token in UserDefaults (readable without entitlements; backed up to iCloud)
UserDefaults.standard.set(authToken, forKey: "auth_token")

// BAD — hardcoded API key in source
let apiKey = "sk-live-abc123xyz789"

// GOOD — store in Keychain with device-only accessibility
import Security

func saveToken(_ token: String, forKey key: String) throws {
    guard let data = token.data(using: .utf8) else { return }
    let query: [String: Any] = [
        kSecClass as String:            kSecClassGenericPassword,
        kSecAttrService as String:      "com.myapp.auth",
        kSecAttrAccount as String:      key,
        kSecValueData as String:        data,
        kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    ]
    SecItemDelete(query as CFDictionary)  // remove old item first
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw KeychainError.saveFailed(status)
    }
}

func loadToken(forKey key: String) throws -> String {
    let query: [String: Any] = [
        kSecClass as String:       kSecClassGenericPassword,
        kSecAttrService as String: "com.myapp.auth",
        kSecAttrAccount as String: key,
        kSecReturnData as String:  true,
        kSecMatchLimit as String:  kSecMatchLimitOne,
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data,
          let token = String(data: data, encoding: .utf8) else {
        throw KeychainError.loadFailed(status)
    }
    return token
}
```

- Use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` unless cross-device sync is explicitly required.
- Never log or print tokens, keys, or passwords — check `os_log` privacy levels.
- Load secrets from server-side configuration at runtime, not hardcoded in the binary.

---

## Cryptography

```swift
// BAD — MD5 for any purpose (deprecated; collision-vulnerable)
import CommonCrypto
var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
CC_MD5(data.bytes, CC_LONG(data.count), &digest)

// BAD — arc4random for security-sensitive values (non-cryptographic)
let token = arc4random_uniform(UInt32.max)

// GOOD — CryptoKit for symmetric encryption (AES-GCM)
import CryptoKit

func encrypt(_ plaintext: Data, key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(plaintext, using: key)
    return sealedBox.combined!
}

func decrypt(_ ciphertext: Data, key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
    return try AES.GCM.open(sealedBox, using: key)
}

// GOOD — CryptoKit ECDH key exchange
let privateKey = P256.KeyAgreement.PrivateKey()
let publicKey = privateKey.publicKey

// GOOD — SecRandomCopyBytes for random data
func secureRandomBytes(count: Int) throws -> Data {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    guard status == errSecSuccess else {
        throw CryptoError.randomGenerationFailed
    }
    return Data(bytes)
}

// GOOD — key derivation with PBKDF2 (when Argon2 is unavailable)
func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
    guard let passwordData = password.data(using: .utf8) else {
        throw CryptoError.encodingFailed
    }
    // Use CryptoKit HKDF for key stretching when appropriate
    let inputKeyMaterial = SymmetricKey(data: passwordData)
    return HKDF<SHA256>.deriveKey(
        inputKeyMaterial: inputKeyMaterial,
        salt: salt,
        outputByteCount: 32
    )
}
```

---

## Transport Security

```swift
// BAD — Info.plist disables ATS entirely
// <key>NSAppTransportSecurity</key>
// <dict>
//     <key>NSAllowsArbitraryLoads</key>
//     <true/>   ← disables TLS verification for all connections
// </dict>

// GOOD — ATS enabled (default); exception only for specific legacy domains
// <key>NSAppTransportSecurity</key>
// <dict>
//     <key>NSExceptionDomains</key>
//     <dict>
//         <key>legacy-api.example.com</key>
//         <dict>
//             <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
//         </dict>
//     </dict>
// </dict>

// GOOD — Certificate pinning via URLSessionDelegate
class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedPublicKeyHash = "base64-encoded-sha256-of-public-key"

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust,
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let publicKey = SecCertificateCopyKey(certificate)
        // ... hash and compare with pinnedPublicKeyHash
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
```

- Never set `allowsAnyHTTPSCertificate = true` in test code that ships to production.
- Use public key pinning (not certificate pinning) — keys survive cert renewals.

---

## Data Protection

```swift
// BAD — sensitive file with default (no) protection
let url = documentsDir.appendingPathComponent("user-data.json")
try data.write(to: url)  // accessible even when device is locked

// GOOD — complete protection: inaccessible when device is locked
let url = documentsDir.appendingPathComponent("user-data.json")
try data.write(to: url, options: .completeFileProtection)

// GOOD — mark directory with complete protection at creation
try FileManager.default.createDirectory(
    at: sensitiveDir,
    withIntermediateDirectories: true,
    attributes: [.protectionKey: FileProtectionType.complete]
)

// Wipe sensitive data from memory after use
func withSensitiveData(_ data: inout Data, _ block: () throws -> Void) rethrows {
    defer { data.resetBytes(in: 0..<data.count) }
    try block()
}
```

---

## Dependency Scanning

```bash
# Swift Package Manager — check for known vulnerabilities
swift package audit           # built-in (Xcode 16+ / swift 5.10+)

# Dependabot / GitHub dependency graph — enable in repo settings
# Automatically opens PRs for vulnerable transitive packages

# Manual review: check Package.resolved for pinned versions
cat Package.resolved | python3 -m json.tool | grep -E '"version"|"identity"'

# CocoaPods — check for outdated pods
pod outdated

# Verify checksum of a specific SPM dependency
swift package show-dependencies --format json | jq '.dependencies[].identity'
```

---

## Anti-Patterns

| Anti-pattern | Risk | Fix |
|---|---|---|
| `UserDefaults` for tokens/passwords | Readable without entitlements; backed up | Keychain with `WhenUnlockedThisDeviceOnly` |
| `NSAllowsArbitraryLoads: true` | MITM attacks; plaintext traffic | Remove; use domain-specific exceptions only |
| String interpolation in `NSPredicate` | SQL/predicate injection | `%@` argument substitution |
| `arc4random` for security randomness | Non-cryptographic; predictable | `SecRandomCopyBytes` or `CryptoKit` |
| MD5/SHA-1 for anything security-related | Collision attacks; broken | CryptoKit SHA-256 or HKDF |
| Logging `authToken`, `password`, etc. | Secrets in log aggregation / Crashlytics | Check `os_log` privacy; never log secrets |
| Hardcoded API keys in source | Key extraction via binary reverse engineering | Load from server config at runtime |
| Missing `FileProtectionType.complete` | Data readable when device is locked | Write with `.completeFileProtection` |
| No certificate pinning for own API | MITM on corporate/public Wi-Fi | Pin public key hash in `URLSessionDelegate` |
| Unused entitlements in `.entitlements` | Expanded attack surface | Audit before release; remove unused |

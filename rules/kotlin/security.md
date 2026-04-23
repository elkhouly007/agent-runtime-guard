# Kotlin Security

Kotlin-specific security rules extending the common rules.

## SQL Injection

- Use parameterized queries in JDBC: `PreparedStatement` or Spring Data Repository methods.
- Kotlin DSL query builders (Exposed, JOOQ) generate parameterized queries by default. Avoid raw SQL strings.
- Never use string templates to build SQL: `"SELECT * FROM users WHERE id = ${userId}"` is injection.

## Coroutine Security

- Do not use `GlobalScope` — it bypasses structured concurrency and can leak coroutines.
- Propagate `CoroutineContext` that contains security context (authenticated user, tenant ID) through the coroutine call chain.
- `withContext(Dispatchers.IO)` for I/O operations. Blocking I/O on the main dispatcher is a denial-of-service risk in Android.

## Serialization

- kotlinx.serialization: use `@Serializable` on data classes with explicit field names. Avoid serializing internal types.
- Jackson (if used with Kotlin): disable `FAIL_ON_UNKNOWN_PROPERTIES` with understanding — it can mask injection of unexpected fields.
- Never deserialize untrusted data into polymorphic types without explicit type restriction.

## Android-Specific (when applicable)

- `android:exported="false"` for activities and services that do not need to be reached by other apps.
- Do not store sensitive data in SharedPreferences without encryption. Use EncryptedSharedPreferences.
- WebView: disable JavaScript if not needed (`setJavaScriptEnabled(false)`). JavaScript bridges are attack surfaces.
- Deep link validation: verify that deep link data originates from trusted sources before acting on it.

## Secrets

- Never hardcode API keys in Kotlin source. Use local.properties for development, secrets manager for production.
- Build-time secrets via `BuildConfig` are compiled into APKs and are extractable. Avoid for sensitive values.

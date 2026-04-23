---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Kotlin Coding Style

## Null Safety

- Avoid `!!` (non-null assertion operator) — it is a runtime crash.
- Use `?.let { }`, `?: return`, or `?: throw` instead.
- `lateinit var` only for fields guaranteed to be initialized before use (e.g., DI).
- Prefer `val` over `var` — reassignment should be the exception, not the default.

```kotlin
// BAD — crashes if user is null
val name = user!!.name

// GOOD
val name = user?.name ?: "Unknown"

// GOOD — early return
fun process(user: User?) {
    user ?: return
    // user is smart-cast to non-null here
}

// GOOD — throw with message
val config = configMap["key"] ?: throw IllegalStateException("Missing required key")
```

## Idioms

- Use data classes for value objects and DTOs.
- Use sealed classes for exhaustive state modeling.
- Use `when` over `if/else` chains for multi-branch logic.
- Extension functions for behavior on types you do not own.
- `object` for singletons; `companion object` for factory methods.
- Avoid Java-style getters/setters — use Kotlin properties.

```kotlin
// Sealed class for UI state
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}

// Exhaustive when
fun render(state: UiState<User>) = when (state) {
    is UiState.Loading -> showSpinner()
    is UiState.Success -> showUser(state.data)
    is UiState.Error -> showError(state.message)
}

// Extension function
fun String.toSlug() = lowercase().replace(Regex("[^a-z0-9]"), "-")
```

## Coroutines

- Never use `GlobalScope` — use structured scopes (`viewModelScope`, `lifecycleScope`, injected scope).
- `withContext(Dispatchers.IO)` for blocking I/O.
- Handle all exceptions inside coroutines with `try/catch` or `CoroutineExceptionHandler`.
- `Flow` for cold streams; `StateFlow` for observable state; `SharedFlow` for events.

```kotlin
// BAD
GlobalScope.launch { fetchData() }

// GOOD — in ViewModel
viewModelScope.launch {
    _state.value = UiState.Loading
    try {
        val result = withContext(Dispatchers.IO) { repository.fetch() }
        _state.value = UiState.Success(result)
    } catch (e: Exception) {
        _state.value = UiState.Error(e.message ?: "Unknown error")
    }
}

// Flow with StateFlow
private val _uiState = MutableStateFlow<UiState<List<Item>>>(UiState.Loading)
val uiState: StateFlow<UiState<List<Item>>> = _uiState.asStateFlow()
```

## Functions

- Functions over 30 lines are candidates for extraction.
- Use named arguments for calls with multiple parameters of the same type.
- Avoid deep nesting — use early returns and extension functions.
- Default parameter values instead of multiple overloads where appropriate.

```kotlin
// BAD — ambiguous call
createUser("Ahmed", "Khouly", true, false)

// GOOD — named arguments
createUser(firstName = "Ahmed", lastName = "Khouly", isAdmin = true, isActive = false)

// Default parameters instead of overloads
fun fetchUsers(page: Int = 1, pageSize: Int = 20, activeOnly: Boolean = true) { }
```

## Style

- Follow the official Kotlin coding conventions.
- Use `ktlint` or `detekt` for linting.
- Trailing commas on multi-line parameter lists and enums.
- No wildcard imports.

## Android (when applicable)

- No Android framework types in ViewModel or domain classes.
- Use `collectAsStateWithLifecycle()` for flows in Compose.
- Do not hold Activity or Context references in long-lived objects — use application context if needed.

```kotlin
// Compose — collect with lifecycle awareness
val state by viewModel.uiState.collectAsStateWithLifecycle()

// BAD — leaks Activity
class MyViewModel(private val activity: Activity) : ViewModel()

// GOOD — use application context or DI
class MyViewModel(private val repo: UserRepository) : ViewModel()
```

## Tooling

```bash
# Lint with ktlint
./gradlew ktlintCheck

# Static analysis with detekt
./gradlew detekt

# Run unit tests
./gradlew test

# Android instrumented tests
./gradlew connectedAndroidTest
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `user!!.name` | `user?.name ?: default` |
| `var` everywhere | `val` unless reassignment is needed |
| `GlobalScope.launch` | Use structured scopes |
| Java-style getters (`getName()`) | Kotlin properties (`name`) |
| Nested `if/else` chains | `when` expression or early returns |
| Wildcard imports | Explicit imports |

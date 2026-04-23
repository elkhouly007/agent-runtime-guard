# Kotlin Design Patterns

Kotlin-specific patterns for idiomatic, safe, expressive code.

## Sealed Classes as State Machines

```kotlin
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}

when (state) {
    is UiState.Loading -> showSpinner()
    is UiState.Success -> showData(state.data)
    is UiState.Error   -> showError(state.message)
}
```

The `when` expression is exhaustive — the compiler catches missing cases.

## Result Wrapping with Arrow or Kotlin Result

```kotlin
fun findUser(id: UserId): Result<User> = runCatching {
    repository.findById(id) ?: throw NotFoundException("User $id not found")
}

findUser(id)
    .onSuccess { user -> render(user) }
    .onFailure { error -> logError(error) }
```

## Delegation Pattern

```kotlin
interface Logger { fun log(message: String) }
class FileLogger(private val path: Path) : Logger { ... }

class Service(logger: Logger) : Logger by logger {
    // Service delegates Logger methods to the injected logger
    // without implementing them manually
}
```

## Builder with DSL

```kotlin
data class ServerConfig(val host: String, val port: Int, val timeout: Duration)

fun serverConfig(block: ServerConfigBuilder.() -> Unit): ServerConfig {
    return ServerConfigBuilder().apply(block).build()
}

val config = serverConfig {
    host = "localhost"
    port = 8080
    timeout = 30.seconds
}
```

## Flow for Reactive Streams

```kotlin
fun userUpdates(userId: UserId): Flow<User> = flow {
    while (true) {
        emit(repository.findById(userId))
        delay(5.seconds)
    }
}.distinctUntilChanged()
```

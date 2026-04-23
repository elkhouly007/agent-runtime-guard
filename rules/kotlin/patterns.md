---
paths:
  - "**/*.kt"
  - "**/*.kts"
last_reviewed: 2026-04-22
version_target: "Best Practices"
---
# Kotlin Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Kotlin and Android/KMP-specific content.

## Dependency Injection

Prefer constructor injection. Use Koin (KMP) or Hilt (Android-only):

```kotlin
val dataModule = module {
    single<ItemRepository> { ItemRepositoryImpl(get(), get()) }
    factory { GetItemsUseCase(get()) }
    viewModelOf(::ItemListViewModel)
}

@HiltViewModel
class ItemListViewModel @Inject constructor(
    private val getItems: GetItemsUseCase
) : ViewModel()
```

## ViewModel Pattern

Use a single state object, event sink, and one-way data flow:

```kotlin
data class ScreenState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false
)

class ScreenViewModel(private val useCase: GetItemsUseCase) : ViewModel() {
    private val _state = MutableStateFlow(ScreenState())
    val state = _state.asStateFlow()

    fun onEvent(event: ScreenEvent) {
        when (event) {
            is ScreenEvent.Load -> load()
            is ScreenEvent.Delete -> delete(event.id)
        }
    }
}
```

## Repository Pattern

- `suspend` functions return `Result<T>` or a custom error type
- `Flow` for reactive streams
- Coordinate local and remote data sources explicitly

```kotlin
interface ItemRepository {
    suspend fun getById(id: String): Result<Item>
    suspend fun getAll(): Result<List<Item>>
    fun observeAll(): Flow<List<Item>>
}
```

## UseCase Pattern

Give each use case one responsibility and prefer `operator fun invoke`:

```kotlin
class GetItemUseCase(private val repository: ItemRepository) {
    suspend operator fun invoke(id: String): Result<Item> {
        return repository.getById(id)
    }
}
```

## expect/actual (KMP)

Use `expect`/`actual` only for truly platform-specific behavior:

```kotlin
expect fun platformName(): String
expect class SecureStorage {
    fun save(key: String, value: String)
    fun get(key: String): String?
}
```

## Coroutine Patterns

- Use `viewModelScope` in ViewModels
- Use `coroutineScope` for structured child work
- Use `stateIn(..., SharingStarted.WhileSubscribed(...), initialValue)` for StateFlow from cold flows
- Use `supervisorScope` when child failures should remain isolated

## Builder Pattern with DSL

```kotlin
class HttpClientConfig {
    var baseUrl: String = ""
    var timeout: Long = 30_000
}

fun httpClient(block: HttpClientConfig.() -> Unit): HttpClient {
    val config = HttpClientConfig().apply(block)
    return HttpClient(config)
}
```

## References

See skill: `kotlin-coroutines-flows` for detailed coroutine patterns.
See skill: `android-clean-architecture` for module and layer patterns.

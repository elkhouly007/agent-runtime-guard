# Dart Design Patterns

Dart-specific patterns for clean, maintainable code.

## Freezed for Sealed Classes

Use `freezed` for immutable data classes and sealed class unions:

```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.error(String message) = _Error;
}

state.when(
  initial: () => LoginPrompt(),
  loading: () => CircularProgressIndicator(),
  authenticated: (user) => HomeScreen(user: user),
  error: (msg) => ErrorBanner(message: msg),
);
```

## Repository Pattern

```dart
abstract class UserRepository {
  Future<User?> findById(UserId id);
  Future<void> save(User user);
  Stream<List<User>> watchActiveUsers();
}

class ApiUserRepository implements UserRepository { ... }
class InMemoryUserRepository implements UserRepository { ... }  // for tests
```

## Result Type

```dart
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}
```

## Extension Methods

```dart
extension StringValidation on String {
  bool get isValidEmail => RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(this);
  String get truncated => length > 50 ? '${substring(0, 50)}...' : this;
}
```

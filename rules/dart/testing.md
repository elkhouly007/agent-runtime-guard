# Dart Testing

Dart and Flutter testing standards.

## Framework

- `test` package for unit and integration tests.
- `flutter_test` for Flutter widget tests.
- `mocktail` or `mockito` for mocking.
- `integration_test` for Flutter end-to-end tests on device.

## Test Organization

- Unit tests in `test/` directory, mirroring the `lib/` structure.
- Widget tests in `test/widgets/`.
- Integration tests in `integration_test/`.
- Test file naming: `user_repository_test.dart` for `user_repository.dart`.

## Unit Test Structure

```dart
group('UserRepository', () {
  late MockHttpClient mockClient;
  late UserRepository repository;

  setUp(() {
    mockClient = MockHttpClient();
    repository = UserRepository(client: mockClient);
  });

  test('returns user when found', () async {
    when(() => mockClient.get(any())).thenAnswer((_) async => userResponse);
    final user = await repository.findById(UserId('123'));
    expect(user, isNotNull);
  });
});
```

## Widget Tests

```dart
testWidgets('shows error message when loading fails', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(seconds: 2));
  expect(find.text('Failed to load'), findsOneWidget);
});
```

## Async Testing

- `await` all async operations in tests.
- Use `pump()` to advance time by one frame in widget tests.
- `pumpAndSettle()` to wait for all animations to complete.
- Test streams with `emitsInOrder` matcher from `stream_matchers`.

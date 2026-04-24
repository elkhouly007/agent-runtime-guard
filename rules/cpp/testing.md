---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# C++ Testing

C++-specific testing standards.

## Framework

- Google Test (gtest/gmock) or Catch2. Both are mature with good IDE integration.
- CTest as the test runner in CMake projects: integrates with `ctest --output-on-failure`.

## Test Structure (Google Test)

```cpp
TEST(AuthServiceTest, ReturnsErrorWhenTokenIsExpired) {
    AuthService service;
    auto result = service.validate(expiredToken);
    EXPECT_FALSE(result.ok());
    EXPECT_EQ(result.error(), AuthError::kTokenExpired);
}

TEST_F(AuthServiceFixture, AcceptsValidToken) {
    auto result = service_.validate(validToken_);
    EXPECT_TRUE(result.ok());
}
```

## Test Structure (Catch2)

```cpp
TEST_CASE("AuthService validates tokens", "[auth]") {
    SECTION("rejects expired token") {
        AuthService service;
        auto result = service.validate(expiredToken);
        REQUIRE_FALSE(result.ok());
        REQUIRE(result.error() == AuthError::kExpired);
    }
}
```

## Sanitizers in Tests

- Always run tests with AddressSanitizer and UndefinedBehaviorSanitizer enabled.
- `cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined"` for a sanitized build.
- ThreadSanitizer for concurrent code: `-fsanitize=thread`.
- Valgrind as an alternative for memory error detection.

## Mocking

- GMock for mocking interfaces.
- Define interfaces (pure virtual classes) for components that need to be mocked in tests.
- Mock objects in test fixtures; use real implementations in production.

## Test Build Configuration

- Test builds should enable `-DDEBUG` and `-O0 -g` for better sanitizer diagnostics.
- Use a separate CMake target for tests: `add_executable(run_tests ...)` with `target_link_libraries(run_tests gtest_main ...)`.

---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# C++ Testing Rules

## Framework Choice

- Use **GoogleTest (gtest/gmock)** for unit and integration tests — it is the de-facto standard with strong tooling support.
- Use **Catch2** as an alternative for header-only, lightweight test suites where gtest would be too heavy.
- Use **libFuzzer** or **AFL++** for fuzz testing parsing code, deserializers, and protocol handlers.
- Do not mix frameworks within a single project — pick one and stay consistent.

## Test Structure (GoogleTest)

```cpp
// BAD — no fixtures, globals leaking between tests
int g_counter = 0;

TEST(CounterTest, Increment) {
    g_counter++;
    EXPECT_EQ(g_counter, 1);  // fails if tests run in different order
}

// GOOD — fixture isolates state
class CounterTest : public ::testing::Test {
protected:
    void SetUp() override { counter_ = 0; }
    int counter_ = 0;
};

TEST_F(CounterTest, Increment) {
    counter_++;
    EXPECT_EQ(counter_, 1);
}
```

- Use `TEST_F` with a fixture when the test needs setup/teardown.
- Use `TEST` only for truly stateless tests.
- Name tests as `ClassName_MethodName_Scenario` or `MethodName_Condition_ExpectedResult`.

## Assertions

```cpp
// Prefer EXPECT_* over ASSERT_* unless test continuation would be meaningless
EXPECT_EQ(result, expected);      // continues on failure
ASSERT_NE(ptr, nullptr);          // stops test on failure (safe to dereference after)

// Use typed comparisons — avoid implicit conversions
EXPECT_EQ(static_cast<size_t>(3), vec.size());

// String comparisons
EXPECT_STREQ("expected", c_str_result);   // C strings
EXPECT_EQ("expected", std_string_result); // std::string

// Floating point
EXPECT_DOUBLE_EQ(3.14, result);           // exact ULP comparison
EXPECT_NEAR(3.14, result, 0.001);         // tolerance-based
```

- Never use `ASSERT_*` in a helper function — it only returns from the current function, not the test.
- Use `SCOPED_TRACE("context")` to annotate loop iterations so failures are identifiable.

## Mocking (GoogleMock)

```cpp
class MockStorage : public IStorage {
public:
    MOCK_METHOD(bool, Save, (const std::string& key, const std::string& value), (override));
    MOCK_METHOD(std::string, Load, (const std::string& key), (const, override));
};

TEST_F(CacheTest, SavesOnFirstAccess) {
    MockStorage storage;
    EXPECT_CALL(storage, Save("key", "value"))
        .Times(1)
        .WillOnce(::testing::Return(true));

    Cache cache(&storage);
    cache.Put("key", "value");
}
```

- Mock interfaces (pure virtual classes), not concrete implementations.
- Always set expectations before calling the code under test.
- Use `EXPECT_CALL` (verifies at end of test) over `ON_CALL` (no verification) unless you intentionally don't need to verify.
- Prefer `NiceMock<>` in tests that only care about specific interactions, to suppress unexpected-call warnings.

## Test Isolation

- Each test must be independent — no shared mutable state between tests.
- Use RAII to manage resources in fixtures (`SetUp`/`TearDown` or smart pointers).
- Temporary files: use `std::filesystem::temp_directory_path()` / create unique paths per test.
- Do not rely on test execution order — tests must pass in any order.

## Catch2 Style

```cpp
// Catch2 v3
#include <catch2/catch_test_macros.hpp>

TEST_CASE("Parser handles empty input", "[parser]") {
    Parser p;
    REQUIRE(p.Parse("").empty());  // REQUIRE = ASSERT, CHECK = EXPECT
}

SCENARIO("Stack operations", "[stack]") {
    GIVEN("an empty stack") {
        Stack<int> s;
        WHEN("push is called") {
            s.Push(42);
            THEN("top returns the pushed value") {
                CHECK(s.Top() == 42);
            }
        }
    }
}
```

- Use `REQUIRE` when continuing after failure would crash or produce noise.
- Use `CHECK` to collect all failures in one pass.
- Tag tests with `[tags]` to allow selective runs.

## Coverage and CI

- Enable coverage in CI: `-fprofile-arcs -ftest-coverage` (gcov) or `--coverage` with llvm-cov.
- Run sanitizers alongside tests: `-fsanitize=address,undefined` catches memory errors that assertions miss.
- Fuzz targets live in a `fuzz/` directory and are CI-gated on a time budget (e.g., 60 seconds per target).
- Minimum coverage target: 80% line coverage for core logic modules.

## What Not to Test

- Don't test the standard library or third-party dependencies.
- Don't write tests that simply restate the implementation (testing that a setter sets a field).
- Don't test private methods directly — test behavior through the public API; if private logic is complex enough to need direct testing, extract it.

# Skill: C++ Testing (GoogleTest + CMake/CTest)

## Trigger

Use when:
- Writing C++ unit or integration tests
- Choosing between TEST(), TEST_F(), or TEST_P()
- Setting up fixtures, mocks, or death tests
- Configuring sanitizers or coverage in CMake
- Wiring GoogleTest into CTest for CI

## Process

### 1. TEST() vs TEST_F() vs TEST_P()

| Macro | Use when |
|-------|----------|
| `TEST(Suite, Name)` | No shared state; standalone test |
| `TEST_F(Fixture, Name)` | Tests share setup/teardown via a class |
| `TEST_P(Fixture, Name)` | Parameterized — run the same fixture with different inputs |

```cpp
#include <gtest/gtest.h>

// TEST — no fixture
TEST(MathTest, AddPositives) {
    EXPECT_EQ(add(2, 3), 5);
}

TEST(MathTest, AddNegatives) {
    EXPECT_EQ(add(-2, -3), -5);
}

// TEST_F — shared fixture
class CartTest : public ::testing::Test {
protected:
    void SetUp() override {
        cart_.add_item(Item{"widget", 10.0, 2});
        cart_.add_item(Item{"gadget", 5.0, 1});
    }

    void TearDown() override {
        // cleanup if needed (RAII usually handles this)
    }

    Cart cart_;
};

TEST_F(CartTest, TotalCalculatedCorrectly) {
    EXPECT_DOUBLE_EQ(cart_.total(), 25.0);
}

TEST_F(CartTest, ItemCountIsCorrect) {
    EXPECT_EQ(cart_.item_count(), 2);
}

// TEST_P — parameterized
class PrimeTest : public ::testing::TestWithParam<int> {};

TEST_P(PrimeTest, IsPrime) {
    EXPECT_TRUE(is_prime(GetParam()));
}

INSTANTIATE_TEST_SUITE_P(
    SmallPrimes,
    PrimeTest,
    ::testing::Values(2, 3, 5, 7, 11, 13)
);
```

### 2. ASSERT vs EXPECT macros

| Macro family | On failure |
|---|---|
| `ASSERT_*` | Stops the current test function immediately |
| `EXPECT_*` | Reports failure and continues |

```cpp
TEST_F(UserServiceTest, CreateUserReturnsValidUser) {
    auto result = service_.create_user("alice@example.com");

    // ASSERT — stop if null; avoids dereferencing nullptr below
    ASSERT_NE(result, nullptr);

    // EXPECT — collect all failures in one run
    EXPECT_EQ(result->email, "alice@example.com");
    EXPECT_FALSE(result->id.empty());
    EXPECT_GT(result->created_at, 0);
}

// Common assertion macros
EXPECT_EQ(a, b);           // a == b
EXPECT_NE(a, b);           // a != b
EXPECT_LT(a, b);           // a < b
EXPECT_LE(a, b);           // a <= b
EXPECT_GT(a, b);           // a > b
EXPECT_GE(a, b);           // a >= b
EXPECT_TRUE(expr);
EXPECT_FALSE(expr);
EXPECT_FLOAT_EQ(a, b);    // float equality with ULP tolerance
EXPECT_DOUBLE_EQ(a, b);   // double equality with ULP tolerance
EXPECT_NEAR(a, b, abs_error);

// String matchers
EXPECT_STREQ(c_str1, c_str2);
EXPECT_STRCASEEQ(c_str1, c_str2);

// Exception assertions
EXPECT_THROW(risky_call(), std::runtime_error);
EXPECT_NO_THROW(safe_call());
EXPECT_ANY_THROW(bad_call());
```

### 3. Fixtures with SetUp/TearDown

```cpp
class DatabaseTest : public ::testing::Test {
protected:
    static void SetUpTestSuite() {
        // Runs once before all tests in this suite
        // Use for expensive shared resources (DB schema creation)
        db_path_ = "/tmp/test_" + random_id() + ".db";
        create_schema(db_path_);
    }

    static void TearDownTestSuite() {
        std::filesystem::remove(db_path_);
    }

    void SetUp() override {
        // Runs before each test — use for per-test isolation
        conn_ = open_connection(db_path_);
        begin_transaction(conn_);
    }

    void TearDown() override {
        // Rollback ensures each test starts clean
        rollback_transaction(conn_);
        close_connection(conn_);
    }

    Connection conn_{};
    inline static std::string db_path_;
};

TEST_F(DatabaseTest, InsertUser) {
    insert_user(conn_, {"alice", "alice@example.com"});
    auto users = query_users(conn_);
    ASSERT_EQ(users.size(), 1u);
    EXPECT_EQ(users[0].email, "alice@example.com");
}
```

### 4. Death tests

```cpp
// Test that code terminates with expected message
TEST(ContractTest, NullptrPreconditionTriggersAbort) {
    EXPECT_DEATH(process(nullptr), "precondition failed");
}

// EXPECT_DEATH — continues on failure
// ASSERT_DEATH — stops on failure
// EXPECT_EXIT — specify exit code
TEST(ProcessTest, ExitsOnInvalidArgument) {
    EXPECT_EXIT(run_with_bad_args(), ::testing::ExitedWithCode(1), "invalid argument");
}
```

### 5. GMock for mocking

```cpp
#include <gmock/gmock.h>

// Define mock — matches the interface exactly
class MockPaymentGateway : public PaymentGateway {
public:
    MOCK_METHOD(ChargeResult, charge,
                (const std::string& token, double amount),
                (override));
    MOCK_METHOD(bool, refund,
                (const std::string& txn_id),
                (override, noexcept));
};

TEST(OrderServiceTest, ChargesCorrectAmount) {
    MockPaymentGateway gateway;

    // Expect exactly one call with these arguments
    EXPECT_CALL(gateway, charge("tok_alice", 99.99))
        .Times(1)
        .WillOnce(::testing::Return(ChargeResult{.success = true, .txn_id = "txn_1"}));

    OrderService svc(&gateway);
    auto result = svc.checkout("tok_alice", 99.99);

    EXPECT_TRUE(result.success);
    EXPECT_EQ(result.txn_id, "txn_1");
}

// Matchers
EXPECT_CALL(gateway, charge(::testing::StartsWith("tok_"), ::testing::Gt(0.0)))
    .Times(::testing::AtLeast(1));

// Capture arguments for inspection
std::string captured_token;
EXPECT_CALL(gateway, charge(::testing::_, ::testing::_))
    .WillOnce([&](const std::string& token, double) {
        captured_token = token;
        return ChargeResult{true, "txn_2"};
    });
```

### 6. CMake + CTest integration

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(MyApp CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Fetch GoogleTest
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
)
FetchContent_MakeAvailable(googletest)

enable_testing()

# Test executable
add_executable(unit_tests
    tests/cart_test.cpp
    tests/user_service_test.cpp
)

target_link_libraries(unit_tests
    PRIVATE
        myapp_lib
        GTest::gtest_main
        GTest::gmock
)

# Sanitizers for test builds
target_compile_options(unit_tests PRIVATE
    $<$<CONFIG:Debug>:-fsanitize=address,undefined -fno-omit-frame-pointer>
)
target_link_options(unit_tests PRIVATE
    $<$<CONFIG:Debug>:-fsanitize=address,undefined>
)

include(GoogleTest)
gtest_discover_tests(unit_tests)
```

```bash
# Build and run tests
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build --output-on-failure -j$(nproc)

# Run specific tests
ctest --test-dir build -R CartTest --output-on-failure
```

### 7. AddressSanitizer and UBSanitizer

```bash
# Enable ASan + UBSan in cmake preset
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer"

cmake --build build && ctest --test-dir build
# ASan will abort with a stack trace on any heap corruption / use-after-free
# UBSan will abort on integer overflow, misaligned access, null dereference
```

### 8. Coverage with gcov/llvm-cov

```bash
# GCC coverage
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="--coverage" \
      -DCMAKE_EXE_LINKER_FLAGS="--coverage"

cmake --build build && ctest --test-dir build

# Generate report
lcov --capture --directory build --output-file coverage.info
lcov --remove coverage.info '/usr/*' '*/tests/*' --output-file coverage_filtered.info
genhtml coverage_filtered.info --output-directory coverage_html

# Clang coverage (preferred — faster, more accurate)
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="-fprofile-instr-generate -fcoverage-mapping" \
      -DCMAKE_EXE_LINKER_FLAGS="-fprofile-instr-generate"

cmake --build build
LLVM_PROFILE_FILE="tests.profraw" ctest --test-dir build
llvm-profdata merge -sparse build/tests.profraw -o tests.profdata
llvm-cov report build/unit_tests -instr-profile=tests.profdata
llvm-cov show build/unit_tests -instr-profile=tests.profdata -format=html > coverage.html
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| Testing private methods directly | Breaks encapsulation | Test via public API; extract if needed |
| ASSERT_* in SetUp() | Unclear error, setup still runs | Validate in test or use `GTEST_SKIP()` |
| Non-virtual destructor in mocked class | Undefined behavior on delete | Virtual destructor in interface |
| EXPECT_CALL with no Times() | Defaults to `Times(1)` — surprising | Always specify `Times(...)` explicitly |
| No `override` on mock methods | Silently mismatches signature | Always use `(override)` in MOCK_METHOD |
| No sanitizers in test builds | Misses memory bugs | Always build tests with ASan+UBSan |

## Safe Behavior

- Every test executable is built with `-fsanitize=address,undefined` in Debug builds.
- Death tests use `EXPECT_DEATH` with a specific regex, not an empty string.
- All `MOCK_METHOD` declarations include `(override)`.
- `gtest_discover_tests()` is used — tests register automatically in CTest.
- Coverage report is generated in CI; threshold enforced via script.
- `SetUpTestSuite`/`TearDownTestSuite` only for genuinely shared, read-only resources.

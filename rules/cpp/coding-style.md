---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# C++ Coding Style

## Modern C++ Standards

Use C++17 as the minimum. Prefer C++20 features where the toolchain supports it.

## Resource Management (RAII)

- All resource acquisition happens in constructors; all release in destructors.
- No raw `new`/`delete` — use `std::unique_ptr<T>` for exclusive ownership.
- `std::shared_ptr<T>` only when multiple owners genuinely exist.
- `std::make_unique<T>()` and `std::make_shared<T>()` — never construct smart pointers directly.
- `std::vector`, `std::string`, `std::array` over raw arrays.

```cpp
// BAD — manual memory, not exception-safe
Widget* w = new Widget(config);
doSetup(w);  // throws → memory leaked
delete w;

// GOOD — RAII, automatic cleanup
auto w = std::make_unique<Widget>(config);
doSetup(w.get());  // throws → w destructor called

// BAD — raw array, fixed size, no bounds check
char buffer[256];
strcpy(buffer, user_input);  // overflow risk

// GOOD
std::string buffer = user_input;

// GOOD — fixed-size on stack with bounds
std::array<char, 256> buf{};
std::strncpy(buf.data(), user_input, buf.size() - 1);
```

## Naming Conventions

- `snake_case` for functions, variables, and members.
- `PascalCase` for classes, structs, and type aliases.
- `SCREAMING_SNAKE_CASE` for macros (avoid macros for constants — use `constexpr`).
- `k` prefix for named constants: `kMaxRetries`.

```cpp
// BAD — macro constant
#define MAX_RETRIES 3

// GOOD — constexpr
constexpr int kMaxRetries = 3;
constexpr double kPi = 3.14159265358979;

class UserRepository {           // PascalCase
    void fetch_user(int user_id); // snake_case
    int max_connections_;         // member with trailing _
};
```

## Const Correctness

- `const` on every variable, reference, and method that does not need to modify state.
- `[[nodiscard]]` on functions whose return value should not be ignored.
- `constexpr` for compile-time constants and functions.

```cpp
// const everywhere possible
const std::string name = user.get_name();

class Vector2D {
public:
    [[nodiscard]] double length() const;  // const method
    [[nodiscard]] Vector2D normalized() const;
    void scale(double factor);  // mutates — no const
};

// Use the return value or the compiler warns
auto v = position.normalized();  // [[nodiscard]] enforces this
```

## Ownership and Value Categories

- Pass by `const&` for read-only access to non-trivial types.
- Pass by value for types you will copy anyway (move semantics makes this cheap).
- Pass by `&&` (rvalue reference) in move constructors and move assignment operators.
- Return by value — the compiler handles copy elision (NRVO/RVO).

```cpp
// Pass by const& for read-only
void print_name(const std::string& name);

// Pass by value when you'll copy internally
void set_name(std::string name) {
    name_ = std::move(name);  // move from the copy
}

// Return by value — RVO eliminates the copy
std::vector<int> make_range(int n) {
    std::vector<int> result;
    result.reserve(n);
    for (int i = 0; i < n; ++i) result.push_back(i);
    return result;  // NRVO: no copy
}

// Move constructor
class Buffer {
public:
    Buffer(Buffer&& other) noexcept
        : data_(std::exchange(other.data_, nullptr)),
          size_(std::exchange(other.size_, 0)) {}
};
```

## Error Handling

- Exceptions for truly exceptional conditions.
- Error codes or `std::expected` (C++23) for expected failures.
- Destructors must never throw — catch inside destructors.
- RAII ensures cleanup even when exceptions are thrown.

```cpp
// std::expected (C++23) for expected failures
std::expected<User, std::string> find_user(int id) {
    if (id <= 0) return std::unexpected("Invalid ID");
    auto it = users_.find(id);
    if (it == users_.end()) return std::unexpected("Not found");
    return it->second;
}

// Destructor never throws
class Connection {
public:
    ~Connection() noexcept {
        try { close(); }
        catch (...) { /* log, but never propagate */ }
    }
};
```

## Style and Tooling

```bash
# Format with clang-format
clang-format -i src/**/*.cpp src/**/*.h

# Lint with clang-tidy
clang-tidy src/**/*.cpp --checks='modernize-*,readability-*,bugprone-*'

# Static analysis
cppcheck --enable=all --inconclusive src/

# Build with sanitizers
cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -g" -B build
cmake --build build

# Run with leak detection
ASAN_OPTIONS=detect_leaks=1 ./build/myapp
```

Additional style rules:
- Header files: `#pragma once` or include guards.
- Includes: system headers (`<vector>`), then third-party, then local (`"myfile.h"`).
- No `using namespace std;` in header files.

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Raw `new`/`delete` | `std::make_unique` / `std::make_shared` |
| `#define` for constants | `constexpr` |
| `char[]` buffers | `std::string` or `std::array` |
| Signed integer overflow | Check before or use `unsigned` |
| Non-const method on const object | Add `const` to method signature |
| `using namespace std;` in headers | Use explicit `std::` prefix |
| Throwing from destructor | Catch inside destructor |

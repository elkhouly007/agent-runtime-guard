# Skill: C++ Coding Standards

## Trigger

Use when:
- Writing or reviewing C++ code
- Auditing for resource management issues (raw pointers, manual delete)
- Designing classes with ownership semantics
- Applying C++17/20 language features
- Flagging anti-patterns against the C++ Core Guidelines

## Process

### 1. RAII — Resource Acquisition Is Initialization

Every resource must be owned by an object whose destructor releases it.

```cpp
#include <fstream>
#include <stdexcept>
#include <string>

// Bad — manual resource management, exception-unsafe
void bad_read(const std::string& path) {
    FILE* f = fopen(path.c_str(), "r");
    // if exception thrown here, f is leaked
    fclose(f);
}

// Good — RAII via ifstream destructor
std::string read_file(const std::string& path) {
    std::ifstream file(path);
    if (!file.is_open()) {
        throw std::runtime_error("cannot open: " + path);
    }
    return {std::istreambuf_iterator<char>(file),
            std::istreambuf_iterator<char>()};
}

// Custom RAII wrapper
class ScopedLock {
public:
    explicit ScopedLock(pthread_mutex_t& m) : mutex_(m) {
        pthread_mutex_lock(&mutex_);
    }
    ~ScopedLock() { pthread_mutex_unlock(&mutex_); }
    ScopedLock(const ScopedLock&) = delete;
    ScopedLock& operator=(const ScopedLock&) = delete;
private:
    pthread_mutex_t& mutex_;
};
// Prefer std::lock_guard / std::scoped_lock in production
```

### 2. Smart pointers — no raw new/delete

```cpp
#include <memory>

// unique_ptr — single ownership (zero overhead)
std::unique_ptr<Widget> make_widget(int id) {
    return std::make_unique<Widget>(id); // use make_unique, never new
}

void use_widget(std::unique_ptr<Widget> w) {
    // ownership transferred into this function
}

// Observe without owning — pass raw pointer or reference
void render(const Widget* w);   // nullable observer
void render(const Widget& w);   // non-null observer (prefer this)

// shared_ptr — shared ownership (ref-counted)
std::shared_ptr<Config> load_config(const std::string& path) {
    return std::make_shared<Config>(path);
}

// weak_ptr — break cycles
struct Node {
    std::shared_ptr<Node> next;
    std::weak_ptr<Node>   parent; // weak to avoid cycle
};

// Bad — raw new/delete
Widget* w = new Widget(1);  // NEVER do this
delete w;                   // missing in any exception path = leak
```

### 3. Const correctness

```cpp
class OrderService {
public:
    // const member functions — do not modify state
    [[nodiscard]] double total() const;
    [[nodiscard]] bool empty() const noexcept;

    // const parameters — document intent
    void apply_discount(const std::string& code, double rate);

    // const references for read-only parameters
    explicit OrderService(const std::vector<Item>& items);

    // const local variables
    static std::string format_price(double amount) {
        const auto cents = static_cast<long>(amount * 100);
        return std::to_string(cents / 100) + "." +
               std::to_string(cents % 100);
    }
};
```

### 4. Rule of 0 / 3 / 5

```cpp
// Rule of 0 — prefer this. Use standard containers; let compiler generate everything.
class Widget {
    std::string name_;
    std::vector<int> data_;
    // All five special members generated correctly by compiler
};

// Rule of 5 — when you manage a raw resource (rare)
class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(std::make_unique<std::byte[]>(size)), size_(size) {}

    // Copy constructor
    Buffer(const Buffer& other)
        : data_(std::make_unique<std::byte[]>(other.size_))
        , size_(other.size_) {
        std::copy_n(other.data_.get(), size_, data_.get());
    }

    // Copy assignment
    Buffer& operator=(const Buffer& other) {
        if (this != &other) {
            auto tmp = other; // copy-and-swap
            swap(tmp);
        }
        return *this;
    }

    // Move constructor
    Buffer(Buffer&&) noexcept = default;

    // Move assignment
    Buffer& operator=(Buffer&&) noexcept = default;

    // Destructor — unique_ptr handles deallocation
    ~Buffer() = default;

    void swap(Buffer& other) noexcept {
        using std::swap;
        swap(data_, other.data_);
        swap(size_, other.size_);
    }

private:
    std::unique_ptr<std::byte[]> data_;
    std::size_t size_;
};
```

### 5. noexcept and constexpr

```cpp
// noexcept — enables move optimizations; document non-throwing functions
class Vector2 {
public:
    Vector2(double x, double y) noexcept : x_(x), y_(y) {}

    [[nodiscard]] Vector2 operator+(const Vector2& other) const noexcept {
        return {x_ + other.x_, y_ + other.y_};
    }

    [[nodiscard]] double length() const noexcept {
        return std::sqrt(x_ * x_ + y_ * y_);
    }

    void swap(Vector2& other) noexcept {
        std::swap(x_, other.x_);
        std::swap(y_, other.y_);
    }

private:
    double x_, y_;
};

// constexpr — evaluated at compile time
constexpr double PI = 3.14159265358979323846;

constexpr int factorial(int n) noexcept {
    return n <= 1 ? 1 : n * factorial(n - 1);
}

static_assert(factorial(5) == 120);

constexpr std::array<int, 5> make_squares() noexcept {
    std::array<int, 5> result{};
    for (int i = 0; i < 5; ++i) result[i] = i * i;
    return result;
}
```

### 6. Structured bindings (C++17)

```cpp
#include <map>
#include <tuple>

// Iterate map with structured binding
std::map<std::string, int> scores{{"alice", 95}, {"bob", 87}};
for (const auto& [name, score] : scores) {
    std::cout << name << ": " << score << "\n";
}

// Function returning multiple values
auto parse_endpoint(std::string_view s)
    -> std::tuple<std::string, int> {
    // ...
    return {"localhost", 8080};
}

auto [host, port] = parse_endpoint("localhost:8080");

// Structured binding with if-init (C++17)
if (auto [it, inserted] = cache.emplace(key, value); !inserted) {
    it->second = value; // update existing
}
```

### 7. Ranges (C++20)

```cpp
#include <algorithm>
#include <ranges>
#include <vector>

std::vector<int> data{5, 3, 8, 1, 9, 2};

// Compose lazy views — no intermediate allocations
auto result = data
    | std::views::filter([](int x) { return x % 2 == 0; })
    | std::views::transform([](int x) { return x * x; })
    | std::views::take(3);

for (int v : result) std::cout << v << " ";

// ranges algorithms
std::ranges::sort(data);
auto it = std::ranges::find(data, 8);
bool any_neg = std::ranges::any_of(data, [](int x) { return x < 0; });
```

### 8. std::span over raw arrays

```cpp
#include <span>
#include <numeric>

// Bad — raw pointer + size (unsafe, error-prone)
double sum_bad(const double* arr, std::size_t n);

// Good — span is a non-owning view; bounds-safe
double sum(std::span<const double> data) {
    return std::reduce(data.begin(), data.end());
}

// Works with any contiguous container
std::vector<double> v{1.0, 2.0, 3.0};
std::array<double, 3> a{4.0, 5.0, 6.0};
double raw[3]{7.0, 8.0, 9.0};

sum(v);
sum(a);
sum(raw);
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `(int*)ptr` C-style cast | Bypasses type system | `static_cast`, `reinterpret_cast`, `const_cast` with justification |
| `void*` for generic code | Loses type safety | Templates or `std::any` |
| Global mutable state | Thread-unsafe, untestable | Inject dependencies via constructor |
| `using namespace std;` in headers | Pollutes all includers | Explicit `std::` prefix |
| `int arr[n]` VLA | Non-standard, stack overflow risk | `std::vector` or `std::array<T, N>` |
| `printf` / `scanf` | No type safety | `std::format` (C++20) or `std::cout` |
| Missing `[[nodiscard]]` on error returns | Silent discard of errors | Add `[[nodiscard]]` to all functions returning error codes |
| `catch (...)` swallowing all exceptions | Hides bugs | Catch specific types; rethrow or log |

## Safe Behavior

- No `new` or `delete` outside of custom RAII wrappers — use `make_unique`/`make_shared`.
- Every class either follows Rule of 0 or explicitly defines all five special members.
- All non-modifying member functions are `const`.
- All non-throwing functions are `noexcept`.
- `[[nodiscard]]` on every function that returns an error indicator or resource.
- C-style casts are compile-error-equivalent — blocked in code review.
- Headers never use `using namespace`.

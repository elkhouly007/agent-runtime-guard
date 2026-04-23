# C++ Design Patterns

Modern C++ patterns for safe, expressive, high-performance code.

## RAII Wrappers

Wrap every resource in an RAII class that acquires on construction and releases on destruction:

```cpp
class DatabaseConnection {
    PGconn* conn_;
public:
    explicit DatabaseConnection(std::string_view dsn)
        : conn_(PQconnectdb(std::string(dsn).c_str())) {
        if (PQstatus(conn_) != CONNECTION_OK) throw DatabaseError("Connection failed");
    }
    ~DatabaseConnection() { PQfinish(conn_); }
    DatabaseConnection(const DatabaseConnection&) = delete;
    DatabaseConnection& operator=(const DatabaseConnection&) = delete;
};
```

## Type Erasure

Use `std::function`, `std::any`, or custom type-erased wrappers to decouple interface from implementation without virtual dispatch overhead in hot paths.

## Policy-Based Design (Templates)

Inject behavior through template parameters for zero-overhead abstraction:

```cpp
template<typename Allocator = DefaultAllocator,
         typename Logger = NoOpLogger>
class Buffer {
    Allocator allocator_;
    Logger logger_;
public:
    Buffer() : allocator_{}, logger_{} {}
};
```

## Variant for Sum Types

Replace inheritance hierarchies with `std::variant` for closed sets of types:

```cpp
using ParseResult = std::variant<int, float, std::string, ParseError>;

std::visit(overloaded {
    [](int v)           { use_int(v); },
    [](float v)         { use_float(v); },
    [](std::string& s)  { use_string(s); },
    [](ParseError& e)   { handle_error(e); }
}, result);
```

## Expected/Result Types

Use `std::expected<T, E>` (C++23) or `tl::expected` for error handling without exceptions:

```cpp
auto result = parse_config(path);
if (!result) {
    log_error(result.error());
    return result.error();
}
use_config(*result);
```

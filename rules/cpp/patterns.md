---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.cc"
  - "**/*.hh"
  - "**/*.cxx"
  - "**/*.h"
  - "**/CMakeLists.txt"
last_reviewed: 2026-04-22
version_target: "Best Practices"
---
# C++ Patterns

> This file extends [common/patterns.md](../common/patterns.md) with C++-specific content.

## RAII (Resource Acquisition Is Initialization)

Tie resource lifetime to object lifetime:

```cpp
class FileHandle {
public:
    explicit FileHandle(const std::string& path) : file_(std::fopen(path.c_str(), "r")) {}
    ~FileHandle() { if (file_) std::fclose(file_); }
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
private:
    std::FILE* file_;
};
```

## Rule of Five / Rule of Zero

- **Rule of Zero**: prefer classes that need no custom destructor, copy/move constructors, or assignment operators
- **Rule of Five**: if you define any of destructor/copy-ctor/copy-assign/move-ctor/move-assign, define all five intentionally

## Value Semantics

- Pass small or trivial types by value
- Pass large types by `const&`
- Return by value and rely on RVO/NRVO
- Use move semantics for sink parameters

## Error Handling

- Use exceptions for exceptional conditions
- Use `std::optional` for values that may not exist
- Use `std::expected` (C++23) or a result type for expected failures

## Reference

See skill: `cpp-coding-standards` for broader C++ patterns and anti-patterns.

# C++ Security

C++-specific security rules.

## Memory Safety

- Never use raw owning pointers. Use smart pointers (`unique_ptr`, `shared_ptr`) or value types.
- Bounds-checked containers: prefer `std::vector::at()` over `operator[]` in code paths that process untrusted input (at() throws on out-of-bounds; [] is undefined behavior).
- String handling: prefer `std::string` over C-style char arrays. Never `strcpy`, `sprintf`, `gets`.
- Use `std::string_view` for non-owning string parameters to avoid buffer length errors.

## Integer Safety

- Check for integer overflow before arithmetic on untrusted inputs.
- Use `std::numeric_limits<T>::max()` for bounds checks.
- Avoid signed/unsigned comparison warnings — they indicate potential logic errors.
- `size_t` for sizes and indices; never mix signed and unsigned arithmetic.

## Input Validation

- Validate all external input sizes before allocating memory based on them.
- Never use user-supplied size parameters directly in `malloc`, `new[]`, or `std::vector::resize()` without bounds checking.
- Regex matching on untrusted strings: be aware of ReDoS (catastrophic backtracking). Use linear-time regex engines for untrusted input.

## Format String Safety

- Never pass a variable as the format string to `printf`, `fprintf`, `snprintf`. Always use a literal format string.
- Use `std::format` (C++20) or `fmt::format` for safe, modern string formatting.

## Hardening Compiler Flags

- Enable: `-Wall -Wextra -Wshadow -Wconversion`
- Address Sanitizer in testing: `-fsanitize=address,undefined`
- Undefined Behavior Sanitizer: `-fsanitize=undefined`
- Position-Independent Executable for libraries: `-fPIE -pie`

---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# C++ Security Rules

## OWASP Coverage Map

| OWASP Item | Section Below |
|------------|---------------|
| A01 Broken Access Control | Auth & Authorization |
| A02 Cryptographic Failures | Cryptography |
| A03 Injection | Command Injection, Format Strings |
| A04 Insecure Design | Memory Safety, Buffer Overflows |
| A05 Security Misconfiguration | Compiler Flags, TLS |
| A06 Vulnerable Components | Dependencies |
| A07 Auth Failures | Auth & Authorization |
| A08 Software Integrity Failures | Serialization |
| A09 Logging Failures | Secrets, Error Handling |
| A10 SSRF | Input Validation, HTTP Clients |

---

## Memory Safety

- Prefer smart pointers (`std::unique_ptr`, `std::shared_ptr`) over raw `new`/`delete`.
- Never `delete` a raw pointer that was not allocated with `new` in the same scope.
- Avoid raw arrays — use `std::vector`, `std::array`, or `std::span` (C++20).
- Use RAII: acquire resources in constructors, release in destructors.
- Use `std::optional<T>` instead of nullable pointers where semantics allow.

**BAD — manual memory, double-free risk:**
```cpp
int* arr = new int[size];
process(arr);        // exception here → memory leak
delete[] arr;
```

**GOOD — RAII via vector:**
```cpp
std::vector<int> arr(size);
process(arr);        // auto-freed on exit, even on exception
```

**BAD — raw pointer ownership confusion:**
```cpp
Widget* create() { return new Widget(); }
void use() {
    Widget* w = create();
    // who owns this? easy to double-free or leak
}
```

**GOOD — unique_ptr for clear ownership:**
```cpp
std::unique_ptr<Widget> create() {
    return std::make_unique<Widget>();
}
void use() {
    auto w = create();  // auto-freed on scope exit
}
```

---

## Buffer Overflows

**BAD — no bounds checking:**
```cpp
char buf[64];
strcpy(buf, user_input);       // overflow if input > 63 chars
sprintf(buf, "%s", user_input); // same problem
```

**GOOD — bounded and null-terminated:**
```cpp
char buf[64];
strncpy(buf, user_input, sizeof(buf) - 1);
buf[sizeof(buf) - 1] = '\0';
```

**BETTER — use std::string (no manual bounds):**
```cpp
std::string s = user_input;    // dynamic allocation, auto-managed
```

**BAD — fixed-size buffer for variable input:**
```cpp
void parse(const char* input) {
    char tmp[256];
    memcpy(tmp, input, strlen(input));  // overflow if input > 256 bytes
}
```

**GOOD — check length first:**
```cpp
void parse(const char* input) {
    const size_t len = strlen(input);
    if (len >= 256) throw std::invalid_argument("input too large");
    char tmp[256];
    memcpy(tmp, input, len);
    tmp[len] = '\0';
}
```

- Never use: `strcpy`, `strcat`, `gets`, `sprintf`, `scanf("%s")` — all lack bounds checking.
- Use their bounded equivalents: `strncpy`, `strncat`, `fgets`, `snprintf`.
- Use `std::string_view` for read-only string parameters — it carries length.

---

## Format String Vulnerabilities

**BAD — user-controlled format string:**
```cpp
printf(user_input);                      // format string attack
fprintf(log_file, user_controlled_msg);  // same risk
```

**GOOD — literal format string:**
```cpp
printf("%s", user_input);               // user_input treated as data, not format
fprintf(log_file, "%s", msg);
```

Enable compiler warning: `-Wformat-security` (GCC/Clang) — promotes format issues to errors.

---

## Integer Safety

**BAD — signed/unsigned mismatch, potential overflow:**
```cpp
int len = get_length();       // returns -1 on error
char* buf = new char[len];    // undefined behavior: cast -1 to size_t = huge number
```

**GOOD — unsigned and validated:**
```cpp
size_t len = get_length();
if (len == 0 || len > MAX_ALLOWED) throw std::runtime_error("invalid length");
auto buf = std::make_unique<char[]>(len);
```

- Prefer `std::size_t` and `std::ptrdiff_t` for sizes and offsets.
- Use `std::numeric_limits<T>` checks before arithmetic that could overflow.
- Enable `-Wsign-conversion` to catch signed/unsigned mixing.

---

## Command Injection

**BAD — shell injection via system():**
```cpp
std::string cmd = "ls " + user_dir;
system(cmd.c_str());  // attacker passes "; rm -rf /" as user_dir
```

**GOOD — exec without shell expansion:**
```cpp
// Linux/macOS — args are separate, no shell interpolation
execvp("/bin/ls", const_cast<char* const*>(args));
```

**GOOD — use subprocess library (if available):**
```cpp
// Use Boost.Process or similar — passes args as array
bp::child c("/bin/ls", user_dir, bp::std_out > out);
c.wait();
```

Never pass user input to `system()`, `popen()`, or `exec("sh", "-c", ...)`.

---

## Path Traversal

**BAD — no path validation:**
```cpp
std::string path = base_dir + "/" + user_filename;
std::ifstream file(path);  // "../../etc/passwd" traversal
```

**GOOD — canonical path check (C++17 filesystem):**
```cpp
#include <filesystem>
namespace fs = std::filesystem;

fs::path safe_path(const fs::path& base, const std::string& user_input) {
    fs::path requested = fs::canonical(base / user_input);
    if (!requested.string().starts_with(fs::canonical(base).string() + "/")) {
        throw std::runtime_error("path traversal detected");
    }
    return requested;
}
```

---

## Input Validation

- Validate all external inputs at the boundary before any processing.
- Sanitize file paths: resolve canonical path and check against base directory.
- Validate string lengths before copying into fixed-size buffers.
- Validate binary protocol fields (lengths, offsets, counts) before use.

---

## Cryptography

- Use `libsodium` or OpenSSL for cryptographic operations — not custom implementations.
- Use `RAND_bytes()` (OpenSSL) or `randombytes_buf()` (libsodium) for secure random values — not `rand()`.
- Password hashing: use `crypto_pwhash` (libsodium / Argon2) or `bcrypt` — never MD5 or SHA-1 for passwords.
- Minimum TLS: 1.2 in production; prefer 1.3.

**BAD — rand() for security:**
```cpp
srand(time(nullptr));
int token = rand();  // predictable — same seed = same sequence
```

**GOOD — libsodium secure random:**
```cpp
#include <sodium.h>
uint8_t token[32];
randombytes_buf(token, sizeof(token));
```

**GOOD — Argon2 password hash:**
```cpp
#include <sodium.h>
char hash[crypto_pwhash_STRBYTES];
if (crypto_pwhash_str(hash, password, strlen(password),
    crypto_pwhash_OPSLIMIT_INTERACTIVE,
    crypto_pwhash_MEMLIMIT_INTERACTIVE) != 0) {
    // out of memory
}
```

---

## Undefined Behavior

- Enable sanitizers in CI: `-fsanitize=address,undefined` (AddressSanitizer + UBSan).
- Never dereference a null pointer — check before use.
- Never access memory after `free`/`delete` or out of bounds — use ASan/valgrind to detect.
- Signed integer overflow is undefined — use unsigned types or checked arithmetic.
- Enable `-fstack-protector-strong` in production builds.

**Compiler security flags (GCC/Clang):**
```bash
-Wall -Wextra -Wshadow -Wconversion -Wformat-security
-Wsign-conversion -Wnull-dereference
-D_FORTIFY_SOURCE=2 -fstack-protector-strong
-pie -fPIE                        # position-independent executable
-Wl,-z,relro,-z,now               # linker hardening (Linux)
```

---

## Serialization and Parsing

- Validate all deserialized data length fields before allocating memory.
- Use schema-based serialization (protobuf, flatbuffers, capnproto) for external data — not custom binary parsers.
- If parsing binary formats manually, use a fuzzer (libFuzzer, AFL++) to find edge cases.
- Reject inputs that exceed expected size bounds before parsing.

**GOOD — protobuf instead of custom binary:**
```cpp
// schema enforces types and sizes
UserRequest request;
if (!request.ParseFromArray(data, length)) {
    return error("invalid protobuf");
}
```

---

## Dependencies

- Run `clang-tidy` and `cppcheck` in CI.
- Use a package manager with a lockfile (`vcpkg`, `conan`) — pin versions.
- Keep OpenSSL, libsodium, and protobuf updated — security patches are critical.
- Audit transitive dependencies for known CVEs.

**Tooling commands:**
```bash
clang-tidy -checks="*,-readability-*" src/*.cpp -- -std=c++17
cppcheck --enable=all --suppress=missingInclude src/
valgrind --tool=memcheck ./binary            # memory errors
./binary &  # then:
address-sanitizer output (build with -fsanitize=address)
AFL_FUZZ_BUILD=1 make && afl-fuzz -i in/ -o out/ ./binary @@
```

---

## Anti-Patterns Table

| Anti-Pattern | Why It's Dangerous | Fix |
|-------------|-------------------|-----|
| `strcpy(buf, user_input)` | Buffer overflow | `strncpy` or `std::string` |
| `printf(user_input)` | Format string attack | `printf("%s", user_input)` |
| `system("cmd " + user_input)` | Command injection | `execvp` with separate args |
| `rand()` for security | Predictable | `RAND_bytes()` / `randombytes_buf()` |
| `new T[len]` without length check | Heap overflow | Validate `len` first |
| Raw pointer ownership | Double-free / use-after-free | `std::unique_ptr` / `shared_ptr` |
| `int` for sizes/lengths | Signed overflow, UB | `size_t` / `std::size_t` |
| Custom crypto | Implementation bugs | Use libsodium / OpenSSL |
| No `-fsanitize` in CI | Silent UB and memory bugs | Enable ASan + UBSan in CI builds |
| Binary parsing without fuzzing | Parsing vulnerabilities | Add libFuzzer / AFL++ target |

---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# C++ + ARG Hooks

C++-specific ARG hook considerations.

## Build System Commands

C++ build commands that may trigger ARG:
- `make install` writing to system directories
- CMake `install()` targets that deploy to system paths
- `sudo ldconfig` after installing shared libraries
- Cross-compilation toolchain downloads and executions

## Compiler and Linker Behavior

C++ builds invoke compilers and linkers that may write to many locations:
- Build artifacts in system `lib` or `bin` directories should trigger review
- `pkg-config --libs` may reveal library paths that indicate system-wide dependencies
- Sanitizer builds may write instrumented binaries to unusual locations

## Memory Debugging Tools

Commands involving memory analysis tools that may trigger ARG:
- `valgrind ./program` on code reading sensitive files
- `heaptrack` and similar tools that trace all allocations
- Core dump generation (`ulimit -c unlimited`) in environments with sensitive process memory

## Sensitive Compilation Targets

Be aware when compiling code that:
- Links against system security libraries (OpenSSL, libcrypto)
- Implements cryptographic primitives
- Accesses system resources (/proc, /dev)

These are legitimate operations but may warrant additional review before execution in shared environments.

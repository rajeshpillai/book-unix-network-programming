# Zig Implementation Details: Daytime TCP Client

This document details the technical decisions, caveats, and Zig-specific patterns used in the `daytimetcpcli.zig` implementation.

## 1. Overview
The implementation uses Zig's `std.posix` namespace to interact with system sockets directly, mirroring the C implementation's use of BSD sockets but with Zig's safety features and error handling.

## 2. Implementation Notes & Caveats

### Manual `sockaddr_in` Definition
**Why:**
In the specific Zig version being used, standard networking types like `sockaddr_in` were either moved, missing from the exposed `std.posix` / `std.net` namespace, or had different internal structures than expected for a direct raw socket port.

**Solution:**
We manually defined a compatible `extern struct` to match the C ABI for `struct sockaddr_in`:
```zig
const sockaddr_in = extern struct {
    family: posix.sa_family_t,
    port: u16,
    addr: u32,
    zero: [8]u8 = [_]u8{0} ** 8,
};
```
*Tip:* `extern struct` guarantees C-compatible memory layout, which is critical when passing pointers to syscalls like `connect`.

### Manual IPv4 Parsing (`parseIp4`)
**Why:**
Similar to `sockaddr_in`, `std.net.Ip4Address.parse` was not readily available in the expected path or lacked a direct way to return a raw `u32` compatible with our manual struct without pulling in other dependencies.

**Solution:**
A custom `parseIp4` function was written to:
1.  Split the string by dots (`.`).
2.  Parse each segment as a `u8`.
3.  Bit-cast the resulting `[4]u8` array to a `u32`.
*Note:* This relies on the fact that `connect` expects the address in Network Byte Order (Big Endian). The raw bytes `[127, 0, 0, 1]` effectively map to the correct memory representation regardless of host endianness when treated as a byte array, assuming we just want to preserve the wire format.

### Namespace: `std.posix`
**Why:**
Zig is transitioning its standard library. Older tutorials might reference `std.os`, but modern Zig uses `std.posix` for standard POSIX definitions.
*   **Constants**: Constants like `AF_INET` are now found under strict enums or namespaces like `posix.AF.INET` and `posix.SOCK.STREAM`.
*   **Functions**: `socket`, `connect`, `read`, `write`, `close` are all available in `std.posix` and map directly to syscalls or libc wrappers.

### Pointer Casting (`@ptrCast`)
**Why:**
The `connect` syscall expects a `*const sockaddr`. Our variable is `sockaddr_in`.
**How:**
```zig
posix.connect(fd, @ptrCast(&addr), @sizeOf(sockaddr_in))
```
We take the address of our struct (`&addr`) and cast it to the opaque pointer type expected by `connect`. Zig's `@ptrCast` is explicit to prevent accidental unsafe type conversions.

### Error Handling
**Pattern:**
```zig
const n = posix.read(...) catch |e| die("read error", e);
```
Zig forces you to handle potential errors.
*   **`try`**: usage propagates errors up.
*   **`catch`**: allows handling errors locally. Here we catch errors to print a message and exit, mimicking the `err_sys` function from the book.

## 3. Comparison with C
| Feature | C Implementation | Zig Implementation |
| :--- | :--- | :--- |
| **Headers** | `<sys/socket.h>`, `<arpa/inet.h>` | `@import("std").posix` |
| **Error Handling** | Checking return codes (`< 0`) + `errno` | `catch` blocks on function calls |
| **Cleanup** | Manual `close()` at end | `defer posix.close(fd)` immediately after creation |
| **String Parsing** | `inet_pton` | Custom `parseIp4` (or `std.net` in full stdlib) |

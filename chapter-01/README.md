# Chapter 01: Introduction

## 1.1 Introduction
This chapter introduces a simple **Daytime Client** and **Daytime Server**. The client connects to a server and prints the current time and date returned by the server.

## Examples

### 1. TCP Daytime Client (`daytimetcpcli`)

A formatted TCP client that connects to a specified IP address on port 13 (Daytime Protocol) or our custom testing port (1313).

#### Build (C)
```bash
gcc -Wall -Wextra -Wpedantic -std=c11 -g daytimetcpcli.c -o daytimetcpcli
```

#### Run
The client expects an IP address as an argument.

**1. Start a mock server (using ncat):**
In a separate terminal, run:
```bash
# Listen on port 1313 and send a string when a client connects
printf "Tue Jan  9 12:00:00 2026\n" | ncat -l 1313
```

**2. Run the client:**
```bash
./daytimetcpcli 127.0.0.1
```
*(Note: If the C code is hardcoded to port 13, you might need to run `ncat` with `sudo` on port 13 or change the code to port 1313).*

---
*Zig implementation coming soon.*

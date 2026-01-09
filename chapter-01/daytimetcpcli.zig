// Compile: zig build-exe daytimetcpcli.zig 
// RUN: ./daytimetcpcli 127.0.0.1 

const std = @import("std");
const posix = std.posix;


fn die(comptime msg: []const u8, err: anytype) noreturn {
    std.debug.print("{s}: {s}\n", .{msg, @errorName(err)});
    std.process.exit(1);
}

// Manual definition since std.net/posix.sockaddr_in is missing/moved
const sockaddr_in = extern struct {
    family: posix.sa_family_t,
    port: u16, // in_port_t
    addr: u32, // in_addr
    zero: [8]u8 = [_]u8{0} ** 8,
};

pub fn main() void {

    const args = std.process.argsAlloc(std.heap.page_allocator) catch unreachable;
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len != 2) {
        die("usage: ./daytimetcpcli <IPaddresss>", error.InvalidArgument);
    }

    // Create TCP socket
    const fd = posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0) catch |err| {
        die("socket error", err);
    };
    defer posix.close(fd); 

    // Convert dotted-decimal string to binary IPv4 
    const ip_u32 = parseIp4(args[1]) catch |err| {
         die("inet_pton/parse error (custom)\n", err);
    };
    
    // Connect 
    var addr: sockaddr_in = .{
        .family = posix.AF.INET,
        .port = std.mem.nativeToBig(u16, 1313),
        .addr = ip_u32,
    };
    
    posix.connect(fd, @ptrCast(&addr), @sizeOf(sockaddr_in))
        catch |e| die("connect error", e);

    // Read loop until EOF
    var buf: [4096]u8 = undefined;
    while(true) {
        const n = posix.read(fd, &buf) catch |e| die("read error", e);
        if (n == 0) break;
        
        _ = posix.write(posix.STDOUT_FILENO, buf[0..n]) catch {};
    }
}

fn parseIp4(s: []const u8) !u32 {
    var iter = std.mem.splitScalar(u8, s, '.');
    var bytes: [4]u8 = undefined;
    var i: usize = 0;
    while (iter.next()) |part| : (i += 1) {
        if (i >= 4) return error.InvalidIp;
        bytes[i] = std.fmt.parseInt(u8, part, 10) catch return error.InvalidIp;
    }
    if (i != 4) return error.InvalidIp;
    return @as(u32, @bitCast(bytes));
}
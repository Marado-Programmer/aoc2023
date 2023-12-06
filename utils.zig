const std = @import("std");
const ArrayList = std.ArrayList;

pub fn lines(allocator: std.mem.Allocator, str: *ArrayList(u8), file: []const u8) !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    try fileToStr(str, file);
    //try fileToStr(str, args[1]);
}

pub fn atoi(comptime T: type, str: []const u8) T {
    var sum: T = 0;
    for (str) |v| {
        sum *= 10;
        sum += v - '0';
    }
    return sum;
}

pub fn fileToStr(str: *ArrayList(u8), name: []const u8) !void {
    const file = try std.fs.cwd().openFile(name, .{});
    defer file.close();

    var buf: [0x400]u8 = undefined;
    try file.seekTo(0);
    while (true) {
        const bytes_read = try file.readAll(&buf);
        defer buf = undefined;
        try str.appendSlice(buf[0..bytes_read]);
        if (bytes_read != buf.len) {
            break;
        }
    }
}

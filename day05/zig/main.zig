const std = @import("std");

pub fn main() !void {
    const out = std.io.getStdOut();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("MEMORY LEAK");
    }

    var str = std.ArrayList(u8).init(allocator);
    defer str.deinit();

    try fileToStr(&str, "./test.in");
    //try fileToStr(&str, "./test2.in");
    //try fileToStr(&str, "./puzzle.in");
    var in = str.items;
    var lines = std.mem.split(u8, in, "\n");

    var seeds = std.ArrayList(u64).init(allocator);
    defer seeds.deinit();
    var check = std.AutoHashMap(usize, bool).init(allocator);
    defer check.deinit();

    var n: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (seeds.items.len == 0) {
            var s = std.mem.split(u8, line, " ");
            _ = s.next();
            var c: u64 = 0;
            while (s.next()) |seed| {
                var range = numStrToUInt(s.next().?);
                while (range >= 0) : (range -= 1) {
                    try seeds.append(numStrToUInt(seed) + range - 1);
                    try check.put(c, false);
                    c += 1;
                    if (range == 0) {
                        break;
                    }
                }
                //try seeds.append(numStrToUInt(seed));
                //try check.put(c, false);
            }

            _ = lines.next();
            _ = lines.next();
        } else {
            var s = std.mem.split(u8, line, " ");
            var t = s.next().?;
            if (t[0] < '0' or t[0] > '9') {
                var iter = check.iterator();
                while (iter.next()) |v| {
                    try check.put(v.key_ptr.*, false);
                }
                n += 1;
                continue;
            }
            var destination = numStrToUInt(t);
            var source = numStrToUInt(s.next().?);
            var range = numStrToUInt(s.next().?);

            var next = std.ArrayList(u64).init(allocator);
            defer next.deinit();
            for (seeds.items, 0..) |value, i| {
                if (source <= value and value < (source + range) and !check.get(i).?) {
                    try next.append(destination + (value - source));
                    try check.put(i, true);
                } else {
                    try next.append(value);
                }
            }

            seeds.clearAndFree();

            try seeds.appendSlice(next.items);
        }
    }

    var min: u64 = std.math.maxInt(u64);
    for (seeds.items) |value| {
        min = @min(min, value);
    }

    try out.writer().print("min:\t{d}\n", .{min});
}

fn numStrToUInt(str: []const u8) u64 {
    var sum: u64 = 0;
    for (str, 0..) |v, i| {
        sum += (v - '0') * std.math.pow(u64, 10, @as(u64, @intCast(str.len - i - 1)));
    }
    return sum;
}

fn fileToStr(str: *std.ArrayList(u8), name: []const u8) !void {
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

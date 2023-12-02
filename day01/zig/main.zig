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

    //try fileToStr(&str, "./test.in");
    //try fileToStr(&str, "./test2.in");
    try fileToStr(&str, "./puzzle.in");
    var in = str.items;
    var lines = std.mem.split(u8, in, "\n");

    const extendo_nums = [_]([]const u8){ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var sum: u64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var first: ?u8 = null;
        var second: ?u8 = null;

        var extendo = std.ArrayList(u8).init(allocator);
        defer extendo.deinit();
        chars: for (line) |i| {
            if (i >= '0' and i <= '9') {
                extendo.clearAndFree();
                if (first == null) {
                    first = i - '0';
                } else {
                    second = i - '0';
                }
            } else {
                try extendo.append(i);

                for (extendo_nums, 0..) |num, j| {
                    const k: u8 = @intCast(j);
                    if (std.mem.eql(u8, num, extendo.items)) {
                        if (first == null) {
                            first = k + 1;
                        } else {
                            second = k + 1;
                        }

                        var old = std.ArrayList(u8).init(allocator);
                        defer old.deinit();

                        for (extendo.items, 0..) |value, l| {
                            if (l == 0) {
                                continue;
                            }

                            try old.append(value);
                        }

                        extendo.clearAndFree();
                        try extendo.appendSlice(old.items);
                        continue :chars;
                    }
                }

                while (extendo.items.len > 1) {
                    var possible = false;
                    possibilities: for (extendo_nums) |num| {
                        var k: usize = 1;
                        while (k < num.len) : (k += 1) {
                            if (std.mem.eql(u8, num[0..k], extendo.items)) {
                                possible = true;
                                break :possibilities;
                            }
                        }
                    }

                    if (!possible) {
                        var old = std.ArrayList(u8).init(allocator);
                        defer old.deinit();

                        for (extendo.items, 0..) |value, j| {
                            if (j == 0) {
                                continue;
                            }

                            try old.append(value);
                        }

                        extendo.clearAndFree();
                        try extendo.appendSlice(old.items);
                    } else {
                        break;
                    }
                }
            }
        }

        if (second == null) {
            second = first.?;
        }

        //try out.writer().print("first:\t{d}\nsecond:\t{d}\n", .{ first.?, second.? });
        try out.writer().print("{d}\n", .{first.? *% 10 +% second.?});

        sum += first.? *% 10 +% second.?;
    }

    try out.writer().print("sum:\t{d}\n", .{sum});
}

fn fileToStr(str: *std.ArrayList(u8), name: []const u8) !void {
    const test_file = try std.fs.cwd().openFile(name, .{});
    defer test_file.close();

    var buf: [0x400]u8 = undefined;
    try test_file.seekTo(0);
    while (true) {
        const bytes_read = try test_file.readAll(&buf);
        defer buf = undefined;
        try str.appendSlice(buf[0..bytes_read]);
        if (bytes_read != buf.len) {
            break;
        }
    }
}

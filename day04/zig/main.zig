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
    var map = std.AutoHashMap(usize, u32).init(allocator);
    defer map.deinit();

    var sum: u32 = 0;
    var scratches: u32 = 0;
    var last_id: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var parts = std.mem.split(u8, line, ": ");
        var id_part = std.mem.split(u8, parts.next().?, " ");
        _ = id_part.next();
        var id_str = id_part.next().?;
        while (id_part.next()) |s| {
            if (std.mem.eql(u8, s, "")) {
                continue;
            }
            id_str = s;
        }
        var id: usize = numStrToUInt(id_str);
        try out.writer().print("{d}\n", .{id});
        last_id = id;
        parts = std.mem.split(u8, parts.next().?, " | ");
        var winning_numbers_str = std.mem.split(u8, parts.next().?, " ");
        var winning_numbers = std.ArrayList(u32).init(allocator);
        defer winning_numbers.deinit();
        while (winning_numbers_str.next()) |number| {
            if (std.mem.eql(u8, number, "")) {
                continue;
            }
            try winning_numbers.append(numStrToUInt(number));
        }

        var numbers = std.mem.split(u8, parts.next().?, " ");

        var c: u8 = 0;
        while (numbers.next()) |number| {
            var n = numStrToUInt(number);

            for (winning_numbers.items) |v| {
                if (n == v) {
                    c += 1;
                    break;
                }
            }
        }

        if (c > 0) {
            //try out.writer().print("pow:\t{d}\n", .{std.math.pow(u32, 2, c - 1)});
            sum += std.math.pow(u32, 2, c - 1);
        }

        if (map.get(id) == null) {
            try map.put(id, 1);
        }

        var times = map.get(id).?;
        while (c > 0) : (c -= 1) {
            if (map.get(id + c)) |v| {
                try map.put(id + c, v + times);
            } else {
                try map.put(id + c, 1 + times);
            }
        }
    }

    var iter = map.iterator();
    while (iter.next()) |value| {
        try out.writer().print("id:\t{d}\ttimes:\t{d}\n", .{ value.key_ptr.*, value.value_ptr.* });
        if (value.key_ptr.* <= last_id) {
            scratches += value.value_ptr.*;
        }
    }

    try out.writer().print("sum:\t{d}\n", .{sum});
    try out.writer().print("scratches:\t{d}\n", .{scratches});
}

fn numStrToUInt(str: []const u8) u32 {
    var sum: u32 = 0;
    for (str, 0..) |v, i| {
        sum += (v - '0') * std.math.pow(u32, 10, @as(u32, @intCast(str.len - i - 1)));
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

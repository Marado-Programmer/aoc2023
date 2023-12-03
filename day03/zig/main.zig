const std = @import("std");

const Vec = struct {
    x: usize,
    y: usize,
};

const Possible = struct {
    val: u32,
    x: usize,
    y: usize,
    size: usize,
    fn close(self: *const Possible, v: Vec) bool {
        return ((if (self.x > 0) self.x - 1 else 0) <= v.x) and
            (v.x <= (self.x + self.size)) and
            ((if (self.y > 0) self.y - 1 else 0) <= v.y) and
            (v.y <= (self.y + 1));
    }
};

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

    var nums = std.ArrayList(Possible).init(allocator);
    defer nums.deinit();
    var cur_num = std.ArrayList(u8).init(allocator);
    defer cur_num.deinit();
    var valid = std.ArrayList(Vec).init(allocator);
    defer valid.deinit();
    var gears = std.ArrayList(Vec).init(allocator);
    defer gears.deinit();

    var y: usize = 0;
    while (lines.next()) |line| : (y += 1) {
        if (line.len == 0) {
            continue;
        }

        for (line, 0..) |value, x| {
            if ('0' <= value and value <= '9') {
                try cur_num.append(value);
            } else {
                if (cur_num.items.len != 0) {
                    try nums.append(Possible{ .val = numStrToUInt(cur_num.items), .x = x -% cur_num.items.len, .y = y, .size = cur_num.items.len });
                }

                cur_num.clearAndFree();
                switch (value) {
                    '.' => {},
                    '*' => {
                        try valid.append(Vec{ .x = x, .y = y });
                        try gears.append(Vec{ .x = x, .y = y });
                    },
                    else => try valid.append(Vec{ .x = x, .y = y }),
                }
            }
        }

        if (cur_num.items.len != 0) {
            try nums.append(Possible{ .val = numStrToUInt(cur_num.items), .x = (line.len - 1) -% cur_num.items.len, .y = y, .size = cur_num.items.len });
        }

        cur_num.clearAndFree();
    }

    var sum: u64 = 0;
    for (nums.items) |value| {
        var v = false;

        for (valid.items) |i| {
            //try out.writer().print("area:\n\t{}\t{}\n\t{}\t{}\n", .{ value.x -% 1, value.x +% value.size, value.y -% 1, value.y +% 1 });
            //try out.writer().print("point:\t{}\t{}\n", .{ i.x, i.y });
            if (value.close(i)) {
                v = true;
                break;
            }
        }

        if (v) {
            sum += value.val;
        }
    }

    try out.writer().print("sum:\t{d}\n", .{sum});

    var gears_sum: u64 = 0;
    for (gears.items) |gear| {
        var mult: u64 = 1;
        var counter: u64 = 0;

        for (nums.items) |n| {
            if (n.close(gear)) {
                counter += 1;
                mult *= n.val;
            }
        }

        if (counter >= 2) {
            gears_sum += mult;
        }
    }
    try out.writer().print("sum:\t{d}\n", .{gears_sum});
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

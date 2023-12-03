const std = @import("std");

const MAX_RED = 12;
const MAX_GREEN = 13;
const MAX_BLUE = 14;
const Subset = struct {
    red: ?u32 = null,
    green: ?u32 = null,
    blue: ?u32 = null,

    fn valid(self: *Subset) bool {
        return (self.red orelse 0) <= MAX_RED and (self.green orelse 0) <= MAX_GREEN and (self.blue orelse 0) <= MAX_BLUE;
    }
    fn power(self: *Subset) u32 {
        return (self.red orelse 0) * (self.green orelse 0) * (self.blue orelse 0);
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

    var sum: u32 = 0;
    var power: u32 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var parts = std.mem.split(u8, line, ": ");
        var game_id = parts.first();
        var subsets = std.mem.split(u8, parts.next().?, "; ");

        var game_subset = Subset{};

        while (subsets.next()) |subset| {
            var colors = std.mem.split(u8, subset, ", ");
            while (colors.next()) |color| {
                var colors_parts = std.mem.split(u8, color, " ");
                var amount = numStrToUInt(colors_parts.next().?);
                var name = colors_parts.next().?;

                if (std.mem.eql(u8, name, "red") and game_subset.red orelse 0 < amount) {
                    game_subset.red = amount;
                } else if (std.mem.eql(u8, name, "green") and game_subset.green orelse 0 < amount) {
                    game_subset.green = amount;
                } else if (std.mem.eql(u8, name, "blue") and game_subset.blue orelse 0 < amount) {
                    game_subset.blue = amount;
                }
            }
        }

        if (game_subset.valid()) {
            var game_info = std.mem.split(u8, game_id, " ");
            _ = game_info.next();
            var id = game_info.next().?;
            sum += numStrToUInt(id);
        }

        power += game_subset.power();
    }

    try out.writer().print("sum:\t{d}\n", .{sum});
    try out.writer().print("power:\t{d}\n", .{power});
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

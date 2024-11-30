const std = @import("std");
const graph = @import("./graph.zig");
const part2 = @import("./part_2.zig").part2;

fn part1(g: *graph.Graph) u64 {
    var counter: usize = 1;
    g.walk();
    while (g.cur[0] != g.cur[1]) : (counter += 1) {
        g.walk();
    }
    return counter;
}

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("TEST FAIL");
    }

    var g = try graph.Graph.fromFile(allocator, "../test5.in");
    defer g.deinit(allocator);

    //try stdout.writeIntNative(u64, part1(&g));
    //try stdout.print("{d}", .{part1(&g)});
    try stdout.print("{d}", .{try part2(allocator, &g)});

    try bw.flush();
}

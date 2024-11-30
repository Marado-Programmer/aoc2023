const std = @import("std");
const Queue = @import("./queue.zig").Queue;
const graph = @import("./graph.zig");

const State = enum { connected_pipe, inside, outside };

const Node = union(State) { connected_pipe: u8, inside, outside };

fn nodeType(neighbors: graph.Neighbors) Node {
    if (neighbors.north == null or neighbors.south == null or neighbors.east == null or neighbors.west == null) {
        return Node.outside;
    }

    var possibilities: u6 = 0b111111;
    const vertical_bar = 1 << 5;
    const hyphen = 1 << 4;
    const L = 1 << 3;
    const J = 1 << 2;
    const seven = 1 << 1;
    const F = 1;

    const north = neighbors.north.?;
    const south = neighbors.south.?;
    const east = neighbors.east.?;
    const west = neighbors.west.?;
    if (north != '|' and north != '7' and north != 'F') {
        possibilities &= ~@as(u6, vertical_bar | L | J);
    }
    if (south != '|' and south != 'L' and south != 'J') {
        possibilities &= ~@as(u6, vertical_bar | seven | F);
    }
    if (east != '-' and east != 'J' and east != '7') {
        possibilities &= ~@as(u6, hyphen | L | F);
    }
    if (west != '-' and west != 'L' and west != 'F') {
        possibilities &= ~@as(u6, hyphen | J | seven);
    }

    return if (possibilities & vertical_bar == vertical_bar)
        Node{ .connected_pipe = '|' }
    else if (possibilities & hyphen == hyphen)
        Node{ .connected_pipe = '-' }
    else if (possibilities & L == L)
        Node{ .connected_pipe = 'L' }
    else if (possibilities & J == J)
        Node{ .connected_pipe = 'J' }
    else if (possibilities & seven == seven)
        Node{ .connected_pipe = '7' }
    else if (possibilities & F == F)
        Node{ .connected_pipe = 'F' }
    else {
        unreachable;
    };
}

fn nodeTypeFromKnown(allocator: std.mem.Allocator, pos: usize, known: []?Node, g: graph.Graph) !?Node {
    var visited = try allocator.alloc(bool, known.len);
    defer allocator.free(visited);

    visited[pos] = true;

    var q = Queue(usize).init(allocator);
    defer q.deinit();

    try enqueueAround(pos, &q, visited, g);

    find: while (q.dequeue()) |i| {
        if (known[i]) |node| {
            switch (node) {
                .outside => return .outside,
                .inside => return .inside,
                else => continue :find,
            }
        }

        visited[i] = true;
        try enqueueAround(i, &q, visited, g);
    }

    return null;
}

fn enqueueAround(pos: usize, q: *Queue(usize), visited: []bool, g: graph.Graph) !void {
    if (g.get(pos - g.width()) != null and visited[pos - g.width()] == false) {
        try q.enqueue(pos - g.width());
    }
    if (g.get(pos + g.width()) != null and visited[pos + g.width()] == false) {
        try q.enqueue(pos + g.width());
    }
    if (g.get(pos + 1) != null and visited[pos + 1] == false) {
        try q.enqueue(pos + 1);
    }
    if (g.get(pos - 1) != null and visited[pos - 1] == false) {
        try q.enqueue(pos - 1);
    }
}

pub fn part2(allocator: std.mem.Allocator, g: *graph.Graph) !u64 {
    var state = try allocator.alloc(?Node, g.length());
    defer allocator.free(state);

    state[0] = nodeType(try g.getAround(0));
    var i: usize = 1;
    while (i < g.length()) : (i += 1) {
        state[i] = try nodeTypeFromKnown(allocator, i, state, g.*) orelse nodeType(try g.getAround(i));
    }

    var y: usize = 0;
    var x: usize = 0;
    while (y < g.height()) : (y += 1) {
        while (x < g.width()) : (x += 1) {
            if (state[g.height() * y + x]) |v| {
                switch (v) {
                    .connected_pipe => |pipe| std.debug.print("{s}", .{[_]u8{pipe}}),
                    .outside => std.debug.print("O", .{}),
                    .inside => std.debug.print("I", .{}),
                }
            } else {
                std.debug.print("?", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    return 0;
}

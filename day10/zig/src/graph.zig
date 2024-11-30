const std = @import("std");

const Direction = enum { north, south, east, west };
pub const Neighbors = struct { north: ?u8 = null, south: ?u8 = null, east: ?u8 = null, west: ?u8 = null };

pub const Graph = struct {
    nodes: []u8,
    stride: usize,
    start: usize,
    cur: [2]usize,
    dir: [2]Direction = undefined,

    pub fn fromFile(allocator: std.mem.Allocator, name: []const u8) !Graph {
        const file = try std.fs.cwd().openFile(name, .{});
        defer file.close();

        const len = try file.getEndPos();

        const reader = file.reader();

        try reader.context.seekTo(0);
        try reader.skipUntilDelimiterOrEof('\n');
        const stride = try reader.context.getPos();

        try reader.skipUntilDelimiterOrEof('S');
        const start = try reader.context.getPos() - 1;

        try reader.context.seekTo(0);
        var buf = try reader.readAllAlloc(allocator, len);

        var graph = Graph{ .nodes = buf, .start = start, .cur = [2]usize{ start, start }, .stride = stride };

        graph.nodes[start] = findInitPipe(try graph.getAround(start));

        std.debug.print("\n\n###{}###\n\n", .{try graph.getAround(start)});
        std.debug.print("\n\n###{s}###\n\n", .{[_]u8{graph.nodes[start]}});

        graph.dir = pipeDirections(graph.nodes[start]);

        return graph;
    }

    pub fn walk(self: *Graph) void {
        self.cur[0] = switch (self.nodes[self.cur[0]]) {
            '|' => switch (self.dir[0]) {
                .north => self.cur[0] - self.stride,
                .south => self.cur[0] + self.stride,
                else => unreachable,
            },
            '-' => switch (self.dir[0]) {
                .east => self.cur[0] + 1,
                .west => self.cur[0] - 1,
                else => unreachable,
            },
            'L' => switch (self.dir[0]) {
                .north => self.cur[0] - self.stride,
                .east => self.cur[0] + 1,
                else => unreachable,
            },
            'J' => switch (self.dir[0]) {
                .north => self.cur[0] - self.stride,
                .west => self.cur[0] - 1,
                else => unreachable,
            },
            '7' => switch (self.dir[0]) {
                .south => self.cur[0] + self.stride,
                .west => self.cur[0] - 1,
                else => unreachable,
            },
            'F' => switch (self.dir[0]) {
                .south => self.cur[0] + self.stride,
                .east => self.cur[0] + 1,
                else => unreachable,
            },
            else => unreachable,
        };

        self.cur[1] = switch (self.nodes[self.cur[1]]) {
            '|' => switch (self.dir[1]) {
                .north => self.cur[1] - self.stride,
                .south => self.cur[1] + self.stride,
                else => unreachable,
            },
            '-' => switch (self.dir[1]) {
                .east => self.cur[1] + 1,
                .west => self.cur[1] - 1,
                else => unreachable,
            },
            'L' => switch (self.dir[1]) {
                .north => self.cur[1] - self.stride,
                .east => self.cur[1] + 1,
                else => unreachable,
            },
            'J' => switch (self.dir[1]) {
                .north => self.cur[1] - self.stride,
                .west => self.cur[1] - 1,
                else => unreachable,
            },
            '7' => switch (self.dir[1]) {
                .south => self.cur[1] + self.stride,
                .west => self.cur[1] - 1,
                else => unreachable,
            },
            'F' => switch (self.dir[1]) {
                .south => self.cur[1] + self.stride,
                .east => self.cur[1] + 1,
                else => unreachable,
            },
            else => unreachable,
        };

        self.dir = [2]Direction{ pipeDirection(self.nodes[self.cur[0]], self.dir[0]), pipeDirection(self.nodes[self.cur[1]], self.dir[1]) };
    }

    pub fn get(self: Graph, pos: usize) ?u8 {
        const i: isize = @intCast(pos + (std.math.divFloor(usize, pos, self.width()) catch 0));
        return if (i >= self.nodes.len or i < 0) null else self.nodes[@as(usize, @intCast(i))];
    }

    pub fn length(self: Graph) usize {
        return self.nodes.len - self.nodes.len / self.stride;
    }

    pub fn width(self: Graph) usize {
        return self.stride - 1;
    }

    pub fn height(self: Graph) usize {
        return self.nodes.len / self.stride;
    }

    pub fn getAround(self: Graph, pos: usize) !Neighbors {
        const i: isize = @intCast(pos + try std.math.divFloor(usize, pos, self.stride - 1));

        var ret = Neighbors{};

        const ni = i - @as(isize, @intCast(self.stride));
        if (ni < self.nodes.len and ni >= 0) ret.north = self.nodes[@as(usize, @intCast(ni))];
        const si = i + @as(isize, @intCast(self.stride));
        if (si < self.nodes.len and si >= 0) ret.north = self.nodes[@as(usize, @intCast(si))];
        const ei = i + 1;
        if (ei < self.nodes.len and ei >= 0) ret.north = self.nodes[@as(usize, @intCast(ei))];
        const wi = i - 1;
        if (wi < self.nodes.len and wi >= 0) ret.north = self.nodes[@as(usize, @intCast(wi))];

        return ret;
    }

    pub fn deinit(self: Graph, allocator: std.mem.Allocator) void {
        allocator.free(self.nodes);
    }
};

fn findInitPipe(neighbors: Neighbors) u8 {
    var possibilities: u7 = 0b1111111;
    const vertical_bar = 1 << 6;
    const hyphen = 1 << 5;
    const L = 1 << 4;
    const J = 1 << 3;
    const seven = 1 << 2;
    const F = 1 << 1;
    const dot = 1;

    const north = neighbors.north;
    const south = neighbors.south;
    const east = neighbors.east;
    const west = neighbors.west;

    if (north == null or (north != '|' and north != '7' and north != 'F')) {
        std.debug.print("1\n", .{});
        possibilities &= ~@as(u7, vertical_bar | L | J);
    }
    if (south == null or (south != '|' and south != 'L' and south != 'J')) {
        std.debug.print("2\n", .{});
        possibilities &= ~@as(u7, vertical_bar | seven | F);
    }
    if (east == null or (east != '-' and east != 'J' and east != '7')) {
        std.debug.print("3\n", .{});
        possibilities &= ~@as(u7, hyphen | L | F);
    }
    if (west == null or (west != '-' and west != 'L' and west != 'F')) {
        std.debug.print("4\n", .{});
        possibilities &= ~@as(u7, hyphen | J | seven);
    }

    return if (possibilities & vertical_bar == vertical_bar)
        '|'
    else if (possibilities & hyphen == hyphen)
        '-'
    else if (possibilities & L == L)
        'L'
    else if (possibilities & J == J)
        'J'
    else if (possibilities & seven == seven)
        '7'
    else if (possibilities & F == F)
        'F'
    else if (possibilities & dot == dot)
        '.'
    else
        unreachable;
}

fn pipeDirections(pipe: u8) [2]Direction {
    return switch (pipe) {
        '|' => [2]Direction{ .north, .south },
        '-' => [2]Direction{ .east, .west },
        'L' => [2]Direction{ .north, .east },
        'J' => [2]Direction{ .north, .west },
        '7' => [2]Direction{ .south, .west },
        'F' => [2]Direction{ .south, .east },
        else => @panic(""),
    };
}

fn pipeDirection(pipe: u8, dir: Direction) Direction {
    return switch (pipe) {
        '|' => switch (dir) {
            .north => .north,
            .south => .south,
            else => unreachable,
        },
        '-' => switch (dir) {
            .east => .east,
            .west => .west,
            else => unreachable,
        },
        'L' => switch (dir) {
            .south => .east,
            .west => .north,
            else => unreachable,
        },
        'J' => switch (dir) {
            .south => .west,
            .east => .north,
            else => unreachable,
        },
        '7' => switch (dir) {
            .north => .west,
            .east => .south,
            else => unreachable,
        },
        'F' => switch (dir) {
            .north => .east,
            .west => .south,
            else => unreachable,
        },
        else => unreachable,
    };
}

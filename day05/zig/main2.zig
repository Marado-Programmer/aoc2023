const std = @import("std");
const utils = @import("./utils.zig");

//const file = "./test.in";
const file = "./puzzle.in";

fn Range(comptime T: type) type {
    return struct {
        start: T,
        size: T,
        const Self = @This();
        fn intersection(self: Self, range: Self) [3]?Self {
            var ranges: [3]?Self = [_]?Self{ null, null, null };

            if (self.start <= range.start and range.start < self.start + self.size) {
                if (self.start + self.size > range.start + range.size) {
                    // [A1; B1[ U [B1; B2[ U [B2; A2[
                    ranges[0] = Self{ .start = self.start, .size = range.start - self.start };
                    ranges[1] = Self{ .start = range.start, .size = range.size };
                    ranges[2] = Self{ .start = range.start + range.size, .size = self.start + self.size - (range.start + range.size) };
                } else {
                    // [A1; B1[ U [B1; A2[ U [A2; B2[
                    ranges[0] = Self{ .start = self.start, .size = range.start - self.start };
                    ranges[1] = Self{ .start = range.start, .size = self.start + self.size - range.start };
                    //ranges[2] = Self{ .start = self.start + self.size, .size = range.start + range.size - (self.start + self.size) };
                }
            } else if (range.start <= self.start and self.start < range.start + range.size) {
                if (range.start + range.size > self.start + self.size) {
                    // [B1; A1[ U [A1; A2[ U [A2; B2[
                    //ranges[0] = Self{ .start = range.start, .size = self.start - range.start };
                    ranges[1] = Self{ .start = self.start, .size = self.size };
                    //ranges[2] = Self{ .start = self.start + self.size, .size = range.start + range.size - (self.start + self.size) };
                } else {
                    // [B1; A1[ U [A1; B2[ U [B2; A2[
                    //ranges[0] = Self{ .start = range.start, .size = self.start - range.start };
                    ranges[1] = Self{ .start = self.start, .size = range.start + range.size - self.start };
                    ranges[2] = Self{ .start = range.start + range.size, .size = self.start + self.size - (range.start + range.size) };
                }
            }

            return ranges;
        }
    };
}

fn Rule(comptime T: type) type {
    return struct {
        range: Range(T),
        destination: T,
    };
}

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

    try utils.lines(allocator, &str, file);

    var in = str.items;
    var lines = std.mem.split(u8, in, "\n");

    var seeds = std.ArrayList(Range(u64)).init(allocator);
    defer seeds.deinit();

    var rules = std.ArrayList(Rule(u64)).init(allocator);
    defer rules.deinit();

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (seeds.items.len == 0) {
            var s = std.mem.split(u8, line, " ");
            _ = s.next(); // Ignore `seeds:`
            while (s.next()) |seed| {
                var range = utils.atoi(u64, s.next().?);
                try seeds.append(Range(u64){ .start = utils.atoi(u64, seed), .size = range });
            }

            _ = lines.next(); // the next two lines are irrelevant
            _ = lines.next();
        } else {
            var s = std.mem.split(u8, line, " ");

            var num = s.next().?; // variable to see if the line it's important
            // for us
            if (num[0] < '0' or num[0] > '9') {
                std.debug.print("Rules:\n", .{});
                print_rules(u64, rules.items);
                std.debug.print("\n", .{});
                std.debug.print("Seeds:\n", .{});
                print_range(u64, seeds.items);
                std.debug.print("\n", .{});

                try apply_rules(allocator, &seeds, &rules);

                continue;
            }

            var destination = utils.atoi(u64, num);
            var range = Range(u64){
                .start = utils.atoi(u64, s.next().?),
                .size = utils.atoi(u64, s.next().?),
            };

            try rules.append(Rule(u64){ .range = range, .destination = destination });
        }
    }

    std.debug.print("Rules:\n", .{});
    print_rules(u64, rules.items);
    std.debug.print("\n", .{});
    std.debug.print("Seeds:\n", .{});
    print_range(u64, seeds.items);
    std.debug.print("\n", .{});

    try apply_rules(allocator, &seeds, &rules);

    print_range(u64, seeds.items);

    var min: u64 = std.math.maxInt(u64);
    for (seeds.items) |seed| {
        if (seed.size == 0) {
            continue;
        }
        min = @min(min, seed.start);
    }

    try out.writer().print("min:\t{d}\n", .{min});
}

fn print_seeds(comptime T: type, items: []Range(T)) void {
    for (items) |range| {
        std.debug.print("range:\n\tstart:\t{d}\n\tsize:\t{d}\n\n", .{ range.start, range.size });
    }
}
fn print_range(comptime T: type, items: []Range(T)) void {
    for (items) |range| {
        std.debug.print("range: [{d}; {d}[\n", .{ range.start, range.start + range.size });
    }
}
fn print_optional_range(comptime T: type, items: []?Range(T)) void {
    for (items) |range| {
        if (range != null) {
            std.debug.print("range: [{d}; {d}[\n", .{ range.?.start, range.?.start + range.?.size });
        }
    }
}

fn print_rules(comptime T: type, items: []Rule(T)) void {
    for (items) |rule| {
        std.debug.print("rule:\n\trange:\n\t\tstart:\t{d}\n\t\tsize:\t{d}\n\tdestination:\t{d}\n\n", .{ rule.range.start, rule.range.size, rule.destination });
    }
}

fn apply_rules(allocator: std.mem.Allocator, seeds: *std.ArrayList(Range(u64)), rules: *std.ArrayList(Rule(u64))) !void {
    var next_seeds = std.ArrayList(Range(u64)).init(allocator);
    defer next_seeds.deinit();

    seeds: for (seeds.items) |j| {
        for (rules.items) |i| {
            var intersections = j.intersection(i.range);

            std.debug.print("Rule:\n", .{});
            var r_p = [_]Range(u64){i.range};
            print_range(u64, &r_p);
            std.debug.print("Seed:\n", .{});
            var s_p = [_]Range(u64){j};
            print_range(u64, &s_p);
            std.debug.print("Intersections:\n", .{});
            print_optional_range(u64, &intersections);
            std.debug.print("\n", .{});

            if (intersections[0] != null) {
                try next_seeds.append(intersections[0].?);
            }
            if (intersections[2] != null) {
                try next_seeds.append(intersections[2].?);
            }
            if (intersections[1] != null) {
                intersections[1].?.start = intersections[1].?.start + i.destination - i.range.start;
                try next_seeds.append(intersections[1].?);
                continue :seeds;
            }
        }

        try next_seeds.append(j);
    }

    rules.clearAndFree();

    seeds.clearAndFree();

    try seeds.appendSlice(next_seeds.items);
}

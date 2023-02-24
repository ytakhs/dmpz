const std = @import("std");
const Allocator = std.mem.Allocator;

const Diff = struct {
    const Operation = enum {
        Delete,
        Insert,
        Equal,
    };

    op: Operation,
    text: []const u8,
};
const DiffList = std.ArrayList(Diff);

pub fn diffMain(
    allocator: Allocator,
    text1: []const u8,
    text2: []const u8,
) !DiffList {
    var dl = DiffList.init(allocator);

    if (std.mem.eql(u8, text1, text2)) {
        try dl.append(.{ .op = Diff.Operation.Equal, .text = text1 });

        return dl;
    }

    return dl;
}

const testing = std.testing;
const expectEqual = testing.expectEqual;

test "diffMain" {
    const dl = try diffMain(testing.allocator, "foo", "foo");
    defer dl.deinit();

    try testing.expectEqual(dl.items.len, 1);
}

fn diffCommonPrefix(text1: []const u8, text2: []const u8) usize {
    if (std.mem.eql(u8, text1, "") or std.mem.eql(u8, text2, "")) {
        return 0;
    }

    var min: usize = 0;
    var max: usize = std.math.min(text1.len, text2.len);
    var mid: usize = max;

    while (min < mid) {
        if (std.mem.eql(u8, text1[min..mid], text2[min..mid])) {
            min = mid;
        } else {
            max = mid;
        }

        mid = @divFloor((max - min), 2) + min;
    }

    return mid;
}

test "diffCommonPrefix" {
    try expectEqual(diffCommonPrefix("", "foo"), 0);
    try expectEqual(diffCommonPrefix(" foo", "foo"), 0);
    try expectEqual(diffCommonPrefix("foo", "foo"), 3);
    try expectEqual(diffCommonPrefix("asdf asdf", "asdf "), 5);
    try expectEqual(diffCommonPrefix("あいうえお", "あいうえ"), 12);
}

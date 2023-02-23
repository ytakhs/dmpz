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

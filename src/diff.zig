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
    if (std.mem.eql(u8, text1, text2)) {
        var diffs = DiffList.init(allocator);
        try diffs.append(.{ .op = Diff.Operation.Equal, .text = text1 });

        return diffs;
    }

    var t1 = text1;
    var t2 = text2;

    var common_length: usize = 0;
    common_length = diffCommonPrefix(t1, t2);
    const common_prefix = text1[0..common_length];
    t1 = t1[common_length..];
    t2 = t2[common_length..];

    common_length = diffCommonSuffix(t1, t2);
    const common_suffix = t1[(t1.len - common_length)..];
    t1 = t1[0..(t1.len - common_length)];
    t2 = t2[0..(t2.len - common_length)];

    var diffs = try diffCompute(allocator, t1, t2);

    if (common_prefix.len != 0) {
        try diffs.insert(0, Diff{ .op = Diff.Operation.Insert, .text = common_prefix });
    }

    if (common_suffix.len != 0) {
        try diffs.append(Diff{ .op = Diff.Operation.Insert, .text = common_suffix });
    }

    return diffs;
}

const testing = std.testing;
const expectEqual = testing.expectEqual;

test "diffMain" {
    const dl = try diffMain(testing.allocator, "foo", "foo");
    defer dl.deinit();

    try testing.expectEqual(dl.items.len, 1);
}

fn diffCommonPrefix(text1: []const u8, text2: []const u8) usize {
    if (text1.len == 0 or text2.len == 0) {
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

fn diffCommonSuffix(text1: []const u8, text2: []const u8) usize {
    if (text1.len == 0 or text2.len == 0) {
        return 0;
    }

    var min: usize = 0;
    var max: usize = std.math.min(text1.len, text2.len);
    var mid: usize = max;

    while (min < mid) {
        if (std.mem.eql(u8, text1[text1.len - mid .. text1.len - min], text2[text2.len - mid .. text2.len - min])) {
            min = mid;
        } else {
            max = mid;
        }

        mid = @divFloor((max - min), 2) + min;
    }

    return mid;
}

test "diffCommonSuffix" {
    try expectEqual(diffCommonSuffix(" foobar", "bar"), 3);
    try expectEqual(diffCommonSuffix("bar", "baz"), 0);
    try expectEqual(diffCommonSuffix("", "bar"), 0);
    try expectEqual(diffCommonSuffix("asdf asdf", " asdf"), 5);
}

fn diffCompute(allocator: Allocator, text1: []const u8, text2: []const u8) !DiffList {
    var diffs = DiffList.init(allocator);

    if (text1.len == 0) {
        try diffs.append(Diff{ .op = Diff.Operation.Insert, .text = text2 });
        return diffs;
    }

    if (text2.len == 0) {
        try diffs.append(Diff{ .op = Diff.Operation.Delete, .text = text1 });
        return diffs;
    }

    return diffs;
}

test "diffCompute" {
    const a = try diffCompute(testing.allocator, "", "foo");
    defer a.deinit();
    try testing.expectEqual(@as(usize, 1), a.items.len);
    try testing.expectEqual(Diff.Operation.Insert, a.items[0].op);
    try testing.expectEqualStrings("foo", a.items[0].text);

    const b = try diffCompute(testing.allocator, "foo", "");
    defer b.deinit();
    try testing.expectEqual(@as(usize, 1), b.items.len);
    try testing.expectEqual(Diff.Operation.Delete, b.items[0].op);
    try testing.expectEqualStrings("foo", b.items[0].text);
}

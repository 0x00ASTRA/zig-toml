const std = @import("std");
const testing = std.testing;
const main = @import("./main.zig");
const struct_mapping = @import("./struct_mapping.zig");
const datetime = @import("./datetime.zig");
const Table = @import("./table.zig").Table;
const serialize = @import("serialize.zig").serialize;
const Date = datetime.Date;
const Time = datetime.Time;
const DateTime = datetime.DateTime;

test "full" {
    var p = main.Parser(main.Table).init(testing.allocator);
    defer p.deinit();

    const parsed = try p.parseString(
        \\  aa = "a1"
        \\
        \\    bb = 33
    );
    defer parsed.deinit();
    const m = parsed.value;

    try testing.expect(m.count() == 2);
    try testing.expect(std.mem.eql(u8, m.get("aa").?.string, "a1"));
    try testing.expect(m.get("bb").?.integer == 33);
}

test "parse into struct" {
    const Tt = struct {
        aa: i64,
        bb: i64,
    };
    const T1 = struct {
        v1: i64,
    };
    const P2 = struct {
        t1: T1,
    };
    const P1 = struct {
        p2: []P2,
    };
    const E1 = enum {
        EnumValue1,
        EnumValue2,
    };
    const Aa = struct {
        aa: i64,
        aa2: i8,
        aa3: i16 = 500,
        bb: []const u8,
        bb2: []const u8 = "test1",
        b1: bool,
        cc: []i64,
        dd: []const []const u8,
        d2: [3][]const u8,
        t1: Tt,
        t2: Tt,
        t3: Tt,
        t4: Tt,
        p1: P1,
        pt1: *T1,
        f1: f64,
        f1a: f16,
        f1b: f16,
        f2: f64,
        d1: datetime.Date,
        ti1: datetime.Time,
        dt1: datetime.DateTime,
        o1: ?i32,
        o2: ?i32,
        e1: E1,
        tab1: Table,
        tab2: *Table,
        hm: main.HashMap(Tt),
        hm2: *main.HashMap(Tt),
    };

    var p = main.Parser(Aa).init(testing.allocator);
    defer p.deinit();

    const parsed = try p.parseFile("./test/doc1.toml.txt");
    const aa: Aa = parsed.value;
    defer parsed.deinit();

    try testing.expect(aa.aa == 34);
    try testing.expect(aa.aa2 == 50);
    try testing.expect(aa.aa3 == 500);
    try testing.expect(std.mem.eql(u8, aa.bb, "abcЖ"));
    try testing.expectEqual("test1", aa.bb2);
    try testing.expect(aa.b1 == true);
    try testing.expect(aa.f1 == 125.55);
    try testing.expect(aa.f1a == 99.5);
    try testing.expect(aa.f1b == 99.0);
    try testing.expect(aa.f2 == 125.0);
    try testing.expect(aa.o1 == null);
    try testing.expect(aa.o2.? == 45);
    try testing.expect(std.meta.eql(aa.d1, datetime.Date{ .year = 2022, .month = 12, .day = 10 }));
    try testing.expect(std.meta.eql(aa.ti1, datetime.Time{ .hour = 9, .minute = 7, .second = 14, .nanosecond = 345678000 }));
    try testing.expect(std.meta.eql(aa.dt1, datetime.DateTime{
        .date = datetime.Date{ .year = 2022, .month = 12, .day = 14 },
        .time = datetime.Time{ .hour = 16, .minute = 44, .second = 30 },
        .offset_minutes = 120,
    }));
    try testing.expect(aa.cc.len == 3);
    try testing.expect(aa.cc[0] == 3);
    try testing.expect(aa.cc[1] == 15);
    try testing.expect(aa.cc[2] == 20);

    try testing.expect(aa.dd.len == 2);
    try testing.expect(std.mem.eql(u8, aa.dd[0], "aa"));
    try testing.expect(std.mem.eql(u8, aa.dd[1], "bb"));

    try testing.expectEqualSlices(u8, aa.d2[0], "a1");
    try testing.expectEqualSlices(u8, aa.d2[1], "a2");
    try testing.expectEqualSlices(u8, aa.d2[2], "a3");

    try testing.expect(aa.t1.aa == 3);
    try testing.expect(aa.t1.bb == 4);
    try testing.expect(aa.t2.aa == 5);
    try testing.expect(aa.t2.bb == 6);
    try testing.expect(aa.t3.aa == 11);
    try testing.expect(aa.t3.bb == 15);
    try testing.expect(aa.t4.aa == 21);
    try testing.expect(aa.t4.bb == 22);

    try testing.expect(aa.p1.p2.len == 2);
    try testing.expect(aa.p1.p2[0].t1.v1 == 44);
    try testing.expect(aa.p1.p2[1].t1.v1 == 50);

    try testing.expect(aa.pt1.v1 == 102);
    try testing.expectEqual(E1.EnumValue1, aa.e1);

    try testing.expectEqual(3, aa.tab1.get("a").?.table.get("val").?.integer);
    try testing.expectEqualSlices(u8, "str1", aa.tab1.get("b").?.table.get("val").?.string);
    try testing.expectEqual(4, aa.tab2.get("a").?.table.get("val").?.integer);
    try testing.expectEqualSlices(u8, "str2", aa.tab2.get("b").?.table.get("val").?.string);

    try testing.expectEqual(3, aa.hm.map.get("f1").?.aa);
    try testing.expectEqual(4, aa.hm.map.get("f1").?.bb);
    try testing.expectEqual(5, aa.hm.map.get("f2").?.aa);
    try testing.expectEqual(6, aa.hm.map.get("f2").?.bb);
    try testing.expectEqual(10, aa.hm.map.get("f3").?.aa);
    try testing.expectEqual(11, aa.hm.map.get("f3").?.bb);

    try testing.expectEqual(3, aa.hm2.map.get("f1").?.aa);
    try testing.expectEqual(4, aa.hm2.map.get("f1").?.bb);
    try testing.expectEqual(5, aa.hm2.map.get("f2").?.aa);
    try testing.expectEqual(6, aa.hm2.map.get("f2").?.bb);
    try testing.expectEqual(10, aa.hm2.map.get("f3").?.aa);
    try testing.expectEqual(11, aa.hm2.map.get("f3").?.bb);
}

test "optionals (--release=fast)" {
    const Sub = struct {
        id: u16,
        name: []const u8,
    };

    const Opts = struct {
        sub: ?Sub,
    };

    var p = main.Parser(Opts).init(testing.allocator);
    defer p.deinit();

    const parsed = try p.parseString(
        \\ [sub]
        \\ id = 12
        \\ name = "world"
    );
    defer parsed.deinit();
    const m = parsed.value;

    try std.testing.expect(m.sub != null);
    try std.testing.expectEqual(12, m.sub.?.id);
    try std.testing.expectEqualStrings("world", m.sub.?.name);
}

test "deinit table" {
    var p = main.Parser(main.Table).init(testing.allocator);
    defer p.deinit();

    const parsed = try p.parseFile("./test/doc1.toml.txt");
    _ = parsed.value;
    defer parsed.deinit();
}

const Allocator = std.testing.allocator;

test "basic literals" {
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();

    // Comptime integers
    try serialize(Allocator, 127, &writer);
    try testing.expectEqualSlices(u8, "127", ba.constSlice());
    ba.clear();

    try serialize(Allocator, -127, &writer);
    try testing.expectEqualSlices(u8, "-127", ba.constSlice());
    ba.clear();

    // Runtime integers
    var n: i16 = 127;
    try serialize(Allocator, n, &writer);
    try testing.expectEqualSlices(u8, "127", ba.constSlice());
    ba.clear();

    n = -127;
    try serialize(Allocator, n, &writer);
    try testing.expectEqualSlices(u8, "-127", ba.constSlice());
    ba.clear();

    // Booleans
    try serialize(Allocator, true, &writer);
    try testing.expectEqualSlices(u8, "true", ba.constSlice());
    ba.clear();

    try serialize(Allocator, false, &writer);
    try testing.expectEqualSlices(u8, "false", ba.constSlice());
    ba.clear();
}

test "infinities" {
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();

    try serialize(Allocator, std.math.inf(f32), &writer);
    try testing.expectEqualSlices(u8, "inf", ba.constSlice());
    ba.clear();

    try serialize(Allocator, -std.math.inf(f32), &writer);
    try testing.expectEqualSlices(u8, "-inf", ba.constSlice());
    ba.clear();

    try serialize(Allocator, std.math.inf(f64), &writer);
    try testing.expectEqualSlices(u8, "inf", ba.constSlice());
    ba.clear();

    try serialize(Allocator, -std.math.inf(f64), &writer);
    try testing.expectEqualSlices(u8, "-inf", ba.constSlice());
    ba.clear();
}

test "pointers" {
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();

    const num: u8 = 127;
    try serialize(Allocator, &num, &writer);
    try testing.expectEqualSlices(u8, "127", ba.constSlice());
    ba.clear();
}

test "enums" {
    const Color = enum {
        Red,
        Green,
        Yellow,
        Blue,
        Pink,
    };

    const color = Color.Blue;
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();
    try serialize(Allocator, color, &writer);
    try testing.expectEqualSlices(u8, "\"Blue\"", ba.constSlice());
    ba.clear();
}

test "optionals" {
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();

    var optval: ?u32 = null;
    try serialize(Allocator, optval, &writer);
    try testing.expectEqualSlices(u8, "", ba.constSlice());

    optval = 100;
    try serialize(Allocator, optval, &writer);
    try testing.expectEqualSlices(u8, "100", ba.constSlice());
}

test "unions" {
    const MyUnion = union(enum) {
        f1: u8,
        f2: u16,
        f3: []const u8,
    };

    const u = MyUnion{ .f1 = 255 };
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();
    try serialize(Allocator, u, &writer);
    try testing.expectEqualSlices(u8, "255", ba.constSlice());
    ba.clear();
}

test "strings" {
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();

    // Basic string
    try serialize(Allocator, "hello world", &writer);
    try testing.expectEqualSlices(u8, "\"hello world\"", ba.constSlice());
    ba.clear();

    // String with escape chars
    try serialize(Allocator, "hello\nworld", &writer);
    try testing.expectEqualSlices(u8, "\"hello\\nworld\"", ba.constSlice());
    ba.clear();

    // String with escape quotes
    try serialize(Allocator, "hello\"world", &writer);
    try testing.expectEqualSlices(u8, "\"hello\\\"world\"", ba.constSlice());
    ba.clear();

    // String with backslashes
    try serialize(Allocator, "hello\\world", &writer);
    try testing.expectEqualSlices(u8, "\"hello\\\\world\"", ba.constSlice());
    ba.clear();

    // String with escape quotes and backslashes
    try serialize(Allocator, "hello\\\"world", &writer);
    try testing.expectEqualSlices(u8, "\"hello\\\\\\\"world\"", ba.constSlice());
    ba.clear();
}

test "date times" {
    var ba = try std.BoundedArray(u8, 64).init(0);
    var writer = ba.writer().any();

    try serialize(Allocator, Date{ .day = 1, .month = 2, .year = 2025 }, &writer);
    try testing.expectEqualSlices(u8, "2025-02-01", ba.constSlice());
    ba.clear();

    try serialize(Allocator, Time{ .hour = 15, .minute = 5, .second = 0 }, &writer);
    try testing.expectEqualSlices(u8, "15:05:00", ba.constSlice());
    ba.clear();

    try serialize(Allocator, Time{ .hour = 15, .minute = 5, .second = 0, .nanosecond = 123456789 }, &writer);
    try testing.expectEqualSlices(u8, "15:05:00.123456789", ba.constSlice());
    ba.clear();

    try serialize(Allocator, DateTime{
        .time = .{ .hour = 15, .minute = 5, .second = 0, .nanosecond = 123456789 },
        .date = .{ .day = 1, .month = 2, .year = 2025 },
        .offset_minutes = 150,
    }, &writer);
    try testing.expectEqualSlices(u8, "2025-02-0115:05:00.123456789-02:30", ba.constSlice());
    ba.clear();
}

test "escape codes" {
    var ba = try std.BoundedArray(u8, 16).init(0);
    var writer = ba.writer().any();

    try serialize(Allocator, "\n", &writer);
    try testing.expectEqualSlices(u8, "\"\\n\"", ba.constSlice());
    ba.clear();

    try serialize(Allocator, "\t", &writer);
    try testing.expectEqualSlices(u8, "\"\\t\"", ba.constSlice());
    ba.clear();

    try serialize(Allocator, "\r", &writer);
    try testing.expectEqualSlices(u8, "\"\\r\"", ba.constSlice());
    ba.clear();

    try serialize(Allocator, "\\", &writer);
    try testing.expectEqualSlices(u8, "\"\\\\\"", ba.constSlice());
    ba.clear();

    try serialize(Allocator, "\x0C", &writer);
    try testing.expectEqualSlices(u8, "\"\\f\"", ba.constSlice());
    ba.clear();

    try serialize(Allocator, "\x08", &writer);
    try testing.expectEqualSlices(u8, "\"\\b\"", ba.constSlice());
    ba.clear();
}

test "arrays" {
    var ba = try std.BoundedArray(u8, 64).init(0);
    var writer = ba.writer().any();

    try serialize(Allocator, [_]usize{ 10, 20, 30, 40, 50 }, &writer);
    try testing.expectEqualSlices(u8, "[ 10, 20, 30, 40, 50 ]", ba.constSlice());
    ba.clear();

    try serialize(Allocator, [_][]const u8{ "this", "is", "a", "string" }, &writer);
    try testing.expectEqualSlices(u8, "[ \"this\", \"is\", \"a\", \"string\" ]", ba.constSlice());
    ba.clear();

    try serialize(Allocator, [_][3]usize{ [_]usize{ 1, 2, 3 }, [_]usize{ 4, 5, 6 }, [_]usize{ 7, 8, 9 } }, &writer);
    try testing.expectEqualSlices(u8, "[ [ 1, 2, 3 ], [ 4, 5, 6 ], [ 7, 8, 9 ] ]", ba.constSlice());
    ba.clear();
}

test "arrays containing complex objects" {
    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();

    const TestStruct2 = struct {
        field1: i32,
        field2: f32,
    };
    const TestStruct = struct {
        field1: [2]TestStruct2,
        field2: [2]*const TestStruct2,
        field3: [2]std.StringHashMap(usize),
    };

    const tp1 = TestStruct2{
        .field1 = 100,
        .field2 = 0.1,
    };
    const tp2 = TestStruct2{
        .field1 = 200,
        .field2 = 0.2,
    };

    var hashmap1 = std.StringHashMap(usize).init(testing.allocator);
    var hashmap2 = std.StringHashMap(usize).init(testing.allocator);
    defer hashmap1.deinit();
    defer hashmap2.deinit();
    try hashmap1.put("a", 1);
    try hashmap1.put("b", 2);
    try hashmap1.put("c", 3);
    try hashmap2.put("d", 4);
    try hashmap2.put("e", 5);
    try hashmap2.put("f", 6);

    const t = TestStruct{
        .field1 = [_]TestStruct2{ TestStruct2{ .field1 = 10, .field2 = 2.71 }, TestStruct2{ .field1 = 20, .field2 = 3.14 } },
        .field2 = [_]*const TestStruct2{ &tp1, &tp2 },
        .field3 = [_]std.StringHashMap(usize){ hashmap1, hashmap2 },
    };

    const result =
        \\[[field1]]
        \\field1 = 10
        \\field2 = 2.71
        \\[[field1]]
        \\field1 = 20
        \\field2 = 3.14
        \\[[field2]]
        \\field1 = 100
        \\field2 = 0.1
        \\[[field2]]
        \\field1 = 200
        \\field2 = 0.2
        \\[[field3]]
        \\a = 1
        \\b = 2
        \\c = 3
        \\[[field3]]
        \\d = 4
        \\e = 5
        \\f = 6
        \\
    ;

    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "structs" {
    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();

    const TestStruct = struct {
        field1: i32,
        field2: []const u8,
        field3: bool,
        field4: f64,
        field5: [5]u8,
        field6: [5][]const u8,
    };

    const t = TestStruct{
        .field1 = 100,
        .field2 = "hello world",
        .field3 = true,
        .field4 = 3.14,
        .field5 = [_]u8{ 1, 2, 3, 4, 5 },
        .field6 = [_][]const u8{ "This", "is", "a", "text", "line" },
    };

    const result =
        \\field1 = 100
        \\field2 = "hello world"
        \\field3 = true
        \\field4 = 3.14
        \\field5 = [ 1, 2, 3, 4, 5 ]
        \\field6 = [ "This", "is", "a", "text", "line" ]
        \\
    ;

    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "tables follow top level fields" {
    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();

    const TestStruct2 = struct {
        field1: i32,
    };

    const TestStruct = struct {
        field1: i32,
        field2: []const u8,
        field3: bool,
        field4: f64,
        field7: TestStruct2,
        field5: [5]u8,
        field6: [5][]const u8,
    };

    const t = TestStruct{
        .field1 = 100,
        .field2 = "hello world",
        .field3 = true,
        .field4 = 3.14,
        .field5 = [_]u8{ 1, 2, 3, 4, 5 },
        .field6 = [_][]const u8{ "This", "is", "a", "text", "line" },
        .field7 = .{ .field1 = 10 },
    };

    const result =
        \\field1 = 100
        \\field2 = "hello world"
        \\field3 = true
        \\field4 = 3.14
        \\field5 = [ 1, 2, 3, 4, 5 ]
        \\field6 = [ "This", "is", "a", "text", "line" ]
        \\[field7]
        \\field1 = 10
        \\
    ;

    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "top level tables" {
    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();

    const TestStruct2 = struct {
        field1: i32,
    };

    const TestStruct = struct {
        field1: i32,
        field2: []const u8,
        field3: bool,
        field4: f64,
        field5: [5]u8,
        field6: [5][]const u8,
        field7: TestStruct2,
    };

    const t = TestStruct{
        .field1 = 100,
        .field2 = "hello world",
        .field3 = true,
        .field4 = 3.14,
        .field5 = [_]u8{ 1, 2, 3, 4, 5 },
        .field6 = [_][]const u8{ "This", "is", "a", "text", "line" },
        .field7 = .{ .field1 = 10 },
    };

    const result =
        \\field1 = 100
        \\field2 = "hello world"
        \\field3 = true
        \\field4 = 3.14
        \\field5 = [ 1, 2, 3, 4, 5 ]
        \\field6 = [ "This", "is", "a", "text", "line" ]
        \\[field7]
        \\field1 = 10
        \\
    ;

    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "sub tables" {
    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();

    const TestStruct3 = struct {
        field1: i32,
    };

    const TestStruct2 = struct {
        field1: i32,
        field2: *const TestStruct3,
    };

    const TestStruct = struct {
        field1: i32,
        field2: []const u8,
        field3: bool,
        field4: f64,
        field5: [5]u8,
        field6: [5][]const u8,
        field7: TestStruct2,
    };

    const t = TestStruct{
        .field1 = 100,
        .field2 = "hello world",
        .field3 = true,
        .field4 = 3.14,
        .field5 = [_]u8{ 1, 2, 3, 4, 5 },
        .field6 = [_][]const u8{ "This", "is", "a", "text", "line" },
        .field7 = .{ .field1 = 10, .field2 = &.{ .field1 = 100 } },
    };

    const result =
        \\field1 = 100
        \\field2 = "hello world"
        \\field3 = true
        \\field4 = 3.14
        \\field5 = [ 1, 2, 3, 4, 5 ]
        \\field6 = [ "This", "is", "a", "text", "line" ]
        \\[field7]
        \\field1 = 10
        \\[field7.field2]
        \\field1 = 100
        \\
    ;

    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "sort fields" {
    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();

    const TestStruct = struct {
        field3: i32,
        field1: f32,
    };

    const t = TestStruct{ .field1 = 3.14, .field3 = 123 };

    const result =
        \\field1 = 3.14
        \\field3 = 123
        \\
    ;

    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "tables with no basic value" {
    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();

    const TestStruct3 = struct {
        field3: i32,
    };

    const TestStruct2 = struct {
        field2: *const TestStruct3,
    };

    const TestStruct = struct {
        field1: TestStruct2,
    };

    const t = TestStruct{
        .field1 = .{ .field2 = &.{ .field3 = 100 } },
    };

    const result =
        \\[field1.field2]
        \\field3 = 100
        \\
    ;

    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "simple value maps" {
    var hashmap = std.StringHashMap(usize).init(testing.allocator);
    defer hashmap.deinit();
    try hashmap.put("a", 1);
    try hashmap.put("b", 2);
    try hashmap.put("c", 3);
    try hashmap.put("d", 4);
    try hashmap.put("e", 5);

    const result =
        \\a = 1
        \\b = 2
        \\c = 3
        \\d = 4
        \\e = 5
        \\
    ;

    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();
    try serialize(Allocator, hashmap, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "maps with structs" {
    const TestStruct = struct {
        field1: usize,
    };

    const t1 = TestStruct{ .field1 = 1 };
    const t2 = TestStruct{ .field1 = 2 };
    const t3 = TestStruct{ .field1 = 3 };

    var hashmap = std.StringHashMap(TestStruct).init(testing.allocator);
    defer hashmap.deinit();
    try hashmap.put("a", t1);
    try hashmap.put("b", t2);
    try hashmap.put("c", t3);

    const result =
        \\[a]
        \\field1 = 1
        \\[b]
        \\field1 = 2
        \\[c]
        \\field1 = 3
        \\
    ;

    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();
    try serialize(Allocator, hashmap, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "maps with maps" {
    var hashmap = std.StringHashMap(std.StringHashMap(usize)).init(testing.allocator);
    var hashmap1 = std.StringHashMap(usize).init(testing.allocator);
    var hashmap2 = std.StringHashMap(usize).init(testing.allocator);
    var hashmap3 = std.StringHashMap(usize).init(testing.allocator);
    defer hashmap.deinit();
    defer hashmap1.deinit();
    defer hashmap2.deinit();
    defer hashmap3.deinit();

    try hashmap1.put("a1", 1);
    try hashmap1.put("a2", 2);
    try hashmap1.put("a3", 3);

    try hashmap2.put("b1", 1);
    try hashmap2.put("b2", 2);
    try hashmap2.put("b3", 3);

    try hashmap3.put("c1", 1);
    try hashmap3.put("c2", 2);
    try hashmap3.put("c3", 3);

    try hashmap.put("a", hashmap1);
    try hashmap.put("b", hashmap2);
    try hashmap.put("c", hashmap3);

    const result =
        \\[a]
        \\a1 = 1
        \\a2 = 2
        \\a3 = 3
        \\[b]
        \\b1 = 1
        \\b2 = 2
        \\b3 = 3
        \\[c]
        \\c1 = 1
        \\c2 = 2
        \\c3 = 3
        \\
    ;

    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();
    try serialize(Allocator, hashmap, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

test "structs containing maps" {
    const TestStruct = struct {
        field1: std.StringHashMap(usize) = std.StringHashMap(usize).init(testing.allocator),
        field2: std.StringHashMap(usize) = std.StringHashMap(usize).init(testing.allocator),
        field3: std.StringHashMap(usize) = std.StringHashMap(usize).init(testing.allocator),
    };

    var t = TestStruct{};
    defer t.field1.deinit();
    defer t.field2.deinit();
    defer t.field3.deinit();

    try t.field1.put("a", 1);
    try t.field1.put("b", 2);
    try t.field1.put("c", 3);

    try t.field2.put("a", 1);
    try t.field2.put("b", 2);
    try t.field2.put("c", 3);

    try t.field3.put("a", 1);
    try t.field3.put("b", 2);
    try t.field3.put("c", 3);

    const result =
        \\[field1]
        \\a = 1
        \\b = 2
        \\c = 3
        \\[field2]
        \\a = 1
        \\b = 2
        \\c = 3
        \\[field3]
        \\a = 1
        \\b = 2
        \\c = 3
        \\
    ;

    var ba = try std.BoundedArray(u8, 512).init(0);
    var writer = ba.writer().any();
    try serialize(Allocator, t, &writer);
    try testing.expectEqualSlices(u8, result, ba.constSlice());
}

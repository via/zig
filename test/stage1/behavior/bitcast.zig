const std = @import("std");
const builtin = @import("builtin");
const expect = std.testing.expect;
const maxInt = std.math.maxInt;

test "@bitCast i32 -> u32" {
    testBitCast_i32_u32();
    comptime testBitCast_i32_u32();
}

fn testBitCast_i32_u32() void {
    expect(conv(-1) == maxInt(u32));
    expect(conv2(maxInt(u32)) == -1);
}

fn conv(x: i32) u32 {
    return @bitCast(u32, x);
}
fn conv2(x: u32) i32 {
    return @bitCast(i32, x);
}

test "@bitCast extern enum to its integer type" {
    const SOCK = extern enum {
        A,
        B,

        fn testBitCastExternEnum() void {
            var SOCK_DGRAM = @This().B;
            var sock_dgram = @bitCast(c_int, SOCK_DGRAM);
            expect(sock_dgram == 1);
        }
    };

    SOCK.testBitCastExternEnum();
    comptime SOCK.testBitCastExternEnum();
}

test "@bitCast packed structs at runtime and comptime" {
    const Full = packed struct {
        number: u16,
    };
    const Divided = packed struct {
        half1: u8,
        quarter3: u4,
        quarter4: u4,
    };
    const S = struct {
        fn doTheTest() void {
            var full = Full{ .number = 0x1234 };
            var two_halves = @bitCast(Divided, full);
            switch (builtin.endian) {
                builtin.Endian.Big => {
                    expect(two_halves.half1 == 0x12);
                    expect(two_halves.quarter3 == 0x3);
                    expect(two_halves.quarter4 == 0x4);
                },
                builtin.Endian.Little => {
                    expect(two_halves.half1 == 0x34);
                    expect(two_halves.quarter3 == 0x2);
                    expect(two_halves.quarter4 == 0x1);
                },
            }
        }
    };
    S.doTheTest();
    comptime S.doTheTest();
}

test "@bitCast extern structs at runtime and comptime" {
    const Full = extern struct {
        number: u16,
    };
    const TwoHalves = extern struct {
        half1: u8,
        half2: u8,
    };
    const S = struct {
        fn doTheTest() void {
            var full = Full{ .number = 0x1234 };
            var two_halves = @bitCast(TwoHalves, full);
            switch (builtin.endian) {
                builtin.Endian.Big => {
                    expect(two_halves.half1 == 0x12);
                    expect(two_halves.half2 == 0x34);
                },
                builtin.Endian.Little => {
                    expect(two_halves.half1 == 0x34);
                    expect(two_halves.half2 == 0x12);
                },
            }
        }
    };
    S.doTheTest();
    comptime S.doTheTest();
}

test "bitcast packed struct to integer and back" {
    const LevelUpMove = packed struct {
        move_id: u9,
        level: u7,
    };
    const S = struct {
        fn doTheTest() void {
            var move = LevelUpMove{ .move_id = 1, .level = 2 };
            var v = @bitCast(u16, move);
            var back_to_a_move = @bitCast(LevelUpMove, v);
            expect(back_to_a_move.move_id == 1);
            expect(back_to_a_move.level == 2);
        }
    };
    S.doTheTest();
    comptime S.doTheTest();
}

test "implicit cast to error union by returning" {
    const S = struct {
        fn entry() void {
            expect((func(-1) catch unreachable) == maxInt(u64));
        }
        pub fn func(sz: i64) anyerror!u64 {
            return @bitCast(u64, sz);
        }
    };
    S.entry();
    comptime S.entry();
}

// issue #3010: compiler segfault
test "bitcast literal [4]u8 param to u32" {
    const ip = @bitCast(u32, [_]u8{ 255, 255, 255, 255 });
    expect(ip == maxInt(u32));
}

test "bitcast packed struct literal to byte" {
    const Foo = packed struct {
        value: u8,
    };
    const casted = @bitCast(u8, Foo{ .value = 0xF });
    expect(casted == 0xf);
}

test "comptime bitcast used in expression has the correct type" {
    const Foo = packed struct {
        value: u8,
    };
    expect(@bitCast(u8, Foo{ .value = 0xF }) == 0xf);
}

test "bitcast result to _" {
    _ = @bitCast(u8, @as(i8, 1));
}

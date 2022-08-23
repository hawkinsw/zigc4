const std = @import("std");
pub const NonceGeneratorResult = enum {
    NonceExhausted,
};

pub fn Noncer(comptime nonce_size: u64) type {
    const default_s = comptime init: {
        var initial_value: [nonce_size]u8 = undefined;
        for (initial_value) |*elem| {
            elem.* = 0;
        }
        break :init initial_value;
    };

    return struct {
        current_value: [nonce_size]u8,
        index: i64,
        const This = @This();
        pub fn create() This {
            return This{ .current_value = default_s, .index = 0 };
        }
        pub fn next(this: *This) ?[nonce_size]u8 {
            while (this.index >= 0) {
                var usable_index = std.math.absCast(this.index);
                this.current_value[usable_index] += 1;
                if (this.current_value[usable_index] == 255) {
                    this.current_value[usable_index] = 0;
                    this.index -= 1;
                } else {
                    if (this.index + 1 < nonce_size) {
                        this.index += 1;
                    }
                    return this.current_value;
                }
            }
            return null;
        }
    };
}

const mem = @import("std").mem;
const io = @import("std").io;

pub const RC4Error = error{
    KeylenTooLong,
};

fn swap(comptime T: type, left: *T, right: *T) void {
    var temp: T = left.*;
    left.* = right.*;
    right.* = temp;
}


pub fn RC4(allocator: mem.Allocator) type {
    const default_s = comptime init: {
        var initial_value: [256]u8 = undefined;
        for (initial_value) |*elem, i| {
            elem.* = i;
        }
        break :init initial_value;
    };
    return struct {
        S: [256]u8,
        i: u16,
        j: u16,
        const This = @This();

        pub fn create() This {
            return This{ .S = default_s, .i = 0, .j = 0 };
        }

        // From https://nullprogram.com/blog/2014/07/23/
        // wikipedia (https://en.wikipedia.org/wiki/RC4)
        pub fn schedule(this: *This, keymat: []const u8) void {
            // Note: The i and j here are *not* the same as this's i/j.
            // Those are only updated when there are prns being generated.
            var j: u16 = 0;
            var i: u16 = 0;
            while (i < 256) : (i += 1) {
                j = (j + this.S[i] + keymat[i % keymat.len]) % 256;
                swap(u8, &this.S[i], &this.S[j]);
            }
        }

        pub fn hash(this: *This, size: usize) ![]u8 {
            var result = try allocator.alloc(u8, size);
            for (result) |*elem| {
                this.i = (this.i + 1) % 256;
                this.j = (this.j + this.S[this.i]) % 256;
                swap(u8, &this.S[this.i], &this.S[this.j]);
                elem.* = this.S[(@as(u16, this.S[this.i]) + @as(u16, this.S[this.j])) % 256];
            }
            return result;
        }
    };
}

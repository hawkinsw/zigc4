const std = @import("std");
const rc4 = @import("rc4.zig");
const noncer = @import("noncer.zig");
const testing = std.testing;

test "Simple smoke test" {
    const heap = std.heap.page_allocator;
    const keymat = [_]u8{ 1, 2, 3, 4 };
    const test_data: []const u8 = "ogwdyyvmacwxkltbgohznvrxfwhkhfutpcqkxwjciban" ++
        "jvsnsshpvmmzctlrabgqjslpumzpjopwdiczfinfkxnt" ++
        "wqvnpccjlziplfulniopvbjezoxefcnbemumftyhuaok" ++
        "kidllrbvchrbwvmoegqksvcvhhyakxnrebagacagteez" ++
        "qkrkpfhnetlggckagphwqaiecxtdvrhxkwynmxxxpdpt" ++
        "saalythhfwdhjwhlgbvcxbrzzlfiocjibjxq";
    const test_data_hash = [_]u8{ 0x12, 0x8f, 0x7e, 0x3b, 0x3c, 0xd1, 0x88, 0xd6, 0x30, 0xdd, 0x8d, 0x39, 0x63, 0x28, 0xc2, 0x00, 0x09, 0x2d, 0xdc, 0xab, 0x10 };
    var r = rc4.RC4(heap).create();

    r.schedule(keymat[0..]);
    r.schedule(test_data);
    const hash = try r.hash(21);
    try testing.expectEqualSlices(u8, hash, test_data_hash[0..]);
}

/// Generate an array of size u8s, each with random value. The default
/// PRNG will be used to generate these random numbers and thee PRNG is
/// seeded by seed.
fn generate_random_block(comptime size: u32, seed: u64) [size]u8 {
    var result: [size]u8 = undefined;
    var i: u32 = 0;
    var prng = std.rand.DefaultPrng.init(seed);

    while (i < size) : (i = i + 1) {
        var point: u8 = prng.random().int(u8);
        result[i] = point;
    }
    return result;
}

/// Print each element (of type slice_type) in to_print. The code
/// in the function is far too generic for what we are writing here,
/// but it's good for exploring.
fn print_slice(comptime slice_type: type, to_print: []const slice_type) !void {
    var stdout = std.io.getStdOut().writer();
    for (to_print) |r| {
        switch (@typeInfo(slice_type)) {
            .Int => {
                try stdout.print("-{x:0>2}-", .{r});
            },
            else => {
                @compileError("Cannot print a slice whose type is " ++ @typeName(slice_type) ++ ".");
            },
        }
    }
    try stdout.print("\n", .{});
}

fn validate_work(comptime difficulty: u32, hash: []u8) bool {
    var iterator: u32 = 0;
    while (iterator < difficulty and iterator < hash.len) : (iterator += 1) {
        if (hash[iterator] != 0) {
            return false;
        }
    }
    return true;
}

const TimeCalculationError = error{
    AfterBeforeBefore,
};
fn calculate_elapsed_time(before: i128, after: i128) !i64 {
    if (after < before) {
        return TimeCalculationError.AfterBeforeBefore;
    }
    return @truncate(i64, after - before);
}

const ProofCalculationError = error {
    CouldNotCalculate,
};

fn prove_work(comptime difficulty: u8, comptime nonce_size: u8, nonce_attempts: *u64, comptime hash_allocator: std.mem.Allocator, block: []const u8) ![nonce_size]u8 {
    // We will use a noncer to systematically work through all the
    // different nonces that we can generate.
    nonce_attempts.* = 0;
    var ncr = noncer.Noncer(nonce_size).create();
    while (ncr.next()) |nonce| {
        nonce_attempts.* += 1;
        var r = rc4.RC4(hash_allocator).create();
        r.schedule(nonce[0..]);
        r.schedule(block[0..]);
        const proof = try r.hash(nonce_size);
        if (validate_work(difficulty, proof)) {
            var result: [nonce_size]u8 = undefined;
            std.mem.copy(u8, result[0..], proof);
            hash_allocator.destroy(proof.ptr);
            return result;
        }
        hash_allocator.destroy(proof.ptr);
    }
    return ProofCalculationError.CouldNotCalculate;
}

pub fn main() !void {
    var stdout = std.io.getStdOut().writer();
    const difficulty = 2;
    const timer_seed = @truncate(u64, std.math.absCast(@mod(std.time.nanoTimestamp(), @sizeOf(u64))));
    const block_bytes = generate_random_block(32, timer_seed);
    const heap = std.heap.page_allocator;
    var nonce_attempts: u64 = 0;

    // Find out the time before we begin doing the proof-of-work.
    const before_pow = std.time.nanoTimestamp();

    // We will use a noncer to systematically work through all the
    // different nonces that we can generate.
    var result = try prove_work(difficulty, 32, &nonce_attempts, heap, block_bytes[0..]);
    try stdout.print("block_bytes: ", .{});
    try print_slice(u8, block_bytes[0..]);
    try stdout.print("\n", .{});

    try stdout.print("nonce: ", .{});
    try print_slice(u8, result[0..]);
    try stdout.print("\n", .{});

    const after_pow = std.time.nanoTimestamp();

    try stdout.print("Proof took ", .{});
    try std.fmt.formatFloatDecimal(@intToFloat(f64, try calculate_elapsed_time(before_pow, after_pow)) / @intToFloat(f64, std.time.ns_per_s), .{}, stdout);
    try stdout.print("s to generate (required {d} nonce generations).\n", .{nonce_attempts});
}

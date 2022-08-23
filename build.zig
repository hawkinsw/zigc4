const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const rc4_lib = b.addSharedLibrary("rc4", "src/rc4.zig", b.version(0,1,0));
    rc4_lib.setBuildMode(mode);
    rc4_lib.install();

    const tester = b.addTest("src/main.zig");
    tester.setBuildMode(mode);

    const test_step = b.step("test", "Run rc4 unit tests.");
    test_step.dependOn(&tester.step);
}
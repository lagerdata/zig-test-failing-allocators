const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

fn functionThatLeaks(allocator: *Allocator) error{OutOfMemory}!void {
    _ = try allocator.create(u8);
}

test "baseline that should not fail" {
    const functionThatUsesAnAllocator = @import("util.zig").functionThatUsesAnAllocator;

    const allocator = std.testing.allocator;
    const result = try functionThatUsesAnAllocator(allocator, 32);
    std.testing.expect(result == 32);
}

test "fail after N allocations" {
    const functionThatUsesAnAllocator = @import("util.zig").functionThatUsesAnAllocator;

    var failing_allocator = std.testing.FailingAllocator.init(std.testing.allocator, 5);
    const result = functionThatUsesAnAllocator(&failing_allocator.allocator, 32);
    std.testing.expectError(error.OutOfMemory, result);
}

test "leaks" {
    // Uncomment me to see result of memory leak

    // const result = functionThatLeaks(std.testing.allocator);
}

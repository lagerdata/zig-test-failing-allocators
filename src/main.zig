const std = @import("std");
const FailOnAllocationSize = @import("fail_on_allocation_size.zig").FailingAllocator;
const FailOnStochastically = @import("fail_stochastically.zig").FailingAllocator;
const functionThatUsesAnAllocator = @import("util.zig").functionThatUsesAnAllocator;
const rand = std.rand;


test "fail after N allocations" {
    // baseline that should not fail
    const success = try functionThatUsesAnAllocator(std.testing.allocator, 32, 10);
    std.testing.expect(success == 32);

    // Create an allocator that fails after the 5th allocation
    var failing_allocator = std.testing.FailingAllocator.init(std.testing.allocator, 5);

    // Perform 5 allocations, success
    const success_2 = try functionThatUsesAnAllocator(&failing_allocator.allocator, 5, 5);
    std.testing.expect(success_2 == 5);

    // Try to allocate one more time and fail
    const result = functionThatUsesAnAllocator(&failing_allocator.allocator, 32, 1);
    std.testing.expectError(error.OutOfMemory, result);
}

test "fail allocation stochastically" {
    // In a real example you would choose a random seed and record it to replay failures
    var prng = rand.DefaultPrng.init(0);

    // Pull NUMALLOCS from environment, or use 10 as default
    const numallocs_env = std.os.getenv("NUMALLOCS") orelse "10";
    const numallocs = try std.fmt.parseInt(usize, numallocs_env, 10);

    // Pull FAILCHANCE from environment, or use 0.1 as default
    const fail_chance_env = std.os.getenv("FAILCHANCE") orelse "0.1";
    const fail_chance = try std.fmt.parseFloat(f64, fail_chance_env);

    // Create an allocator that fails with probability FAILCHANCE on any given allocation
    var failing_allocator = FailOnStochastically.init(std.testing.allocator, fail_chance, &prng.random);

    var result = functionThatUsesAnAllocator(&failing_allocator.allocator, 10, numallocs);
    if (result) |value| {
        std.debug.print("No memory errors\n", .{});
        std.testing.expect(value == numallocs);
    } else |err| {
        std.debug.print("Memory error caught\n", .{});
        std.testing.expect(err == error.OutOfMemory);
    }
}

test "fail on size N allocation" {
    // Create an allocator that fails when trying to allocate a block of size 5
    var failing_allocator = FailOnAllocationSize.init(std.testing.allocator, 5);

    // Allocate 10 bytes 5 times, no problem
    var result = functionThatUsesAnAllocator(&failing_allocator.allocator, 10, 5);
    std.testing.expect((try result) == 10);

    // Try to allocate 5 bytes 1 time, fails with OutOfMemory
    result = functionThatUsesAnAllocator(&failing_allocator.allocator, 5, 1);
    std.testing.expectError(error.OutOfMemory, result);
}

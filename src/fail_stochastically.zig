const std = @import("std");
const mem = std.mem;
const rand = std.rand;

pub const FailingAllocator = struct {
    allocator: mem.Allocator,
    fail_chance: f64,
    internal_allocator: *mem.Allocator,
    prng: *rand.Random,

    /// `fail_size` is the size of an allocation that will cause a memory failure
    ///
    /// var a = try failing_alloc.create(i32);
    /// var b = try failing_alloc.create(i32);
    /// testing.expectError(error.OutOfMemory, failing_alloc.create(i32));
    pub fn init(allocator: *mem.Allocator, fail_chance: f64, prng: *rand.Random) FailingAllocator {
        return FailingAllocator{
            .internal_allocator = allocator,
            .fail_chance = fail_chance,
            .prng = prng,
            .allocator = mem.Allocator{
                .allocFn = alloc,
                .resizeFn = resize,
            },
        };
    }

    fn alloc(
        allocator: *std.mem.Allocator,
        len: usize,
        ptr_align: u29,
        len_align: u29,
        return_address: usize,
    ) error{OutOfMemory}![]u8 {
        const self = @fieldParentPtr(FailingAllocator, "allocator", allocator);
        const val = self.prng.float(f64);
        if (val <= self.fail_chance) {
            return error.OutOfMemory;
        }
        return self.internal_allocator.allocFn(self.internal_allocator, len, ptr_align, len_align, return_address);
    }

    fn resize(
        allocator: *std.mem.Allocator,
        old_mem: []u8,
        old_align: u29,
        new_len: usize,
        len_align: u29,
        ra: usize,
    ) error{OutOfMemory}!usize {
        const self = @fieldParentPtr(FailingAllocator, "allocator", allocator);
        return self.internal_allocator.resizeFn(self.internal_allocator, old_mem, old_align, new_len, len_align, ra);
    }
};

test "fail allocation stochastically" {
    var prng = rand.DefaultPrng.init(0);
    const functionThatUsesAnAllocator = @import("util.zig").functionThatUsesAnAllocator;

    const numallocs_env = std.os.getenv("NUMALLOCS") orelse "10";
    const numallocs = try std.fmt.parseInt(usize, numallocs_env, 10);

    const fail_chance_env = std.os.getenv("FAILCHANCE") orelse "0.1";
    const fail_chance = try std.fmt.parseFloat(f64, fail_chance_env);

    var failing_allocator = FailingAllocator.init(std.testing.allocator, fail_chance, &prng.random);

    var result = functionThatUsesAnAllocator(&failing_allocator.allocator, numallocs);
    if (result) |value| {
        std.debug.print("No memory errors\n", .{});
        std.testing.expect(value == numallocs);
    } else |err| {
        std.debug.print("Memory error caught\n", .{});
        std.testing.expect(err == error.OutOfMemory);
    }
}


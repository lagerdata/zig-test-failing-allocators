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

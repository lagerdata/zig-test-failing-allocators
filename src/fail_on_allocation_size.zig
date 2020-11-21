const std = @import("std");
const mem = std.mem;

pub const FailingAllocator = struct {
    allocator: mem.Allocator,
    fail_size: usize,
    internal_allocator: *mem.Allocator,

    /// `fail_size` is the size of an allocation that will cause a memory failure
    ///
    /// var a = try failing_alloc.create(i32);
    /// var b = try failing_alloc.create(i32);
    /// testing.expectError(error.OutOfMemory, failing_alloc.create(i32));
    pub fn init(allocator: *mem.Allocator, fail_size: usize) FailingAllocator {
        return FailingAllocator{
            .internal_allocator = allocator,
            .fail_size = fail_size,
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
        if (self.fail_size == len) {
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

test "fail on size N allocation" {
    const functionThatUsesAnAllocator = @import("util.zig").functionThatUsesAnAllocator;

    var failing_allocator = FailingAllocator.init(std.testing.allocator, 5);

    var result = functionThatUsesAnAllocator(&failing_allocator.allocator, 10);
    // std.testing.expect((try result) == 10);

    // result = functionThatUsesAnAllocator(&failing_allocator.allocator, 5);
    // std.testing.expectError(error.OutOfMemory, result);
}


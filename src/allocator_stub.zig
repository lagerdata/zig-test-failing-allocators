const std = @import("std");
const mem = std.mem;

pub const MyAllocator = struct {
    allocator: mem.Allocator,
    internal_allocator: *mem.Allocator,

    pub fn init(allocator: *mem.Allocator) MyAllocator {
        return MyAllocator{
            .internal_allocator = allocator,
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
        const self = @fieldParentPtr(MyAllocator, "allocator", allocator);
        // implement custom logic here
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
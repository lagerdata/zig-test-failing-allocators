const std = @import("std");
const mem = std.mem;

pub fn functionThatUsesAnAllocator(allocator: *mem.Allocator, size: usize, times: usize) !usize {
    var i : usize = 0;
    while (i < times) {
        const memory = try allocator.alloc(u8, size);
        defer allocator.free(memory);
        i += 1;
    }
    return size;
}

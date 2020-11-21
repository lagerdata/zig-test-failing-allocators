const std = @import("std");
const mem = std.mem;

fn range(max: usize) []const void {
    return @as([]const void, &[_]void{}).ptr[0..max];
}

pub fn functionThatUsesAnAllocator(allocator: *mem.Allocator, size: usize, times: usize) !usize {
    for (range(times)) |_, i| {
        const memory = try allocator.alloc(u8, size);
        defer allocator.free(memory);
    }
    return size;
}

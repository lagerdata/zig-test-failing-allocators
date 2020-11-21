const std = @import("std");
const mem = std.mem;

fn range(max: usize) []const void {
    return @as([]const void, &[_]void{}).ptr[0..max];
}

pub fn functionThatUsesAnAllocator(allocator: *mem.Allocator, size: usize) !usize {
    for (range(10)) |_, i| {
        const memory = try allocator.alloc(u8, size);
        defer allocator.free(memory);
    }
    return size;
}

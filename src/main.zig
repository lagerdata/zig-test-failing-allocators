test "all" {
    _ = @import("fail_on_allocation_size.zig");
    _ = @import("fail_on_n_allocations.zig");
    _ = @import("fail_stochastically.zig");
}
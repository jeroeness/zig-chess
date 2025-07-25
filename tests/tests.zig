const std = @import("std");

test {
    _ = @import("board_test.zig");
    _ = @import("renderer_test.zig");
    _ = @import("action_test.zig");
    _ = @import("gamestate_test.zig");
    _ = @import("turn_test.zig");
}

const std = @import("std");
const board_module = @import("../board.zig");
const piece_module = @import("../piece.zig");
const action_module = @import("action.zig");

pub const Board = board_module.Board;
pub const Action = action_module.Action;

// Concrete Skip action - represents skipping a turn
pub const Skip = struct {
    player_color: piece_module.PieceColor, // Which player is skipping their turn

    pub fn init(player_color: piece_module.PieceColor) Skip {
        return Skip{
            .player_color = player_color,
        };
    }

    // Create an Action interface for this Skip
    pub fn asAction(self: *Skip, allocator: std.mem.Allocator) !*Action {
        const action = try allocator.create(Action);
        action.* = Action{
            .executeFn = executeSkip,
            .undoFn = undoSkip,
            .toStringFn = skipToString,
            .deinitFn = deinitSkip,
            .data = self,
        };
        return action;
    }

    // Implementation of execute for Skip
    fn executeSkip(action: *const Action, game_board: *Board) bool {
        // Skip action doesn't change the board state
        _ = action;
        _ = game_board;
        return true;
    }

    // Implementation of undo for Skip
    fn undoSkip(action: *const Action, game_board: *Board) bool {
        // Skip action doesn't change the board state, so undo is trivial
        _ = action;
        _ = game_board;
        return true;
    }

    // Implementation of toString for Skip
    fn skipToString(action: *const Action, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        const skip = @as(*const Skip, @ptrCast(@alignCast(action.data)));
        const color_str = switch (skip.player_color) {
            .white => "White",
            .black => "Black",
        };
        return std.fmt.allocPrint(allocator, "{s} skips turn", .{color_str});
    }

    // Implementation of deinit for Skip
    fn deinitSkip(action: *const Action, allocator: std.mem.Allocator) void {
        _ = action;
        _ = allocator;
        // Skip doesn't need special cleanup
    }
};

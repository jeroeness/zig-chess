const std = @import("std");
const board_module = @import("../board.zig");
const piece_module = @import("../piece.zig");
const coord_module = @import("../coord.zig");
const move_module = @import("move.zig");
const skip_module = @import("skip.zig");

pub const Board = board_module.Board;
pub const Piece = piece_module.Piece;
pub const Coord = coord_module.Coord;
pub const Move = move_module.Move;
pub const Skip = skip_module.Skip;

// Abstract Action interface using function pointers
pub const Action = struct {
    const Self = @This();

    // Function pointer for executing the action
    executeFn: *const fn (action: *const Action, game_board: *Board) bool,
    // Function pointer for undoing the action
    undoFn: *const fn (action: *const Action, game_board: *Board) bool,
    // Function pointer for getting string representation
    toStringFn: *const fn (action: *const Action, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8,
    // Function pointer for cleanup
    deinitFn: *const fn (action: *const Action, allocator: std.mem.Allocator) void,

    // Pointer to the actual data (will be cast to specific action type)
    data: *anyopaque,

    // Interface methods
    pub fn execute(self: *const Action, game_board: *Board) bool {
        return self.executeFn(self, game_board);
    }

    pub fn undo(self: *const Action, game_board: *Board) bool {
        return self.undoFn(self, game_board);
    }

    pub fn toString(self: *const Action, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        return self.toStringFn(self, allocator);
    }

    pub fn deinit(self: *const Action, allocator: std.mem.Allocator) void {
        self.deinitFn(self, allocator);
    }
};

const std = @import("std");
const action = @import("actions/action.zig");
const piece = @import("piece.zig");
const board = @import("board.zig");

pub const Action = action.Action;
pub const Piece = piece.Piece;
pub const Board = board.Board;

pub const Turn = struct {
    actions: std.ArrayList(*Action),
    captures: std.ArrayList(Piece),
    side: u8,
    ply: i32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, side: u8, ply: i32) Turn {
        return Turn{
            .actions = std.ArrayList(*Action).init(allocator),
            .captures = std.ArrayList(Piece).init(allocator),
            .side = side,
            .ply = ply,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Turn) void {
        for (self.actions.items) |action_ptr| {
            action_ptr.deinit(self.allocator);
            self.allocator.destroy(action_ptr);
        }
        self.actions.deinit();
        self.captures.deinit();
    }

    pub fn addAction(self: *Turn, action_ptr: *Action) !void {
        try self.actions.append(action_ptr);
    }

    pub fn addCapture(self: *Turn, captured_piece: Piece) !void {
        try self.captures.append(captured_piece);
    }

    pub fn getActionCount(self: *const Turn) usize {
        return self.actions.items.len;
    }

    pub fn getCaptureCount(self: *const Turn) usize {
        return self.captures.items.len;
    }

    pub fn getAction(self: *const Turn, index: usize) ?*Action {
        if (index >= self.actions.items.len) {
            return null;
        }
        return self.actions.items[index];
    }

    pub fn getCapture(self: *const Turn, index: usize) ?Piece {
        if (index >= self.captures.items.len) {
            return null;
        }
        return self.captures.items[index];
    }

    pub fn undoAllActions(self: *Turn, game_board: *Board) bool {
        var all_successful = true;

        var i = self.actions.items.len;
        while (i > 0) {
            i -= 1;
            const action_ptr = self.actions.items[i];
            const success = action_ptr.undo(game_board);
            if (!success) {
                all_successful = false;
            }
        }

        return all_successful;
    }
};
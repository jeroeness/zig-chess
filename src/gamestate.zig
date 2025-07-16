const std = @import("std");
const board = @import("board.zig");
const action = @import("actions/action.zig");
const piece = @import("piece.zig");

pub const Board = board.Board;
pub const Action = action.Action;
pub const PieceColor = piece.PieceColor;

// GameState class that manages the board and action history
pub const GameState = struct {
    board: Board,
    actions: std.ArrayList(*Action),
    allocator: std.mem.Allocator,
    current_turn: PieceColor,

    pub fn init(allocator: std.mem.Allocator) GameState {
        return GameState{
            .board = Board.init(),
            .actions = std.ArrayList(*Action).init(allocator),
            .allocator = allocator,
            .current_turn = .white,
        };
    }

    pub fn deinit(self: *GameState) void {
        // Clean up all actions
        for (self.actions.items) |action_ptr| {
            action_ptr.deinit(self.allocator);
            self.allocator.destroy(action_ptr);
        }
        self.actions.deinit();
    }

    pub fn executeAction(self: *GameState, action_ptr: *Action) !bool {
        const success = action_ptr.execute(&self.board);
        if (success) {
            try self.actions.append(action_ptr);
        }
        return success;
    }

    pub fn undoLastAction(self: *GameState) bool {
        if (self.actions.items.len == 0) {
            return false;
        }

        if (self.actions.pop()) |last_action| {
            const success = last_action.undo(&self.board);

            if (success) {
                // Clean up the action
                last_action.deinit(self.allocator);
                self.allocator.destroy(last_action);
            } else {
                // If undo failed, put the action back
                self.actions.append(last_action) catch return false;
            }

            return success;
        }
        return false;
    }

    pub fn getActionCount(self: *const GameState) usize {
        return self.actions.items.len;
    }

    pub fn getAction(self: *const GameState, index: usize) ?*Action {
        if (index >= self.actions.items.len) {
            return null;
        }
        return self.actions.items[index];
    }

    pub fn getLastAction(self: *const GameState) ?*Action {
        if (self.actions.items.len == 0) {
            return null;
        }
        return self.actions.items[self.actions.items.len - 1];
    }

    pub fn clearActions(self: *GameState) void {
        // Clean up all actions
        for (self.actions.items) |action_ptr| {
            action_ptr.deinit(self.allocator);
            self.allocator.destroy(action_ptr);
        }
        self.actions.clearAndFree();
    }

    pub fn setupInitialPosition(self: *GameState) void {
        self.board.setupInitialPosition();
    }

    pub fn getBoard(self: *GameState) *Board {
        return &self.board;
    }

    pub fn getBoardConst(self: *const GameState) *const Board {
        return &self.board;
    }

    pub fn getTurn(self: *const GameState) PieceColor {
        return self.current_turn;
    }

    pub fn nextTurn(self: *GameState) void {
        self.current_turn = switch (self.current_turn) {
            .white => .black,
            .black => .white,
        };
    }

    pub fn getHistoryLength(self: *const GameState) usize {
        return self.actions.items.len;
    }

    pub fn hash(self: *const GameState) u64 {
        // Create a mutable copy to call hash on
        var board_copy = self.board;
        return board_copy.hash();
    }

    pub fn eql(self: *const GameState, other: GameState) bool {
        return self.board.eql(other.board) and self.current_turn == other.current_turn;
    }

    pub fn serialize(self: *const GameState, allocator: std.mem.Allocator) ![]u32 {
        return self.board.serialize(allocator);
    }

    pub fn deserialize(data: []const u32, allocator: std.mem.Allocator) !GameState {
        var state = GameState.init(allocator);
        state.board = try Board.deserialize(data, allocator);
        return state;
    }
};

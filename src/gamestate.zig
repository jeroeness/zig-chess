const std = @import("std");
const board = @import("board.zig");
const action = @import("actions/action.zig");
const piece = @import("piece.zig");
const turn = @import("turn.zig");

pub const Board = board.Board;
pub const Action = action.Action;
pub const PieceColor = piece.PieceColor;
pub const Turn = turn.Turn;

// GameState class that manages the board and action history
pub const GameState = struct {
    board: Board,
    turns: std.ArrayList(*Turn),
    allocator: std.mem.Allocator,
    current_turn: PieceColor,
    current_ply: i32,

    pub fn init(allocator: std.mem.Allocator) GameState {
        return GameState{
            .board = Board.init(),
            .turns = std.ArrayList(*Turn).init(allocator),
            .allocator = allocator,
            .current_turn = .white,
            .current_ply = 0,
        };
    }

    pub fn deinit(self: *GameState) void {
        for (self.turns.items) |turn_ptr| {
            turn_ptr.deinit();
            self.allocator.destroy(turn_ptr);
        }
        self.turns.deinit();
    }

    pub fn executeAction(self: *GameState, action_ptr: *Action) !bool {
        const side: u8 = if (self.current_turn == .white) 0 else 1;

        var current_turn_ptr: *Turn = undefined;

        if (self.turns.items.len == 0 or self.turns.items[self.turns.items.len - 1].side != side) {
            current_turn_ptr = try self.allocator.create(Turn);
            current_turn_ptr.* = Turn.init(self.allocator, side, self.current_ply);
            try self.turns.append(current_turn_ptr);
        } else {
            current_turn_ptr = self.turns.items[self.turns.items.len - 1];
        }

        const success = action_ptr.execute(&self.board);
        if (success) {
            try current_turn_ptr.addAction(action_ptr);
            self.nextTurn();
            if (side == 1) {
                self.current_ply += 1;
            }
            return true;
        }
        return false;
    }

    pub fn undoLastAction(self: *GameState) bool {
        if (self.turns.items.len == 0) {
            return false;
        }

        const last_turn = self.turns.items[self.turns.items.len - 1];
        if (last_turn.actions.items.len == 0) {
            return false;
        }

        const last_action = last_turn.actions.items[last_turn.actions.items.len - 1];
        const success = last_action.undo(&self.board);

        if (success) {
            _ = last_turn.actions.pop();
            last_action.deinit(self.allocator);
            self.allocator.destroy(last_action);

            if (last_turn.actions.items.len == 0) {
                _ = self.turns.pop();
                last_turn.deinit();
                self.allocator.destroy(last_turn);
            }
        }

        return success;
    }

    pub fn getActionCount(self: *const GameState) usize {
        var total_actions: usize = 0;
        for (self.turns.items) |turn_ptr| {
            total_actions += turn_ptr.getActionCount();
        }
        return total_actions;
    }

    pub fn getAction(self: *const GameState, index: usize) ?*Action {
        var current_index: usize = 0;
        for (self.turns.items) |turn_ptr| {
            if (index < current_index + turn_ptr.getActionCount()) {
                return turn_ptr.getAction(index - current_index);
            }
            current_index += turn_ptr.getActionCount();
        }
        return null;
    }

    pub fn getLastAction(self: *const GameState) ?*Action {
        if (self.turns.items.len == 0) {
            return null;
        }
        const last_turn = self.turns.items[self.turns.items.len - 1];
        if (last_turn.actions.items.len == 0) {
            return null;
        }
        return last_turn.actions.items[last_turn.actions.items.len - 1];
    }

    pub fn clearActions(self: *GameState) void {
        for (self.turns.items) |turn_ptr| {
            turn_ptr.deinit();
            self.allocator.destroy(turn_ptr);
        }
        self.turns.clearAndFree();
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
        return self.turns.items.len;
    }

    pub fn getTurnCount(self: *const GameState) usize {
        return self.turns.items.len;
    }

    pub fn getTurnByIndex(self: *const GameState, index: usize) ?*Turn {
        if (index >= self.turns.items.len) {
            return null;
        }
        return self.turns.items[index];
    }

    pub fn getLastTurn(self: *const GameState) ?*Turn {
        if (self.turns.items.len == 0) {
            return null;
        }
        return self.turns.items[self.turns.items.len - 1];
    }

    pub fn getCurrentPly(self: *const GameState) i32 {
        return self.current_ply;
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

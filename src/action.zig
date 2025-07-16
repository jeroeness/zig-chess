const std = @import("std");
const board_module = @import("board.zig");
const piece_module = @import("piece.zig");

pub const Board = board_module.Board;
pub const Piece = piece_module.Piece;

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

// Coordinate position on the board
pub const Coord = struct {
    row: u8,
    col: u8,

    pub fn init(row: u8, col: u8) Coord {
        return Coord{
            .row = row,
            .col = col,
        };
    }

    pub fn isValid(self: Coord) bool {
        return self.row < 8 and self.col < 8;
    }

    pub fn eql(self: Coord, other: Coord) bool {
        return self.row == other.row and self.col == other.col;
    }

    pub fn toString(self: Coord, allocator: std.mem.Allocator) ![]u8 {
        const col_char = @as(u8, 'a') + self.col;
        const row_char = @as(u8, '1') + self.row;
        return std.fmt.allocPrint(allocator, "{c}{c}", .{ col_char, row_char });
    }
};

// Concrete Move action
pub const Move = struct {
    start_coord: Coord,
    target_coord: Coord,
    captured_piece: ?Piece = null, // For undo functionality
    promotion_type: ?piece_module.PieceType = null, // For pawn promotion
    original_piece: ?Piece = null, // For undoing promotion

    pub fn init(start_coord: Coord, target_coord: Coord) Move {
        return Move{
            .start_coord = start_coord,
            .target_coord = target_coord,
        };
    }

    pub fn initWithPromotion(start_coord: Coord, target_coord: Coord, promotion_type: piece_module.PieceType) Move {
        return Move{
            .start_coord = start_coord,
            .target_coord = target_coord,
            .promotion_type = promotion_type,
        };
    }

    pub fn initFromCoords(start_row: u8, start_col: u8, target_row: u8, target_col: u8) Move {
        return Move{
            .start_coord = Coord.init(start_row, start_col),
            .target_coord = Coord.init(target_row, target_col),
        };
    }

    pub fn initFromCoordsWithPromotion(start_row: u8, start_col: u8, target_row: u8, target_col: u8, promotion_type: piece_module.PieceType) Move {
        return Move{
            .start_coord = Coord.init(start_row, start_col),
            .target_coord = Coord.init(target_row, target_col),
            .promotion_type = promotion_type,
        };
    }

    // Create an Action interface for this Move
    pub fn asAction(self: *Move, allocator: std.mem.Allocator) !*Action {
        const action = try allocator.create(Action);
        action.* = Action{
            .executeFn = executeMove,
            .undoFn = undoMove,
            .toStringFn = moveToString,
            .deinitFn = deinitMove,
            .data = self,
        };
        return action;
    }

    // Implementation of execute for Move
    fn executeMove(action: *const Action, game_board: *Board) bool {
        const move = @as(*const Move, @ptrCast(@alignCast(action.data)));

        // Validate coordinates
        if (!move.start_coord.isValid() or !move.target_coord.isValid()) {
            return false;
        }

        // Check if there's a piece at the start coordinate
        const piece_at_start = game_board.getPieceConst(move.start_coord.row, move.start_coord.col);
        if (piece_at_start == null) {
            return false;
        }

        // Store captured piece for undo
        const move_mut = @as(*Move, @ptrCast(@alignCast(@constCast(action.data))));
        move_mut.captured_piece = game_board.getPieceConst(move.target_coord.row, move.target_coord.col);

        // Execute the move
        const move_success = game_board.movePiece(move.start_coord.row, move.start_coord.col, move.target_coord.row, move.target_coord.col);
        if (!move_success) {
            return false;
        }

        // Handle pawn promotion
        if (move.promotion_type) |promo_type| {
            const moved_piece = game_board.getPieceConst(move.target_coord.row, move.target_coord.col);
            if (moved_piece) |piece| {
                // Store original piece for undo
                move_mut.original_piece = piece;
                const promoted_piece = Piece.init(promo_type, piece.color);
                _ = game_board.setPiece(move.target_coord.row, move.target_coord.col, promoted_piece);
            }
        }

        return true;
    }

    // Implementation of undo for Move
    fn undoMove(action: *const Action, game_board: *Board) bool {
        const move = @as(*const Move, @ptrCast(@alignCast(action.data)));

        // Validate coordinates
        if (!move.start_coord.isValid() or !move.target_coord.isValid()) {
            return false;
        }

        // Get the piece at target coordinate (should be the piece we moved)
        const moved_piece = game_board.getPieceConst(move.target_coord.row, move.target_coord.col);
        if (moved_piece == null) {
            return false;
        }

        // If this was a promotion, restore the original piece type
        var piece_to_move_back = moved_piece.?;
        if (move.promotion_type != null and move.original_piece != null) {
            piece_to_move_back = move.original_piece.?;
        }

        // Move piece back to start coordinate
        _ = game_board.setPiece(move.start_coord.row, move.start_coord.col, piece_to_move_back);

        // Clear the target coordinate first
        _ = game_board.clearPiece(move.target_coord.row, move.target_coord.col);

        // Restore captured piece if any
        if (move.captured_piece) |captured| {
            _ = game_board.setPiece(move.target_coord.row, move.target_coord.col, captured);
        }

        return true;
    }

    // Implementation of toString for Move
    fn moveToString(action: *const Action, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        const move = @as(*const Move, @ptrCast(@alignCast(action.data)));

        const start_str = try move.start_coord.toString(allocator);
        defer allocator.free(start_str);

        const target_str = try move.target_coord.toString(allocator);
        defer allocator.free(target_str);

        const capture_symbol = if (move.captured_piece != null) "x" else "-";

        if (move.promotion_type) |promo_type| {
            const promo_char = switch (promo_type) {
                .queen => "Q",
                .rook => "R",
                .knight => "N",
                .bishop => "B",
                .amazon => "A",
                else => "?",
            };
            return std.fmt.allocPrint(allocator, "{s}{s}{s}={s}", .{ start_str, capture_symbol, target_str, promo_char });
        } else {
            return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ start_str, capture_symbol, target_str });
        }
    }

    // Implementation of deinit for Move
    fn deinitMove(action: *const Action, allocator: std.mem.Allocator) void {
        _ = action;
        _ = allocator;
        // Move doesn't need special cleanup
    }
};

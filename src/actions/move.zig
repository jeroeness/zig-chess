const std = @import("std");
const board_module = @import("../board.zig");
const piece_module = @import("../piece.zig");
const piecetype_module = @import("../pieces/piecetype.zig");
const coord_module = @import("../coord.zig");
const action_module = @import("action.zig");

pub const Board = board_module.Board;
pub const Piece = piece_module.Piece;
pub const Coord = coord_module.Coord;
pub const Action = action_module.Action;
const PieceType = piecetype_module.PieceType;

pub const Move = struct {
    start_coord: Coord,
    target_coord: Coord,
    captured_piece: ?Piece = null,
    promotion_type: ?PieceType = null,
    original_piece: ?Piece = null,

    pub fn init(start_coord: Coord, target_coord: Coord) Move {
        return Move{
            .start_coord = start_coord,
            .target_coord = target_coord,
        };
    }

    pub fn initWithPromotion(start_coord: Coord, target_coord: Coord, promotion_type: PieceType) Move {
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

    pub fn initFromCoordsWithPromotion(start_row: u8, start_col: u8, target_row: u8, target_col: u8, promotion_type: PieceType) Move {
        return Move{
            .start_coord = Coord.init(start_row, start_col),
            .target_coord = Coord.init(target_row, target_col),
            .promotion_type = promotion_type,
        };
    }

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

    pub fn toString(self: *const Move, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        const start_str = try self.start_coord.toString(allocator);
        defer allocator.free(start_str);

        const target_str = try self.target_coord.toString(allocator);
        defer allocator.free(target_str);

        const capture_symbol = if (self.captured_piece != null) "x" else "-";

        if (self.promotion_type) |promo_type| {
            const promo_char = switch (promo_type) {
                .queen => "Q",
                .rook => "R",
                .knight => "N",
                .bishop => "B",
                .amazon => "A",
                else => "?",
            };
            try std.debug.print("{s}{s}{s}={s}\n", .{ start_str, capture_symbol, target_str, promo_char });
            return allocator.alloc(u8, 0);
        } else {
            try std.debug.print("{s}{s}{s}\n", .{ start_str, capture_symbol, target_str });
            return allocator.alloc(u8, 0);
        }
    }

    fn executeMove(action: *const Action, game_board: *Board) bool {
        const move = @as(*const Move, @ptrCast(@alignCast(action.data)));

        if (!move.start_coord.isValid() or !move.target_coord.isValid()) {
            return false;
        }

        const piece_at_start = game_board.getPieceConst(move.start_coord);
        if (piece_at_start == null) {
            return false;
        }

        const move_mut = @as(*Move, @ptrCast(@alignCast(@constCast(action.data))));
        move_mut.captured_piece = game_board.getPieceConst(move.target_coord);

        const move_success = game_board.movePiece(move.start_coord, move.target_coord);
        if (!move_success) {
            return false;
        }

        if (move.promotion_type) |promo_type| {
            const moved_piece = game_board.getPieceConst(move.target_coord);
            if (moved_piece) |piece| {
                move_mut.original_piece = piece;
                const promoted_piece = Piece.init(promo_type, piece.getColor(), piece.id);
                _ = game_board.setPiece(move.target_coord, promoted_piece);
            }
        }

        return true;
    }

    fn undoMove(action: *const Action, game_board: *Board) bool {
        const move = @as(*const Move, @ptrCast(@alignCast(action.data)));

        if (!move.start_coord.isValid() or !move.target_coord.isValid()) {
            return false;
        }

        const moved_piece = game_board.getPieceConst(move.target_coord);
        if (moved_piece == null) {
            return false;
        }

        var piece_to_move_back = moved_piece.?;
        if (move.promotion_type != null and move.original_piece != null) {
            piece_to_move_back = move.original_piece.?;
        }

        _ = game_board.setPiece(move.start_coord, piece_to_move_back);

        _ = game_board.clearPiece(move.target_coord);

        if (move.captured_piece) |captured| {
            _ = game_board.setPiece(move.target_coord, captured);
        }

        return true;
    }

    fn moveToString(action: *const Action, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        const move = @as(*const Move, @ptrCast(@alignCast(action.data)));
        const start_str = try move.start_coord.toString(allocator);
        defer allocator.free(start_str);
        const target_str = try move.target_coord.toString(allocator);
        defer allocator.free(target_str);
        const capture_symbol = if (move.captured_piece != null) "x" else "-";
        if (move.promotion_type) |promo_type| {
            const promo_char = piecetype_module.toString(promo_type);
            return std.fmt.allocPrint(allocator, "{s}{s}{s}={s}", .{ start_str, capture_symbol, target_str, promo_char });
        } else {
            return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ start_str, capture_symbol, target_str });
        }
    }

    fn deinitMove(action: *const Action, allocator: std.mem.Allocator) void {
        _ = action;
        _ = allocator;
    }
};

const std = @import("std");
const pieceType = @import("pieces/piecetype.zig");
const movement = @import("pieces/movement.zig");
const PieceType = pieceType.PieceType;

pub const PieceColor = enum(u8) {
    white = 0x00,
    black = 0x80,
};

pub const PieceTypeColor = u8;

pub fn pieceToString(piece: Piece) []const u8 {
    const piece_type = piece.getType();

    const symbol = switch (piece_type) {
        .none => " ",
        .pawn => "P",
        .rook => "R",
        .knight => "N",
        .bishop => "B",
        .queen => "Q",
        .king => "K",
        else => "?",
    };
    return symbol;
}
pub const Piece = struct {
    piece: PieceTypeColor,
    id: u8,

    pub fn init(piece_type: PieceType, color: PieceColor, id: u8) Piece {
        return Piece{
            .piece = @intFromEnum(piece_type) + @intFromEnum(color),
            .id = id,
        };
    }

    pub fn toString(piece: Piece) []const u8 {
        return pieceToString(piece);
    }

    pub fn isColor(self: Piece, color: PieceColor) bool {
        return (self.piece & 0x80) == @intFromEnum(color);
    }

    pub fn isType(self: Piece, piece_type: PieceType) bool {
        return (self.piece & 0x7F) == @intFromEnum(piece_type);
    }

    pub fn getType(self: Piece) PieceType {
        return @enumFromInt(self.piece & 0x7F);
    }

    pub fn getColor(self: Piece) PieceColor {
        return @enumFromInt(self.piece & 0x80);
    }

    pub fn isEmpty(self: Piece) bool {
        return self.piece & 0x7F == .none;
    }

    pub fn serialize(self: Piece) [2]u32 {
        return [2]u32{ self.piece, self.id };
    }

    pub fn deserialize(data: [2]u32) Piece {
        return Piece{
            .piece = @intCast(data[0]),
            .id = @intCast(data[1]),
        };
    }

    pub fn hash(self: Piece) u64 {
        return @as(u64, self.piece) ^ (@as(u64, self.id) << 8);
    }

    pub fn eql(self: Piece, other: Piece) bool {
        return self.piece == other.piece and self.id == other.id;
    }

    pub fn getMoves(self: Piece, from: movement.Coord, board: *const movement.Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!movement.MoveList {
        return movement.getMoves(self, from, board, allocator);
    }
};

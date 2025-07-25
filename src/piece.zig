const std = @import("std");

pub const PieceType = enum(u32) {
    none = 0,
    pawn = 1,
    rook = 2,
    knight = 3,
    bishop = 4,
    queen = 5,
    king = 6,
    amazon = 7, 
};

pub const PieceColor = enum(u32) {
    white = 0x00, 
    black = 0x10, 
};

pub const Piece = struct {
    piece_type: PieceType,
    color: PieceColor,

    pub fn init(piece_type: PieceType, color: PieceColor) Piece {
        return Piece{
            .piece_type = piece_type,
            .color = color,
        };
    }

    pub fn isEmpty(self: Piece) bool {
        return self.piece_type == .none;
    }

    pub fn serialize(self: Piece) [2]u32 {
        return [2]u32{ @intFromEnum(self.piece_type), @intFromEnum(self.color) };
    }

    pub fn deserialize(data: [2]u32) !Piece {
        const piece_type = @as(PieceType, @enumFromInt(data[0]));
        const color = @as(PieceColor, @enumFromInt(data[1]));

        return Piece.init(piece_type, color);
    }

    pub fn hash(self: Piece) u64 {
        return @as(u64, @intFromEnum(self.piece_type)) ^ @as(u64, @intFromEnum(self.color));
    }

    pub fn eql(self: Piece, other: Piece) bool {
        return self.piece_type == other.piece_type and self.color == other.color;
    }
};
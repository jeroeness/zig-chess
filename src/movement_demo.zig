const std = @import("std");
const root = @import("root_chess");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = root.Board.init();

    const pieces = [_]struct { piece: root.Piece, name: []const u8, pos: root.Coord }{
        .{ .piece = root.Piece.init(.pawn, .white, 1), .name = "White Pawn", .pos = root.Coord.init(1, 4) },
        .{ .piece = root.Piece.init(.knight, .white, 2), .name = "White Knight", .pos = root.Coord.init(4, 4) },
        .{ .piece = root.Piece.init(.rook, .white, 3), .name = "White Rook", .pos = root.Coord.init(0, 0) },
        .{ .piece = root.Piece.init(.bishop, .white, 4), .name = "White Bishop", .pos = root.Coord.init(4, 4) },
        .{ .piece = root.Piece.init(.queen, .white, 5), .name = "White Queen", .pos = root.Coord.init(4, 4) },
        .{ .piece = root.Piece.init(.king, .white, 6), .name = "White King", .pos = root.Coord.init(4, 4) },
    };

    for (pieces) |piece_info| {
        board.pieces[piece_info.pos.row][piece_info.pos.col] = piece_info.piece;

        var moves = try piece_info.piece.getMoves(piece_info.pos, &board, allocator);
        defer moves.deinit();

        std.debug.print("{s} at {c}{c} can move to {} squares:\n", .{ piece_info.name, @as(u8, 'a') + piece_info.pos.col, @as(u8, '1') + piece_info.pos.row, moves.items.len });

        for (moves.items) |move| {
            std.debug.print("  {c}{c}\n", .{ @as(u8, 'a') + move.col, @as(u8, '1') + move.row });
        }

        std.debug.print("\n");

        board.pieces[piece_info.pos.row][piece_info.pos.col] = null;
    }
}

const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var chess_board = root.Board.init();

    _ = chess_board.setPiece(0, 0, root.Piece.init(.rook, .black));
    _ = chess_board.setPiece(0, 1, root.Piece.init(.knight, .black));
    _ = chess_board.setPiece(0, 2, root.Piece.init(.bishop, .black));
    _ = chess_board.setPiece(0, 3, root.Piece.init(.queen, .black));
    _ = chess_board.setPiece(0, 4, root.Piece.init(.king, .black));
    _ = chess_board.setPiece(0, 5, root.Piece.init(.bishop, .black));
    _ = chess_board.setPiece(0, 6, root.Piece.init(.knight, .black));
    _ = chess_board.setPiece(0, 7, root.Piece.init(.rook, .black));

    for (0..8) |col| {
        _ = chess_board.setPiece(1, @intCast(col), root.Piece.init(.pawn, .black));
    }

    for (0..8) |col| {
        _ = chess_board.setPiece(6, @intCast(col), root.Piece.init(.pawn, .white));
    }

    _ = chess_board.setPiece(7, 0, root.Piece.init(.rook, .white));
    _ = chess_board.setPiece(7, 1, root.Piece.init(.knight, .white));
    _ = chess_board.setPiece(7, 2, root.Piece.init(.bishop, .white));
    _ = chess_board.setPiece(7, 3, root.Piece.init(.queen, .white));
    _ = chess_board.setPiece(7, 4, root.Piece.init(.king, .white));
    _ = chess_board.setPiece(7, 5, root.Piece.init(.bishop, .white));
    _ = chess_board.setPiece(7, 6, root.Piece.init(.knight, .white));
    _ = chess_board.setPiece(7, 7, root.Piece.init(.rook, .white));

    const config = root.RendererConfig{
        .cell_size = 8,
        .show_coordinates = true,
        .use_unicode = false,
    };

    var renderer = root.Renderer.init(allocator, config);
    defer renderer.deinit();

    try std.debug.print("Chess Board Renderer Demo\n", .{});
    try std.debug.print("=========================\n\n", .{});

    try std.debug.print("Board with Unicode shapes:\n", .{});
    try renderer.render(&chess_board);

    try renderer.printLegend();

    try std.debug.print("\nBoard in ASCII mode:\n", .{});
    try renderer.renderAscii(&chess_board);

    try std.debug.print("\nAfter moving white pawn from e2 to e4:\n", .{});
    _ = chess_board.movePiece(6, 4, 4, 4); 
    try renderer.render(&chess_board);
}
const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    // Create a chess board
    var chess_board = root.Board.init();

    // Set up some initial pieces for demonstration
    _ = chess_board.setPiece(0, 0, root.Piece.init(.rook, .black));
    _ = chess_board.setPiece(0, 1, root.Piece.init(.knight, .black));
    _ = chess_board.setPiece(0, 2, root.Piece.init(.bishop, .black));
    _ = chess_board.setPiece(0, 3, root.Piece.init(.queen, .black));
    _ = chess_board.setPiece(0, 4, root.Piece.init(.king, .black));
    _ = chess_board.setPiece(0, 5, root.Piece.init(.bishop, .black));
    _ = chess_board.setPiece(0, 6, root.Piece.init(.knight, .black));
    _ = chess_board.setPiece(0, 7, root.Piece.init(.rook, .black));

    // Black pawns
    for (0..8) |col| {
        _ = chess_board.setPiece(1, @intCast(col), root.Piece.init(.pawn, .black));
    }

    // White pawns
    for (0..8) |col| {
        _ = chess_board.setPiece(6, @intCast(col), root.Piece.init(.pawn, .white));
    }

    // White pieces
    _ = chess_board.setPiece(7, 0, root.Piece.init(.rook, .white));
    _ = chess_board.setPiece(7, 1, root.Piece.init(.knight, .white));
    _ = chess_board.setPiece(7, 2, root.Piece.init(.bishop, .white));
    _ = chess_board.setPiece(7, 3, root.Piece.init(.queen, .white));
    _ = chess_board.setPiece(7, 4, root.Piece.init(.king, .white));
    _ = chess_board.setPiece(7, 5, root.Piece.init(.bishop, .white));
    _ = chess_board.setPiece(7, 6, root.Piece.init(.knight, .white));
    _ = chess_board.setPiece(7, 7, root.Piece.init(.rook, .white));

    // Create renderer with default config
    const config = root.RendererConfig{
        .cell_size = 8,
        .show_coordinates = true,
        .use_unicode = false,
    };

    var renderer = root.Renderer.init(allocator, config);
    defer renderer.deinit();

    // Print title
    try std.debug.print("Chess Board Renderer Demo\n", .{});
    try std.debug.print("=========================\n\n", .{});

    // Render the board with Unicode shapes
    try std.debug.print("Board with Unicode shapes:\n", .{});
    try renderer.render(&chess_board);

    // Print legend
    try renderer.printLegend();

    // Render the board in ASCII mode
    try std.debug.print("\nBoard in ASCII mode:\n", .{});
    try renderer.renderAscii(&chess_board);

    // Demo: Move a piece and render again
    try std.debug.print("\nAfter moving white pawn from e2 to e4:\n", .{});
    _ = chess_board.movePiece(6, 4, 4, 4); // Move pawn from e2 to e4
    try renderer.render(&chess_board);
}

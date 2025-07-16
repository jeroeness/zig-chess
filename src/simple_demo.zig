const std = @import("std");
const renderer = @import("renderer.zig");
const board = @import("board.zig");
const piece = @import("piece.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a chess board
    var chess_board = board.Board.init();

    // Set up some initial pieces for demonstration
    _ = chess_board.setPiece(0, 0, piece.Piece.init(.rook, .black));
    _ = chess_board.setPiece(0, 4, piece.Piece.init(.king, .black));
    _ = chess_board.setPiece(7, 4, piece.Piece.init(.king, .white));
    _ = chess_board.setPiece(7, 0, piece.Piece.init(.rook, .white));

    // Place some pawns
    _ = chess_board.setPiece(1, 0, piece.Piece.init(.pawn, .black));
    _ = chess_board.setPiece(6, 0, piece.Piece.init(.pawn, .white));

    // Create renderer with default config
    const config = renderer.RendererConfig{
        .cell_size = 8,
        .show_coordinates = true,
        .use_unicode = false,
    };

    var board_renderer = renderer.Renderer.init(allocator, config);
    defer board_renderer.deinit();

    // Print title
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Chess Board Renderer Demo\n", .{});
    try stdout.print("=========================\n\n", .{});

    // Render the board with Unicode shapes
    try stdout.print("Board with Unicode shapes:\n", .{});
    try board_renderer.render(&chess_board);

    // Print legend
    try board_renderer.printLegend();

    // Render the board in ASCII mode
    try stdout.print("\nBoard in ASCII mode:\n", .{});
    try board_renderer.renderAscii(&chess_board);
}

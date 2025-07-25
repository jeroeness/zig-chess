const std = @import("std");
const renderer = @import("renderer.zig");
const board = @import("board.zig");
const piece = @import("piece.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var chess_board = board.Board.init();

    _ = chess_board.setPiece(0, 0, piece.Piece.init(.rook, .black));
    _ = chess_board.setPiece(0, 4, piece.Piece.init(.king, .black));
    _ = chess_board.setPiece(7, 4, piece.Piece.init(.king, .white));
    _ = chess_board.setPiece(7, 0, piece.Piece.init(.rook, .white));

    _ = chess_board.setPiece(1, 0, piece.Piece.init(.pawn, .black));
    _ = chess_board.setPiece(6, 0, piece.Piece.init(.pawn, .white));

    const config = renderer.RendererConfig{
        .cell_size = 8,
        .show_coordinates = true,
        .use_unicode = false,
    };

    var board_renderer = renderer.Renderer.init(allocator, config);
    defer board_renderer.deinit();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Chess Board Renderer Demo\n", .{});
    try stdout.print("=========================\n\n", .{});

    try stdout.print("Board with Unicode shapes:\n", .{});
    try board_renderer.render(&chess_board);

    try board_renderer.printLegend();

    try stdout.print("\nBoard in ASCII mode:\n", .{});
    try board_renderer.renderAscii(&chess_board);
}
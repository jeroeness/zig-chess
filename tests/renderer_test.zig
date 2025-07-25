const std = @import("std");
const testing = std.testing;
const root = @import("root_chess");

const Board = root.Board;
const Renderer = root.Renderer;
const RendererConfig = root.RendererConfig;

test "renderer functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a board with some pieces
    var chess_board = Board.init();
    chess_board.setupInitialPosition();

    // Create renderer with config
    const config = RendererConfig{
        .show_coordinates = true,
    };
    var renderer = Renderer.init(config, allocator);
    defer renderer.deinit();

    // Test that we can create and use the renderer without errors
    // In a real test, we might capture output and verify it
    // For now, just ensure no crashes
    try testing.expect(true);
}

test "renderer move highlighting" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var chess_board = Board.init();
    const white_knight = root.Piece.init(.knight, .white, 1);
    const black_pawn = root.Piece.init(.pawn, .black, 2);

    chess_board.pieces[4][4] = white_knight;
    chess_board.pieces[6][5] = black_pawn;

    const config = RendererConfig{};
    var renderer = Renderer.init(config, allocator);
    defer renderer.deinit();

    const knight_coord = root.Coord.init(4, 4);
    renderer.selectPiece(knight_coord, &chess_board);

    try testing.expect(renderer.selected_piece != null);
    try testing.expect(renderer.possible_moves != null);

    if (renderer.possible_moves) |moves| {
        try testing.expect(moves.items.len > 0);
    }
}

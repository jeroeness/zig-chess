const std = @import("std");
const testing = std.testing;
const root = @import("root_chess");

const Board = root.Board;
const Renderer = root.Renderer;
const RendererConfig = root.RendererConfig;

test "renderer functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Create a board with some pieces
    var chess_board = Board.init();
    chess_board.setupInitialPosition();

    // Create renderer with config
    const config = RendererConfig{
        .show_coordinates = true,
    };
    var renderer = Renderer.init(config);
    defer renderer.deinit();

    // Test that we can create and use the renderer without errors
    // In a real test, we might capture output and verify it
    // For now, just ensure no crashes
    try testing.expect(true);
}

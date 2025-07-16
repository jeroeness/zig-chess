// build with `zig build-exe cimport.zig -lc -lraylib`
const ray = @cImport({
    @cInclude("raylib.h");
});
const std = @import("std");
const board = @import("board.zig");
const renderer = @import("renderer.zig");

const Board = board.Board;
const Renderer = renderer.Renderer;
const RendererConfig = renderer.RendererConfig;
const GameState = @import("gamestate.zig").GameState;
const Move = @import("actions/move.zig").Move;

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 800;

    ray.InitWindow(screenWidth, screenHeight, "Zig Chess with Raylib");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    var game_state = GameState.init(std.heap.page_allocator);
    defer game_state.deinit();
    // Initialize chess board

    game_state.getBoard().setupInitialPosition();
    var move = Move.initFromCoords(6, 4, 7, 4);
    const move_action = try move.asAction(std.heap.page_allocator);
    const result = try game_state.executeAction(move_action);
    std.debug.print("Move executed: {}\n", .{result});
    // _ = game_state.undoLastAction();

    // Initialize renderer with configuration
    const config = RendererConfig{
        .cell_size = 80,
        .board_offset_x = 80,
        .board_offset_y = 80,
        .show_coordinates = true,
        .use_unicode = false,
    };
    const chess_renderer = Renderer.init(config);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.RAYWHITE);

        // Draw the chess board and pieces
        chess_renderer.drawBoard(game_state.getBoard());

        // Draw coordinate labels
        chess_renderer.drawCoordinates();

        // Draw title
        chess_renderer.drawTitle();

        // Check for Q key press to exit
        if (ray.IsKeyPressed(ray.KEY_Q)) {
            break;
        }
    }
}

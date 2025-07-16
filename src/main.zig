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

pub fn main() void {
    const screenWidth = 800;
    const screenHeight = 800;

    ray.InitWindow(screenWidth, screenHeight, "Zig Chess with Raylib");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    // Initialize chess board
    var chess_board = Board.init();
    chess_board.setupInitialPosition();

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
        chess_renderer.drawBoard(&chess_board);

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

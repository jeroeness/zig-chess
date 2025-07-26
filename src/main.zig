const std = @import("std");
const root = @import("root_chess.zig");

const ray = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 800;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    ray.InitWindow(screen_width, screen_height, "Zig Chess");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    var chess_board = root.Board.init();
    chess_board.setupInitialPosition();

    const config = root.RendererConfig{
        .cell_size = 80,
        .board_offset_x = 80,
        .board_offset_y = 80,
        .show_coordinates = true,
        .use_unicode = false,
    };

    var gamestate = root.GameState.init(allocator);
    defer gamestate.deinit();

    var renderer = root.Renderer.init(config, allocator);
    defer renderer.deinit();

    while (!ray.WindowShouldClose()) {
        renderer.handleMouseClick(&chess_board, &gamestate);

        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.RAYWHITE);

        renderer.drawBoard(&chess_board);

        renderer.drawCoordinates();

        renderer.drawTitle();
    }
}

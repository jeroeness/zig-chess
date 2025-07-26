const std = @import("std");
const board = @import("board.zig");
const piece = @import("piece.zig");
const cell = @import("cell.zig");
const coord = @import("coord.zig");
const movement = @import("pieces/movement.zig");
const gamestate = @import("gamestate.zig");
const move_action = @import("actions/move.zig");

const ray = @cImport({
    @cInclude("raylib.h");
});

pub const Board = board.Board;
pub const Piece = piece.Piece;
pub const PieceType = piece.PieceType;
pub const PieceColor = piece.PieceColor;
pub const Cell = cell.Cell;
pub const Coord = coord.Coord;
pub const MoveList = movement.MoveList;
pub const GameState = gamestate.GameState;
pub const Move = move_action.Move;

pub const RendererConfig = struct {
    cell_size: i32 = 80,
    board_offset_x: i32 = 80,
    board_offset_y: i32 = 80,
    show_coordinates: bool = true,
    use_unicode: bool = false,
};

pub const Renderer = struct {
    config: RendererConfig,
    selected_piece: ?Coord,
    possible_moves: ?MoveList,
    allocator: std.mem.Allocator,
    font: ray.Font,

    pub fn init(config: RendererConfig, allocator: std.mem.Allocator) Renderer {
        const font = ray.LoadFont("DejaVuSans.ttf");
        const final_font = if (font.texture.id == 0) ray.GetFontDefault() else font;

        return Renderer{
            .config = config,
            .selected_piece = null,
            .possible_moves = null,
            .allocator = allocator,
            .font = final_font,
        };
    }

    pub fn deinit(self: *Renderer) void {
        if (self.possible_moves) |*moves| {
            moves.deinit();
        }
        if (self.font.texture.id != ray.GetFontDefault().texture.id) {
            ray.UnloadFont(self.font);
        }
    }

    pub fn handleMouseClick(self: *Renderer, board_ref: *const Board, game_state: *GameState) void {
        if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT)) {
            const mouse_pos = ray.GetMousePosition();
            const coord_opt = self.screenToBoard(mouse_pos.x, mouse_pos.y);

            if (coord_opt) |clicked_coord| {
                const piece_opt = board_ref.getPieceConst(clicked_coord.row, clicked_coord.col);

                if (self.selected_piece) |selected_coord| {
                    if (self.isValidMove(clicked_coord)) {
                        self.executeMove(selected_coord, clicked_coord, game_state);
                        self.clearSelection();
                        return;
                    }
                }

                if (piece_opt != null) {
                    if (self.selected_piece) |selected| {
                        if (selected.eql(clicked_coord)) {
                            self.clearSelection();
                        } else {
                            self.selectPiece(clicked_coord, board_ref);
                        }
                    } else {
                        self.selectPiece(clicked_coord, board_ref);
                    }
                } else {
                    self.clearSelection();
                }
            } else {
                self.clearSelection();
            }
        }
    }

    pub fn selectPiece(self: *Renderer, piece_coord: Coord, board_ref: *const Board) void {
        self.clearSelection();

        if (board_ref.getPieceConst(piece_coord.row, piece_coord.col)) |selected_piece| {
            self.selected_piece = piece_coord;
            self.possible_moves = selected_piece.getMoves(piece_coord, board_ref, self.allocator) catch null;
        }
    }

    fn clearSelection(self: *Renderer) void {
        self.selected_piece = null;
        if (self.possible_moves) |*moves| {
            moves.deinit();
            self.possible_moves = null;
        }
    }

    fn isValidMove(self: *const Renderer, target_coord: Coord) bool {
        if (self.possible_moves) |moves| {
            for (moves.items) |move| {
                if (move.eql(target_coord)) {
                    return true;
                }
            }
        }
        return false;
    }

    fn executeMove(self: *Renderer, start_coord: Coord, target_coord: Coord, game_state: *GameState) void {
        var move = Move.init(start_coord, target_coord);
        const action = move.asAction(self.allocator) catch return;

        // Debug print action
        const action_str = action.toString(self.allocator) catch "Error converting action to string";
        std.debug.print("Executing action: {}\n", .{action_str});

        const success = game_state.executeAction(action) catch false;
        if (!success) {
            action.deinit(self.allocator);
            self.allocator.destroy(action);
        }
    }

    fn screenToBoard(self: *const Renderer, screen_x: f32, screen_y: f32) ?Coord {
        const board_x = screen_x - @as(f32, @floatFromInt(self.config.board_offset_x));
        const board_y = screen_y - @as(f32, @floatFromInt(self.config.board_offset_y));

        if (board_x < 0 or board_y < 0) return null;

        const col = @as(u8, @intFromFloat(board_x / @as(f32, @floatFromInt(self.config.cell_size))));
        const row = @as(u8, @intFromFloat(board_y / @as(f32, @floatFromInt(self.config.cell_size))));

        const result = Coord.init(row, col);
        if (result.isValid()) {
            return result;
        }

        return null;
    }

    pub fn drawBoard(self: *const Renderer, chess_board: *const Board) void {
        const BOARD_SIZE = 8;

        for (0..BOARD_SIZE) |row| {
            for (0..BOARD_SIZE) |col| {
                const x = self.config.board_offset_x + @as(i32, @intCast(col)) * self.config.cell_size;
                const y = self.config.board_offset_y + @as(i32, @intCast(row)) * self.config.cell_size;

                const is_light_square = (row + col) % 2 == 0;

                const color = if (is_light_square) ray.BEIGE else ray.BROWN;
                ray.DrawRectangle(x, y, self.config.cell_size, self.config.cell_size, color);

                ray.DrawRectangleLines(x, y, self.config.cell_size, self.config.cell_size, ray.BLACK);
            }
        }

        self.drawMoveHighlights(chess_board);

        for (0..BOARD_SIZE) |row| {
            for (0..BOARD_SIZE) |col| {
                const piece_opt = chess_board.getPieceConst(@intCast(row), @intCast(col));
                if (piece_opt) |piece_val| {
                    self.drawPiece(piece_val, @intCast(row), @intCast(col));
                }
            }
        }

        ray.DrawRectangleLines(self.config.board_offset_x - 2, self.config.board_offset_y - 2, BOARD_SIZE * self.config.cell_size + 4, BOARD_SIZE * self.config.cell_size + 4, ray.BLACK);
    }

    fn drawPiece(self: *const Renderer, piece_val: Piece, row: u8, col: u8) void {
        const x = self.config.board_offset_x + @as(i32, @intCast(col)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2);
        const y = self.config.board_offset_y + @as(i32, @intCast(row)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2);

        const piece_symbol = switch (piece_val.getType()) {
            .pawn => "P",
            .rook => "R",
            .knight => "N",
            .bishop => "B",
            .queen => "Q",
            .king => "K",
            .amazon => "A",
            .none => "",
            else => "?", // Fallback for unknown piece types
        };

        const text_color = switch (piece_val.getColor()) {
            .white => ray.BLACK,
            .black => ray.WHITE,
        };

        const bg_color = switch (piece_val.getColor()) {
            .white => ray.LIGHTGRAY,
            .black => ray.DARKGRAY,
        };

        const current_coord = Coord.init(row, col);
        const is_selected = if (self.selected_piece) |selected| selected.eql(current_coord) else false;

        if (is_selected) {
            ray.DrawCircle(x, y, 35, ray.YELLOW);
            ray.DrawCircleLines(x, y, 35, ray.YELLOW);
        }

        ray.DrawCircle(x, y, 25, bg_color);
        ray.DrawCircleLines(x, y, 25, ray.BLACK);

        const text_width = ray.MeasureTextEx(self.font, piece_symbol.ptr, 24, 0).x;
        const text_pos = ray.Vector2{ .x = @as(f32, @floatFromInt(x)) - text_width / 2, .y = @as(f32, @floatFromInt(y - 12)) };
        ray.DrawTextEx(self.font, piece_symbol.ptr, text_pos, 24, 0, text_color);
    }

    fn drawMoveHighlights(self: *const Renderer, chess_board: *const Board) void {
        if (self.possible_moves) |moves| {
            for (moves.items) |move| {
                const x = self.config.board_offset_x + @as(i32, @intCast(move.col)) * self.config.cell_size;
                const y = self.config.board_offset_y + @as(i32, @intCast(move.row)) * self.config.cell_size;
                const center_x = x + @divTrunc(self.config.cell_size, 2);
                const center_y = y + @divTrunc(self.config.cell_size, 2);

                const target_piece = chess_board.getPieceConst(move.row, move.col);
                if (target_piece != null) {
                    self.drawCaptureTriangles(x, y);
                } else {
                    ray.DrawCircle(center_x, center_y, 12, ray.ColorAlpha(ray.DARKGREEN, 0.5));
                }
            }
        }
    }

    fn drawCaptureTriangles(self: *const Renderer, x: i32, y: i32) void {
        const triangle_size = 12;
        const margin = 4;

        const corners = [_][2]i32{
            .{ x + margin, y + margin },
            .{ x + self.config.cell_size - margin, y + margin },
            .{ x + margin, y + self.config.cell_size - margin },
            .{ x + self.config.cell_size - margin, y + self.config.cell_size - margin },
        };

        const triangle_offsets = [_][3][2]i32{
            .{ .{ 0, 0 }, .{ triangle_size, 0 }, .{ 0, triangle_size } },
            .{ .{ 0, 0 }, .{ -triangle_size, 0 }, .{ 0, triangle_size } },
            .{ .{ 0, 0 }, .{ triangle_size, 0 }, .{ 0, -triangle_size } },
            .{ .{ 0, 0 }, .{ -triangle_size, 0 }, .{ 0, -triangle_size } },
        };

        for (corners, triangle_offsets) |corner, offsets| {
            const v1 = ray.Vector2{ .x = @as(f32, @floatFromInt(corner[0] + offsets[0][0])), .y = @as(f32, @floatFromInt(corner[1] + offsets[0][1])) };
            const v2 = ray.Vector2{ .x = @as(f32, @floatFromInt(corner[0] + offsets[1][0])), .y = @as(f32, @floatFromInt(corner[1] + offsets[1][1])) };
            const v3 = ray.Vector2{ .x = @as(f32, @floatFromInt(corner[0] + offsets[2][0])), .y = @as(f32, @floatFromInt(corner[1] + offsets[2][1])) };

            ray.DrawTriangle(v1, v2, v3, ray.ColorAlpha(ray.DARKGREEN, 0.5));
        }
    }

    pub fn drawCoordinates(self: *const Renderer) void {
        if (!self.config.show_coordinates) return;

        const BOARD_SIZE = 8;

        for (0..8) |col| {
            const file_char = @as(u8, @intCast('a' + col));
            const file_str = [_]u8{ file_char, 0 };
            const x = self.config.board_offset_x + @as(i32, @intCast(col)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2) - 5;
            const y = self.config.board_offset_y + BOARD_SIZE * self.config.cell_size + 10;
            const text_pos = ray.Vector2{ .x = @as(f32, @floatFromInt(x)), .y = @as(f32, @floatFromInt(y)) };
            ray.DrawTextEx(self.font, @ptrCast(&file_str), text_pos, 20, 0, ray.BLACK);
        }

        for (0..8) |row| {
            const rank_char = @as(u8, @intCast('8' - row));
            const rank_str = [_]u8{ rank_char, 0 };
            const x = self.config.board_offset_x - 30;
            const y = self.config.board_offset_y + @as(i32, @intCast(row)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2) - 10;
            const text_pos = ray.Vector2{ .x = @as(f32, @floatFromInt(x)), .y = @as(f32, @floatFromInt(y)) };
            ray.DrawTextEx(self.font, @ptrCast(&rank_str), text_pos, 20, 0, ray.BLACK);
        }
    }

    pub fn drawTitle(self: *const Renderer) void {
        const text_pos = ray.Vector2{ .x = 10, .y = 10 };
        ray.DrawTextEx(self.font, "Zig Chess", text_pos, 30, 0, ray.BLACK);
    }
};

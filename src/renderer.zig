const std = @import("std");
const board = @import("board.zig");
const piece = @import("piece.zig");
const cell = @import("cell.zig");

const ray = @cImport({
    @cInclude("raylib.h");
});

pub const Board = board.Board;
pub const Piece = piece.Piece;
pub const PieceType = piece.PieceType;
pub const PieceColor = piece.PieceColor;
pub const Cell = cell.Cell;

// Renderer configuration
pub const RendererConfig = struct {
    cell_size: i32 = 80,
    board_offset_x: i32 = 80,
    board_offset_y: i32 = 80,
    show_coordinates: bool = true,
    use_unicode: bool = false,
};

// Renderer class for displaying the chess board
pub const Renderer = struct {
    config: RendererConfig,

    pub fn init(config: RendererConfig) Renderer {
        return Renderer{
            .config = config,
        };
    }

    pub fn deinit(self: *const Renderer) void {
        // No resources to free in this simple implementation
        _ = self; // unused parameter
    }

    pub fn drawBoard(self: *const Renderer, chess_board: *const Board) void {
        const BOARD_SIZE = 8;

        // Draw the chess board squares
        for (0..BOARD_SIZE) |row| {
            for (0..BOARD_SIZE) |col| {
                const x = self.config.board_offset_x + @as(i32, @intCast(col)) * self.config.cell_size;
                const y = self.config.board_offset_y + @as(i32, @intCast(row)) * self.config.cell_size;

                // Alternate colors for checkerboard pattern
                const is_light_square = (row + col) % 2 == 0;
                const color = if (is_light_square) ray.BEIGE else ray.BROWN;

                ray.DrawRectangle(x, y, self.config.cell_size, self.config.cell_size, color);

                // Draw border for each square
                ray.DrawRectangleLines(x, y, self.config.cell_size, self.config.cell_size, ray.BLACK);
            }
        }

        // Draw pieces
        for (0..BOARD_SIZE) |row| {
            for (0..BOARD_SIZE) |col| {
                const piece_opt = chess_board.getPieceConst(@intCast(row), @intCast(col));
                if (piece_opt) |piece_val| {
                    self.drawPiece(piece_val, @intCast(row), @intCast(col));
                }
            }
        }

        // Draw board border
        ray.DrawRectangleLines(self.config.board_offset_x - 2, self.config.board_offset_y - 2, BOARD_SIZE * self.config.cell_size + 4, BOARD_SIZE * self.config.cell_size + 4, ray.BLACK);
    }

    fn drawPiece(self: *const Renderer, piece_val: Piece, row: u8, col: u8) void {
        const x = self.config.board_offset_x + @as(i32, @intCast(col)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2);
        const y = self.config.board_offset_y + @as(i32, @intCast(row)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2);

        // Choose piece symbol based on type
        const piece_symbol = switch (piece_val.piece_type) {
            .pawn => "P",
            .rook => "R",
            .knight => "N",
            .bishop => "B",
            .queen => "Q",
            .king => "K",
            .amazon => "A", // Amazon fairy piece
            .none => "",
        };

        // Choose color based on piece color
        const text_color = switch (piece_val.color) {
            .white => ray.WHITE,
            .black => ray.BLACK,
        };

        // Draw a circle background for the piece
        const bg_color = switch (piece_val.color) {
            .white => ray.LIGHTGRAY,
            .black => ray.DARKGRAY,
        };

        ray.DrawCircle(x, y, 25, bg_color);
        ray.DrawCircleLines(x, y, 25, ray.BLACK);

        // Draw piece symbol
        const text_width = ray.MeasureText(piece_symbol.ptr, 24);
        ray.DrawText(piece_symbol.ptr, x - @divTrunc(text_width, 2), y - 12, 24, text_color);
    }

    pub fn drawCoordinates(self: *const Renderer) void {
        if (!self.config.show_coordinates) return;

        const BOARD_SIZE = 8;

        // Draw file labels (a-h) at the bottom
        for (0..8) |col| {
            const file_char = @as(u8, @intCast('a' + col));
            const file_str = [_]u8{ file_char, 0 };
            const x = self.config.board_offset_x + @as(i32, @intCast(col)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2) - 5;
            const y = self.config.board_offset_y + BOARD_SIZE * self.config.cell_size + 10;
            ray.DrawText(@ptrCast(&file_str), x, y, 20, ray.BLACK);
        }

        // Draw rank labels (1-8) on the left side
        for (0..8) |row| {
            const rank_char = @as(u8, @intCast('8' - row));
            const rank_str = [_]u8{ rank_char, 0 };
            const x = self.config.board_offset_x - 30;
            const y = self.config.board_offset_y + @as(i32, @intCast(row)) * self.config.cell_size + @divTrunc(self.config.cell_size, 2) - 10;
            ray.DrawText(@ptrCast(&rank_str), x, y, 20, ray.BLACK);
        }
    }

    pub fn drawTitle(self: *const Renderer) void {
        _ = self; // unused parameter
        ray.DrawText("Zig Chess", 10, 10, 30, ray.BLACK);
    }
};

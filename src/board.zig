const std = @import("std");
const piece = @import("piece.zig");
const cell = @import("cell.zig");

pub const Piece = piece.Piece;
pub const Cell = cell.Cell;

// Represents the chess board
pub const Board = struct {
    cells: [8][8]Cell,
    pieces: [8][8]?Piece,
    saved_hash: u64 = 0,

    pub fn init() Board {
        var board = Board{
            .cells = undefined,
            .pieces = undefined,
        };

        // Initialize all cells and pieces
        for (0..8) |row| {
            for (0..8) |col| {
                board.cells[row][col] = Cell.init(@intCast(row), @intCast(col));
                board.pieces[row][col] = null;
            }
        }

        return board;
    }

    pub fn getCell(self: *Board, row: usize, col: usize) ?*Cell {
        if (row >= 8 or col >= 8) {
            return null;
        }
        return &self.cells[row][col];
    }

    pub fn getCellConst(self: *const Board, row: u8, col: u8) ?*const Cell {
        if (row >= 8 or col >= 8) {
            return null;
        }
        return &self.cells[row][col];
    }

    pub fn getPiece(self: *Board, row: u8, col: u8) ?*?Piece {
        if (row >= 8 or col >= 8) {
            return null;
        }
        return &self.pieces[row][col];
    }

    pub fn getPieceConst(self: *const Board, row: u8, col: u8) ?Piece {
        if (row >= 8 or col >= 8) {
            return null;
        }
        return self.pieces[row][col];
    }

    pub fn isEmpty(self: *const Board, row: usize, col: usize) bool {
        if (row >= 8 or col >= 8) {
            return false;
        }
        return self.pieces[row][col] == null;
    }

    pub fn setPiece(self: *Board, row: u8, col: u8, new_piece: Piece) bool {
        if (row >= 8 or col >= 8) {
            return false;
        }
        self.pieces[row][col] = new_piece;
        return true;
    }

    pub fn clearPiece(self: *Board, row: u8, col: u8) bool {
        if (row >= 8 or col >= 8) {
            return false;
        }
        self.pieces[row][col] = null;
        return true;
    }

    pub fn movePiece(self: *Board, from_row: u8, from_col: u8, to_row: u8, to_col: u8) bool {
        if (from_row >= 8 or from_col >= 8 or to_row >= 8 or to_col >= 8) {
            return false;
        }

        const piece_to_move = self.pieces[from_row][from_col];
        if (piece_to_move == null) {
            return false;
        }

        self.pieces[to_row][to_col] = piece_to_move;
        self.pieces[from_row][from_col] = null;
        return true;
    }

    pub fn setupInitialPosition(self: *Board) void {
        // Clear the board first
        for (0..8) |row| {
            for (0..8) |col| {
                self.pieces[row][col] = null;
            }
        }

        // Place white pieces
        _ = self.setPiece(0, 0, Piece.init(.rook, .white));
        _ = self.setPiece(0, 1, Piece.init(.knight, .white));
        _ = self.setPiece(0, 2, Piece.init(.bishop, .white));
        _ = self.setPiece(0, 3, Piece.init(.queen, .white));
        _ = self.setPiece(0, 4, Piece.init(.king, .white));
        _ = self.setPiece(0, 5, Piece.init(.bishop, .white));
        _ = self.setPiece(0, 6, Piece.init(.amazon, .white));
        _ = self.setPiece(0, 7, Piece.init(.rook, .white));

        // Place white pawns
        for (0..8) |col| {
            _ = self.setPiece(1, @intCast(col), Piece.init(.pawn, .white));
        }

        // Place black pieces
        _ = self.setPiece(7, 0, Piece.init(.rook, .black));
        _ = self.setPiece(7, 1, Piece.init(.knight, .black));
        _ = self.setPiece(7, 2, Piece.init(.bishop, .black));
        _ = self.setPiece(7, 3, Piece.init(.queen, .black));
        _ = self.setPiece(7, 4, Piece.init(.king, .black));
        _ = self.setPiece(7, 5, Piece.init(.bishop, .black));
        _ = self.setPiece(7, 6, Piece.init(.amazon, .black));
        _ = self.setPiece(7, 7, Piece.init(.rook, .black));

        // Place black pawns
        for (0..8) |col| {
            _ = self.setPiece(6, @intCast(col), Piece.init(.pawn, .black));
        }
    }

    pub fn isValidPosition(row: u8, col: u8) bool {
        return row < 8 and col < 8;
    }

    // Binary serialization with dynamic typing
    pub fn serialize(self: Board, allocator: std.mem.Allocator) ![]u32 {
        var result = std.ArrayList(u32).init(allocator);
        defer result.deinit();

        for (0..8) |row| {
            for (0..8) |col| {
                // Serialize cell with type identifier
                try result.append(1); // Type 1 = Cell
                const cell_data = self.cells[row][col].serialize();
                try result.append(@intCast(cell_data.len));
                for (cell_data) |value| {
                    try result.append(@intCast(value));
                }

                // Serialize piece with type identifier
                if (self.pieces[row][col]) |current_piece| {
                    try result.append(2); // Type 2 = Piece
                    const piece_data = current_piece.serialize();
                    try result.append(@intCast(piece_data.len));
                    try result.appendSlice(&piece_data);
                } else {
                    try result.append(0); // Type 0 = No piece
                    try result.append(0); // Length 0
                }
            }
        }

        return result.toOwnedSlice();
    }

    // Binary deserialization with dynamic typing
    pub fn deserialize(data: []const u32, allocator: std.mem.Allocator) !Board {
        _ = allocator; // Unused parameter
        var board = Board.init();
        var index: usize = 0;

        for (0..8) |row| {
            for (0..8) |col| {
                // Deserialize cell
                if (index >= data.len) return error.InvalidData;
                const cell_type = data[index];
                index += 1;

                if (cell_type != 1) return error.InvalidCellType;

                if (index >= data.len) return error.InvalidData;
                const cell_data_len = data[index];
                index += 1;

                if (index + cell_data_len > data.len) return error.InvalidData;
                const cell_data = data[index .. index + cell_data_len];

                // Convert u32 slice to [3]u32 for cell deserialization
                if (cell_data.len != 3) return error.InvalidCellData;
                const cell_array: [3]u32 = cell_data[0..3].*;
                board.cells[row][col] = try Cell.deserialize(cell_array);
                index += cell_data_len;

                // Deserialize piece
                if (index >= data.len) return error.InvalidData;
                const piece_type = data[index];
                index += 1;

                if (index >= data.len) return error.InvalidData;
                const piece_data_len = data[index];
                index += 1;

                if (piece_type == 2) { // Piece exists
                    if (index + piece_data_len > data.len) return error.InvalidData;
                    const piece_data = data[index .. index + piece_data_len];

                    // Convert u32 slice to [2]u32 for piece deserialization
                    if (piece_data.len != 2) return error.InvalidPieceData;
                    const piece_array: [2]u32 = piece_data[0..2].*;
                    board.pieces[row][col] = try Piece.deserialize(piece_array);
                    index += piece_data_len;
                } else if (piece_type == 0) { // No piece
                    board.pieces[row][col] = null;
                    // piece_data_len should be 0, but we still need to advance index
                    index += piece_data_len;
                } else {
                    return error.InvalidPieceType;
                }
            }
        }

        return board;
    }

    // Hash function for comparing boards (optimized with XOR)
    // Hash function for comparing boards (optimized)
    pub fn hash(self: *Board) u64 {
        var result: u64 = 0;
        const zobrist_table = [_]u64{ 0x9D39247E33776D41, 0x2AF7398005AAA5C7, 0x44DB015024623547, 0x9C15F73E62A76AE2, 0x75834465489C0C89, 0x3826B398B4C0748B, 0x81F24AA026CCF93E, 0x4F63E5F4C8F20E01, 0x5B0E608526323C55, 0x1A46C1A9FA1D37F9, 0x806567CB0A61A2BA, 0x703B5835D9098C92, 0x2F8B8B78ACD28CBD, 0x7F6EF2E0F162FC45, 0x60A2F059A9906ABE, 0x520E518C68B37A52, 0x851B06CA6C093AA4, 0x73F17AF40DE2B1CE, 0x3F53D1B7DC8B7A6A, 0x6BC4FC5DEE3B618A, 0x37550B8C6B6B54BC, 0x1F25A3D14B2F2E1E, 0x8ED61D79A85B5A2D, 0x74A7426B64C2E3D5, 0x65B3D4DC8C7A8953, 0x1085BDA1ECCE6EA6, 0x7C6A042F2B4C0A5D, 0x5896B7E4AA08F7B2, 0x3D52A13C06490154, 0x6D8EEF4A6B785442, 0x7543FD1A05CC4C6D, 0x2B5B1C98DB6B6A18, 0x8F9B6E3F40AC3C75, 0x4C5F3BA09A59C712, 0x78D1E201E98EF4A6, 0x176F8D95D7C40F26, 0x695A7C3D2C1A8B4E, 0x34F3EAE5B15D0C93, 0x8B26F6C7E9B3A1D2, 0x5F4C3D2B7EA8F695, 0x7B9D8A4E5C3F2610, 0x2E7C49A1B5D8036F, 0x8A3E7B2C9D1F5648, 0x4D6F9C1A8B3E5270, 0x9F2A7E4B8D1C3560, 0x3B8D6F2A5C9E1470, 0x7E2B9C8A6D1F3540, 0x5A8F7D2C9B4E1630, 0x8D4B7E2A6C9F1350, 0x2C9F8A5D7E3B1460, 0x7A8D4B9E6C2F1570, 0x5E9C7A3D8B4F1260, 0x9A7E5C8D2B4F1360, 0x3F8B7D5A9C2E1470, 0x7D9A8C5E3B4F1680, 0x4E7B9D8A5B3F1270, 0x8C5F7A9D3B2E1480, 0x2A9E8C7D5B4F1390, 0x7C8A5D9E3B7F1450, 0x5D9C8A7E4B3F1260, 0x9E7C8D5A3B4F1370, 0x3A8F7D9C5E2B1480, 0x7F9A8C5D3E4B1690, 0x4C7E9D8A5B3F1270 };

        // Single pass through the board
        for (0..8) |row| {
            for (0..8) |col| {
                // Hash cell and piece in one iteration
                const position = @as(u64, row * 8 + col);
                result ^= self.cells[row][col].hash() ^ zobrist_table[position];

                if (self.pieces[row][col]) |current_piece| {
                    // Fix: remove redundant XOR of current_piece.hash()
                    const mixed_hash = current_piece.hash() ^ zobrist_table[position];
                    result ^= mixed_hash;
                }
            }
        }
        self.saved_hash = result;
        return result;
    }

    pub fn update_hash(self: *Board) void {
        self.saved_hash = self.hash();
    }

    pub fn eql_fast(self: *Board, other: *Board) bool {
        // Quick check using hashes
        const self_hash = self.hash();
        const other_hash = other.hash();
        if (self_hash != other_hash) {
            return false;
        }

        // If hashes match, do a full comparison
        return self.eql(other.*);
    }

    // Equality function for comparing boards
    pub fn eql(self: Board, other: Board) bool {
        // Compare all cells
        for (0..8) |row| {
            for (0..8) |col| {
                if (!self.cells[row][col].eql(other.cells[row][col])) {
                    return false;
                }
            }
        }

        // Compare all pieces
        for (0..8) |row| {
            for (0..8) |col| {
                const self_piece = self.pieces[row][col];
                const other_piece = other.pieces[row][col];

                // Both null
                if (self_piece == null and other_piece == null) {
                    continue;
                }

                // One null, one not
                if (self_piece == null or other_piece == null) {
                    return false;
                }

                // Both have pieces, compare them
                if (!self_piece.?.eql(other_piece.?)) {
                    return false;
                }
            }
        }
        return true;
    }
};

const std = @import("std");
const piece = @import("piece.zig");
const cell = @import("cell.zig");
const coord = @import("coord.zig");

pub const Piece = piece.Piece;
pub const Cell = cell.Cell;
pub const Coord = coord.Coord;

pub fn allCoords() [64]Coord {
    var coords: [64]Coord = undefined;
    var index: usize = 0;

    for (0..8) |row| {
        for (0..8) |col| {
            coords[index] = Coord.init(@intCast(row), @intCast(col));
            index += 1;
        }
    }

    return coords;
}

pub const Board = struct {
    cells: [8][8]Cell,
    pieces: [8][8]?Piece,
    saved_hash: u64 = 0,

    pub fn init() Board {
        var board = Board{
            .cells = undefined,
            .pieces = undefined,
        };

        for (0..8) |row| {
            for (0..8) |col| {
                board.cells[row][col] = Cell.init(@intCast(row), @intCast(col));
                board.pieces[row][col] = null;
            }
        }

        return board;
    }

    pub fn getCell(self: *Board, position: Coord) ?*Cell {
        if (!position.isValid()) {
            return null;
        }
        return &self.cells[position.row][position.col];
    }

    pub fn getCellConst(self: *const Board, position: Coord) ?*const Cell {
        if (!position.isValid()) {
            return null;
        }
        return &self.cells[position.row][position.col];
    }

    pub fn getPiece(self: *Board, position: Coord) ?*?Piece {
        if (!position.isValid()) {
            return null;
        }
        return &self.pieces[position.row][position.col];
    }

    pub fn getPieceConst(self: *const Board, position: Coord) ?Piece {
        if (!position.isValid()) {
            return null;
        }
        return self.pieces[position.row][position.col];
    }

    pub fn isEmpty(self: *const Board, position: Coord) bool {
        if (!position.isValid()) {
            return false;
        }
        return self.pieces[position.row][position.col] == null;
    }

    pub fn setPiece(self: *Board, position: Coord, new_piece: Piece) bool {
        if (!position.isValid()) {
            return false;
        }
        self.pieces[position.row][position.col] = new_piece;
        return true;
    }

    pub fn clearPiece(self: *Board, position: Coord) bool {
        if (!position.isValid()) {
            return false;
        }
        self.pieces[position.row][position.col] = null;
        return true;
    }

    pub fn movePiece(self: *Board, from: Coord, to: Coord) bool {
        if (!from.isValid() or !to.isValid()) {
            return false;
        }

        const piece_to_move = self.pieces[from.row][from.col];
        if (piece_to_move == null) {
            return false;
        }

        self.pieces[to.row][to.col] = piece_to_move;
        self.pieces[from.row][from.col] = null;
        return true;
    }

    pub fn setupInitialPosition(self: *Board) void {
        for (0..8) |row| {
            for (0..8) |col| {
                self.pieces[row][col] = null;
            }
        }
        var id: u8 = 0;

        _ = self.setPiece(Coord.init(0, 0), Piece.init(.rook, .white, id));
        id += 1;
        _ = self.setPiece(Coord.init(0, 1), Piece.init(.knight, .white, id));
        id += 1;
        _ = self.setPiece(Coord.init(0, 2), Piece.init(.bishop, .white, id));
        id += 1;
        _ = self.setPiece(Coord.init(0, 3), Piece.init(.queen, .white, id));
        id += 1;
        _ = self.setPiece(Coord.init(0, 4), Piece.init(.king, .white, id));
        id += 1;
        _ = self.setPiece(Coord.init(0, 5), Piece.init(.bishop, .white, id));
        id += 1;
        _ = self.setPiece(Coord.init(0, 6), Piece.init(.amazon, .white, id));
        id += 1;
        _ = self.setPiece(Coord.init(0, 7), Piece.init(.rook, .white, id));
        id += 1;

        for (0..8) |col| {
            _ = self.setPiece(Coord.init(1, @intCast(col)), Piece.init(.pawn, .white, id));
            id += 1;
        }

        _ = self.setPiece(Coord.init(7, 0), Piece.init(.rook, .black, id));
        id += 1;
        _ = self.setPiece(Coord.init(7, 1), Piece.init(.knight, .black, id));
        id += 1;
        _ = self.setPiece(Coord.init(7, 2), Piece.init(.bishop, .black, id));
        id += 1;
        _ = self.setPiece(Coord.init(7, 3), Piece.init(.queen, .black, id));
        id += 1;
        _ = self.setPiece(Coord.init(7, 4), Piece.init(.king, .black, id));
        id += 1;
        _ = self.setPiece(Coord.init(7, 5), Piece.init(.bishop, .black, id));
        id += 1;
        _ = self.setPiece(Coord.init(7, 6), Piece.init(.amazon, .black, id));
        id += 1;
        _ = self.setPiece(Coord.init(7, 7), Piece.init(.rook, .black, id));
        id += 1;

        for (0..8) |col| {
            _ = self.setPiece(Coord.init(6, @intCast(col)), Piece.init(.pawn, .black, id));
            id += 1;
        }
    }

    pub fn isValidPosition(position: Coord) bool {
        return position.isValid();
    }

    pub fn serialize(self: Board, allocator: std.mem.Allocator) ![]u32 {
        var result = std.ArrayList(u32).init(allocator);
        defer result.deinit();

        for (0..8) |row| {
            for (0..8) |col| {
                try result.append(1);
                const cell_data = self.cells[row][col].serialize();
                try result.append(@intCast(cell_data.len));
                for (cell_data) |value| {
                    try result.append(@intCast(value));
                }

                if (self.pieces[row][col]) |current_piece| {
                    try result.append(2);
                    const piece_data = current_piece.serialize();
                    try result.append(@intCast(piece_data.len));
                    try result.appendSlice(&piece_data);
                } else {
                    try result.append(0);
                    try result.append(0);
                }
            }
        }

        return result.toOwnedSlice();
    }

    pub fn deserialize(data: []const u32, allocator: std.mem.Allocator) !Board {
        _ = allocator;
        var board = Board.init();
        var index: usize = 0;

        for (0..8) |row| {
            for (0..8) |col| {
                if (index >= data.len) return error.InvalidData;
                const cell_type = data[index];
                index += 1;

                if (cell_type != 1) return error.InvalidCellType;

                if (index >= data.len) return error.InvalidData;
                const cell_data_len = data[index];
                index += 1;

                if (index + cell_data_len > data.len) return error.InvalidData;
                const cell_data = data[index .. index + cell_data_len];

                if (cell_data.len != 3) return error.InvalidCellData;
                const cell_array: [3]u32 = cell_data[0..3].*;
                board.cells[row][col] = try Cell.deserialize(cell_array);
                index += cell_data_len;

                if (index >= data.len) return error.InvalidData;
                const piece_type = data[index];
                index += 1;

                if (index >= data.len) return error.InvalidData;
                const piece_data_len = data[index];
                index += 1;

                if (piece_type == 2) {
                    if (index + piece_data_len > data.len) return error.InvalidData;
                    const piece_data = data[index .. index + piece_data_len];

                    if (piece_data.len != 2) return error.InvalidPieceData;
                    const piece_array: [2]u32 = piece_data[0..2].*;
                    board.pieces[row][col] = Piece.deserialize(piece_array);
                    index += piece_data_len;
                } else if (piece_type == 0) {
                    board.pieces[row][col] = null;
                    index += piece_data_len;
                } else {
                    return error.InvalidPieceType;
                }
            }
        }

        return board;
    }

    pub fn hash(self: *Board) u64 {
        var hash_value: u64 = 14695981039346656037;
        const prime: u64 = 1099511628211;

        inline for (0..8) |row| {
            inline for (0..8) |col| {
                const cell_hash = self.cells[row][col].hash();
                hash_value ^= cell_hash;
                hash_value *%= prime;

                if (self.pieces[row][col]) |current_piece| {
                    const piece_hash = current_piece.hash();
                    hash_value ^= piece_hash;
                    hash_value *%= prime;
                }
            }
        }

        self.saved_hash = hash_value;
        return hash_value;
    }

    pub fn update_hash(self: *Board) void {
        self.saved_hash = self.hash();
    }

    pub fn eql_fast(self: *Board, other: *Board) bool {
        const self_hash = self.hash();
        const other_hash = other.hash();
        if (self_hash != other_hash) {
            return false;
        }

        return self.eql(other.*);
    }

    pub fn eql(self: Board, other: Board) bool {
        for (0..8) |row| {
            for (0..8) |col| {
                if (!self.cells[row][col].eql(other.cells[row][col])) {
                    return false;
                }
            }
        }

        for (0..8) |row| {
            for (0..8) |col| {
                const self_piece = self.pieces[row][col];
                const other_piece = other.pieces[row][col];

                if (self_piece == null and other_piece == null) {
                    continue;
                }

                if (self_piece == null or other_piece == null) {
                    return false;
                }

                if (!self_piece.?.eql(other_piece.?)) {
                    return false;
                }
            }
        }
        return true;
    }
};

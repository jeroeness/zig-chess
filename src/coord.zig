const std = @import("std");

pub const Coord = struct {
    row: u8,
    col: u8,

    pub fn init(row: u8, col: u8) Coord {
        return Coord{
            .row = row,
            .col = col,
        };
    }

    pub fn isValid(self: Coord) bool {
        return self.row < 8 and self.col < 8;
    }

    pub fn eql(self: Coord, other: Coord) bool {
        return self.row == other.row and self.col == other.col;
    }

    pub fn toString(self: Coord, allocator: std.mem.Allocator) ![]u8 {
        const col_char = @as(u8, 'a') + self.col;
        const row_char = @as(u8, '1') + self.row;
        return std.fmt.allocPrint(allocator, "{c}{c}", .{ col_char, row_char });
    }
};
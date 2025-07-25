const std = @import("std");

pub const CellState = enum(u64) {
    Normal = 0,
    Frosted = 1,
    Burning = 2,
};

pub const Cell = struct {
    row: u8,
    col: u8,
    state: CellState,

    pub fn init(row: u8, col: u8) Cell {
        return Cell{
            .row = row,
            .col = col,
            .state = CellState.Normal,
        };
    }

    pub fn initWithState(row: u8, col: u8, state: CellState) Cell {
        return Cell{
            .row = row,
            .col = col,
            .state = state,
        };
    }

    pub fn serialize(self: Cell) [3]i32 {
        const state_int: u64 = @intFromEnum(self.state);
        return [3]i32{ @intCast(self.row), @intCast(self.col), @intCast(state_int) };
    }

    pub fn deserialize(data: [3]u32) !Cell {
        const state: CellState = @enumFromInt(data[2]);
        return Cell.initWithState(@intCast(data[0]), @intCast(data[1]), state);
    }

    pub fn hash(self: Cell) u64 {
        return (@as(u64, self.row) << 16) ^ (@as(u64, self.col) << 8) ^ @as(u64, @intFromEnum(self.state));
    }

    pub fn eql(self: Cell, other: Cell) bool {
        return self.row == other.row and self.col == other.col and self.state == other.state;
    }
};
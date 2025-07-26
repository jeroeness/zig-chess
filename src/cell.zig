const std = @import("std");
const coord = @import("coord.zig");

pub const CellState = enum(u64) {
    Normal = 0,
    Frosted = 1,
    Burning = 2,
};

pub const Cell = struct {
    coord: coord.Coord,
    state: CellState,

    pub fn init(row: u8, col: u8) Cell {
        return Cell{
            .coord = coord.Coord.init(row, col),
            .state = CellState.Normal,
        };
    }

    pub fn initWithState(row: u8, col: u8, state: CellState) Cell {
        return Cell{
            .coord = coord.Coord.init(row, col),
            .state = state,
        };
    }

    pub fn serialize(self: Cell) [3]i32 {
        const state_int: u64 = @intFromEnum(self.state);
        return [3]i32{ @intCast(self.coord.row), @intCast(self.coord.col), @intCast(state_int) };
    }

    pub fn deserialize(data: [3]u32) !Cell {
        const state: CellState = @enumFromInt(data[2]);
        return Cell.initWithState(@intCast(data[0]), @intCast(data[1]), state);
    }

    pub fn hash(self: Cell) u64 {
        return (@as(u64, self.coord.row) << 16) ^ (@as(u64, self.coord.col) << 8) ^ @as(u64, @intFromEnum(self.state));
    }

    pub fn eql(self: Cell, other: Cell) bool {
        return self.coord.eql(other.coord) and self.state == other.state;
    }
};

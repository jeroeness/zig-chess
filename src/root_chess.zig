//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");

// Re-export the modules
pub const piece = @import("piece.zig");
pub const cell = @import("cell.zig");
pub const board = @import("board.zig");
pub const renderer = @import("renderer.zig");
pub const action = @import("actions/action.zig");
pub const coord = @import("coord.zig");
pub const gamestate = @import("gamestate.zig");
pub const turn = @import("turn.zig");

// Re-export the main types for easy access
pub const PieceType = piece.PieceType;
pub const PieceColor = piece.PieceColor;
pub const Piece = piece.Piece;
pub const Cell = cell.Cell;
pub const Board = board.Board;
pub const Renderer = renderer.Renderer;
pub const RendererConfig = renderer.RendererConfig;
pub const Action = action.Action;
pub const Move = action.Move;
pub const Skip = action.Skip;
pub const Coord = coord.Coord;
pub const GameState = gamestate.GameState;
pub const Turn = turn.Turn;

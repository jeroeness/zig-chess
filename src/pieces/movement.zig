const std = @import("std");
const piece_module = @import("../piece.zig");
const board_module = @import("../board.zig");
const coord_module = @import("../coord.zig");
const piecetype = @import("piecetype.zig");

pub const Piece = piece_module.Piece;
pub const PieceColor = piece_module.PieceColor;
pub const PieceType = piecetype.PieceType;
pub const Board = board_module.Board;
pub const Coord = coord_module.Coord;

pub const MoveList = std.ArrayList(Coord);

const MovementFunction = *const fn (piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList;

const movement_functions = [_]MovementFunction{
    none_movement,
    pawn_movement,
    rook_movement,
    knight_movement,
    bishop_movement,
    queen_movement,
    king_movement,
    amazon_movement,
    archbishop_movement,
    chancellor_movement,
    crowned_knight_movement,
    crowned_rook_movement,
    crowned_bishop_movement,
    dragon_movement,
    alfil_movement,
    antelope_movement,
    camel_movement,
    dabbabah_movement,
    ferz_movement,
    flamingo_movement,
    giraffe_movement,
    wazir_movement,
    zebra_movement,
    alibaba_movement,
    bison_movement,
    carpenter_movement,
    gnu_movement,
    kangaroo_movement,
    man_movement,
    okapi_movement,
    phoenix_movement,
    root50_leaper_movement,
    wizard_movement,
    buffalo_movement,
    centaur_movement,
    champion_movement,
    fad_movement,
    squirrel_movement,
    barc_movement,
};

pub fn getMoves(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const piece_type = piece.getType();
    const type_index = @intFromEnum(piece_type);

    if (type_index >= movement_functions.len) {
        return none_movement(piece, from, board, allocator);
    }

    return movement_functions[type_index](piece, from, board, allocator);
}

fn none_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    _ = piece;
    _ = from;
    _ = board;
    return MoveList.init(allocator);
}

fn pawn_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = MoveList.init(allocator);
    const color = piece.getColor();

    const direction: i8 = if (color == .white) 1 else -1;
    const start_row: u8 = if (color == .white) 1 else 6;

    const one_forward_row = @as(i8, @intCast(from.row)) + direction;
    if (one_forward_row >= 0 and one_forward_row < 8) {
        const target_row = @as(u8, @intCast(one_forward_row));
        const target = Coord.init(target_row, from.col);

        if (board.getPieceConst(target) == null) {
            try moves.append(target);

            if (from.row == start_row) {
                const two_forward_row = @as(i8, @intCast(from.row)) + (2 * direction);
                if (two_forward_row >= 0 and two_forward_row < 8) {
                    const two_target_row = @as(u8, @intCast(two_forward_row));
                    const two_target = Coord.init(two_target_row, from.col);

                    if (board.getPieceConst(two_target) == null) {
                        try moves.append(two_target);
                    }
                }
            }
        }
    }

    const capture_cols = [_]i8{ -1, 1 };
    for (capture_cols) |col_offset| {
        const new_col = @as(i8, @intCast(from.col)) + col_offset;
        const new_row = @as(i8, @intCast(from.row)) + direction;

        if (new_col >= 0 and new_col < 8 and new_row >= 0 and new_row < 8) {
            const target = Coord.init(@as(u8, @intCast(new_row)), @as(u8, @intCast(new_col)));

            if (board.getPieceConst(target)) |target_piece| {
                if (!target_piece.isColor(color)) {
                    try moves.append(target);
                }
            }
        }
    }

    return moves;
}

fn rook_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = MoveList.init(allocator);
    const color = piece.getColor();

    const directions = [_][2]i8{ .{ 0, 1 }, .{ 0, -1 }, .{ 1, 0 }, .{ -1, 0 } };

    for (directions) |dir| {
        var row = @as(i8, @intCast(from.row));
        var col = @as(i8, @intCast(from.col));

        while (true) {
            row += dir[0];
            col += dir[1];

            if (row < 0 or row >= 8 or col < 0 or col >= 8) break;

            const target = Coord.init(@as(u8, @intCast(row)), @as(u8, @intCast(col)));

            if (board.getPieceConst(target)) |target_piece| {
                if (!target_piece.isColor(color)) {
                    try moves.append(target);
                }
                break;
            } else {
                try moves.append(target);
            }
        }
    }

    return moves;
}

fn knight_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = MoveList.init(allocator);
    const color = piece.getColor();

    const knight_moves = [_][2]i8{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };

    for (knight_moves) |move| {
        const new_row = @as(i8, @intCast(from.row)) + move[0];
        const new_col = @as(i8, @intCast(from.col)) + move[1];

        if (new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8) {
            const target = Coord.init(@as(u8, @intCast(new_row)), @as(u8, @intCast(new_col)));

            if (board.getPieceConst(target)) |target_piece| {
                if (!target_piece.isColor(color)) {
                    try moves.append(target);
                }
            } else {
                try moves.append(target);
            }
        }
    }

    return moves;
}

fn bishop_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = MoveList.init(allocator);
    const color = piece.getColor();

    const directions = [_][2]i8{ .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 } };

    for (directions) |dir| {
        var row = @as(i8, @intCast(from.row));
        var col = @as(i8, @intCast(from.col));

        while (true) {
            row += dir[0];
            col += dir[1];

            if (row < 0 or row >= 8 or col < 0 or col >= 8) break;

            const target = Coord.init(@as(u8, @intCast(row)), @as(u8, @intCast(col)));

            if (board.getPieceConst(target)) |target_piece| {
                if (!target_piece.isColor(color)) {
                    try moves.append(target);
                }
                break;
            } else {
                try moves.append(target);
            }
        }
    }

    return moves;
}

fn queen_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = rook_movement(piece, from, board, allocator) catch |err| return err;
    var bishop_moves = bishop_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer bishop_moves.deinit();

    try moves.appendSlice(bishop_moves.items);
    return moves;
}

fn king_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = MoveList.init(allocator);
    const color = piece.getColor();

    const king_moves = [_][2]i8{ .{ 0, 1 }, .{ 0, -1 }, .{ 1, 0 }, .{ -1, 0 }, .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 } };

    for (king_moves) |move| {
        const new_row = @as(i8, @intCast(from.row)) + move[0];
        const new_col = @as(i8, @intCast(from.col)) + move[1];

        if (new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8) {
            const target = Coord.init(@as(u8, @intCast(new_row)), @as(u8, @intCast(new_col)));

            if (board.getPieceConst(target)) |target_piece| {
                if (!target_piece.isColor(color)) {
                    try moves.append(target);
                }
            } else {
                try moves.append(target);
            }
        }
    }

    return moves;
}

fn amazon_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = queen_movement(piece, from, board, allocator) catch |err| return err;
    var knight_moves = knight_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer knight_moves.deinit();

    try moves.appendSlice(knight_moves.items);
    return moves;
}

fn archbishop_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = bishop_movement(piece, from, board, allocator) catch |err| return err;
    var knight_moves = knight_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer knight_moves.deinit();

    try moves.appendSlice(knight_moves.items);
    return moves;
}

fn chancellor_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = rook_movement(piece, from, board, allocator) catch |err| return err;
    var knight_moves = knight_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer knight_moves.deinit();

    try moves.appendSlice(knight_moves.items);
    return moves;
}

fn crowned_knight_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = king_movement(piece, from, board, allocator) catch |err| return err;
    var knight_moves = knight_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer knight_moves.deinit();

    try moves.appendSlice(knight_moves.items);
    return moves;
}

fn crowned_rook_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = king_movement(piece, from, board, allocator) catch |err| return err;
    var rook_moves = rook_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer rook_moves.deinit();

    try moves.appendSlice(rook_moves.items);
    return moves;
}

fn crowned_bishop_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = king_movement(piece, from, board, allocator) catch |err| return err;
    var bishop_moves = bishop_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer bishop_moves.deinit();

    try moves.appendSlice(bishop_moves.items);
    return moves;
}

fn dragon_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = pawn_movement(piece, from, board, allocator) catch |err| return err;
    var knight_moves = knight_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer knight_moves.deinit();

    try moves.appendSlice(knight_moves.items);
    return moves;
}

fn leaper_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator, leaps: []const [2]i8) std.mem.Allocator.Error!MoveList {
    var moves = MoveList.init(allocator);
    const color = piece.getColor();

    for (leaps) |leap| {
        const new_row = @as(i8, @intCast(from.row)) + leap[0];
        const new_col = @as(i8, @intCast(from.col)) + leap[1];

        if (new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8) {
            const target = Coord.init(@as(u8, @intCast(new_row)), @as(u8, @intCast(new_col)));

            if (board.getPieceConst(target)) |target_piece| {
                if (!target_piece.isColor(color)) {
                    try moves.append(target);
                }
            } else {
                try moves.append(target);
            }
        }
    }

    return moves;
}

fn alfil_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 2, 2 }, .{ 2, -2 }, .{ -2, 2 }, .{ -2, -2 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn antelope_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 3, 4 }, .{ 3, -4 }, .{ -3, 4 }, .{ -3, -4 }, .{ 4, 3 }, .{ 4, -3 }, .{ -4, 3 }, .{ -4, -3 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn camel_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 1, 3 }, .{ 1, -3 }, .{ -1, 3 }, .{ -1, -3 }, .{ 3, 1 }, .{ 3, -1 }, .{ -3, 1 }, .{ -3, -1 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn dabbabah_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 0, 2 }, .{ 0, -2 }, .{ 2, 0 }, .{ -2, 0 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn ferz_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn flamingo_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 1, 6 }, .{ 1, -6 }, .{ -1, 6 }, .{ -1, -6 }, .{ 6, 1 }, .{ 6, -1 }, .{ -6, 1 }, .{ -6, -1 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn giraffe_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 1, 4 }, .{ 1, -4 }, .{ -1, 4 }, .{ -1, -4 }, .{ 4, 1 }, .{ 4, -1 }, .{ -4, 1 }, .{ -4, -1 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn wazir_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 0, 1 }, .{ 0, -1 }, .{ 1, 0 }, .{ -1, 0 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn zebra_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 2, 3 }, .{ 2, -3 }, .{ -2, 3 }, .{ -2, -3 }, .{ 3, 2 }, .{ 3, -2 }, .{ -3, 2 }, .{ -3, -2 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn alibaba_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = alfil_movement(piece, from, board, allocator) catch |err| return err;
    var dabbabah_moves = dabbabah_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer dabbabah_moves.deinit();

    try moves.appendSlice(dabbabah_moves.items);
    return moves;
}

fn bison_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = camel_movement(piece, from, board, allocator) catch |err| return err;
    var zebra_moves = zebra_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer zebra_moves.deinit();

    try moves.appendSlice(zebra_moves.items);
    return moves;
}

fn carpenter_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = knight_movement(piece, from, board, allocator) catch |err| return err;
    var dabbabah_moves = dabbabah_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer dabbabah_moves.deinit();

    try moves.appendSlice(dabbabah_moves.items);
    return moves;
}

fn gnu_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = knight_movement(piece, from, board, allocator) catch |err| return err;
    var camel_moves = camel_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer camel_moves.deinit();

    try moves.appendSlice(camel_moves.items);
    return moves;
}

fn kangaroo_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = knight_movement(piece, from, board, allocator) catch |err| return err;
    var alfil_moves = alfil_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer alfil_moves.deinit();

    try moves.appendSlice(alfil_moves.items);
    return moves;
}

fn man_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = ferz_movement(piece, from, board, allocator) catch |err| return err;
    var wazir_moves = wazir_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer wazir_moves.deinit();

    try moves.appendSlice(wazir_moves.items);
    return moves;
}

fn okapi_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = knight_movement(piece, from, board, allocator) catch |err| return err;
    var zebra_moves = zebra_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer zebra_moves.deinit();

    try moves.appendSlice(zebra_moves.items);
    return moves;
}

fn phoenix_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = wazir_movement(piece, from, board, allocator) catch |err| return err;
    var alfil_moves = alfil_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer alfil_moves.deinit();

    try moves.appendSlice(alfil_moves.items);
    return moves;
}

fn root50_leaper_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    const leaps = [_][2]i8{ .{ 5, 5 }, .{ 5, -5 }, .{ -5, 5 }, .{ -5, -5 }, .{ 1, 7 }, .{ 1, -7 }, .{ -1, 7 }, .{ -1, -7 }, .{ 7, 1 }, .{ 7, -1 }, .{ -7, 1 }, .{ -7, -1 } };
    return leaper_movement(piece, from, board, allocator, &leaps);
}

fn wizard_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = camel_movement(piece, from, board, allocator) catch |err| return err;
    var ferz_moves = ferz_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer ferz_moves.deinit();

    try moves.appendSlice(ferz_moves.items);
    return moves;
}

fn buffalo_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = knight_movement(piece, from, board, allocator) catch |err| return err;
    var camel_moves = camel_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer camel_moves.deinit();

    var zebra_moves = zebra_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer zebra_moves.deinit();

    try moves.appendSlice(camel_moves.items);
    try moves.appendSlice(zebra_moves.items);
    return moves;
}

fn centaur_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = ferz_movement(piece, from, board, allocator) catch |err| return err;
    var wazir_moves = wazir_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer wazir_moves.deinit();

    var knight_moves = knight_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer knight_moves.deinit();

    try moves.appendSlice(wazir_moves.items);
    try moves.appendSlice(knight_moves.items);
    return moves;
}

fn champion_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = wazir_movement(piece, from, board, allocator) catch |err| return err;
    var dabbabah_moves = dabbabah_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer dabbabah_moves.deinit();

    var alfil_moves = alfil_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer alfil_moves.deinit();

    try moves.appendSlice(dabbabah_moves.items);
    try moves.appendSlice(alfil_moves.items);
    return moves;
}

fn fad_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = ferz_movement(piece, from, board, allocator) catch |err| return err;
    var alfil_moves = alfil_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer alfil_moves.deinit();

    var dabbabah_moves = dabbabah_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer dabbabah_moves.deinit();

    try moves.appendSlice(alfil_moves.items);
    try moves.appendSlice(dabbabah_moves.items);
    return moves;
}

fn squirrel_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    var moves = alfil_movement(piece, from, board, allocator) catch |err| return err;
    var dabbabah_moves = dabbabah_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer dabbabah_moves.deinit();

    var knight_moves = knight_movement(piece, from, board, allocator) catch |err| {
        moves.deinit();
        return err;
    };
    defer knight_moves.deinit();

    try moves.appendSlice(dabbabah_moves.items);
    try moves.appendSlice(knight_moves.items);
    return moves;
}

fn barc_movement(piece: Piece, from: Coord, board: *const Board, allocator: std.mem.Allocator) std.mem.Allocator.Error!MoveList {
    return none_movement(piece, from, board, allocator);
}

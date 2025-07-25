const std = @import("std");
const root = @import("root_chess");

test "pawn movement white" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const white_pawn = root.Piece.init(.pawn, .white, 1);
    const from = root.Coord.init(1, 4);

    board.pieces[1][4] = white_pawn;

    var moves = try white_pawn.getMoves(from, &board, allocator);
    defer moves.deinit();

    try std.testing.expect(moves.items.len == 2);
    try std.testing.expect(moves.items[0].row == 2 and moves.items[0].col == 4);
    try std.testing.expect(moves.items[1].row == 3 and moves.items[1].col == 4);
}

test "pawn movement black" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const black_pawn = root.Piece.init(.pawn, .black, 1);
    const from = root.Coord.init(6, 4);

    board.pieces[6][4] = black_pawn;

    var moves = try black_pawn.getMoves(from, &board, allocator);
    defer moves.deinit();

    try std.testing.expect(moves.items.len == 2);
    try std.testing.expect(moves.items[0].row == 5 and moves.items[0].col == 4);
    try std.testing.expect(moves.items[1].row == 4 and moves.items[1].col == 4);
}

test "knight movement" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const knight = root.Piece.init(.knight, .white, 1);
    const from = root.Coord.init(4, 4);

    board.pieces[4][4] = knight;

    var moves = try knight.getMoves(from, &board, allocator);
    defer moves.deinit();

    try std.testing.expect(moves.items.len == 8);
}

test "rook movement" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const rook = root.Piece.init(.rook, .white, 1);
    const from = root.Coord.init(0, 0);

    board.pieces[0][0] = rook;

    var moves = try rook.getMoves(from, &board, allocator);
    defer moves.deinit();

    try std.testing.expect(moves.items.len == 14);
}

test "bishop movement" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const bishop = root.Piece.init(.bishop, .white, 1);
    const from = root.Coord.init(4, 4);

    board.pieces[4][4] = bishop;

    var moves = try bishop.getMoves(from, &board, allocator);
    defer moves.deinit();

    try std.testing.expect(moves.items.len == 13);
}

test "queen movement" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const queen = root.Piece.init(.queen, .white, 1);
    const from = root.Coord.init(4, 4);

    board.pieces[4][4] = queen;

    var moves = try queen.getMoves(from, &board, allocator);
    defer moves.deinit();

    try std.testing.expect(moves.items.len == 27);
}

test "king movement" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const king = root.Piece.init(.king, .white, 1);
    const from = root.Coord.init(4, 4);

    board.pieces[4][4] = king;

    var moves = try king.getMoves(from, &board, allocator);
    defer moves.deinit();

    try std.testing.expect(moves.items.len == 8);
}

test "pawn capture" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const white_pawn = root.Piece.init(.pawn, .white, 1);
    const black_pawn = root.Piece.init(.pawn, .black, 2);
    const from = root.Coord.init(4, 4);

    board.pieces[4][4] = white_pawn;
    board.pieces[5][3] = black_pawn;

    var moves = try white_pawn.getMoves(from, &board, allocator);
    defer moves.deinit();

    var found_capture = false;
    for (moves.items) |move| {
        if (move.row == 5 and move.col == 3) {
            found_capture = true;
            break;
        }
    }

    try std.testing.expect(found_capture);
}

test "blocked movement" {
    var board = root.Board.init();
    const allocator = std.testing.allocator;

    const rook = root.Piece.init(.rook, .white, 1);
    const blocking_piece = root.Piece.init(.pawn, .white, 2);
    const from = root.Coord.init(0, 0);

    board.pieces[0][0] = rook;
    board.pieces[0][3] = blocking_piece;

    var moves = try rook.getMoves(from, &board, allocator);
    defer moves.deinit();

    var found_beyond_block = false;
    for (moves.items) |move| {
        if (move.row == 0 and move.col > 3) {
            found_beyond_block = true;
            break;
        }
    }

    try std.testing.expect(!found_beyond_block);
}

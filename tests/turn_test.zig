const std = @import("std");
const testing = std.testing;
const root = @import("root_chess");

const Turn = root.Turn;
const Board = root.Board;
const Action = root.Action;
const Move = root.Move;
const Coord = root.Coord;
const Piece = root.Piece;

test "turn undo all actions functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = Board.init();
    board.setupInitialPosition();

    var turn = Turn.init(allocator, 0, 1);
    defer turn.deinit();

    const initial_piece_count = countPieces(&board);

    var move1 = Move.initFromCoords(1, 0, 2, 0);
    const move1_ptr = try move1.asAction(allocator);
    try turn.addAction(move1_ptr);

    var move2 = Move.initFromCoords(1, 1, 3, 1);
    const move2_ptr = try move2.asAction(allocator);
    try turn.addAction(move2_ptr);

    try testing.expect(turn.getActionCount() == 2);

    const success1 = move1_ptr.execute(&board);
    const success2 = move2_ptr.execute(&board);
    try testing.expect(success1);
    try testing.expect(success2);

    try testing.expect(!board.isEmpty(2, 0));
    try testing.expect(!board.isEmpty(3, 1));
    try testing.expect(board.isEmpty(1, 0));
    try testing.expect(board.isEmpty(1, 1));

    const undo_success = turn.undoAllActions(&board);
    try testing.expect(undo_success);

    try testing.expect(board.isEmpty(2, 0));
    try testing.expect(board.isEmpty(3, 1));
    try testing.expect(!board.isEmpty(1, 0));
    try testing.expect(!board.isEmpty(1, 1));

    const final_piece_count = countPieces(&board);
    try testing.expect(initial_piece_count == final_piece_count);
}

test "turn undo all actions empty turn" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = Board.init();
    var turn = Turn.init(allocator, 0, 1);
    defer turn.deinit();

    const undo_success = turn.undoAllActions(&board);
    try testing.expect(undo_success);
}

test "turn undo all actions reverse order" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = Board.init();
    board.setupInitialPosition();

    var turn = Turn.init(allocator, 0, 1);
    defer turn.deinit();

    var move1 = Move.initFromCoords(1, 0, 2, 0);
    const move1_ptr = try move1.asAction(allocator);
    try turn.addAction(move1_ptr);

    var move2 = Move.initFromCoords(2, 0, 3, 0);
    const move2_ptr = try move2.asAction(allocator);
    try turn.addAction(move2_ptr);

    var move3 = Move.initFromCoords(3, 0, 4, 0);
    const move3_ptr = try move3.asAction(allocator);
    try turn.addAction(move3_ptr);

    _ = move1_ptr.execute(&board);
    _ = move2_ptr.execute(&board);
    _ = move3_ptr.execute(&board);

    try testing.expect(!board.isEmpty(4, 0));
    try testing.expect(board.isEmpty(1, 0));
    try testing.expect(board.isEmpty(2, 0));
    try testing.expect(board.isEmpty(3, 0));

    const undo_success = turn.undoAllActions(&board);
    try testing.expect(undo_success);

    try testing.expect(board.isEmpty(4, 0));
    try testing.expect(!board.isEmpty(1, 0));
    try testing.expect(board.isEmpty(2, 0));
    try testing.expect(board.isEmpty(3, 0));
}

fn countPieces(board: *const Board) u32 {
    var count: u32 = 0;
    for (0..8) |row| {
        for (0..8) |col| {
            if (!board.isEmpty(@intCast(row), @intCast(col))) {
                count += 1;
            }
        }
    }
    return count;
}

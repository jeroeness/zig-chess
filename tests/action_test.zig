const std = @import("std");
const testing = std.testing;
const root = @import("root_chess");

const Board = root.Board;
const Piece = root.Piece;
const Move = root.Move;
const Skip = root.Skip;
const Coord = root.Coord;

test "action and move functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a chess board with some pieces
    var chess_board = Board.init();
    chess_board.setupInitialPosition();

    // Create a move from e2 to e4 (pawn move)
    var move = Move.initFromCoords(1, 4, 3, 4); // e2 to e4
    const move_action = try move.asAction(allocator);
    defer allocator.destroy(move_action);

    // Test coordinate functionality
    const start_coord = Coord.init(1, 4);
    const target_coord = Coord.init(3, 4);
    try testing.expect(start_coord.isValid());
    try testing.expect(target_coord.isValid());
    try testing.expect(!start_coord.eql(target_coord));

    // Test coordinate string representation
    const start_str = try start_coord.toString(allocator);
    defer allocator.free(start_str);
    try testing.expect(std.mem.eql(u8, start_str, "e2"));

    const target_str = try target_coord.toString(allocator);
    defer allocator.free(target_str);
    try testing.expect(std.mem.eql(u8, target_str, "e4"));

    // Test that there's a pawn at the start position
    const piece_at_start = chess_board.getPieceConst(1, 4);
    try testing.expect(piece_at_start != null);
    try testing.expect(piece_at_start.?.getType() == .pawn);
    try testing.expect(piece_at_start.?.getColor() == .white);

    // Test that target position is empty
    try testing.expect(chess_board.isEmpty(3, 4));

    // Execute the move
    try testing.expect(move_action.execute(&chess_board));

    // Verify the move was executed
    try testing.expect(chess_board.isEmpty(1, 4)); // Start position should be empty
    try testing.expect(!chess_board.isEmpty(3, 4)); // Target position should have piece

    const piece_at_target = chess_board.getPieceConst(3, 4);
    try testing.expect(piece_at_target != null);
    try testing.expect(piece_at_target.?.getType() == .pawn);
    try testing.expect(piece_at_target.?.getColor() == .white);

    // Test move string representation
    const move_str = try move_action.toString(allocator);
    defer allocator.free(move_str);
    try testing.expect(std.mem.eql(u8, move_str, "e2-e4"));

    // Test undo functionality
    try testing.expect(move_action.undo(&chess_board));

    // Verify the move was undone
    try testing.expect(!chess_board.isEmpty(1, 4)); // Start position should have piece again
    try testing.expect(chess_board.isEmpty(3, 4)); // Target position should be empty

    const piece_back_at_start = chess_board.getPieceConst(1, 4);
    try testing.expect(piece_back_at_start != null);
    try testing.expect(piece_back_at_start.?.getType() == .pawn);
    try testing.expect(piece_back_at_start.?.getColor() == .white);

    // Test cleanup
    move_action.deinit(allocator);
}

test "action demo - comprehensive move execution and undo" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a chess board
    var game_board = Board.init();
    game_board.setupInitialPosition();

    // Create some moves
    var move1 = Move.initFromCoords(1, 4, 3, 4); // e2 to e4
    var move2 = Move.initFromCoords(6, 4, 4, 4); // e7 to e5

    // Convert moves to actions
    const action1 = try move1.asAction(allocator);
    defer allocator.destroy(action1);

    const action2 = try move2.asAction(allocator);
    defer allocator.destroy(action2);

    // Execute moves
    // Test move 1: e2 to e4 (white pawn)
    try testing.expect(action1.execute(&game_board));
    const move1_str = try action1.toString(allocator);
    defer allocator.free(move1_str);
    try testing.expect(std.mem.eql(u8, move1_str, "e2-e4"));

    // Verify the move was executed correctly
    try testing.expect(game_board.isEmpty(1, 4)); // e2 should be empty
    try testing.expect(!game_board.isEmpty(3, 4)); // e4 should have piece
    const piece_at_e4 = game_board.getPieceConst(3, 4);
    try testing.expect(piece_at_e4 != null);
    try testing.expect(piece_at_e4.?.getType() == .pawn);
    try testing.expect(piece_at_e4.?.getColor() == .white);

    // Test move 2: e7 to e5 (black pawn)
    try testing.expect(action2.execute(&game_board));
    const move2_str = try action2.toString(allocator);
    defer allocator.free(move2_str);
    try testing.expect(std.mem.eql(u8, move2_str, "e7-e5"));

    // Verify the move was executed correctly
    try testing.expect(game_board.isEmpty(6, 4)); // e7 should be empty
    try testing.expect(!game_board.isEmpty(4, 4)); // e5 should have piece
    const piece_at_e5 = game_board.getPieceConst(4, 4);
    try testing.expect(piece_at_e5 != null);
    try testing.expect(piece_at_e5.?.getType() == .pawn);
    try testing.expect(piece_at_e5.?.getColor() == .black);

    // Test undo functionality
    // Undo move 2 first (last move first)
    try testing.expect(action2.undo(&game_board));

    // Verify move 2 was undone
    try testing.expect(!game_board.isEmpty(6, 4)); // e7 should have piece again
    try testing.expect(game_board.isEmpty(4, 4)); // e5 should be empty
    const piece_back_at_e7 = game_board.getPieceConst(6, 4);
    try testing.expect(piece_back_at_e7 != null);
    try testing.expect(piece_back_at_e7.?.getType() == .pawn);
    try testing.expect(piece_back_at_e7.?.getColor() == .black);

    // Undo move 1
    try testing.expect(action1.undo(&game_board));

    // Verify move 1 was undone
    try testing.expect(!game_board.isEmpty(1, 4)); // e2 should have piece again
    try testing.expect(game_board.isEmpty(3, 4)); // e4 should be empty
    const piece_back_at_e2 = game_board.getPieceConst(1, 4);
    try testing.expect(piece_back_at_e2 != null);
    try testing.expect(piece_back_at_e2.?.getType() == .pawn);
    try testing.expect(piece_back_at_e2.?.getColor() == .white);

    // Clean up
    action1.deinit(allocator);
    action2.deinit(allocator);
}

test "pawn promotion - all piece types including amazon" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test promotion to queen
    {
        var game_board = Board.init();

        // Place a white pawn on the 7th rank (about to promote)
        _ = game_board.setPiece(6, 4, Piece.init(.pawn, .white, 1));

        // Create a promotion move from e7 to e8, promoting to queen
        var promotion_move = Move.initFromCoordsWithPromotion(6, 4, 7, 4, .queen);
        const promotion_action = try promotion_move.asAction(allocator);
        defer allocator.destroy(promotion_action);

        // Execute the promotion
        try testing.expect(promotion_action.execute(&game_board));

        // Verify the promoted piece
        const promoted_piece = game_board.getPieceConst(7, 4);
        try testing.expect(promoted_piece != null);
        try testing.expect(promoted_piece.?.getType() == .queen);
        try testing.expect(promoted_piece.?.getColor() == .white);

        // Verify the original position is empty
        try testing.expect(game_board.isEmpty(6, 4));

        // Test string representation
        const move_str = try promotion_action.toString(allocator);
        defer allocator.free(move_str);
        try testing.expect(std.mem.eql(u8, move_str, "e7-e8=Q"));

        // Test undo functionality
        try testing.expect(promotion_action.undo(&game_board));

        // Verify undo worked correctly
        try testing.expect(game_board.isEmpty(7, 4)); // Target should be empty
        const restored_piece = game_board.getPieceConst(6, 4);
        try testing.expect(restored_piece != null);
        try testing.expect(restored_piece.?.getType() == .pawn);
        try testing.expect(restored_piece.?.getColor() == .white);

        promotion_action.deinit(allocator);
    }

    // Test promotion to amazon (fairy piece)
    {
        var game_board = Board.init();

        // Place a black pawn on the 2nd rank (about to promote)
        _ = game_board.setPiece(1, 3, Piece.init(.pawn, .black, 1));

        // Create a promotion move from d2 to d1, promoting to amazon
        var promotion_move = Move.initFromCoordsWithPromotion(1, 3, 0, 3, .amazon);
        const amazon_action = try promotion_move.asAction(allocator);
        defer allocator.destroy(amazon_action);

        // Execute the promotion
        try testing.expect(amazon_action.execute(&game_board));

        // Verify the promoted piece
        const promoted_piece = game_board.getPieceConst(0, 3);
        try testing.expect(promoted_piece != null);
        try testing.expect(promoted_piece.?.getType() == .amazon);
        try testing.expect(promoted_piece.?.getColor() == .black);

        // Verify the original position is empty
        try testing.expect(game_board.isEmpty(1, 3));

        // Test string representation
        const move_str = try amazon_action.toString(allocator);
        defer allocator.free(move_str);
        try testing.expect(std.mem.eql(u8, move_str, "d2-d1=A"));

        // Test undo functionality
        try testing.expect(amazon_action.undo(&game_board));

        // Verify undo worked correctly
        try testing.expect(game_board.isEmpty(0, 3)); // Target should be empty
        const restored_piece = game_board.getPieceConst(1, 3);
        try testing.expect(restored_piece != null);
        try testing.expect(restored_piece.?.getType() == .pawn);
        try testing.expect(restored_piece.?.getColor() == .black);

        amazon_action.deinit(allocator);
    }

    // Test promotion with capture
    {
        var game_board = Board.init();

        // Place a white pawn on the 7th rank
        _ = game_board.setPiece(6, 4, Piece.init(.pawn, .white, 1));

        // Place a black piece to be captured on e8
        _ = game_board.setPiece(7, 4, Piece.init(.rook, .black, 2));

        // Create a promotion move with capture from e7 to e8, promoting to rook
        var promotion_move = Move.initFromCoordsWithPromotion(6, 4, 7, 4, .rook);
        const capture_action = try promotion_move.asAction(allocator);
        defer allocator.destroy(capture_action);

        // Execute the promotion
        try testing.expect(capture_action.execute(&game_board));

        // Verify the promoted piece
        const promoted_piece = game_board.getPieceConst(7, 4);
        try testing.expect(promoted_piece != null);
        try testing.expect(promoted_piece.?.getType() == .rook);
        try testing.expect(promoted_piece.?.getColor() == .white);

        // Verify the original position is empty
        try testing.expect(game_board.isEmpty(6, 4));

        // Test string representation (should show capture)
        const move_str = try capture_action.toString(allocator);
        defer allocator.free(move_str);
        try testing.expect(std.mem.eql(u8, move_str, "e7xe8=R"));

        // Test undo functionality
        try testing.expect(capture_action.undo(&game_board));

        // Verify undo worked correctly
        const restored_piece = game_board.getPieceConst(6, 4);
        try testing.expect(restored_piece != null);
        try testing.expect(restored_piece.?.getType() == .pawn);
        try testing.expect(restored_piece.?.getColor() == .white);

        // Verify captured piece was restored
        const restored_captured = game_board.getPieceConst(7, 4);
        try testing.expect(restored_captured != null);
        try testing.expect(restored_captured.?.getType() == .rook);
        try testing.expect(restored_captured.?.getColor() == .black);

        capture_action.deinit(allocator);
    }
}

test "skip action functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a chess board with some pieces
    var game_board = Board.init();
    game_board.setupInitialPosition();

    // Store initial board state for comparison
    const initial_piece_e2 = game_board.getPieceConst(1, 4);
    const initial_piece_e7 = game_board.getPieceConst(6, 4);

    // Test white skip
    {
        var white_skip = Skip.init(.white);
        const skip_action = try white_skip.asAction(allocator);
        defer allocator.destroy(skip_action);

        // Execute the skip action
        try testing.expect(skip_action.execute(&game_board));

        // Verify board state unchanged
        const piece_e2_after = game_board.getPieceConst(1, 4);
        const piece_e7_after = game_board.getPieceConst(6, 4);
        try testing.expect(std.meta.eql(initial_piece_e2, piece_e2_after));
        try testing.expect(std.meta.eql(initial_piece_e7, piece_e7_after));

        // Test string representation
        const skip_str = try skip_action.toString(allocator);
        defer allocator.free(skip_str);
        try testing.expect(std.mem.eql(u8, skip_str, "White skips turn"));

        // Test undo functionality
        try testing.expect(skip_action.undo(&game_board));

        // Verify board state still unchanged (skip undo doesn't change anything)
        const piece_e2_after_undo = game_board.getPieceConst(1, 4);
        const piece_e7_after_undo = game_board.getPieceConst(6, 4);
        try testing.expect(std.meta.eql(initial_piece_e2, piece_e2_after_undo));
        try testing.expect(std.meta.eql(initial_piece_e7, piece_e7_after_undo));

        skip_action.deinit(allocator);
    }

    // Test black skip
    {
        var black_skip = Skip.init(.black);
        const skip_action = try black_skip.asAction(allocator);
        defer allocator.destroy(skip_action);

        // Execute the skip action
        try testing.expect(skip_action.execute(&game_board));

        // Test string representation
        const skip_str = try skip_action.toString(allocator);
        defer allocator.free(skip_str);
        try testing.expect(std.mem.eql(u8, skip_str, "Black skips turn"));

        // Test undo functionality
        try testing.expect(skip_action.undo(&game_board));

        skip_action.deinit(allocator);
    }
}

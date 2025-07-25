const std = @import("std");
const testing = std.testing;
const root = @import("root_chess");

const GameState = root.GameState;
const Board = root.Board;
const Piece = root.Piece;
const Move = root.Move;
const Skip = root.Skip;

test "gamestate initialization" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var state = GameState.init(allocator);
    defer state.deinit();

    // Test initial turn
    try testing.expect(state.getTurn() == .white);

    // Test initial board setup
    const initial_board = state.getBoard();
    for (0..8) |row| {
        for (0..8) |col| {
            try testing.expect(initial_board.isEmpty(row, col));
        }
    }

    // Test initial history state
    try testing.expect(state.getHistoryLength() == 0);
}

test "gamestate turn management" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var state = GameState.init(allocator);
    defer state.deinit();

    // Test turn progression
    try testing.expect(state.getTurn() == .white);
    state.nextTurn();
    try testing.expect(state.getTurn() == .black);
    state.nextTurn();
    try testing.expect(state.getTurn() == .white);
}

test "gamestate move execution and undo" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var state = GameState.init(allocator);
    defer state.deinit();
    var chess_board = state.getBoard();
    chess_board.setupInitialPosition();

    // Create a move from e2 to e4 (pawn move)
    var move = Move.initFromCoords(1, 4, 3, 4); // e2 to e4
    const move_action = try move.asAction(allocator);

    // Execute the move
    _ = try state.executeAction(move_action);

    // Verify the move was executed
    try testing.expect(chess_board.isEmpty(1, 4)); // Start position should be empty
    try testing.expect(!chess_board.isEmpty(3, 4)); // Target position should have piece

    // Test gamestate history
    try testing.expect(state.getHistoryLength() == 1);

    // Undo the move
    try testing.expect(move_action.undo(chess_board));

    // Verify the move was undone
    try testing.expect(!chess_board.isEmpty(1, 4)); // Start position should have piece again
    try testing.expect(chess_board.isEmpty(3, 4)); // Target position should be empty

    // Test gamestate history after undo
    try testing.expect(state.getHistoryLength() == 1); // Still 1, since we only undid the last move
}

test "gamestate serialization and deserialization" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var state = GameState.init(allocator);
    defer state.deinit();
    var chess_board = state.getBoard();
    chess_board.setupInitialPosition();

    // Add a custom amazon piece for testing
    _ = chess_board.setPiece(2, 2, Piece.init(.amazon, .white, 1));

    // Serialize the initial state
    const serialized_data = try state.serialize(allocator);
    defer allocator.free(serialized_data);

    // Deserialize to a new gamestate
    var deserialized_state = try GameState.deserialize(serialized_data, allocator);

    // Compare original and deserialized state
    try testing.expect(state.eql(deserialized_state));

    // Test some specific pieces to make sure they're correctly preserved
    const original_king = chess_board.getPieceConst(0, 4);
    const deserialized_king = deserialized_state.getBoard().getPieceConst(0, 4);
    try testing.expect(original_king != null);
    try testing.expect(deserialized_king != null);
    try testing.expect(original_king.?.getType() == deserialized_king.?.getType());
    try testing.expect(original_king.?.getColor() == deserialized_king.?.getColor());

    // Test the custom amazon piece
    const original_amazon = chess_board.getPieceConst(2, 2);
    const deserialized_amazon = deserialized_state.getBoard().getPieceConst(2, 2);
    try testing.expect(original_amazon != null);
    try testing.expect(deserialized_amazon != null);
    try testing.expect(original_amazon.?.getType() == .amazon);
    try testing.expect(deserialized_amazon.?.getType() == .amazon);
    try testing.expect(original_amazon.?.getColor() == deserialized_amazon.?.getColor());

    // Test that a pawn position is consistent (should have white pawn in both boards)
    try testing.expect(!chess_board.isEmpty(1, 1));
    try testing.expect(!deserialized_state.getBoard().isEmpty(1, 1));

    const original_pawn = chess_board.getPieceConst(1, 1);
    const deserialized_pawn = deserialized_state.getBoard().getPieceConst(1, 1);
    try testing.expect(original_pawn != null);
    try testing.expect(deserialized_pawn != null);
    try testing.expect(original_pawn.?.getType() == .pawn);
    try testing.expect(deserialized_pawn.?.getType() == .pawn);
    try testing.expect(original_pawn.?.getColor() == deserialized_pawn.?.getColor());
}

test "gamestate initialization and basic functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test GameState initialization
    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    // Test initial state
    try testing.expect(game_state.getActionCount() == 0);
    try testing.expect(game_state.getLastAction() == null);
    try testing.expect(game_state.getAction(0) == null);

    // Test board access
    const board_ptr = game_state.getBoard();
    try testing.expect(@intFromPtr(board_ptr) != 0);

    const board_const = game_state.getBoardConst();
    try testing.expect(@intFromPtr(board_const) != 0);

    // Test setup initial position
    game_state.setupInitialPosition();

    // Verify initial position is set
    try testing.expect(!game_state.getBoard().isEmpty(0, 0)); // White rook
    try testing.expect(!game_state.getBoard().isEmpty(7, 0)); // Black rook
    try testing.expect(!game_state.getBoard().isEmpty(1, 0)); // White pawn
    try testing.expect(!game_state.getBoard().isEmpty(6, 0)); // Black pawn
}

test "gamestate action execution and history" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    game_state.setupInitialPosition();

    // Create and execute first move: e2-e4
    var move1 = Move.initFromCoords(1, 4, 3, 4);
    const action1 = try move1.asAction(allocator);

    // Execute the action
    const success1 = try game_state.executeAction(action1);
    try testing.expect(success1);

    // Verify action was added to history
    try testing.expect(game_state.getActionCount() == 1);
    try testing.expect(game_state.getLastAction() != null);
    try testing.expect(game_state.getAction(0) == action1);

    // Verify the move was executed on the board
    try testing.expect(game_state.getBoard().isEmpty(1, 4)); // e2 should be empty
    try testing.expect(!game_state.getBoard().isEmpty(3, 4)); // e4 should have piece

    // Create and execute second move: e7-e5
    var move2 = Move.initFromCoords(6, 4, 4, 4);
    const action2 = try move2.asAction(allocator);

    const success2 = try game_state.executeAction(action2);
    try testing.expect(success2);

    // Verify action history
    try testing.expect(game_state.getActionCount() == 2);
    try testing.expect(game_state.getLastAction() == action2);
    try testing.expect(game_state.getAction(1) == action2);

    // Verify the move was executed on the board
    try testing.expect(game_state.getBoard().isEmpty(6, 4)); // e7 should be empty
    try testing.expect(!game_state.getBoard().isEmpty(4, 4)); // e5 should have piece
}

test "gamestate undo functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    game_state.setupInitialPosition();

    // Execute a move
    var move1 = Move.initFromCoords(1, 4, 3, 4); // e2-e4
    const action1 = try move1.asAction(allocator);

    _ = try game_state.executeAction(action1);
    try testing.expect(game_state.getActionCount() == 1);

    // Verify the move was executed
    try testing.expect(game_state.getBoard().isEmpty(1, 4));
    try testing.expect(!game_state.getBoard().isEmpty(3, 4));

    // Undo the move
    const undo_success = game_state.undoLastAction();
    try testing.expect(undo_success);

    // Verify the move was undone
    try testing.expect(game_state.getActionCount() == 0);
    try testing.expect(game_state.getLastAction() == null);

    // Verify the board state was restored
    try testing.expect(!game_state.getBoard().isEmpty(1, 4)); // e2 should have piece again
    try testing.expect(game_state.getBoard().isEmpty(3, 4)); // e4 should be empty

    // Test undo when no actions exist
    const undo_empty = game_state.undoLastAction();
    try testing.expect(!undo_empty);
}

test "gamestate multiple actions and undo sequence" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    game_state.setupInitialPosition();

    // Execute multiple moves
    var move1 = Move.initFromCoords(1, 4, 3, 4); // e2-e4
    const action1 = try move1.asAction(allocator);
    _ = try game_state.executeAction(action1);

    var move2 = Move.initFromCoords(6, 4, 4, 4); // e7-e5
    const action2 = try move2.asAction(allocator);
    _ = try game_state.executeAction(action2);

    var move3 = Move.initFromCoords(1, 3, 3, 3); // d2-d4
    const action3 = try move3.asAction(allocator);
    _ = try game_state.executeAction(action3);

    // Verify all actions are tracked
    try testing.expect(game_state.getActionCount() == 3);
    try testing.expect(game_state.getAction(0) == action1);
    try testing.expect(game_state.getAction(1) == action2);
    try testing.expect(game_state.getAction(2) == action3);
    try testing.expect(game_state.getLastAction() == action3);

    // Undo moves in reverse order
    try testing.expect(game_state.undoLastAction()); // Undo move3
    try testing.expect(game_state.getActionCount() == 2);
    try testing.expect(game_state.getLastAction() == action2);

    try testing.expect(game_state.undoLastAction()); // Undo move2
    try testing.expect(game_state.getActionCount() == 1);
    try testing.expect(game_state.getLastAction() == action1);

    try testing.expect(game_state.undoLastAction()); // Undo move1
    try testing.expect(game_state.getActionCount() == 0);
    try testing.expect(game_state.getLastAction() == null);

    // Verify all moves are undone
    try testing.expect(!game_state.getBoard().isEmpty(1, 4)); // e2 should have piece
    try testing.expect(!game_state.getBoard().isEmpty(6, 4)); // e7 should have piece
    try testing.expect(!game_state.getBoard().isEmpty(1, 3)); // d2 should have piece
    try testing.expect(game_state.getBoard().isEmpty(3, 4)); // e4 should be empty
    try testing.expect(game_state.getBoard().isEmpty(4, 4)); // e5 should be empty
    try testing.expect(game_state.getBoard().isEmpty(3, 3)); // d4 should be empty
}

test "gamestate clear actions functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    game_state.setupInitialPosition();

    // Execute some moves
    var move1 = Move.initFromCoords(1, 4, 3, 4); // e2-e4
    const action1 = try move1.asAction(allocator);
    _ = try game_state.executeAction(action1);

    var move2 = Move.initFromCoords(6, 4, 4, 4); // e7-e5
    const action2 = try move2.asAction(allocator);
    _ = try game_state.executeAction(action2);

    // Verify actions exist
    try testing.expect(game_state.getActionCount() == 2);

    // Clear all actions
    game_state.clearActions();

    // Verify all actions are cleared
    try testing.expect(game_state.getActionCount() == 0);
    try testing.expect(game_state.getLastAction() == null);
    try testing.expect(game_state.getAction(0) == null);

    // Board state should remain unchanged (clearActions doesn't undo moves)
    try testing.expect(game_state.getBoard().isEmpty(1, 4)); // e2 should still be empty
    try testing.expect(game_state.getBoard().isEmpty(6, 4)); // e7 should still be empty
    try testing.expect(!game_state.getBoard().isEmpty(3, 4)); // e4 should still have piece
    try testing.expect(!game_state.getBoard().isEmpty(4, 4)); // e5 should still have piece
}

test "gamestate with skip actions" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    game_state.setupInitialPosition();

    // Execute a regular move
    var move1 = Move.initFromCoords(1, 4, 3, 4); // e2-e4
    const action1 = try move1.asAction(allocator);
    _ = try game_state.executeAction(action1);

    // Execute a skip action
    var skip_action = Skip.init(.black);
    const action2 = try skip_action.asAction(allocator);
    _ = try game_state.executeAction(action2);

    // Execute another regular move
    var move3 = Move.initFromCoords(1, 3, 3, 3); // d2-d4
    const action3 = try move3.asAction(allocator);
    _ = try game_state.executeAction(action3);

    // Verify all actions are tracked
    try testing.expect(game_state.getActionCount() == 3);
    try testing.expect(game_state.getAction(0) == action1);
    try testing.expect(game_state.getAction(1) == action2);
    try testing.expect(game_state.getAction(2) == action3);

    // Undo the skip action
    try testing.expect(game_state.undoLastAction()); // Undo move3
    try testing.expect(game_state.undoLastAction()); // Undo skip
    try testing.expect(game_state.getActionCount() == 1);
    try testing.expect(game_state.getLastAction() == action1);

    // Board should only have the first move
    try testing.expect(game_state.getBoard().isEmpty(1, 4)); // e2 should be empty
    try testing.expect(!game_state.getBoard().isEmpty(3, 4)); // e4 should have piece
    try testing.expect(!game_state.getBoard().isEmpty(1, 3)); // d2 should have piece (move3 undone)
    try testing.expect(game_state.getBoard().isEmpty(3, 3)); // d4 should be empty (move3 undone)
}

test "gamestate with promotion moves" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    // Set up a board with a pawn ready to promote
    _ = game_state.getBoard().setPiece(6, 4, Piece.init(.pawn, .white, 1));

    // Execute a promotion move
    var promotion_move = Move.initFromCoordsWithPromotion(6, 4, 7, 4, .queen);
    const action1 = try promotion_move.asAction(allocator);

    const success = try game_state.executeAction(action1);
    try testing.expect(success);

    // Verify the promotion was executed
    try testing.expect(game_state.getActionCount() == 1);
    try testing.expect(game_state.getBoard().isEmpty(6, 4)); // Original position empty

    const promoted_piece = game_state.getBoard().getPieceConst(7, 4);
    try testing.expect(promoted_piece != null);
    try testing.expect(promoted_piece.?.getType() == .queen);
    try testing.expect(promoted_piece.?.getColor() == .white);

    // Undo the promotion
    try testing.expect(game_state.undoLastAction());
    try testing.expect(game_state.getActionCount() == 0);

    // Verify the promotion was undone
    try testing.expect(game_state.getBoard().isEmpty(7, 4)); // Promoted position empty

    const restored_piece = game_state.getBoard().getPieceConst(6, 4);
    try testing.expect(restored_piece != null);
    try testing.expect(restored_piece.?.getType() == .pawn);
    try testing.expect(restored_piece.?.getColor() == .white);
}

test "gamestate edge cases and error handling" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_state = GameState.init(allocator);
    defer game_state.deinit();

    game_state.setupInitialPosition();

    // Test invalid move (should not be added to history)
    var invalid_move = Move.initFromCoords(3, 3, 4, 4); // No piece at d4
    const invalid_action = try invalid_move.asAction(allocator);

    const invalid_success = try game_state.executeAction(invalid_action);
    try testing.expect(!invalid_success);

    // Verify invalid action was not added to history
    try testing.expect(game_state.getActionCount() == 0);

    // Clean up the invalid action since it wasn't added to game state
    invalid_action.deinit(allocator);
    allocator.destroy(invalid_action);

    // Test accessing actions with invalid indices
    try testing.expect(game_state.getAction(0) == null);
    try testing.expect(game_state.getAction(100) == null);

    // Test multiple consecutive undos on empty history
    try testing.expect(!game_state.undoLastAction());
    try testing.expect(!game_state.undoLastAction());
    try testing.expect(game_state.getActionCount() == 0);
}

test "gamestate memory management" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test that multiple init/deinit cycles work correctly
    for (0..3) |_| {
        var game_state = GameState.init(allocator);
        defer game_state.deinit();

        game_state.setupInitialPosition();

        // Execute some moves
        var move1 = Move.initFromCoords(1, 4, 3, 4);
        const action1 = try move1.asAction(allocator);
        _ = try game_state.executeAction(action1);

        var move2 = Move.initFromCoords(6, 4, 4, 4);
        const action2 = try move2.asAction(allocator);
        _ = try game_state.executeAction(action2);

        try testing.expect(game_state.getActionCount() == 2);

        // Clear actions and verify cleanup
        game_state.clearActions();
        try testing.expect(game_state.getActionCount() == 0);
    }

    // Test that actions are properly cleaned up on deinit
    {
        var game_state = GameState.init(allocator);

        game_state.setupInitialPosition();

        // Execute several moves
        for (0..5) |i| {
            var move = Move.initFromCoords(1, @intCast(i % 8), 3, @intCast(i % 8));
            const move_action = try move.asAction(allocator);
            _ = try game_state.executeAction(move_action);
        }

        try testing.expect(game_state.getActionCount() == 5);

        // Deinit should clean up all actions
        game_state.deinit();
    }
}

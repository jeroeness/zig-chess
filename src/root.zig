//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

// Re-export the modules
pub const piece = @import("piece.zig");
pub const cell = @import("cell.zig");
pub const board = @import("board.zig");
pub const renderer = @import("renderer.zig");
pub const action = @import("actions/action.zig");
pub const coord = @import("coord.zig");
pub const gamestate = @import("gamestate.zig");

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

test "board initialization" {
    var chessboard = Board.init();

    // Test that all cells are initialized and pieces are empty
    for (0..8) |row| {
        for (0..8) |col| {
            const chess_cell = chessboard.getCell(@intCast(row), @intCast(col));
            try testing.expect(chess_cell != null);
            try testing.expect(chess_cell.?.row == row);
            try testing.expect(chess_cell.?.col == col);
            try testing.expect(chessboard.isEmpty(@intCast(row), @intCast(col)));
        }
    }
}

test "piece placement and movement" {
    var chessboard = Board.init();

    // Test piece placement
    const white_king = Piece.init(.king, .white);
    try testing.expect(chessboard.setPiece(4, 4, white_king));

    try testing.expect(!chessboard.isEmpty(4, 4));
    const placed_piece = chessboard.getPieceConst(4, 4);
    try testing.expect(placed_piece != null);
    try testing.expect(placed_piece.?.piece_type == .king);
    try testing.expect(placed_piece.?.color == .white);

    // Test piece movement
    try testing.expect(chessboard.movePiece(4, 4, 5, 5));

    try testing.expect(chessboard.isEmpty(4, 4));
    try testing.expect(!chessboard.isEmpty(5, 5));
    const moved_piece = chessboard.getPieceConst(5, 5);
    try testing.expect(moved_piece != null);
    try testing.expect(moved_piece.?.piece_type == .king);
    try testing.expect(moved_piece.?.color == .white);
}

test "initial board setup" {
    var chessboard = Board.init();
    chessboard.setupInitialPosition();

    // Test white pieces
    const white_rook = chessboard.getPieceConst(0, 0);
    try testing.expect(white_rook != null);
    try testing.expect(white_rook.?.piece_type == .rook);
    try testing.expect(white_rook.?.color == .white);

    const white_king = chessboard.getPieceConst(0, 4);
    try testing.expect(white_king != null);
    try testing.expect(white_king.?.piece_type == .king);
    try testing.expect(white_king.?.color == .white);

    // Test black pieces
    const black_rook = chessboard.getPieceConst(7, 0);
    try testing.expect(black_rook != null);
    try testing.expect(black_rook.?.piece_type == .rook);
    try testing.expect(black_rook.?.color == .black);

    const black_king = chessboard.getPieceConst(7, 4);
    try testing.expect(black_king != null);
    try testing.expect(black_king.?.piece_type == .king);
    try testing.expect(black_king.?.color == .black);

    // Test pawns
    const white_pawn = chessboard.getPieceConst(1, 0);
    try testing.expect(white_pawn != null);
    try testing.expect(white_pawn.?.piece_type == .pawn);
    try testing.expect(white_pawn.?.color == .white);

    const black_pawn = chessboard.getPieceConst(6, 0);
    try testing.expect(black_pawn != null);
    try testing.expect(black_pawn.?.piece_type == .pawn);
    try testing.expect(black_pawn.?.color == .black);

    // Test empty squares
    try testing.expect(chessboard.isEmpty(2, 0));
    try testing.expect(chessboard.isEmpty(5, 0));
}

test "renderer functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Create a chess board
    var chess_board = Board.init();

    // Place some test pieces
    try testing.expect(chess_board.setPiece(0, 0, Piece.init(.rook, .black)));
    try testing.expect(chess_board.setPiece(7, 7, Piece.init(.king, .white)));

    // Create renderer
    const config = RendererConfig{
        .cell_size = 8,
        .show_coordinates = true,
        .use_unicode = false,
    };

    var board_renderer = Renderer.init(config);
    defer board_renderer.deinit();

    // Test that we can create and use the renderer without errors
    // In a real test, we might capture output and verify it
    // For now, just ensure no crashes
    try testing.expect(true);
}

test "serialize and deserialize board" {
    const allocator = std.heap.page_allocator;

    var original_board = Board.init();
    original_board.setupInitialPosition();

    // Add some custom pieces to test various scenarios
    try testing.expect(original_board.setPiece(2, 2, Piece.init(.amazon, .white)));
    try testing.expect(original_board.setPiece(3, 5, Piece.init(.knight, .black)));
    try testing.expect(original_board.clearPiece(1, 1)); // Remove a pawn

    // Serialize the board
    const serialized_data = try original_board.serialize(allocator);
    defer allocator.free(serialized_data);

    // Debug print to show all u32 values in serialized data
    // std.debug.print("Serialized data contains {} bytes\n", .{serialized_data.len});

    // const u32_count = serialized_data.len;

    // std.debug.print("U32 values in serialized data:\n", .{});
    // for (0..u32_count) |i| {
    //     const value = serialized_data[i];
    //     std.debug.print("[{}]: 0x{X:08} ({})\n", .{ i, value, value });
    // }

    // Deserialize the board
    var deserialized_board = try Board.deserialize(serialized_data, allocator);

    // Test that the boards are equal using both equality methods
    try testing.expect(original_board.eql(deserialized_board));
    try testing.expect(original_board.eql_fast(&deserialized_board));

    // Test some specific pieces to make sure they're correctly preserved
    const original_king = original_board.getPieceConst(0, 4);
    const deserialized_king = deserialized_board.getPieceConst(0, 4);
    try testing.expect(original_king != null);
    try testing.expect(deserialized_king != null);
    try testing.expect(original_king.?.piece_type == deserialized_king.?.piece_type);
    try testing.expect(original_king.?.color == deserialized_king.?.color);

    // Test the custom amazon piece
    const original_amazon = original_board.getPieceConst(2, 2);
    const deserialized_amazon = deserialized_board.getPieceConst(2, 2);
    try testing.expect(original_amazon != null);
    try testing.expect(deserialized_amazon != null);
    try testing.expect(original_amazon.?.piece_type == .amazon);
    try testing.expect(deserialized_amazon.?.piece_type == .amazon);
    try testing.expect(original_amazon.?.color == deserialized_amazon.?.color);

    // Test the cleared piece (should be empty in both boards)
    try testing.expect(original_board.isEmpty(1, 1));
    try testing.expect(deserialized_board.isEmpty(1, 1));

    // Test that hash values are consistent
    const original_hash = original_board.hash();
    const deserialized_hash = deserialized_board.hash();
    try testing.expect(original_hash == deserialized_hash);
}

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
    try testing.expect(piece_at_start.?.piece_type == .pawn);
    try testing.expect(piece_at_start.?.color == .white);

    // Test that target position is empty
    try testing.expect(chess_board.isEmpty(3, 4));

    // Execute the move
    try testing.expect(move_action.execute(&chess_board));

    // Verify the move was executed
    try testing.expect(chess_board.isEmpty(1, 4)); // Start position should be empty
    try testing.expect(!chess_board.isEmpty(3, 4)); // Target position should have piece

    const piece_at_target = chess_board.getPieceConst(3, 4);
    try testing.expect(piece_at_target != null);
    try testing.expect(piece_at_target.?.piece_type == .pawn);
    try testing.expect(piece_at_target.?.color == .white);

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
    try testing.expect(piece_back_at_start.?.piece_type == .pawn);
    try testing.expect(piece_back_at_start.?.color == .white);

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
    try testing.expect(piece_at_e4.?.piece_type == .pawn);
    try testing.expect(piece_at_e4.?.color == .white);

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
    try testing.expect(piece_at_e5.?.piece_type == .pawn);
    try testing.expect(piece_at_e5.?.color == .black);

    // Test undo functionality
    // Undo move 2 first (last move first)
    try testing.expect(action2.undo(&game_board));

    // Verify move 2 was undone
    try testing.expect(!game_board.isEmpty(6, 4)); // e7 should have piece again
    try testing.expect(game_board.isEmpty(4, 4)); // e5 should be empty
    const piece_back_at_e7 = game_board.getPieceConst(6, 4);
    try testing.expect(piece_back_at_e7 != null);
    try testing.expect(piece_back_at_e7.?.piece_type == .pawn);
    try testing.expect(piece_back_at_e7.?.color == .black);

    // Undo move 1
    try testing.expect(action1.undo(&game_board));

    // Verify move 1 was undone
    try testing.expect(!game_board.isEmpty(1, 4)); // e2 should have piece again
    try testing.expect(game_board.isEmpty(3, 4)); // e4 should be empty
    const piece_back_at_e2 = game_board.getPieceConst(1, 4);
    try testing.expect(piece_back_at_e2 != null);
    try testing.expect(piece_back_at_e2.?.piece_type == .pawn);
    try testing.expect(piece_back_at_e2.?.color == .white);

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
        _ = game_board.setPiece(6, 4, Piece.init(.pawn, .white));

        // Create a promotion move from e7 to e8, promoting to queen
        var promotion_move = Move.initFromCoordsWithPromotion(6, 4, 7, 4, .queen);
        const promotion_action = try promotion_move.asAction(allocator);
        defer allocator.destroy(promotion_action);

        // Execute the promotion
        try testing.expect(promotion_action.execute(&game_board));

        // Verify the promoted piece
        const promoted_piece = game_board.getPieceConst(7, 4);
        try testing.expect(promoted_piece != null);
        try testing.expect(promoted_piece.?.piece_type == .queen);
        try testing.expect(promoted_piece.?.color == .white);

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
        try testing.expect(restored_piece.?.piece_type == .pawn);
        try testing.expect(restored_piece.?.color == .white);

        promotion_action.deinit(allocator);
    }

    // Test promotion to amazon (fairy piece)
    {
        var game_board = Board.init();

        // Place a black pawn on the 2nd rank (about to promote)
        _ = game_board.setPiece(1, 3, Piece.init(.pawn, .black));

        // Create a promotion move from d2 to d1, promoting to amazon
        var promotion_move = Move.initFromCoordsWithPromotion(1, 3, 0, 3, .amazon);
        const amazon_action = try promotion_move.asAction(allocator);
        defer allocator.destroy(amazon_action);

        // Execute the promotion
        try testing.expect(amazon_action.execute(&game_board));

        // Verify the promoted piece
        const promoted_piece = game_board.getPieceConst(0, 3);
        try testing.expect(promoted_piece != null);
        try testing.expect(promoted_piece.?.piece_type == .amazon);
        try testing.expect(promoted_piece.?.color == .black);

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
        try testing.expect(restored_piece.?.piece_type == .pawn);
        try testing.expect(restored_piece.?.color == .black);

        amazon_action.deinit(allocator);
    }

    // Test promotion with capture
    {
        var game_board = Board.init();

        // Place a white pawn on the 7th rank
        _ = game_board.setPiece(6, 4, Piece.init(.pawn, .white));

        // Place a black piece to be captured on e8
        _ = game_board.setPiece(7, 4, Piece.init(.rook, .black));

        // Create a promotion move with capture from e7 to e8, promoting to rook
        var promotion_move = Move.initFromCoordsWithPromotion(6, 4, 7, 4, .rook);
        const capture_action = try promotion_move.asAction(allocator);
        defer allocator.destroy(capture_action);

        // Execute the promotion
        try testing.expect(capture_action.execute(&game_board));

        // Verify the promoted piece
        const promoted_piece = game_board.getPieceConst(7, 4);
        try testing.expect(promoted_piece != null);
        try testing.expect(promoted_piece.?.piece_type == .rook);
        try testing.expect(promoted_piece.?.color == .white);

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
        try testing.expect(restored_piece.?.piece_type == .pawn);
        try testing.expect(restored_piece.?.color == .white);

        // Verify captured piece was restored
        const restored_captured = game_board.getPieceConst(7, 4);
        try testing.expect(restored_captured != null);
        try testing.expect(restored_captured.?.piece_type == .rook);
        try testing.expect(restored_captured.?.color == .black);

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
    _ = chess_board.setPiece(2, 2, Piece.init(.amazon, .white));

    // Serialize the initial state
    const serialized_data = try state.serialize(allocator);
    defer allocator.free(serialized_data);

    // Debug print to show all u32 values in serialized data
    // std.debug.print("Serialized data contains {} bytes\n", .{serialized_data.len});

    // const u32_count = serialized_data.len;

    // std.debug.print("U32 values in serialized data:\n", .{});
    // for (0..u32_count) |i| {
    //     const value = serialized_data[i];
    //     std.debug.print("[{}]: 0x{X:08} ({})\n", .{ i, value, value });
    // }

    // Deserialize to a new gamestate
    var deserialized_state = try GameState.deserialize(serialized_data, allocator);

    // Compare original and deserialized state
    try testing.expect(state.eql(deserialized_state));

    // Test some specific pieces to make sure they're correctly preserved
    const original_king = chess_board.getPieceConst(0, 4);
    const deserialized_king = deserialized_state.getBoard().getPieceConst(0, 4);
    try testing.expect(original_king != null);
    try testing.expect(deserialized_king != null);
    try testing.expect(original_king.?.piece_type == deserialized_king.?.piece_type);
    try testing.expect(original_king.?.color == deserialized_king.?.color);

    // Test the custom amazon piece
    const original_amazon = chess_board.getPieceConst(2, 2);
    const deserialized_amazon = deserialized_state.getBoard().getPieceConst(2, 2);
    try testing.expect(original_amazon != null);
    try testing.expect(deserialized_amazon != null);
    try testing.expect(original_amazon.?.piece_type == .amazon);
    try testing.expect(deserialized_amazon.?.piece_type == .amazon);
    try testing.expect(original_amazon.?.color == deserialized_amazon.?.color);

    // Test that a pawn position is consistent (should have white pawn in both boards)
    try testing.expect(!chess_board.isEmpty(1, 1));
    try testing.expect(!deserialized_state.getBoard().isEmpty(1, 1));
    
    const original_pawn = chess_board.getPieceConst(1, 1);
    const deserialized_pawn = deserialized_state.getBoard().getPieceConst(1, 1);
    try testing.expect(original_pawn != null);
    try testing.expect(deserialized_pawn != null);
    try testing.expect(original_pawn.?.piece_type == .pawn);
    try testing.expect(deserialized_pawn.?.piece_type == .pawn);
    try testing.expect(original_pawn.?.color == deserialized_pawn.?.color);

    // Test that hash values are consistent
    const original_hash = state.hash();
    const deserialized_hash = deserialized_state.hash();
    try testing.expect(original_hash == deserialized_hash);
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
    _ = game_state.getBoard().setPiece(6, 4, Piece.init(.pawn, .white));

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
    try testing.expect(promoted_piece.?.piece_type == .queen);
    try testing.expect(promoted_piece.?.color == .white);

    // Undo the promotion
    try testing.expect(game_state.undoLastAction());
    try testing.expect(game_state.getActionCount() == 0);

    // Verify the promotion was undone
    try testing.expect(game_state.getBoard().isEmpty(7, 4)); // Promoted position empty

    const restored_piece = game_state.getBoard().getPieceConst(6, 4);
    try testing.expect(restored_piece != null);
    try testing.expect(restored_piece.?.piece_type == .pawn);
    try testing.expect(restored_piece.?.color == .white);
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

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
pub const action = @import("action.zig");

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
pub const Coord = action.Coord;

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

const std = @import("std");
const testing = std.testing;
const root = @import("root_chess");

const Board = root.Board;
const Piece = root.Piece;
const Coord = root.Coord;

test "board initialization" {
    var chessboard = Board.init();

    // Test that all cells are initialized and pieces are empty
    for (0..8) |row| {
        for (0..8) |col| {
            const position = Coord.init(@intCast(row), @intCast(col));
            const chess_cell = chessboard.getCell(position);
            try testing.expect(chess_cell != null);
            try testing.expect(chess_cell.?.coord.row == row);
            try testing.expect(chess_cell.?.coord.col == col);
            try testing.expect(chessboard.isEmpty(position));
        }
    }
}

test "piece placement and movement" {
    var chessboard = Board.init();

    // Test piece placement
    const white_king = Piece.init(.king, .white, 1);
    const position1 = Coord.init(4, 4);
    try testing.expect(chessboard.setPiece(position1, white_king));

    // Verify the piece was placed correctly
    const placed_piece = chessboard.getPieceConst(position1);
    try testing.expect(placed_piece != null);
    try testing.expect(placed_piece.?.getType() == .king);
    try testing.expect(placed_piece.?.getColor() == .white);

    // Test move piece
    const position2 = Coord.init(5, 5);
    try testing.expect(chessboard.movePiece(position1, position2));

    // Verify the piece was moved
    try testing.expect(chessboard.isEmpty(position1));
    const moved_piece = chessboard.getPieceConst(position2);
    try testing.expect(moved_piece != null);
    try testing.expect(moved_piece.?.getType() == .king);
    try testing.expect(moved_piece.?.getColor() == .white);
}

test "initial board setup" {
    var chessboard = Board.init();
    chessboard.setupInitialPosition();

    // Test white pieces (bottom row - row 0)
    const white_rook_a1 = chessboard.getPieceConst(Coord.init(0, 0));
    try testing.expect(white_rook_a1 != null);
    try testing.expect(white_rook_a1.?.getType() == .rook);
    try testing.expect(white_rook_a1.?.getColor() == .white);

    const white_knight_b1 = chessboard.getPieceConst(Coord.init(0, 1));
    try testing.expect(white_knight_b1 != null);
    try testing.expect(white_knight_b1.?.getType() == .knight);
    try testing.expect(white_knight_b1.?.getColor() == .white);

    const white_king_e1 = chessboard.getPieceConst(Coord.init(0, 4));
    try testing.expect(white_king_e1 != null);
    try testing.expect(white_king_e1.?.getType() == .king);
    try testing.expect(white_king_e1.?.getColor() == .white);

    // Test white pawns (row 1)
    for (0..8) |col| {
        const pawn = chessboard.getPieceConst(Coord.init(1, @intCast(col)));
        try testing.expect(pawn != null);
        try testing.expect(pawn.?.getType() == .pawn);
        try testing.expect(pawn.?.getColor() == .white);
    }

    // Test black pieces (top row - row 7)
    const black_rook_a8 = chessboard.getPieceConst(Coord.init(7, 0));
    try testing.expect(black_rook_a8 != null);
    try testing.expect(black_rook_a8.?.getType() == .rook);
    try testing.expect(black_rook_a8.?.getColor() == .black);

    const black_king_e8 = chessboard.getPieceConst(Coord.init(7, 4));
    try testing.expect(black_king_e8 != null);
    try testing.expect(black_king_e8.?.getType() == .king);
    try testing.expect(black_king_e8.?.getColor() == .black);

    // Test black pawns (row 6)
    for (0..8) |col| {
        const pawn = chessboard.getPieceConst(Coord.init(6, @intCast(col)));
        try testing.expect(pawn != null);
        try testing.expect(pawn.?.getType() == .pawn);
        try testing.expect(pawn.?.getColor() == .black);
    }

    // Test empty squares (rows 2-5)
    for (2..6) |row| {
        for (0..8) |col| {
            try testing.expect(chessboard.isEmpty(Coord.init(@intCast(row), @intCast(col))));
        }
    }
}

test "serialize and deserialize board" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a board with initial position
    var original_board = Board.init();
    original_board.setupInitialPosition();

    // Add a custom amazon piece for testing
    _ = original_board.setPiece(Coord.init(2, 2), Piece.init(.amazon, .white, 1));

    // Clear a piece for testing empty positions
    _ = original_board.clearPiece(Coord.init(1, 1));

    // Serialize the board
    const serialized_data = try original_board.serialize(allocator);
    defer allocator.free(serialized_data);

    // Deserialize to a new board
    var deserialized_board = try Board.deserialize(serialized_data, allocator);

    // Test that the boards are equal using both equality methods
    try testing.expect(original_board.eql(deserialized_board));
    try testing.expect(original_board.eql_fast(&deserialized_board));

    // Test some specific pieces to make sure they're correctly preserved
    const original_king = original_board.getPieceConst(Coord.init(0, 4));
    const deserialized_king = deserialized_board.getPieceConst(Coord.init(0, 4));
    try testing.expect(original_king != null);
    try testing.expect(deserialized_king != null);
    try testing.expect(original_king.?.getType() == deserialized_king.?.getType());
    try testing.expect(original_king.?.getColor() == deserialized_king.?.getColor());

    // Test the custom amazon piece
    const original_amazon = original_board.getPieceConst(Coord.init(2, 2));
    const deserialized_amazon = deserialized_board.getPieceConst(Coord.init(2, 2));
    try testing.expect(original_amazon != null);
    try testing.expect(deserialized_amazon != null);
    try testing.expect(original_amazon.?.getType() == .amazon);
    try testing.expect(deserialized_amazon.?.getType() == .amazon);
    try testing.expect(original_amazon.?.getColor() == deserialized_amazon.?.getColor());

    // Test the cleared piece (should be empty in both boards)
    try testing.expect(original_board.isEmpty(Coord.init(1, 1)));
    try testing.expect(deserialized_board.isEmpty(Coord.init(1, 1)));

    // Test that hash values are consistent
    const original_hash = original_board.hash();
    const deserialized_hash = deserialized_board.hash();
    try testing.expect(original_hash == deserialized_hash);
}

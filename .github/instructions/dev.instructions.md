---
applyTo: '**'
---
# Principles for Development
When creating a new feature: follow instructions from the user, write tests, run the tests, and update the `.github/instructions/dev.instructions.md` with important details if necessary.
Make sure all modules are imported and declared in `src/root_chess.zig` for easy access.

## Coding styleguide
Do not add comments to the code. The code should be self-explanatory through clear naming conventions and structure.
For debug prints without parameters, use this template: `std.debug.print("Message\n", .{});`

## Movement System
- Created `src/pieces/movement.zig` that provides movement behaviors for all piece types
- Each piece type has its own movement function indexed by the piece type enum value
- The `Piece` struct has a `getMoves()` method that returns a list of valid moves
- Movement functions handle blocking, captures, and piece-specific rules (e.g., pawn double move from starting position)

## Renderer Enhancements
- Renderer now requires an allocator in its constructor: `Renderer.init(config, allocator)`
- When a piece is selected, it shows possible moves with visual indicators:
  - Green circles for normal moves
  - Red triangles in corners for capture moves
- Clicking a piece selects it and calculates/displays possible moves
- Clicking the same piece again deselects it
- Clicking empty space clears selection

## Testing

Running tests call the tool: `run_all_zig_tests`.
Do not run individual tests directly. Always use the tool.

Add a test in the `tests/` directory. Each test file should `const root = @import("root_chess");` to access the main functionality of the chess engine.
Make sure to add the test file to `tests/tests.zig` so it gets included in the test suite. Do not modify the `build.zig` file directly for test imports.
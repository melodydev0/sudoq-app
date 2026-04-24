import 'dart:math';

/// Robust Sudoku puzzle generator that ALWAYS produces valid, solvable puzzles
/// with exactly one unique solution
class SudokuGenerator {
  late Random _random;

  SudokuGenerator() {
    _random = Random();
  }

  /// Generate a Sudoku puzzle with the specified difficulty
  /// Returns a map with 'puzzle' and 'solution'
  /// GUARANTEED to have exactly one valid solution
  Map<String, List<List<int>>> generatePuzzle({
    required String difficulty,
    int gridSize = 9,
  }) {
    // Step 1: Generate a complete valid solution
    final solution = _generateValidSolution(gridSize);

    // Step 2: Create puzzle by carefully removing cells while ensuring unique solution
    final puzzle = _createValidPuzzle(solution, difficulty, gridSize);

    // Step 3: Verify the puzzle is solvable (safety check)
    assert(_verifySolvable(puzzle, solution, gridSize),
        'Generated puzzle must be solvable!');

    return {
      'puzzle': puzzle,
      'solution': solution,
    };
  }

  /// Generate a complete valid 9x9 Sudoku solution using a proven method
  List<List<int>> _generateValidSolution(int size) {
    final grid = List.generate(size, (_) => List.filled(size, 0));

    // Use a proven base pattern and shuffle it
    _fillWithShuffledPattern(grid, size);

    return grid;
  }

  /// Fill grid using a shuffled valid pattern
  void _fillWithShuffledPattern(List<List<int>> grid, int size) {
    // Note: boxSize would be size == 9 ? 3 : 4 for 16x16 support

    // Create shuffled number mapping (1-9 -> random permutation)
    final numbers = List.generate(size, (i) => i + 1)..shuffle(_random);

    // Create shuffled row bands and column bands
    final rowBands = [0, 1, 2]..shuffle(_random);
    final colBands = [0, 1, 2]..shuffle(_random);

    // Shuffle rows within each band
    final rowOrder = <int>[];
    for (final band in rowBands) {
      final bandRows = [0, 1, 2]..shuffle(_random);
      for (final r in bandRows) {
        rowOrder.add(band * 3 + r);
      }
    }

    // Shuffle columns within each band
    final colOrder = <int>[];
    for (final band in colBands) {
      final bandCols = [0, 1, 2]..shuffle(_random);
      for (final c in bandCols) {
        colOrder.add(band * 3 + c);
      }
    }

    // Use a known valid base pattern
    final basePattern = _getBasePattern(size);

    // Apply all transformations
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final sourceRow = rowOrder[r];
        final sourceCol = colOrder[c];
        final baseValue = basePattern[sourceRow][sourceCol];
        grid[r][c] = numbers[baseValue - 1];
      }
    }
  }

  /// Get a known valid Sudoku pattern
  List<List<int>> _getBasePattern(int size) {
    if (size == 9) {
      return [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [4, 5, 6, 7, 8, 9, 1, 2, 3],
        [7, 8, 9, 1, 2, 3, 4, 5, 6],
        [2, 3, 4, 5, 6, 7, 8, 9, 1],
        [5, 6, 7, 8, 9, 1, 2, 3, 4],
        [8, 9, 1, 2, 3, 4, 5, 6, 7],
        [3, 4, 5, 6, 7, 8, 9, 1, 2],
        [6, 7, 8, 9, 1, 2, 3, 4, 5],
        [9, 1, 2, 3, 4, 5, 6, 7, 8],
      ];
    }
    // For 16x16, use backtracking
    final grid = List.generate(size, (_) => List.filled(size, 0));
    _fillGridBacktrack(grid, size);
    return grid;
  }

  /// Fill grid using backtracking (fallback method)
  bool _fillGridBacktrack(List<List<int>> grid, int size) {
    final boxSize = size == 9 ? 3 : 4;

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == 0) {
          final numbers = List.generate(size, (i) => i + 1)..shuffle(_random);

          for (final num in numbers) {
            if (_isValidPlacement(grid, row, col, num, size, boxSize)) {
              grid[row][col] = num;

              if (_fillGridBacktrack(grid, size)) {
                return true;
              }

              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Check if placing a number at position is valid
  bool _isValidPlacement(
    List<List<int>> grid,
    int row,
    int col,
    int num,
    int size,
    int boxSize,
  ) {
    // Check row
    for (int c = 0; c < size; c++) {
      if (grid[row][c] == num) return false;
    }

    // Check column
    for (int r = 0; r < size; r++) {
      if (grid[r][col] == num) return false;
    }

    // Check box
    final boxRowStart = (row ~/ boxSize) * boxSize;
    final boxColStart = (col ~/ boxSize) * boxSize;

    for (int r = boxRowStart; r < boxRowStart + boxSize; r++) {
      for (int c = boxColStart; c < boxColStart + boxSize; c++) {
        if (grid[r][c] == num) return false;
      }
    }

    return true;
  }

  /// Create a puzzle by removing numbers while ALWAYS ensuring unique solution
  List<List<int>> _createValidPuzzle(
    List<List<int>> solution,
    String difficulty,
    int size,
  ) {
    final puzzle = solution.map((row) => List<int>.from(row)).toList();
    final targetClues = _getTargetClues(difficulty, size);
    final totalCells = size * size;
    final targetRemove = totalCells - targetClues;

    // Get all cell positions and shuffle
    final positions = <List<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        positions.add([r, c]);
      }
    }
    positions.shuffle(_random);

    int removed = 0;
    int attempts = 0;
    final maxAttempts = totalCells * 2; // Prevent infinite loops

    for (final pos in positions) {
      if (removed >= targetRemove || attempts >= maxAttempts) break;
      attempts++;

      final row = pos[0];
      final col = pos[1];

      if (puzzle[row][col] == 0) continue;

      final backup = puzzle[row][col];
      puzzle[row][col] = 0;

      // ALWAYS check for unique solution
      final solutionCount = _countSolutions(puzzle, size, 2);

      if (solutionCount != 1) {
        // More than one solution or no solution - restore the cell
        puzzle[row][col] = backup;
      } else {
        removed++;
      }
    }

    return puzzle;
  }

  /// Get target number of clues (filled cells) based on difficulty
  int _getTargetClues(String difficulty, int size) {
    // For 9x9 Sudoku, minimum clues for unique solution is 17
    // We use safe values above this
    final Map<String, int> clueCount = {
      'Beginner': 45, // Very easy
      'Easy': 38,
      'Medium': 32,
      'Hard': 28,
      'Expert': 24,
      'Extreme': 22,
      'Fast': 40,
    };

    return clueCount[difficulty] ?? 35;
  }

  /// Count solutions (stops at limit)
  int _countSolutions(List<List<int>> puzzle, int size, int limit) {
    final copy = puzzle.map((row) => List<int>.from(row)).toList();
    int count = 0;

    _solveCounting(copy, size, 0, () {
      count++;
      return count < limit; // Continue only if below limit
    });

    return count;
  }

  /// Solve with counting
  bool _solveCounting(
    List<List<int>> grid,
    int size,
    int startPos,
    bool Function() shouldContinue,
  ) {
    final boxSize = size == 9 ? 3 : 4;

    // Find next empty cell starting from startPos
    int pos = startPos;
    while (pos < size * size) {
      final row = pos ~/ size;
      final col = pos % size;
      if (grid[row][col] == 0) break;
      pos++;
    }

    if (pos >= size * size) {
      // All cells filled - found a solution
      return true;
    }

    final row = pos ~/ size;
    final col = pos % size;

    for (int num = 1; num <= size; num++) {
      if (_isValidPlacement(grid, row, col, num, size, boxSize)) {
        grid[row][col] = num;

        if (_solveCounting(grid, size, pos + 1, shouldContinue)) {
          if (!shouldContinue()) {
            grid[row][col] = 0;
            return true;
          }
        }

        grid[row][col] = 0;
      }
    }
    return false;
  }

  /// Verify that puzzle is solvable and matches solution
  bool _verifySolvable(
    List<List<int>> puzzle,
    List<List<int>> solution,
    int size,
  ) {
    final copy = puzzle.map((row) => List<int>.from(row)).toList();

    if (!_solve(copy, size)) {
      return false;
    }

    // Check solved puzzle matches original solution
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (copy[r][c] != solution[r][c]) {
          return false;
        }
      }
    }

    return true;
  }

  /// Solve a puzzle
  bool _solve(List<List<int>> grid, int size) {
    final boxSize = size == 9 ? 3 : 4;

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == 0) {
          for (int num = 1; num <= size; num++) {
            if (_isValidPlacement(grid, row, col, num, size, boxSize)) {
              grid[row][col] = num;

              if (_solve(grid, size)) {
                return true;
              }

              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Solve a puzzle (public method for hint feature)
  bool solvePuzzle(List<List<int>> grid, int size) {
    return _solve(grid, size);
  }

  /// Validate if a move is correct
  bool isValidMove(
    List<List<int>> grid,
    int row,
    int col,
    int num,
    int size,
  ) {
    final boxSize = size == 9 ? 3 : 4;
    final temp = grid[row][col];
    grid[row][col] = 0;
    final isValid = _isValidPlacement(grid, row, col, num, size, boxSize);
    grid[row][col] = temp;
    return isValid;
  }

  /// Get hint - returns the correct number for a random empty cell
  Map<String, int>? getHintForEmptyCell(
    List<List<int>> currentGrid,
    List<List<int>> solution,
    int size,
  ) {
    final emptyCells = <List<int>>[];

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (currentGrid[row][col] == 0) {
          emptyCells.add([row, col]);
        }
      }
    }

    if (emptyCells.isEmpty) return null;

    final randomCell = emptyCells[_random.nextInt(emptyCells.length)];
    return {
      'row': randomCell[0],
      'col': randomCell[1],
      'value': solution[randomCell[0]][randomCell[1]],
    };
  }

  /// Generate a daily challenge (seeded by date for reproducibility)
  Map<String, List<List<int>>> generateDailyChallenge(DateTime date) {
    // Use date as seed for consistent daily puzzle
    final seed = date.year * 10000 + date.month * 100 + date.day;
    _random = Random(seed);

    // Rotate difficulty based on day of week
    final difficulties = [
      'Easy',
      'Easy',
      'Medium',
      'Medium',
      'Hard',
      'Hard',
      'Expert'
    ];
    final difficulty = difficulties[date.weekday - 1];

    final result = generatePuzzle(difficulty: difficulty);

    // Reset random to unseeded for other operations
    _random = Random();

    return result;
  }

  /// Get candidates for a cell (possible valid numbers)
  Set<int> getCandidates(List<List<int>> grid, int row, int col, int size) {
    if (grid[row][col] != 0) return {};

    final boxSize = size == 9 ? 3 : 4;
    final candidates = <int>{};

    for (int num = 1; num <= size; num++) {
      if (_isValidPlacement(grid, row, col, num, size, boxSize)) {
        candidates.add(num);
      }
    }

    return candidates;
  }

  /// Fill all candidates as notes (for Fast Pencil feature)
  List<List<Set<int>>> fillAllCandidates(List<List<int>> grid, int size) {
    final notes = List.generate(
      size,
      (_) => List.generate(size, (_) => <int>{}),
    );

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == 0) {
          notes[row][col] = getCandidates(grid, row, col, size);
        }
      }
    }

    return notes;
  }
}

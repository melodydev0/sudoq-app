import 'dart:math';

/// Comprehensive Sudoku Generator Test
/// Tests puzzle generation for all difficulty levels
/// Verifies: solvability, unique solution, proper difficulty

void main() {
  print('=' * 60);
  print('SUDOKU GENERATOR COMPREHENSIVE TEST');
  print('=' * 60);
  print('');

  final generator = TestSudokuGenerator();
  final results = <String, TestResult>{};

  // Test each difficulty level
  final difficulties = [
    'Beginner',
    'Easy',
    'Medium',
    'Hard',
    'Expert',
    'Extreme'
  ];
  const puzzlesPerDifficulty = 10; // Test 10 puzzles per difficulty

  int totalPuzzles = 0;
  int totalPassed = 0;
  int totalFailed = 0;

  for (final difficulty in difficulties) {
    print('Testing $difficulty difficulty...');
    print('-' * 40);

    int passed = 0;
    int failed = 0;
    List<int> clueCounts = [];
    List<int> solveTimes = [];

    for (int i = 0; i < puzzlesPerDifficulty; i++) {
      totalPuzzles++;
      final testResult = testPuzzle(generator, difficulty, i + 1);

      if (testResult.passed) {
        passed++;
        totalPassed++;
        clueCounts.add(testResult.clueCount);
        solveTimes.add(testResult.solveTimeMs);
        print(
            '  Puzzle ${i + 1}: ✓ PASS (${testResult.clueCount} clues, ${testResult.solveTimeMs}ms)');
      } else {
        failed++;
        totalFailed++;
        print('  Puzzle ${i + 1}: ✗ FAIL - ${testResult.errorMessage}');
      }
    }

    final avgClues = clueCounts.isEmpty
        ? 0
        : (clueCounts.reduce((a, b) => a + b) / clueCounts.length).round();
    final avgTime = solveTimes.isEmpty
        ? 0
        : (solveTimes.reduce((a, b) => a + b) / solveTimes.length).round();

    results[difficulty] = TestResult(
      passed: passed == puzzlesPerDifficulty,
      clueCount: avgClues,
      solveTimeMs: avgTime,
      errorMessage: failed > 0 ? '$failed puzzles failed' : '',
    );

    print('');
    print('  Summary: $passed/$puzzlesPerDifficulty passed');
    print('  Average clues: $avgClues');
    print('  Average solve time: ${avgTime}ms');
    print('');
  }

  // Final Summary
  print('=' * 60);
  print('FINAL RESULTS');
  print('=' * 60);
  print('');
  print('Total puzzles tested: $totalPuzzles');
  print('Passed: $totalPassed');
  print('Failed: $totalFailed');
  print(
      'Success rate: ${(totalPassed / totalPuzzles * 100).toStringAsFixed(1)}%');
  print('');

  print('Difficulty Analysis:');
  print('-' * 40);
  for (final entry in results.entries) {
    final status = entry.value.passed ? '✓' : '✗';
    print(
        '  ${entry.key.padRight(10)} $status  Avg clues: ${entry.value.clueCount}');
  }
  print('');

  // Verify difficulty progression
  print('Difficulty Progression Check:');
  print('-' * 40);
  final clueProgression =
      difficulties.map((d) => results[d]!.clueCount).toList();
  bool validProgression = true;
  for (int i = 0; i < clueProgression.length - 1; i++) {
    if (clueProgression[i] < clueProgression[i + 1]) {
      print(
          '  ✗ ${difficulties[i]} (${clueProgression[i]}) should have more clues than ${difficulties[i + 1]} (${clueProgression[i + 1]})');
      validProgression = false;
    }
  }
  if (validProgression) {
    print('  ✓ Difficulty progression is correct (more clues = easier)');
  }

  print('');
  print('=' * 60);
  if (totalFailed == 0 && validProgression) {
    print('ALL TESTS PASSED! ✓');
  } else {
    print('SOME TESTS FAILED! ✗');
  }
  print('=' * 60);
}

class TestResult {
  final bool passed;
  final int clueCount;
  final int solveTimeMs;
  final String errorMessage;

  TestResult({
    required this.passed,
    required this.clueCount,
    required this.solveTimeMs,
    required this.errorMessage,
  });
}

TestResult testPuzzle(
    TestSudokuGenerator generator, String difficulty, int puzzleNum) {
  try {
    final stopwatch = Stopwatch()..start();

    // Generate puzzle
    final result = generator.generatePuzzle(difficulty: difficulty);
    final puzzle = result['puzzle']!;
    final solution = result['solution']!;

    // Count clues
    int clueCount = 0;
    for (final row in puzzle) {
      for (final cell in row) {
        if (cell != 0) clueCount++;
      }
    }

    // Verify solution is valid
    if (!isValidSolution(solution)) {
      return TestResult(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Invalid solution generated',
      );
    }

    // Verify puzzle matches solution for given clues
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0 && puzzle[r][c] != solution[r][c]) {
          return TestResult(
            passed: false,
            clueCount: clueCount,
            solveTimeMs: stopwatch.elapsedMilliseconds,
            errorMessage: 'Puzzle clue doesn\'t match solution at ($r,$c)',
          );
        }
      }
    }

    // Verify puzzle is solvable (has at least one solution)
    final puzzleCopy = puzzle.map((row) => List<int>.from(row)).toList();
    if (!solvePuzzle(puzzleCopy)) {
      return TestResult(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Puzzle is not solvable',
      );
    }

    // Verify unique solution
    final solutionCount =
        countSolutions(puzzle.map((row) => List<int>.from(row)).toList(), 2);
    if (solutionCount != 1) {
      return TestResult(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Puzzle has $solutionCount solutions (should be 1)',
      );
    }

    // Verify solved puzzle matches original solution
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzleCopy[r][c] != solution[r][c]) {
          return TestResult(
            passed: false,
            clueCount: clueCount,
            solveTimeMs: stopwatch.elapsedMilliseconds,
            errorMessage: 'Solved puzzle doesn\'t match solution',
          );
        }
      }
    }

    stopwatch.stop();

    return TestResult(
      passed: true,
      clueCount: clueCount,
      solveTimeMs: stopwatch.elapsedMilliseconds,
      errorMessage: '',
    );
  } catch (e) {
    return TestResult(
      passed: false,
      clueCount: 0,
      solveTimeMs: 0,
      errorMessage: 'Exception: $e',
    );
  }
}

bool isValidSolution(List<List<int>> grid) {
  // Check all rows
  for (int r = 0; r < 9; r++) {
    final seen = <int>{};
    for (int c = 0; c < 9; c++) {
      final val = grid[r][c];
      if (val < 1 || val > 9 || seen.contains(val)) return false;
      seen.add(val);
    }
  }

  // Check all columns
  for (int c = 0; c < 9; c++) {
    final seen = <int>{};
    for (int r = 0; r < 9; r++) {
      final val = grid[r][c];
      if (seen.contains(val)) return false;
      seen.add(val);
    }
  }

  // Check all 3x3 boxes
  for (int boxRow = 0; boxRow < 3; boxRow++) {
    for (int boxCol = 0; boxCol < 3; boxCol++) {
      final seen = <int>{};
      for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
        for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
          final val = grid[r][c];
          if (seen.contains(val)) return false;
          seen.add(val);
        }
      }
      if (seen.length != 9) return false;
    }
  }

  return true;
}

bool solvePuzzle(List<List<int>> grid) {
  for (int row = 0; row < 9; row++) {
    for (int col = 0; col < 9; col++) {
      if (grid[row][col] == 0) {
        for (int num = 1; num <= 9; num++) {
          if (isValidPlacement(grid, row, col, num)) {
            grid[row][col] = num;
            if (solvePuzzle(grid)) return true;
            grid[row][col] = 0;
          }
        }
        return false;
      }
    }
  }
  return true;
}

int countSolutions(List<List<int>> grid, int limit) {
  int count = 0;
  _countSolutionsHelper(grid, 0, () {
    count++;
    return count < limit;
  });
  return count;
}

bool _countSolutionsHelper(
    List<List<int>> grid, int pos, bool Function() shouldContinue) {
  while (pos < 81) {
    final row = pos ~/ 9;
    final col = pos % 9;
    if (grid[row][col] == 0) break;
    pos++;
  }

  if (pos >= 81) return true; // Found a solution

  final row = pos ~/ 9;
  final col = pos % 9;

  for (int num = 1; num <= 9; num++) {
    if (isValidPlacement(grid, row, col, num)) {
      grid[row][col] = num;
      if (_countSolutionsHelper(grid, pos + 1, shouldContinue)) {
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

bool isValidPlacement(List<List<int>> grid, int row, int col, int num) {
  // Check row
  for (int c = 0; c < 9; c++) {
    if (grid[row][c] == num) return false;
  }

  // Check column
  for (int r = 0; r < 9; r++) {
    if (grid[r][col] == num) return false;
  }

  // Check 3x3 box
  final boxRow = (row ~/ 3) * 3;
  final boxCol = (col ~/ 3) * 3;
  for (int r = boxRow; r < boxRow + 3; r++) {
    for (int c = boxCol; c < boxCol + 3; c++) {
      if (grid[r][c] == num) return false;
    }
  }

  return true;
}

/// Copy of the SudokuGenerator for testing
class TestSudokuGenerator {
  late Random _random;

  TestSudokuGenerator() {
    _random = Random();
  }

  Map<String, List<List<int>>> generatePuzzle({
    required String difficulty,
    int gridSize = 9,
  }) {
    final solution = _generateValidSolution(gridSize);
    final puzzle = _createValidPuzzle(solution, difficulty, gridSize);

    return {
      'puzzle': puzzle,
      'solution': solution,
    };
  }

  List<List<int>> _generateValidSolution(int size) {
    final grid = List.generate(size, (_) => List.filled(size, 0));
    _fillWithShuffledPattern(grid, size);
    return grid;
  }

  void _fillWithShuffledPattern(List<List<int>> grid, int size) {
    final numbers = List.generate(size, (i) => i + 1)..shuffle(_random);
    final rowBands = [0, 1, 2]..shuffle(_random);
    final colBands = [0, 1, 2]..shuffle(_random);

    final rowOrder = <int>[];
    for (final band in rowBands) {
      final bandRows = [0, 1, 2]..shuffle(_random);
      for (final r in bandRows) {
        rowOrder.add(band * 3 + r);
      }
    }

    final colOrder = <int>[];
    for (final band in colBands) {
      final bandCols = [0, 1, 2]..shuffle(_random);
      for (final c in bandCols) {
        colOrder.add(band * 3 + c);
      }
    }

    final basePattern = _getBasePattern(size);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final sourceRow = rowOrder[r];
        final sourceCol = colOrder[c];
        final baseValue = basePattern[sourceRow][sourceCol];
        grid[r][c] = numbers[baseValue - 1];
      }
    }
  }

  List<List<int>> _getBasePattern(int size) {
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

  List<List<int>> _createValidPuzzle(
    List<List<int>> solution,
    String difficulty,
    int size,
  ) {
    final puzzle = solution.map((row) => List<int>.from(row)).toList();
    final targetClues = _getTargetClues(difficulty, size);
    final totalCells = size * size;
    final targetRemove = totalCells - targetClues;

    final positions = <List<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        positions.add([r, c]);
      }
    }
    positions.shuffle(_random);

    int removed = 0;
    int attempts = 0;
    final maxAttempts = totalCells * 2;

    for (final pos in positions) {
      if (removed >= targetRemove || attempts >= maxAttempts) break;
      attempts++;

      final row = pos[0];
      final col = pos[1];

      if (puzzle[row][col] == 0) continue;

      final backup = puzzle[row][col];
      puzzle[row][col] = 0;

      final solutionCount = _countSolutions(puzzle, size, 2);

      if (solutionCount != 1) {
        puzzle[row][col] = backup;
      } else {
        removed++;
      }
    }

    return puzzle;
  }

  int _getTargetClues(String difficulty, int size) {
    final Map<String, int> clueCount = {
      'Beginner': 45,
      'Easy': 38,
      'Medium': 32,
      'Hard': 28,
      'Expert': 24,
      'Extreme': 22,
      'Fast': 40,
    };
    return clueCount[difficulty] ?? 35;
  }

  int _countSolutions(List<List<int>> puzzle, int size, int limit) {
    final copy = puzzle.map((row) => List<int>.from(row)).toList();
    int count = 0;

    _solveCounting(copy, size, 0, () {
      count++;
      return count < limit;
    });

    return count;
  }

  bool _solveCounting(
    List<List<int>> grid,
    int size,
    int startPos,
    bool Function() shouldContinue,
  ) {
    int pos = startPos;
    while (pos < size * size) {
      final row = pos ~/ size;
      final col = pos % size;
      if (grid[row][col] == 0) break;
      pos++;
    }

    if (pos >= size * size) return true;

    final row = pos ~/ size;
    final col = pos % size;

    for (int num = 1; num <= size; num++) {
      if (_isValidPlacement(grid, row, col, num, size)) {
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

  bool _isValidPlacement(
      List<List<int>> grid, int row, int col, int num, int size) {
    for (int c = 0; c < size; c++) {
      if (grid[row][c] == num) return false;
    }

    for (int r = 0; r < size; r++) {
      if (grid[r][col] == num) return false;
    }

    const boxSize = 3;
    final boxRowStart = (row ~/ boxSize) * boxSize;
    final boxColStart = (col ~/ boxSize) * boxSize;

    for (int r = boxRowStart; r < boxRowStart + boxSize; r++) {
      for (int c = boxColStart; c < boxColStart + boxSize; c++) {
        if (grid[r][c] == num) return false;
      }
    }

    return true;
  }
}

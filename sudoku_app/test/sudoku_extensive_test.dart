import 'dart:math';

/// EXTENSIVE Sudoku Generator Test
/// Tests 50 puzzles per difficulty (300 total)
/// Also tests Daily Challenge generation

void main() {
  print('=' * 70);
  print('EXTENSIVE SUDOKU GENERATOR TEST (50 puzzles per difficulty)');
  print('=' * 70);
  print('');

  final generator = TestSudokuGenerator();
  final dailyChallengeGenerator = DailyChallengeGenerator(generator);

  // Test configurations
  final difficulties = ['Beginner', 'Easy', 'Medium', 'Hard', 'Expert'];
  const puzzlesPerDifficulty = 50;

  final allResults = <String, DifficultyStats>{};
  int totalPuzzles = 0;
  int totalPassed = 0;
  int totalFailed = 0;

  // Test each difficulty
  for (final difficulty in difficulties) {
    print('Testing $difficulty difficulty (50 puzzles)...');

    final stats = DifficultyStats();

    for (int i = 0; i < puzzlesPerDifficulty; i++) {
      totalPuzzles++;
      final result = testPuzzle(generator, difficulty);

      if (result.passed) {
        totalPassed++;
        stats.passed++;
        stats.clueCounts.add(result.clueCount);
        stats.solveTimes.add(result.solveTimeMs);
      } else {
        totalFailed++;
        stats.failed++;
        stats.errors.add('Puzzle ${i + 1}: ${result.errorMessage}');
        print('  ✗ Puzzle ${i + 1} FAILED: ${result.errorMessage}');
      }
    }

    allResults[difficulty] = stats;

    final avgClues = stats.clueCounts.isEmpty
        ? 0
        : (stats.clueCounts.reduce((a, b) => a + b) / stats.clueCounts.length)
            .round();
    final minClues =
        stats.clueCounts.isEmpty ? 0 : stats.clueCounts.reduce(min);
    final maxClues =
        stats.clueCounts.isEmpty ? 0 : stats.clueCounts.reduce(max);
    final avgTime = stats.solveTimes.isEmpty
        ? 0
        : (stats.solveTimes.reduce((a, b) => a + b) / stats.solveTimes.length)
            .round();

    print(
        '  ✓ ${stats.passed}/50 passed | Clues: min=$minClues avg=$avgClues max=$maxClues | Avg time: ${avgTime}ms');
    print('');
  }

  // Test Daily Challenge (30 days)
  print('=' * 70);
  print('TESTING DAILY CHALLENGE (30 days)');
  print('=' * 70);

  int dailyPassed = 0;
  int dailyFailed = 0;
  final dailyClues = <int>[];
  final dailyDifficulties = <String>[];

  for (int day = 0; day < 30; day++) {
    totalPuzzles++;
    final date = DateTime(2026, 1, 1).add(Duration(days: day));
    final result = testDailyChallenge(dailyChallengeGenerator, date);

    if (result.passed) {
      totalPassed++;
      dailyPassed++;
      dailyClues.add(result.clueCount);
      dailyDifficulties.add(result.difficulty);
    } else {
      totalFailed++;
      dailyFailed++;
      print('  ✗ Day ${day + 1} FAILED: ${result.errorMessage}');
    }
  }

  print('  Daily Challenge: $dailyPassed/30 passed ($dailyFailed failed)');
  if (dailyClues.isNotEmpty) {
    print(
        '  Clue range: ${dailyClues.reduce(min)} - ${dailyClues.reduce(max)}');
    print(
        '  Difficulty distribution: ${_countDistribution(dailyDifficulties)}');
  }
  print('');

  // Final Summary
  print('=' * 70);
  print('FINAL SUMMARY');
  print('=' * 70);
  print('');
  print('Total puzzles tested: $totalPuzzles');
  print('  - Regular puzzles: ${difficulties.length * puzzlesPerDifficulty}');
  print('  - Daily challenges: 30');
  print('');
  print('Results:');
  print('  Passed: $totalPassed');
  print('  Failed: $totalFailed');
  print(
      '  Success rate: ${(totalPassed / totalPuzzles * 100).toStringAsFixed(2)}%');
  print('');

  print('Difficulty Statistics:');
  print('-' * 70);
  print(
      '${'Difficulty'.padRight(12)} ${'Pass'.padRight(8)} ${'Min'.padRight(6)} ${'Avg'.padRight(6)} ${'Max'.padRight(6)} ${'AvgTime'}');
  print('-' * 70);

  for (final entry in allResults.entries) {
    final stats = entry.value;
    final avgClues = stats.clueCounts.isEmpty
        ? 0
        : (stats.clueCounts.reduce((a, b) => a + b) / stats.clueCounts.length)
            .round();
    final minClues =
        stats.clueCounts.isEmpty ? 0 : stats.clueCounts.reduce(min);
    final maxClues =
        stats.clueCounts.isEmpty ? 0 : stats.clueCounts.reduce(max);
    final avgTime = stats.solveTimes.isEmpty
        ? 0
        : (stats.solveTimes.reduce((a, b) => a + b) / stats.solveTimes.length)
            .round();

    print(
        '${entry.key.padRight(12)} ${stats.passed.toString().padRight(8)} ${minClues.toString().padRight(6)} ${avgClues.toString().padRight(6)} ${maxClues.toString().padRight(6)} ${avgTime}ms');
  }
  print('-' * 70);

  // Verify clue ranges don't overlap incorrectly
  print('');
  print('Clue Range Verification:');
  final clueRanges = <String, List<int>>{};
  for (final entry in allResults.entries) {
    clueRanges[entry.key] = entry.value.clueCounts;
  }

  bool rangesValid = true;
  final difficultyOrder = ['Beginner', 'Easy', 'Medium', 'Hard', 'Expert'];
  for (int i = 0; i < difficultyOrder.length - 1; i++) {
    final easier = difficultyOrder[i];
    final harder = difficultyOrder[i + 1];
    final easierMin = clueRanges[easier]?.reduce(min) ?? 0;
    final harderMax = clueRanges[harder]?.reduce(max) ?? 0;

    if (harderMax >= easierMin) {
      // Some overlap is OK as long as averages are different
      final easierAvg = clueRanges[easier]!.reduce((a, b) => a + b) /
          clueRanges[easier]!.length;
      final harderAvg = clueRanges[harder]!.reduce((a, b) => a + b) /
          clueRanges[harder]!.length;

      if (harderAvg >= easierAvg) {
        print(
            '  ✗ $easier avg (${easierAvg.toStringAsFixed(1)}) should be > $harder avg (${harderAvg.toStringAsFixed(1)})');
        rangesValid = false;
      } else {
        print(
            '  ✓ $easier (avg ${easierAvg.toStringAsFixed(1)}) > $harder (avg ${harderAvg.toStringAsFixed(1)})');
      }
    } else {
      print('  ✓ $easier (min $easierMin) > $harder (max $harderMax)');
    }
  }

  print('');
  print('=' * 70);
  if (totalFailed == 0 && rangesValid) {
    print('🎉 ALL $totalPuzzles TESTS PASSED! 🎉');
  } else {
    print('⚠️  SOME TESTS FAILED: $totalFailed failures');
  }
  print('=' * 70);
}

String _countDistribution(List<String> items) {
  final counts = <String, int>{};
  for (final item in items) {
    counts[item] = (counts[item] ?? 0) + 1;
  }
  return counts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
}

class DifficultyStats {
  int passed = 0;
  int failed = 0;
  List<int> clueCounts = [];
  List<int> solveTimes = [];
  List<String> errors = [];
}

class TestResultExtended {
  final bool passed;
  final int clueCount;
  final int solveTimeMs;
  final String errorMessage;
  final String difficulty;

  TestResultExtended({
    required this.passed,
    required this.clueCount,
    required this.solveTimeMs,
    required this.errorMessage,
    this.difficulty = '',
  });
}

TestResultExtended testPuzzle(
    TestSudokuGenerator generator, String difficulty) {
  try {
    final stopwatch = Stopwatch()..start();

    final result = generator.generatePuzzle(difficulty: difficulty);
    final puzzle = result['puzzle']!;
    final solution = result['solution']!;

    int clueCount = 0;
    for (final row in puzzle) {
      for (final cell in row) {
        if (cell != 0) clueCount++;
      }
    }

    // Validate solution
    if (!isValidSolution(solution)) {
      return TestResultExtended(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Invalid solution',
      );
    }

    // Validate puzzle clues match solution
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0 && puzzle[r][c] != solution[r][c]) {
          return TestResultExtended(
            passed: false,
            clueCount: clueCount,
            solveTimeMs: stopwatch.elapsedMilliseconds,
            errorMessage: 'Clue mismatch at ($r,$c)',
          );
        }
      }
    }

    // Verify solvable
    final puzzleCopy = puzzle.map((row) => List<int>.from(row)).toList();
    if (!solvePuzzle(puzzleCopy)) {
      return TestResultExtended(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Not solvable',
      );
    }

    // Verify unique solution
    final solutionCount =
        countSolutions(puzzle.map((row) => List<int>.from(row)).toList(), 2);
    if (solutionCount != 1) {
      return TestResultExtended(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: '$solutionCount solutions (expected 1)',
      );
    }

    stopwatch.stop();

    return TestResultExtended(
      passed: true,
      clueCount: clueCount,
      solveTimeMs: stopwatch.elapsedMilliseconds,
      errorMessage: '',
    );
  } catch (e) {
    return TestResultExtended(
      passed: false,
      clueCount: 0,
      solveTimeMs: 0,
      errorMessage: 'Exception: $e',
    );
  }
}

TestResultExtended testDailyChallenge(
    DailyChallengeGenerator generator, DateTime date) {
  try {
    final stopwatch = Stopwatch()..start();

    final result = generator.generateDailyChallenge(date);
    final puzzle = result['puzzle']!;
    final solution = result['solution']!;
    final difficulty = result['difficulty'] as String? ?? 'Unknown';

    int clueCount = 0;
    for (final row in puzzle) {
      for (final cell in row) {
        if (cell != 0) clueCount++;
      }
    }

    if (!isValidSolution(solution as List<List<int>>)) {
      return TestResultExtended(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Invalid solution',
        difficulty: difficulty,
      );
    }

    final puzzleCopy =
        (puzzle as List<List<int>>).map((row) => List<int>.from(row)).toList();
    if (!solvePuzzle(puzzleCopy)) {
      return TestResultExtended(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Not solvable',
        difficulty: difficulty,
      );
    }

    final solutionCount =
        countSolutions(puzzle.map((row) => List<int>.from(row)).toList(), 2);
    if (solutionCount != 1) {
      return TestResultExtended(
        passed: false,
        clueCount: clueCount,
        solveTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: '$solutionCount solutions',
        difficulty: difficulty,
      );
    }

    stopwatch.stop();

    return TestResultExtended(
      passed: true,
      clueCount: clueCount,
      solveTimeMs: stopwatch.elapsedMilliseconds,
      errorMessage: '',
      difficulty: difficulty,
    );
  } catch (e) {
    return TestResultExtended(
      passed: false,
      clueCount: 0,
      solveTimeMs: 0,
      errorMessage: 'Exception: $e',
    );
  }
}

bool isValidSolution(List<List<int>> grid) {
  for (int r = 0; r < 9; r++) {
    final seen = <int>{};
    for (int c = 0; c < 9; c++) {
      final val = grid[r][c];
      if (val < 1 || val > 9 || seen.contains(val)) return false;
      seen.add(val);
    }
  }

  for (int c = 0; c < 9; c++) {
    final seen = <int>{};
    for (int r = 0; r < 9; r++) {
      final val = grid[r][c];
      if (seen.contains(val)) return false;
      seen.add(val);
    }
  }

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

  if (pos >= 81) return true;

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
  for (int c = 0; c < 9; c++) {
    if (grid[row][c] == num) return false;
  }

  for (int r = 0; r < 9; r++) {
    if (grid[r][col] == num) return false;
  }

  final boxRow = (row ~/ 3) * 3;
  final boxCol = (col ~/ 3) * 3;
  for (int r = boxRow; r < boxRow + 3; r++) {
    for (int c = boxCol; c < boxCol + 3; c++) {
      if (grid[r][c] == num) return false;
    }
  }

  return true;
}

/// Daily Challenge Generator
class DailyChallengeGenerator {
  final TestSudokuGenerator _generator;

  DailyChallengeGenerator(this._generator);

  Map<String, dynamic> generateDailyChallenge(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    // final random = Random(seed);

    // Rotate difficulties based on day
    final difficulties = ['Easy', 'Medium', 'Hard', 'Expert', 'Medium'];
    final difficultyIndex = date.weekday % difficulties.length;
    final difficulty = difficulties[difficultyIndex];

    // Generate with seeded random
    final result =
        _generator.generatePuzzleWithSeed(difficulty: difficulty, seed: seed);

    return {
      'puzzle': result['puzzle'],
      'solution': result['solution'],
      'difficulty': difficulty,
      'date': date,
    };
  }
}

/// Sudoku Generator
class TestSudokuGenerator {
  late Random _random;

  TestSudokuGenerator() {
    _random = Random();
  }

  Map<String, List<List<int>>> generatePuzzle({required String difficulty}) {
    final solution = _generateValidSolution(9);
    final puzzle = _createValidPuzzle(solution, difficulty, 9);
    return {'puzzle': puzzle, 'solution': solution};
  }

  Map<String, List<List<int>>> generatePuzzleWithSeed(
      {required String difficulty, required int seed}) {
    _random = Random(seed);
    final solution = _generateValidSolution(9);
    final puzzle = _createValidPuzzle(solution, difficulty, 9);
    return {'puzzle': puzzle, 'solution': solution};
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
      List<List<int>> solution, String difficulty, int size) {
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

    for (final pos in positions) {
      if (removed >= targetRemove) break;

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

  bool _solveCounting(List<List<int>> grid, int size, int startPos,
      bool Function() shouldContinue) {
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

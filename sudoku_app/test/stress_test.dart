import 'dart:math';
import 'package:sudoku_app/core/services/sudoku_generator.dart';

/// STRESS TEST - 100 puzzles per difficulty (500 total) + 60 daily challenges
/// This is the final comprehensive test to ensure bulletproof puzzle generation

void main() {
  print('═' * 70);
  print('  SUDOKU GENERATOR STRESS TEST');
  print('  100 puzzles × 5 difficulties = 500 puzzles + 60 daily challenges');
  print('═' * 70);
  print('');

  final generator = SudokuGenerator();
  final stopwatch = Stopwatch()..start();

  int totalPuzzles = 0;
  int totalPassed = 0;
  int totalFailed = 0;

  final difficulties = ['Beginner', 'Easy', 'Medium', 'Hard', 'Expert'];
  const puzzlesPerDifficulty = 100;

  final stats = <String, DifficultyStats>{};

  for (final difficulty in difficulties) {
    final diffStats = DifficultyStats();
    print('[$difficulty] Testing 100 puzzles...');

    for (int i = 0; i < puzzlesPerDifficulty; i++) {
      totalPuzzles++;

      try {
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

        // Test 1: Valid solution
        if (!_isValidSolution(solution)) {
          diffStats.addFailure('Puzzle ${i + 1}: Invalid solution');
          totalFailed++;
          continue;
        }

        // Test 2: Clues match solution
        bool cluesMatch = true;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (puzzle[r][c] != 0 && puzzle[r][c] != solution[r][c]) {
              cluesMatch = false;
              break;
            }
          }
          if (!cluesMatch) break;
        }

        if (!cluesMatch) {
          diffStats.addFailure('Puzzle ${i + 1}: Clue mismatch');
          totalFailed++;
          continue;
        }

        // Test 3: Solvable
        final copy = puzzle.map((row) => List<int>.from(row)).toList();
        if (!_solvePuzzle(copy)) {
          diffStats.addFailure('Puzzle ${i + 1}: Unsolvable');
          totalFailed++;
          continue;
        }

        // Test 4: Unique solution
        final solCount =
            _countSolutions(puzzle.map((r) => List<int>.from(r)).toList(), 2);
        if (solCount != 1) {
          diffStats.addFailure('Puzzle ${i + 1}: $solCount solutions');
          totalFailed++;
          continue;
        }

        // All tests passed
        diffStats.addSuccess(clueCount);
        totalPassed++;
      } catch (e) {
        diffStats.addFailure('Puzzle ${i + 1}: Exception');
        totalFailed++;
      }
    }

    stats[difficulty] = diffStats;

    // Progress display
    print(
        '  └─ ${diffStats.passed}/100 passed | ${diffStats.failed} failed | Clues: ${diffStats.minClues}-${diffStats.maxClues}');
    if (diffStats.failures.isNotEmpty) {
      for (final f in diffStats.failures.take(5)) {
        print('     ✗ $f');
      }
      if (diffStats.failures.length > 5) {
        print('     ... and ${diffStats.failures.length - 5} more');
      }
    }
    print('');
  }

  // Test Daily Challenges
  print('[Daily Challenge] Testing 60 days...');
  int dailyPassed = 0;
  int dailyFailed = 0;

  for (int day = 0; day < 60; day++) {
    totalPuzzles++;
    final date = DateTime(2026, 1, 1).add(Duration(days: day));

    try {
      final result = generator.generateDailyChallenge(date);
      final puzzle = result['puzzle']!;
      final solution = result['solution']!;

      if (!_isValidSolution(solution)) {
        dailyFailed++;
        totalFailed++;
        continue;
      }

      final copy = puzzle.map((row) => List<int>.from(row)).toList();
      if (!_solvePuzzle(copy)) {
        dailyFailed++;
        totalFailed++;
        continue;
      }

      final solCount =
          _countSolutions(puzzle.map((r) => List<int>.from(r)).toList(), 2);
      if (solCount != 1) {
        dailyFailed++;
        totalFailed++;
        continue;
      }

      dailyPassed++;
      totalPassed++;
    } catch (e) {
      dailyFailed++;
      totalFailed++;
    }
  }

  print('  └─ $dailyPassed/60 passed | $dailyFailed failed');
  print('');

  stopwatch.stop();

  // Final Summary
  print('═' * 70);
  print('  FINAL RESULTS');
  print('═' * 70);
  print('');
  print('  Total puzzles tested:    $totalPuzzles');
  print(
      '  ├─ Regular puzzles:      ${difficulties.length * puzzlesPerDifficulty}');
  print('  └─ Daily challenges:     60');
  print('');
  print('  Results:');
  print('  ├─ PASSED:               $totalPassed');
  print('  └─ FAILED:               $totalFailed');
  print('');
  print(
      '  Success rate:            ${(totalPassed / totalPuzzles * 100).toStringAsFixed(2)}%');
  print('  Total time:              ${stopwatch.elapsed.inSeconds}s');
  print('');

  // Difficulty breakdown
  print('  Difficulty Breakdown:');
  print('  ┌────────────┬────────┬─────────┬─────────┬─────────┐');
  print('  │ Difficulty │ Passed │ Min Clue│ Avg Clue│ Max Clue│');
  print('  ├────────────┼────────┼─────────┼─────────┼─────────┤');
  for (final entry in stats.entries) {
    final s = entry.value;
    print(
        '  │ ${entry.key.padRight(10)} │ ${s.passed.toString().padLeft(6)} │ ${s.minClues.toString().padLeft(7)} │ ${s.avgClues.toStringAsFixed(1).padLeft(7)} │ ${s.maxClues.toString().padLeft(7)} │');
  }
  print('  └────────────┴────────┴─────────┴─────────┴─────────┘');
  print('');

  // Verify difficulty ordering
  print('  Difficulty Ordering Verification:');
  bool orderCorrect = true;
  for (int i = 0; i < difficulties.length - 1; i++) {
    final easier = difficulties[i];
    final harder = difficulties[i + 1];
    final easierAvg = stats[easier]!.avgClues;
    final harderAvg = stats[harder]!.avgClues;

    if (easierAvg <= harderAvg) {
      print(
          '  ✗ $easier (${easierAvg.toStringAsFixed(1)}) should have MORE clues than $harder (${harderAvg.toStringAsFixed(1)})');
      orderCorrect = false;
    }
  }
  if (orderCorrect) {
    print('  ✓ All difficulties properly ordered (more clues = easier)');
  }
  print('');

  print('═' * 70);
  if (totalFailed == 0 && orderCorrect) {
    print(
        '  🎉🎉🎉 ALL $totalPuzzles TESTS PASSED! GENERATOR IS BULLETPROOF! 🎉🎉🎉');
  } else {
    print('  ⚠️  SOME TESTS FAILED! Review errors above.');
  }
  print('═' * 70);
}

class DifficultyStats {
  int passed = 0;
  int failed = 0;
  List<int> clues = [];
  List<String> failures = [];

  void addSuccess(int clueCount) {
    passed++;
    clues.add(clueCount);
  }

  void addFailure(String reason) {
    failed++;
    failures.add(reason);
  }

  int get minClues => clues.isEmpty ? 0 : clues.reduce(min);
  int get maxClues => clues.isEmpty ? 0 : clues.reduce(max);
  double get avgClues =>
      clues.isEmpty ? 0 : clues.reduce((a, b) => a + b) / clues.length;
}

bool _isValidSolution(List<List<int>> grid) {
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
      if (seen.contains(grid[r][c])) return false;
      seen.add(grid[r][c]);
    }
  }

  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      final seen = <int>{};
      for (int r = br * 3; r < br * 3 + 3; r++) {
        for (int c = bc * 3; c < bc * 3 + 3; c++) {
          if (seen.contains(grid[r][c])) return false;
          seen.add(grid[r][c]);
        }
      }
    }
  }
  return true;
}

bool _solvePuzzle(List<List<int>> grid) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (grid[r][c] == 0) {
        for (int n = 1; n <= 9; n++) {
          if (_canPlace(grid, r, c, n)) {
            grid[r][c] = n;
            if (_solvePuzzle(grid)) return true;
            grid[r][c] = 0;
          }
        }
        return false;
      }
    }
  }
  return true;
}

int _countSolutions(List<List<int>> grid, int limit) {
  int count = 0;
  _countHelper(grid, 0, () {
    count++;
    return count < limit;
  });
  return count;
}

bool _countHelper(List<List<int>> grid, int pos, bool Function() cont) {
  while (pos < 81) {
    if (grid[pos ~/ 9][pos % 9] == 0) break;
    pos++;
  }
  if (pos >= 81) return true;

  final r = pos ~/ 9, c = pos % 9;
  for (int n = 1; n <= 9; n++) {
    if (_canPlace(grid, r, c, n)) {
      grid[r][c] = n;
      if (_countHelper(grid, pos + 1, cont)) {
        if (!cont()) {
          grid[r][c] = 0;
          return true;
        }
      }
      grid[r][c] = 0;
    }
  }
  return false;
}

bool _canPlace(List<List<int>> grid, int r, int c, int n) {
  for (int i = 0; i < 9; i++) {
    if (grid[r][i] == n || grid[i][c] == n) return false;
  }
  final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
  for (int i = br; i < br + 3; i++) {
    for (int j = bc; j < bc + 3; j++) {
      if (grid[i][j] == n) return false;
    }
  }
  return true;
}

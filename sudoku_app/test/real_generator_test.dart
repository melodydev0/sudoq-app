import 'dart:math';

// Import the actual project generator
import 'package:sudoku_app/core/services/sudoku_generator.dart';

/// Test the actual project Sudoku Generator
/// This ensures the production code matches our test expectations

void main() {
  print('=' * 70);
  print('TESTING ACTUAL PROJECT SUDOKU GENERATOR');
  print('=' * 70);
  print('');

  final generator = SudokuGenerator();

  int totalTests = 0;
  int passed = 0;
  int failed = 0;

  // Test each difficulty with 20 puzzles each
  final difficulties = ['Beginner', 'Easy', 'Medium', 'Hard', 'Expert'];

  for (final difficulty in difficulties) {
    print('Testing $difficulty...');

    int diffPassed = 0;
    int diffFailed = 0;
    List<int> clues = [];

    for (int i = 0; i < 20; i++) {
      totalTests++;

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
        clues.add(clueCount);

        // Validate solution
        if (!_isValidSolution(solution)) {
          diffFailed++;
          failed++;
          print('  ✗ Puzzle ${i + 1}: Invalid solution');
          continue;
        }

        // Validate puzzle matches solution
        bool matchesSolution = true;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (puzzle[r][c] != 0 && puzzle[r][c] != solution[r][c]) {
              matchesSolution = false;
              break;
            }
          }
          if (!matchesSolution) break;
        }

        if (!matchesSolution) {
          diffFailed++;
          failed++;
          print('  ✗ Puzzle ${i + 1}: Clues don\'t match solution');
          continue;
        }

        // Verify solvability
        final puzzleCopy = puzzle.map((row) => List<int>.from(row)).toList();
        if (!generator.solvePuzzle(puzzleCopy, 9)) {
          diffFailed++;
          failed++;
          print('  ✗ Puzzle ${i + 1}: Not solvable');
          continue;
        }

        // Verify unique solution
        final solutionCount = _countSolutions(
            puzzle.map((row) => List<int>.from(row)).toList(), 2);
        if (solutionCount != 1) {
          diffFailed++;
          failed++;
          print('  ✗ Puzzle ${i + 1}: Has $solutionCount solutions');
          continue;
        }

        diffPassed++;
        passed++;
      } catch (e) {
        diffFailed++;
        failed++;
        print('  ✗ Puzzle ${i + 1}: Exception - $e');
      }
    }

    final avgClues = clues.isEmpty
        ? 0
        : (clues.reduce((a, b) => a + b) / clues.length).round();
    final minClues = clues.isEmpty ? 0 : clues.reduce(min);
    final maxClues = clues.isEmpty ? 0 : clues.reduce(max);

    print(
        '  ✓ $diffPassed/20 passed ($diffFailed failed) | Clues: $minClues-$maxClues (avg: $avgClues)');
    print('');
  }

  // Test Daily Challenge
  print('Testing Daily Challenge (14 days)...');
  int dailyPassed = 0;
  int dailyFailed = 0;

  for (int day = 0; day < 14; day++) {
    totalTests++;
    final date = DateTime(2026, 1, 1).add(Duration(days: day));

    try {
      final result = generator.generateDailyChallenge(date);
      final puzzle = result['puzzle']!;
      final solution = result['solution']!;

      if (!_isValidSolution(solution)) {
        dailyFailed++;
        failed++;
        print('  ✗ Day ${day + 1}: Invalid solution');
        continue;
      }

      final puzzleCopy = puzzle.map((row) => List<int>.from(row)).toList();
      if (!generator.solvePuzzle(puzzleCopy, 9)) {
        dailyFailed++;
        failed++;
        print('  ✗ Day ${day + 1}: Not solvable');
        continue;
      }

      final solutionCount =
          _countSolutions(puzzle.map((row) => List<int>.from(row)).toList(), 2);
      if (solutionCount != 1) {
        dailyFailed++;
        failed++;
        print('  ✗ Day ${day + 1}: Has $solutionCount solutions');
        continue;
      }

      // Verify same date produces same puzzle
      final result2 = generator.generateDailyChallenge(date);
      final puzzle2 = result2['puzzle']!;
      bool matches = true;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (puzzle[r][c] != puzzle2[r][c]) {
            matches = false;
            break;
          }
        }
        if (!matches) break;
      }

      if (!matches) {
        dailyFailed++;
        failed++;
        print('  ✗ Day ${day + 1}: Not reproducible');
        continue;
      }

      dailyPassed++;
      passed++;
    } catch (e) {
      dailyFailed++;
      failed++;
      print('  ✗ Day ${day + 1}: Exception - $e');
    }
  }

  print('  ✓ $dailyPassed/14 passed ($dailyFailed failed)');
  print('');

  // Test hint feature
  print('Testing Hint Feature...');
  totalTests++;

  try {
    final result = generator.generatePuzzle(difficulty: 'Easy');
    final puzzle = result['puzzle']!;
    final solution = result['solution']!;

    final hint = generator.getHintForEmptyCell(puzzle, solution, 9);
    if (hint == null) {
      failed++;
      print('  ✗ Hint returned null');
    } else {
      final row = hint['row']!;
      final col = hint['col']!;
      final value = hint['value']!;

      if (puzzle[row][col] != 0) {
        failed++;
        print('  ✗ Hint cell not empty');
      } else if (solution[row][col] != value) {
        failed++;
        print('  ✗ Hint value incorrect');
      } else {
        passed++;
        print('  ✓ Hint feature works correctly');
      }
    }
  } catch (e) {
    failed++;
    print('  ✗ Hint exception: $e');
  }
  print('');

  // Test Fast Pencil (candidates)
  print('Testing Fast Pencil (Candidates)...');
  totalTests++;

  try {
    final result = generator.generatePuzzle(difficulty: 'Medium');
    final puzzle = result['puzzle']!;

    final allCandidates = generator.fillAllCandidates(puzzle, 9);

    bool candidatesValid = true;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle[r][c] == 0) {
          // Cell is empty, should have candidates
          final candidates = allCandidates[r][c];
          if (candidates.isEmpty) {
            candidatesValid = false;
            print('  ✗ Empty cell ($r,$c) has no candidates');
            break;
          }

          // Verify each candidate is actually valid
          for (final num in candidates) {
            if (!_isValidPlacement(puzzle, r, c, num)) {
              candidatesValid = false;
              print('  ✗ Invalid candidate $num at ($r,$c)');
              break;
            }
          }
        } else {
          // Cell is filled, should have no candidates
          if (allCandidates[r][c].isNotEmpty) {
            candidatesValid = false;
            print('  ✗ Filled cell ($r,$c) has candidates');
            break;
          }
        }
      }
      if (!candidatesValid) break;
    }

    if (candidatesValid) {
      passed++;
      print('  ✓ Fast Pencil feature works correctly');
    } else {
      failed++;
    }
  } catch (e) {
    failed++;
    print('  ✗ Fast Pencil exception: $e');
  }
  print('');

  // Final Summary
  print('=' * 70);
  print('FINAL RESULTS');
  print('=' * 70);
  print('');
  print('Total tests: $totalTests');
  print('Passed: $passed');
  print('Failed: $failed');
  print('Success rate: ${(passed / totalTests * 100).toStringAsFixed(2)}%');
  print('');

  if (failed == 0) {
    print('🎉 ALL TESTS PASSED - SUDOKU GENERATOR IS WORKING CORRECTLY! 🎉');
  } else {
    print('⚠️  SOME TESTS FAILED - PLEASE REVIEW');
  }
  print('=' * 70);
}

bool _isValidSolution(List<List<int>> grid) {
  // Check rows
  for (int r = 0; r < 9; r++) {
    final seen = <int>{};
    for (int c = 0; c < 9; c++) {
      final val = grid[r][c];
      if (val < 1 || val > 9 || seen.contains(val)) return false;
      seen.add(val);
    }
  }

  // Check columns
  for (int c = 0; c < 9; c++) {
    final seen = <int>{};
    for (int r = 0; r < 9; r++) {
      final val = grid[r][c];
      if (seen.contains(val)) return false;
      seen.add(val);
    }
  }

  // Check boxes
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

int _countSolutions(List<List<int>> grid, int limit) {
  int count = 0;
  _countHelper(grid, 0, () {
    count++;
    return count < limit;
  });
  return count;
}

bool _countHelper(
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
    if (_isValidPlacement(grid, row, col, num)) {
      grid[row][col] = num;
      if (_countHelper(grid, pos + 1, shouldContinue)) {
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

bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
  // Check row
  for (int c = 0; c < 9; c++) {
    if (grid[row][c] == num) return false;
  }

  // Check column
  for (int r = 0; r < 9; r++) {
    if (grid[r][col] == num) return false;
  }

  // Check box
  final boxRow = (row ~/ 3) * 3;
  final boxCol = (col ~/ 3) * 3;
  for (int r = boxRow; r < boxRow + 3; r++) {
    for (int c = boxCol; c < boxCol + 3; c++) {
      if (grid[r][c] == num) return false;
    }
  }

  return true;
}

import 'dart:convert';

/// Represents the current state of a Sudoku game
class GameState {
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final List<List<int>> currentGrid;
  final List<List<Set<int>>> notes;
  final String difficulty;
  final int gridSize;
  final int mistakes;
  final int hintsUsed;
  final int score;
  final Duration elapsedTime;
  final bool isCompleted;
  final bool isPaused;
  final DateTime startTime;
  final List<GameMove> moveHistory;

  // Combo & Performance tracking
  final int comboStreak; // Current consecutive correct moves
  final int maxCombo; // Best combo this game
  final int fastSolves; // Number of quick solves (under 3 seconds)
  final DateTime? lastMoveTime; // Time of last move for speed bonus

  /// Cells where the user entered the correct value; cannot be changed (prevents accidental overwrite).
  final Set<int> confirmedCorrectCells;

  GameState({
    required this.puzzle,
    required this.solution,
    required this.currentGrid,
    required this.notes,
    required this.difficulty,
    this.gridSize = 9,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.score = 0,
    this.elapsedTime = Duration.zero,
    this.isCompleted = false,
    this.isPaused = false,
    DateTime? startTime,
    List<GameMove>? moveHistory,
    this.comboStreak = 0,
    this.maxCombo = 0,
    this.fastSolves = 0,
    this.lastMoveTime,
    Set<int>? confirmedCorrectCells,
  })  : startTime = startTime ?? DateTime.now(),
        moveHistory = moveHistory ?? [],
        confirmedCorrectCells = confirmedCorrectCells ?? <int>{};

  /// Index for (row, col): row * gridSize + col
  int _cellIndex(int row, int col) => row * gridSize + col;

  /// True if this cell was filled by the user with the correct value and is locked.
  bool isConfirmedCorrectCell(int row, int col) =>
      confirmedCorrectCells.contains(_cellIndex(row, col));

  /// True if every cell matches the solution (puzzle is fully solved).
  bool get isGridSolved {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (currentGrid[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  /// Get current score multiplier based on combo
  double get scoreMultiplier {
    if (comboStreak >= 10) return 3.0; // 🔥🔥🔥 UNSTOPPABLE!
    if (comboStreak >= 7) return 2.5; // 🔥🔥 ON FIRE!
    if (comboStreak >= 5) return 2.0; // 🔥 HOT!
    if (comboStreak >= 3) return 1.5; // ⚡ GOOD!
    return 1.0;
  }

  /// Get combo status text
  String get comboStatus {
    if (comboStreak >= 10) return 'UNSTOPPABLE!';
    if (comboStreak >= 7) return 'ON FIRE!';
    if (comboStreak >= 5) return 'HOT!';
    if (comboStreak >= 3) return 'GOOD!';
    return '';
  }

  GameState copyWith({
    List<List<int>>? puzzle,
    List<List<int>>? solution,
    List<List<int>>? currentGrid,
    List<List<Set<int>>>? notes,
    String? difficulty,
    int? gridSize,
    int? mistakes,
    int? hintsUsed,
    int? score,
    Duration? elapsedTime,
    bool? isCompleted,
    bool? isPaused,
    DateTime? startTime,
    List<GameMove>? moveHistory,
    int? comboStreak,
    int? maxCombo,
    int? fastSolves,
    DateTime? lastMoveTime,
    Set<int>? confirmedCorrectCells,
  }) {
    return GameState(
      puzzle: puzzle ?? this.puzzle,
      solution: solution ?? this.solution,
      currentGrid: currentGrid ?? this.currentGrid,
      notes: notes ?? this.notes,
      difficulty: difficulty ?? this.difficulty,
      gridSize: gridSize ?? this.gridSize,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      score: score ?? this.score,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
      moveHistory: moveHistory ?? this.moveHistory,
      comboStreak: comboStreak ?? this.comboStreak,
      maxCombo: maxCombo ?? this.maxCombo,
      fastSolves: fastSolves ?? this.fastSolves,
      lastMoveTime: lastMoveTime ?? this.lastMoveTime,
      confirmedCorrectCells:
          confirmedCorrectCells ?? this.confirmedCorrectCells,
    );
  }

  /// Check if a cell is fixed (part of original puzzle)
  bool isFixedCell(int row, int col) {
    return puzzle[row][col] != 0;
  }

  /// Number of empty cells (currentGrid[r][c] == 0)
  int get emptyCellCount {
    int count = 0;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (currentGrid[r][c] == 0) count++;
      }
    }
    return count;
  }

  /// Get remaining count for a number
  int getRemainingCount(int number) {
    int count = gridSize;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (currentGrid[i][j] == number) {
          count--;
        }
      }
    }
    return count;
  }

  /// Check if game is complete and correct
  bool checkCompletion() {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (currentGrid[i][j] != solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'puzzle': puzzle.map((row) => row.toList()).toList(),
      'solution': solution.map((row) => row.toList()).toList(),
      'currentGrid': currentGrid.map((row) => row.toList()).toList(),
      'notes': notes
          .map((row) => row.map((cell) => cell.toList()).toList())
          .toList(),
      'difficulty': difficulty,
      'gridSize': gridSize,
      'mistakes': mistakes,
      'hintsUsed': hintsUsed,
      'score': score,
      'elapsedTime': elapsedTime.inSeconds,
      'isCompleted': isCompleted,
      'isPaused': isPaused,
      'startTime': startTime.toIso8601String(),
      'moveHistory': moveHistory.map((m) => m.toJson()).toList(),
      'comboStreak': comboStreak,
      'maxCombo': maxCombo,
      'fastSolves': fastSolves,
      'lastMoveTime': lastMoveTime?.toIso8601String(),
      'confirmedCorrectCells': confirmedCorrectCells.toList(),
    };
  }

  /// Deserialize from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    final gridSize = (json['gridSize'] as num).toInt();
    return GameState(
      puzzle: (json['puzzle'] as List)
          .map((row) => (row as List).map((e) => (e as num).toInt()).toList())
          .toList(),
      solution: (json['solution'] as List)
          .map((row) => (row as List).map((e) => (e as num).toInt()).toList())
          .toList(),
      currentGrid: (json['currentGrid'] as List)
          .map((row) => (row as List).map((e) => (e as num).toInt()).toList())
          .toList(),
      notes: (json['notes'] as List)
          .map((row) => (row as List)
              .map((cell) => (cell as List).map((e) => (e as num).toInt()).toSet())
              .toList())
          .toList(),
      difficulty: json['difficulty'] as String,
      gridSize: gridSize,
      mistakes: (json['mistakes'] as num).toInt(),
      hintsUsed: (json['hintsUsed'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      elapsedTime: Duration(seconds: (json['elapsedTime'] as num).toInt()),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isPaused: json['isPaused'] as bool? ?? false,
      startTime: DateTime.parse(json['startTime'] as String),
      moveHistory: (json['moveHistory'] as List?)
              ?.map((m) => GameMove.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      comboStreak: (json['comboStreak'] as num?)?.toInt() ?? 0,
      maxCombo: (json['maxCombo'] as num?)?.toInt() ?? 0,
      fastSolves: (json['fastSolves'] as num?)?.toInt() ?? 0,
      lastMoveTime: json['lastMoveTime'] != null
          ? DateTime.parse(json['lastMoveTime'] as String)
          : null,
      confirmedCorrectCells: json['confirmedCorrectCells'] != null
          ? Set<int>.from(
              (json['confirmedCorrectCells'] as List).map((e) => (e as num).toInt()))
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameState.fromJsonString(String jsonString) =>
      GameState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

/// Represents a single move in the game
class GameMove {
  final int row;
  final int col;
  final int? previousValue;
  final int? newValue;
  final Set<int>? previousNotes;
  final Set<int>? newNotes;
  final MoveType type;
  final DateTime timestamp;

  GameMove({
    required this.row,
    required this.col,
    this.previousValue,
    this.newValue,
    this.previousNotes,
    this.newNotes,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'previousValue': previousValue,
      'newValue': newValue,
      'previousNotes': previousNotes?.toList(),
      'newNotes': newNotes?.toList(),
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameMove.fromJson(Map<String, dynamic> json) {
    return GameMove(
      row: (json['row'] as num).toInt(),
      col: (json['col'] as num).toInt(),
      previousValue: (json['previousValue'] as num?)?.toInt(),
      newValue: (json['newValue'] as num?)?.toInt(),
      previousNotes:
          (json['previousNotes'] as List?)?.map((e) => (e as num).toInt()).toSet(),
      newNotes: (json['newNotes'] as List?)?.map((e) => (e as num).toInt()).toSet(),
      type: MoveType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => MoveType.setValue,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

enum MoveType { setValue, clearValue, addNote, removeNote, hint }

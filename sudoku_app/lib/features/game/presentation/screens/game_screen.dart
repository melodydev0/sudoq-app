import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/game_state.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/sudoku_generator.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/level_service.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/daily_challenge_service.dart';
import '../../../../core/services/user_sync_service.dart';
import '../../../../core/models/level_system.dart';
import '../../../../core/models/achievement.dart';
import '../../../level/presentation/screens/level_progress_screen.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/celebration_effect.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../subscription/presentation/screens/subscription_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/game_info_bar.dart';
import '../widgets/auto_complete_button.dart';
import '../widgets/game_action_bar.dart';
import '../widgets/game_number_pad.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String? difficulty;
  final bool isNewGame;
  final bool isDailyChallenge;
  final DateTime? dailyChallengeDate;

  const GameScreen({
    super.key,
    this.difficulty,
    this.isNewGame = true,
    this.isDailyChallenge = false,
    this.dailyChallengeDate,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late GameState _gameState;
  int? _selectedRow;
  int? _selectedCol;
  bool _isPencilMode = false;
  bool _isLoading = true;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  int _secondChancesUsed = 0; // Track how many times user used second chance

  // Track wrong attempts per cell: cellIndex → set of wrong numbers tried
  final Map<int, Set<int>> _wrongAttempts = {};

  // Celebration effect state
  final List<_CelebrationData> _celebrations = [];
  final GlobalKey _gridKey = GlobalKey();

  // Completed sections tracking (for row/col/box completion effects)
  final List<CompletedSection> _completedSections = [];
  final Set<String> _previouslyCompleted = {};

  // Combo milestone display
  bool _showComboMilestone = false;
  int _lastMilestoneCombo = 0;
  Timer? _comboMilestoneTimer;

  // Fast Pencil toggle state
  bool _fastPencilEnabled = false;

  // Auto-complete overlay button
  bool _showAutoCompleteBtn = false;
  Set<int> _droppingCells = {};

  // Board completion effect (shown after auto-complete before game complete flow)
  bool _showBoardCompletion = false;
  Rect? _boardCompletionRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _comboMilestoneTimer?.cancel();
    _saveGame();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _saveGame();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  void _initGame() async {
    if (widget.isNewGame) {
      await _startNewGame();
    } else {
      await _loadGame();
    }
    setState(() => _isLoading = false);
    _startTimer();

    // Play game start sound
    SoundService().playGameStart();
  }

  Future<void> _startNewGame() async {
    final generator = SudokuGenerator();
    final difficulty = widget.difficulty ?? 'Easy';
    final gridSize = difficulty == '16×16' ? 16 : 9;

    final result = generator.generatePuzzle(
      difficulty: difficulty == '16×16' ? 'Medium' : difficulty,
      gridSize: gridSize,
    );

    _gameState = GameState(
      puzzle: result['puzzle']!,
      solution: result['solution']!,
      currentGrid: result['puzzle']!.map((row) => List<int>.from(row)).toList(),
      notes: List.generate(
        gridSize,
        (_) => List.generate(gridSize, (_) => <int>{}),
      ),
      difficulty: difficulty,
      gridSize: gridSize,
      score: 0,
    );
    _secondChancesUsed = 0;
  }

  Future<void> _loadGame() async {
    final savedGame = StorageService.getCurrentGame();
    if (savedGame != null) {
      _gameState = savedGame;
      _elapsedTime = savedGame.elapsedTime;
    } else {
      await _startNewGame();
    }
  }

  void _saveGame() {
    if (!_gameState.isCompleted) {
      final updatedState = _gameState.copyWith(elapsedTime: _elapsedTime);
      StorageService.saveCurrentGame(updatedState);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_gameState.isPaused && !_gameState.isCompleted) {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);
        });
      }
    });
  }

  void _onCellTap(int row, int col) {
    debugPrint('GameScreen: Cell tapped at ($row, $col)');
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
    HapticService.selectionClick();
  }

  void _onNumberSelected(int number) {
    debugPrint(
        'Number selected: $number, selectedRow: $_selectedRow, selectedCol: $_selectedCol');

    final l10n = AppLocalizations.of(context);
    if (_selectedRow == null || _selectedCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectCellFirst),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_gameState.isFixedCell(_selectedRow!, _selectedCol!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectCellFirst),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_gameState.isConfirmedCorrectCell(_selectedRow!, _selectedCol!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotErase),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final row = _selectedRow!;
    final col = _selectedCol!;

    if (_isPencilMode) {
      _toggleNote(row, col, number);
    } else {
      _setCell(row, col, number);
    }

    HapticService.lightImpact();
  }

  void _setCell(int row, int col, int number) {
    final newGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();
    final newNotes = _gameState.notes
        .map((r) => r.map((c) => Set<int>.from(c)).toList())
        .toList();

    final previousValue = newGrid[row][col];
    final previousNotes = Set<int>.from(newNotes[row][col]);

    newGrid[row][col] = number;
    newNotes[row][col].clear();

    final isCorrect = number == _gameState.solution[row][col];
    int newMistakes = _gameState.mistakes;
    int newScore = _gameState.score;
    int newCombo = _gameState.comboStreak;
    int newMaxCombo = _gameState.maxCombo;
    int newFastSolves = _gameState.fastSolves;
    final now = DateTime.now();

    if (!isCorrect) {
      final cellIndex = row * _gameState.gridSize + col;
      _wrongAttempts[cellIndex] ??= {};

      if (_wrongAttempts[cellIndex]!.contains(number)) {
        // Already tried this wrong number in this cell — warn, don't count mistake
        HapticService.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).alreadyTriedWrong),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
        return;
      }

      _wrongAttempts[cellIndex]!.add(number);
      newMistakes++;
      newCombo = 0; // Reset combo on mistake
      HapticService.heavyImpact();
      SoundService().playWrongInput();
    } else {
      // Clear wrong attempts for this cell on correct entry
      _wrongAttempts.remove(row * _gameState.gridSize + col);
      // Play correct input sound
      SoundService().playCorrectInput();

      // Calculate combo and speed bonus
      newCombo++;
      if (newCombo > newMaxCombo) newMaxCombo = newCombo;

      // Speed bonus - if solved within 3 seconds of last move
      bool isFastSolve = false;
      if (_gameState.lastMoveTime != null) {
        final timeSinceLastMove =
            now.difference(_gameState.lastMoveTime!).inMilliseconds;
        if (timeSinceLastMove < 3000) {
          isFastSolve = true;
          newFastSolves++;
        }
      }

      // Calculate points with multiplier
      final multiplier = _getMultiplierForCombo(newCombo);
      int basePoints = 10;
      if (isFastSolve) basePoints += 5; // Speed bonus
      newScore += (basePoints * multiplier).round();

      // Haptic feedback based on combo
      if (newCombo >= 5) {
        HapticService.heavyImpact();
      } else {
        HapticService.mediumImpact();
      }

      // Check for combo milestone (3, 5, 7, 10, 15, 20, 25...)
      _checkComboMilestone(newCombo);

      // Trigger celebration effect
      _triggerCelebration(row, col);

      final settings = ref.read(settingsProvider);
      if (settings.autoRemoveNotes) {
        _removeRelatedNotes(newNotes, row, col, number);
      }

      // Auto-remove wrong instances of this number in same row/column/box
      _removeWrongDuplicates(newGrid, row, col, number);

      // Check for completed rows, columns, and boxes (only if game not complete)
      final isGameComplete = _checkCompletion(newGrid);
      if (!isGameComplete) {
        _checkSectionCompletions(newGrid, row, col);
      }
    }

    final move = GameMove(
      row: row,
      col: col,
      previousValue: previousValue,
      newValue: number,
      previousNotes: previousNotes,
      type: MoveType.setValue,
    );

    final newConfirmed = Set<int>.from(_gameState.confirmedCorrectCells);
    if (isCorrect) {
      newConfirmed.add(row * _gameState.gridSize + col);
    }

    setState(() {
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
        mistakes: newMistakes,
        score: newScore,
        moveHistory: [..._gameState.moveHistory, move],
        comboStreak: newCombo,
        maxCombo: newMaxCombo,
        fastSolves: newFastSolves,
        lastMoveTime: now,
        confirmedCorrectCells: newConfirmed,
      );
    });

    if (newMistakes >= AppConstants.maxMistakes) {
      _onGameOver();
    } else if (_checkCompletion(newGrid)) {
      _onGameComplete();
    } else {
      _checkAutoComplete();
    }
  }

  bool _checkCompletion(List<List<int>> grid) {
    for (int i = 0; i < _gameState.gridSize; i++) {
      for (int j = 0; j < _gameState.gridSize; j++) {
        if (grid[i][j] != _gameState.solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  void _checkAutoComplete() {
    if (_gameState.isCompleted) return;
    int remainingEmpty = 0;
    for (int r = 0; r < _gameState.gridSize; r++) {
      for (int c = 0; c < _gameState.gridSize; c++) {
        if (_gameState.puzzle[r][c] == 0 &&
            _gameState.currentGrid[r][c] != _gameState.solution[r][c]) {
          remainingEmpty++;
        }
      }
    }
    final shouldShow = remainingEmpty > 0 && remainingEmpty <= 5;
    if (shouldShow != _showAutoCompleteBtn) {
      setState(() => _showAutoCompleteBtn = shouldShow);
    }
  }

  Future<void> _onAutoComplete() async {
    // Collect empty cells that need filling
    final emptyCells = <(int, int)>[];
    for (int r = 0; r < _gameState.gridSize; r++) {
      for (int c = 0; c < _gameState.gridSize; c++) {
        if (_gameState.puzzle[r][c] == 0 &&
            _gameState.currentGrid[r][c] == 0) {
          emptyCells.add((r, c));
        }
      }
    }

    // Capture grid rect before we start modifying state
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    final boardRect = gridBox != null
        ? (gridBox.localToGlobal(Offset.zero) & gridBox.size)
        : null;

    setState(() => _showAutoCompleteBtn = false);

    // Play completion sound immediately so user hears it right away
    SoundService().playGameComplete();
    HapticService.heavyImpact();

    // Build a mutable working grid
    final workingGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();

    // Fill cells one-by-one with staggered drop animation
    const delayPerCell = Duration(milliseconds: 50);
    for (int i = 0; i < emptyCells.length; i++) {
      final (r, c) = emptyCells[i];
      workingGrid[r][c] = _gameState.solution[r][c];
      final cellKey = r * _gameState.gridSize + c;

      if (!mounted) return;
      setState(() {
        _gameState = _gameState.copyWith(
          currentGrid:
              workingGrid.map((row) => List<int>.from(row)).toList(),
        );
        _droppingCells = {..._droppingCells, cellKey};
      });

      if (i % 6 == 0) HapticService.lightImpact();
      await Future.delayed(delayPerCell);
    }

    // Brief wait for last drop animation then show board completion
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    setState(() {
      _droppingCells = {};
      if (boardRect != null) {
        _boardCompletionRect = boardRect;
        _showBoardCompletion = true;
      }
    });

    if (boardRect == null) _onGameComplete();
    // Otherwise _onGameComplete is called by BoardCompletionEffect.onComplete
  }

  Widget _buildAutoCompleteButton(AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(80 * value, 0),
        child: child,
      ),
      child: AutoCompleteButton(l10n: l10n, onTap: _onAutoComplete),
    );
  }

  /// Remove wrong instances of a number in same row, column, and box
  /// when the correct instance is placed
  void _removeWrongDuplicates(
      List<List<int>> grid, int row, int col, int number) {
    final size = _gameState.gridSize;
    final boxSize = size == 9 ? 3 : (size == 16 ? 4 : 3);

    // Check row - remove wrong instances of this number
    for (int c = 0; c < size; c++) {
      if (c != col && grid[row][c] == number) {
        // This is a duplicate - check if it's wrong
        if (_gameState.solution[row][c] != number) {
          grid[row][c] = 0; // Remove wrong duplicate
        }
      }
    }

    // Check column - remove wrong instances of this number
    for (int r = 0; r < size; r++) {
      if (r != row && grid[r][col] == number) {
        // This is a duplicate - check if it's wrong
        if (_gameState.solution[r][col] != number) {
          grid[r][col] = 0; // Remove wrong duplicate
        }
      }
    }

    // Check box - remove wrong instances of this number
    final int boxStartRow = (row ~/ boxSize) * boxSize;
    final int boxStartCol = (col ~/ boxSize) * boxSize;
    for (int r = boxStartRow; r < boxStartRow + boxSize; r++) {
      for (int c = boxStartCol; c < boxStartCol + boxSize; c++) {
        if ((r != row || c != col) && grid[r][c] == number) {
          // This is a duplicate - check if it's wrong
          if (_gameState.solution[r][c] != number) {
            grid[r][c] = 0; // Remove wrong duplicate
          }
        }
      }
    }
  }

  /// Get score multiplier based on combo streak
  double _getMultiplierForCombo(int combo) {
    if (combo >= 10) return 3.0; // 🔥🔥🔥 UNSTOPPABLE!
    if (combo >= 7) return 2.5; // 🔥🔥 ON FIRE!
    if (combo >= 5) return 2.0; // 🔥 HOT!
    if (combo >= 3) return 1.5; // ⚡ GOOD!
    return 1.0;
  }

  /// Check if combo reached a milestone (3, 5, 7, 10, 15, 20...)
  void _checkComboMilestone(int combo) {
    // Define milestones
    const milestones = [3, 5, 7, 10, 15, 20, 25, 30, 40, 50];

    // Check if this combo is a milestone and different from last shown
    if (milestones.contains(combo) && combo != _lastMilestoneCombo) {
      _comboMilestoneTimer?.cancel();
      setState(() {
        _showComboMilestone = true;
        _lastMilestoneCombo = combo;
      });

      // Hide after 1.5 seconds
      _comboMilestoneTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showComboMilestone = false;
          });
        }
      });
    }
  }

  /// Check if a row, column, or box was completed by the last move
  void _checkSectionCompletions(List<List<int>> grid, int row, int col) {
    final size = _gameState.gridSize;
    final boxSize = size == 9 ? 3 : 4;
    final now = DateTime.now();

    // Clean up old completed sections
    _completedSections.removeWhere((s) => !s.isAnimating);

    // Check if row is complete
    if (_isRowComplete(grid, row)) {
      final key = 'row_$row';
      if (!_previouslyCompleted.contains(key)) {
        _previouslyCompleted.add(key);
        _completedSections.add(CompletedSection(
          type: 'row',
          index: row,
          completedAt: now,
        ));
        HapticService.mediumImpact();
        SoundService().playRowComplete();
      }
    }

    // Check if column is complete
    if (_isColComplete(grid, col)) {
      final key = 'col_$col';
      if (!_previouslyCompleted.contains(key)) {
        _previouslyCompleted.add(key);
        _completedSections.add(CompletedSection(
          type: 'col',
          index: col,
          completedAt: now,
        ));
        HapticService.mediumImpact();
        SoundService().playColumnComplete();
      }
    }

    // Check if 3x3 box is complete
    final boxIndex = (row ~/ boxSize) * (size ~/ boxSize) + (col ~/ boxSize);
    if (_isBoxComplete(grid, row, col, boxSize)) {
      final key = 'box_$boxIndex';
      if (!_previouslyCompleted.contains(key)) {
        _previouslyCompleted.add(key);
        _completedSections.add(CompletedSection(
          type: 'box',
          index: boxIndex,
          completedAt: now,
        ));
        HapticService.heavyImpact();
        SoundService().playBoxComplete();
      }
    }
  }

  bool _isRowComplete(List<List<int>> grid, int row) {
    for (int col = 0; col < _gameState.gridSize; col++) {
      if (grid[row][col] != _gameState.solution[row][col]) {
        return false;
      }
    }
    return true;
  }

  bool _isColComplete(List<List<int>> grid, int col) {
    for (int row = 0; row < _gameState.gridSize; row++) {
      if (grid[row][col] != _gameState.solution[row][col]) {
        return false;
      }
    }
    return true;
  }

  bool _isBoxComplete(List<List<int>> grid, int row, int col, int boxSize) {
    final startRow = (row ~/ boxSize) * boxSize;
    final startCol = (col ~/ boxSize) * boxSize;

    for (int r = startRow; r < startRow + boxSize; r++) {
      for (int c = startCol; c < startCol + boxSize; c++) {
        if (grid[r][c] != _gameState.solution[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  void _triggerCelebration(int row, int col) {
    // Calculate cell position
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final gridPosition = gridBox.localToGlobal(Offset.zero);
    final cellSize = gridBox.size.width / _gameState.gridSize;

    final cellCenterX = gridPosition.dx + (col + 0.5) * cellSize;
    final cellCenterY = gridPosition.dy + (row + 0.5) * cellSize;

    final celebrationId = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _celebrations.add(_CelebrationData(
        id: celebrationId,
        position: Offset(cellCenterX, cellCenterY),
      ));
    });
  }

  void _removeCelebration(int id) {
    setState(() {
      _celebrations.removeWhere((c) => c.id == id);
    });
  }

  void _toggleNote(int row, int col, int number) {
    final newNotes = _gameState.notes
        .map((r) => r.map((c) => Set<int>.from(c)).toList())
        .toList();

    if (newNotes[row][col].contains(number)) {
      newNotes[row][col].remove(number);
    } else {
      newNotes[row][col].add(number);
    }

    final newGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();
    if (newGrid[row][col] != 0) {
      newGrid[row][col] = 0;
    }

    // Play note toggle sound
    SoundService().playHintFastPencil();

    setState(() {
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
      );
    });
  }

  void _removeRelatedNotes(
    List<List<Set<int>>> notes,
    int row,
    int col,
    int number,
  ) {
    final size = _gameState.gridSize;
    final boxSize = size == 9 ? 3 : 4;

    for (int c = 0; c < size; c++) {
      notes[row][c].remove(number);
    }

    for (int r = 0; r < size; r++) {
      notes[r][col].remove(number);
    }

    final boxRowStart = (row ~/ boxSize) * boxSize;
    final boxColStart = (col ~/ boxSize) * boxSize;
    for (int r = boxRowStart; r < boxRowStart + boxSize; r++) {
      for (int c = boxColStart; c < boxColStart + boxSize; c++) {
        notes[r][c].remove(number);
      }
    }
  }

  void _onUndo() {
    final l10n = AppLocalizations.of(context);
    if (_gameState.moveHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.noMoveToUndo),
            duration: const Duration(seconds: 1)),
      );
      return;
    }

    final moves = List<GameMove>.from(_gameState.moveHistory);
    final lastMove = moves.last;

    // Block undo for correctly placed numbers
    if (lastMove.type == MoveType.setValue &&
        lastMove.newValue == _gameState.solution[lastMove.row][lastMove.col]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cantUndoCorrect),
            duration: const Duration(seconds: 1)),
      );
      return;
    }

    moves.removeLast();

    final newGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();
    final newNotes = _gameState.notes
        .map((r) => r.map((c) => Set<int>.from(c)).toList())
        .toList();

    newGrid[lastMove.row][lastMove.col] = lastMove.previousValue ?? 0;
    if (lastMove.previousNotes != null) {
      newNotes[lastMove.row][lastMove.col] = lastMove.previousNotes!;
    }

    final newConfirmed = Set<int>.from(_gameState.confirmedCorrectCells);

    setState(() {
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
        moveHistory: moves,
        confirmedCorrectCells: newConfirmed,
      );
      _selectedRow = lastMove.row;
      _selectedCol = lastMove.col;
    });

    HapticService.lightImpact();
  }

  void _onErase() {
    final l10n = AppLocalizations.of(context);
    if (_selectedRow == null || _selectedCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.selectCellFirst),
            duration: const Duration(seconds: 1)),
      );
      return;
    }

    if (_gameState.isFixedCell(_selectedRow!, _selectedCol!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cannotErase),
            duration: const Duration(seconds: 1)),
      );
      return;
    }

    if (_gameState.isConfirmedCorrectCell(_selectedRow!, _selectedCol!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cannotErase),
            duration: const Duration(seconds: 1)),
      );
      return;
    }

    final row = _selectedRow!;
    final col = _selectedCol!;

    final newGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();
    final newNotes = _gameState.notes
        .map((r) => r.map((c) => Set<int>.from(c)).toList())
        .toList();

    final previousValue = newGrid[row][col];
    final previousNotes = Set<int>.from(newNotes[row][col]);

    newGrid[row][col] = 0;
    newNotes[row][col].clear();

    // Clear wrong attempts for this cell when erased
    _wrongAttempts.remove(row * _gameState.gridSize + col);

    final move = GameMove(
      row: row,
      col: col,
      previousValue: previousValue,
      newValue: 0,
      previousNotes: previousNotes,
      type: MoveType.clearValue,
    );

    setState(() {
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
        moveHistory: [..._gameState.moveHistory, move],
      );
    });

    HapticService.lightImpact();
  }

  void _onHint() async {
    // Play hint button sound
    SoundService().playHintFastPencil();

    // Both free and premium users are limited to maxHints per game
    if (_gameState.hintsUsed >= AppConstants.maxHints) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noHintsRemaining),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final isAdsFree = ref.read(adsFreeProvider);

    // Premium users can use hints freely up to maxHints
    if (isAdsFree) {
      _useHint();
      return;
    }

    // Free users: after freeHintsWithoutAd, must watch ad for each additional hint
    if (_gameState.hintsUsed >= AppConstants.freeHintsWithoutAd) {
      _showHintOptionsDialog();
      return;
    }

    _useHint();
  }

  /// Show dialog with options to get more hints – premium handcrafted style
  void _showHintOptionsDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.2),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: const Icon(Icons.lightbulb_rounded,
                  color: AppColors.accentGold, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.needAHint,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.getMoreHintsBy,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.textSecondary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Watch 1 Ad option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _watchAdForHint();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: AppTheme.buttonRadius,
                  border: Border.all(
                      color: theme.accent.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: theme.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_filled,
                        color: theme.accent, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.watchOneAd,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: theme.textPrimary,
                            ),
                          ),
                          Text(
                            l10n.getFreeHint,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: theme.textSecondary, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Go Premium option
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.buttonPrimary,
                  borderRadius: AppTheme.cardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: theme.textPrimary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium,
                        color: theme.buttonText, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.goPremium,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: theme.buttonText,
                            ),
                          ),
                          Text(
                            l10n.unlimitedHints,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.buttonText.withValues(alpha: 0.9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: AppTheme.buttonRadius,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.bestBadge,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14.sp,
                  letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  /// Watch 1 ad to get a hint
  void _watchAdForHint() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Builder(
                  builder: (ctx) => Text(AppLocalizations.of(ctx).loadingAd)),
            ],
          ),
        ),
      ),
    );

    final adCompleted = await _showRewardedAd();

    if (mounted) Navigator.pop(context);

    if (adCompleted) {
      // Re-check limit — user might have reached maxHints while the ad was playing
      if (_gameState.hintsUsed >= AppConstants.maxHints) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noHintsRemaining),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      _useHint();
      if (mounted) {
        final snackL10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.white),
                const SizedBox(width: 8),
                Text(snackL10n.hintUsedThanks),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        final snackL10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackL10n.adNotCompleted),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _useHint() {
    late int row;
    late int col;
    late int value;

    // If a cell is selected and it's empty, use hint on that cell
    if (_selectedRow != null && _selectedCol != null) {
      final selectedCellValue =
          _gameState.currentGrid[_selectedRow!][_selectedCol!];
      if (selectedCellValue == 0) {
        // Selected cell is empty, provide hint for it
        row = _selectedRow!;
        col = _selectedCol!;
        value = _gameState.solution[_selectedRow!][_selectedCol!];
      } else {
        // Selected cell is already filled, show message
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectEmptyCellForHint),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    } else {
      // No cell selected, find any empty cell
      final generator = SudokuGenerator();
      final hint = generator.getHintForEmptyCell(
        _gameState.currentGrid,
        _gameState.solution,
        _gameState.gridSize,
      );

      if (hint == null) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noEmptyCellsLeft),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }

      row = hint['row']!;
      col = hint['col']!;
      value = hint['value']!;
    }

    final newGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();
    final newNotes = _gameState.notes
        .map((r) => r.map((c) => Set<int>.from(c)).toList())
        .toList();

    newGrid[row][col] = value;
    newNotes[row][col].clear();

    // Auto-remove related notes (same as when placing a number manually)
    final settings = ref.read(settingsProvider);
    if (settings.autoRemoveNotes) {
      _removeRelatedNotes(newNotes, row, col, value);
    }

    ref.read(statisticsProvider.notifier).recordHintUsed();

    // Trigger celebration effect for hint
    _triggerCelebration(row, col);

    // Check for game completion first (avoid duplicate sounds)
    final isGameComplete = _checkCompletion(newGrid);
    if (!isGameComplete) {
      // Check for completed sections
      _checkSectionCompletions(newGrid, row, col);
    }

    final newConfirmed = Set<int>.from(_gameState.confirmedCorrectCells);
    newConfirmed.add(row * _gameState.gridSize + col);

    setState(() {
      _selectedRow = row;
      _selectedCol = col;
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
        hintsUsed: _gameState.hintsUsed + 1,
        score: _gameState.score + 5, // Reduced points for hint
        confirmedCorrectCells: newConfirmed,
      );
    });

    if (isGameComplete) {
      _onGameComplete();
    }

    HapticService.mediumImpact();
  }

  void _togglePencilMode() {
    setState(() {
      _isPencilMode = !_isPencilMode;
    });
    HapticService.selectionClick();
  }

  /// Fast Pencil - Toggle ON/OFF
  /// Premium: Free toggle
  /// Free users: Watch ad to turn ON, can turn OFF freely but need ad again to turn ON
  void _onFastPencil() async {
    // Play fast pencil button sound
    SoundService().playHintFastPencil();

    final isAdsFree = ref.read(adsFreeProvider);

    // If already enabled, turn OFF (free for everyone)
    if (_fastPencilEnabled) {
      _disableFastPencil();
      return;
    }

    // Turning ON - Premium users can toggle freely
    if (isAdsFree) {
      _enableFastPencil();
      return;
    }

    // Free users: Show options dialog to watch ad
    _showFastPencilOptionsDialog();
  }

  /// Enable Fast Pencil - fill all candidates
  void _enableFastPencil() {
    final size = _gameState.gridSize;
    final boxSize = size == 9 ? 3 : 4;

    final newNotes = _gameState.notes
        .map((r) => r.map((c) => Set<int>.from(c)).toList())
        .toList();

    // For each empty cell, calculate possible candidates
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (_gameState.currentGrid[row][col] != 0) continue;
        if (_gameState.isFixedCell(row, col)) continue;

        final candidates = <int>{};
        for (int num = 1; num <= size; num++) {
          if (_isValidCandidate(row, col, num, boxSize)) {
            candidates.add(num);
          }
        }
        newNotes[row][col] = candidates;
      }
    }

    setState(() {
      _gameState = _gameState.copyWith(notes: newNotes);
      _fastPencilEnabled = true;
    });

    HapticService.mediumImpact();
    final snackL10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.white),
            const SizedBox(width: 8),
            Text(snackL10n.fastPencilOn),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Disable Fast Pencil - clear all notes
  void _disableFastPencil() {
    final size = _gameState.gridSize;

    final newNotes = List.generate(
      size,
      (_) => List.generate(size, (_) => <int>{}),
    );

    setState(() {
      _gameState = _gameState.copyWith(notes: newNotes);
      _fastPencilEnabled = false;
    });

    HapticService.lightImpact();
    final snackL10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.flash_off, color: Colors.white),
            const SizedBox(width: 8),
            Text(snackL10n.fastPencilOff),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Show dialog with options to unlock Fast Pencil – premium handcrafted style
  void _showFastPencilOptionsDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.15),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: Icon(Icons.flash_on, color: theme.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.fastPencil,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.fastPencilUnlock,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.textSecondary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Watch 1 Ad option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _watchAdForFastPencil();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: AppTheme.buttonRadius,
                  border: Border.all(
                      color: theme.accent.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: theme.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_filled,
                        color: theme.accent, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.watchOneAd,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: theme.textPrimary,
                            ),
                          ),
                          Text(
                            l10n.useFastPencilOnce,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: theme.textSecondary, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Go Premium option
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.buttonPrimary,
                  borderRadius: AppTheme.cardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: theme.textPrimary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium,
                        color: theme.buttonText, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.goPremium,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: theme.buttonText,
                            ),
                          ),
                          Text(
                            l10n.unlimitedFastPencil,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.buttonText.withValues(alpha: 0.9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: AppTheme.buttonRadius,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.bestBadge,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14.sp,
                  letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  /// Watch 1 ad to enable Fast Pencil
  void _watchAdForFastPencil() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Builder(
                  builder: (ctx) => Text(AppLocalizations.of(ctx).loadingAd)),
            ],
          ),
        ),
      ),
    );

    final adCompleted = await _showRewardedAd();

    if (mounted) Navigator.pop(context);

    if (adCompleted) {
      _enableFastPencil();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).adNotCompleted),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Check if a number is a valid candidate for a cell
  bool _isValidCandidate(int row, int col, int num, int boxSize) {
    final size = _gameState.gridSize;

    // Check row
    for (int c = 0; c < size; c++) {
      if (_gameState.currentGrid[row][c] == num) return false;
    }

    // Check column
    for (int r = 0; r < size; r++) {
      if (_gameState.currentGrid[r][col] == num) return false;
    }

    // Check box
    final boxRowStart = (row ~/ boxSize) * boxSize;
    final boxColStart = (col ~/ boxSize) * boxSize;
    for (int r = boxRowStart; r < boxRowStart + boxSize; r++) {
      for (int c = boxColStart; c < boxColStart + boxSize; c++) {
        if (_gameState.currentGrid[r][c] == num) return false;
      }
    }

    return true;
  }

  void _onGameComplete({bool skipSound = false}) async {
    _timer?.cancel();
    // Mark completed so _saveGame() (e.g. in dispose) won't re-persist this game
    _gameState = _gameState.copyWith(isCompleted: true);
    await StorageService.clearCurrentGame();

    if (!skipSound) {
      // Play game complete celebration sound
      SoundService().playGameComplete();
      // Brief pause so the game_complete sound has time to start before
      // the async operations below trigger navigation to the result screen
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final bonusScore = _gameState.mistakes == 0 ? 100 : 0;
    final finalScore = _gameState.score + bonusScore;
    final isPerfect = _gameState.mistakes == 0;

    // Record game won in statistics (with isDailyChallenge flag)
    await ref.read(statisticsProvider.notifier).recordGameWon(
          difficulty: _gameState.difficulty,
          time: _elapsedTime.inSeconds,
          score: finalScore,
          mistakes: _gameState.mistakes,
          isDailyChallenge: widget.isDailyChallenge,
        );

    // Record daily challenge completion if this is a daily challenge
    if (widget.isDailyChallenge) {
      final challengeDate = widget.dailyChallengeDate ?? DateTime.now();
      await DailyChallengeService.recordCompletion(
        date: challengeDate,
        completionTimeSeconds: _elapsedTime.inSeconds,
        mistakes: _gameState.mistakes,
        score: finalScore,
      );
    }

    // Get updated statistics for achievement check
    final stats = ref.read(statisticsProvider);

    // Check achievements and get XP bonus
    final achievementResult = await AchievementService.checkAfterWin(
      stats: stats,
      difficulty: _gameState.difficulty,
      completionTimeSeconds: _elapsedTime.inSeconds,
      isPerfect: isPerfect,
      isDailyChallenge: widget.isDailyChallenge,
    );

    // Refresh achievements provider with new data
    ref.read(achievementsDataProvider.notifier).refresh();

    // Get previous level data before adding XP
    final previousLevelData = LevelService.levelData;

    // Preview XP that would be earned (same formula as addGameXp for accurate dialog)
    final previewXp = LevelService.previewXp(
      difficulty: _gameState.difficulty,
      completionTime: _elapsedTime,
      mistakes: _gameState.mistakes,
      isDailyChallenge: widget.isDailyChallenge,
      isRanked: false,
      score: finalScore,
      maxCombo: _gameState.maxCombo,
      fastSolves: _gameState.fastSolves,
    );

    // For FREE users, show XP Boost option
    if (AdsService.shouldShowAds() && mounted) {
      _showXpBoostDialog(
        previewXp: previewXp,
        achievementXp: achievementResult.totalXpBonus,
        finalScore: finalScore,
        isPerfect: isPerfect,
        achievementResult: achievementResult,
        previousLevelData: previousLevelData,
      );
    } else if (mounted) {
      // Premium users get 2x XP automatically
      await _finalizeGameComplete(
        xpMultiplier: 2.0,
        isPremiumXpBoost: true,
        achievementResult: achievementResult,
        previousLevelData: previousLevelData,
        finalScore: finalScore,
      );
    }
  }

  /// Show XP Boost dialog offering 2x XP for watching an ad
  void _showXpBoostDialog({
    required int previewXp,
    required int achievementXp,
    required int finalScore,
    required bool isPerfect,
    required AchievementCheckResult achievementResult,
    required UserLevelData previousLevelData,
  }) {
    final totalXp = previewXp + achievementXp;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars,
                color: Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.doubleYourXp,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current XP preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.gameXp),
                      Text('+$previewXp',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (achievementXp > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.achievementBonus),
                        Text('+$achievementXp',
                            style: TextStyle(
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.total,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('+$totalXp XP',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2x XP offer
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                _watchAdForXpBoost(
                  achievementResult: achievementResult,
                  previousLevelData: previousLevelData,
                  finalScore: finalScore,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_filled,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.watchAdFor2xXp,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            l10n.getXpInstead(totalXp * 2),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '2X',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Skip option
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _finalizeGameComplete(
                  xpMultiplier: 1.0,
                  achievementResult: achievementResult,
                  previousLevelData: previousLevelData,
                  finalScore: finalScore,
                );
              },
              child: Text(
                l10n.noThanksXp(totalXp),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Watch ad for XP boost
  void _watchAdForXpBoost({
    required AchievementCheckResult achievementResult,
    required UserLevelData previousLevelData,
    required int finalScore,
  }) {
    bool rewarded = false;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Builder(
                  builder: (ctx) => Text(AppLocalizations.of(ctx).loadingAd)),
            ],
          ),
        ),
      ),
    );

    AdsService.showXpBoostAd(
      onRewarded: () {
        rewarded = true;
      },
      onAdClosed: () {
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (!mounted) return;
          Navigator.pop(context); // Close loading

          await _finalizeGameComplete(
            xpMultiplier: rewarded ? 2.0 : 1.0,
            achievementResult: achievementResult,
            previousLevelData: previousLevelData,
            finalScore: finalScore,
          );
        });
      },
    );
  }

  /// Finalize game complete with XP multiplier
  Future<void> _finalizeGameComplete({
    required double xpMultiplier,
    required AchievementCheckResult achievementResult,
    required UserLevelData previousLevelData,
    required int finalScore,
    bool isPremiumXpBoost = false,
  }) async {
    // Calculate and add XP with multiplier
    final gameXpResult = await LevelService.addGameXp(
      difficulty: _gameState.difficulty,
      completionTime: _elapsedTime,
      mistakes: _gameState.mistakes,
      isDailyChallenge: widget.isDailyChallenge,
      isRanked: false,
      score: finalScore,
      maxCombo: _gameState.maxCombo,
      fastSolves: _gameState.fastSolves,
      performanceMultiplier: xpMultiplier,
    );
    var newLevelData = gameXpResult.levelData;
    final dailyStreakXp = gameXpResult.dailyStreakXp;

    // Add achievement XP bonus if any (also multiplied)
    if (achievementResult.totalXpBonus > 0) {
      final bonusXp = (achievementResult.totalXpBonus * xpMultiplier).round();
      newLevelData = await LevelService.addBonusXp(bonusXp);
    }

    // Calculate total XP earned (game + achievements)
    final xpEarned = newLevelData.totalXp - previousLevelData.totalXp;

    // Build the XP breakdown now (before the async ad gap) so the
    // LevelProgressScreen can animate each source row individually.
    var gameXpBreakdown = XpMultipliers.getXpBreakdown(
      difficulty: _gameState.difficulty,
      completionTime: _elapsedTime,
      mistakes: _gameState.mistakes,
      isDailyChallenge: widget.isDailyChallenge,
      isRanked: false,
      streakDays: previousLevelData.streakDays,
      score: finalScore,
      maxCombo: _gameState.maxCombo,
      fastSolves: _gameState.fastSolves,
    );

    // Add daily streak bonus as a separate breakdown row if awarded today
    if (dailyStreakXp > 0) {
      gameXpBreakdown = [
        ...gameXpBreakdown,
        GameXpBreakdownEntry('streak_daily', dailyStreakXp),
      ];
    }

    // Sync to cloud (if logged in)
    UserSyncService.syncToCloud();

    // Show interstitial ad, then navigate to level progress screen
    AdsService.showInterstitialAd(onAdClosed: () {
      _showLevelProgressScreen(
        xpEarned: xpEarned,
        previousLevelData: previousLevelData,
        newLevelData: newLevelData,
        newAchievements: achievementResult.newlyUnlocked,
        achievementXp: (achievementResult.totalXpBonus * xpMultiplier).round(),
        xpBoostMultiplier: xpMultiplier,
        isPremiumXpBoost: isPremiumXpBoost,
        gameXpBreakdown: gameXpBreakdown,
      );
    });
  }

  void _showLevelProgressScreen({
    required int xpEarned,
    required UserLevelData previousLevelData,
    required UserLevelData newLevelData,
    List<Achievement> newAchievements = const [],
    int achievementXp = 0,
    double xpBoostMultiplier = 1.0,
    bool isPremiumXpBoost = false,
    List<GameXpBreakdownEntry> gameXpBreakdown = const [],
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LevelProgressScreen(
          xpEarned: xpEarned,
          previousLevelData: previousLevelData,
          newLevelData: newLevelData,
          difficulty: _gameState.difficulty,
          completionTime: _elapsedTime,
          mistakes: _gameState.mistakes,
          isDailyChallenge: widget.isDailyChallenge,
          isRanked: false,
          newAchievements: newAchievements,
          achievementXp: achievementXp,
          xpBoostMultiplier: xpBoostMultiplier,
          isPremiumXpBoost: isPremiumXpBoost,
          gameXpBreakdown: gameXpBreakdown,
          onContinue: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _onGameOver() {
    _timer?.cancel();
    final isPremium = StorageService.isAdsFree();
    final maxChances = isPremium
        ? AppConstants.maxSecondChancesPremium
        : AppConstants.maxSecondChancesFree;
    if (_secondChancesUsed >= maxChances) {
      _finalizeGameOver();
      return;
    }
    _showSecondChanceDialog();
  }

  /// Show dialog offering second chance by watching ad OR becoming VIP – premium handcrafted style
  void _showSecondChanceDialog() {
    final isPremium = StorageService.isAdsFree();
    final maxChances = isPremium
        ? AppConstants.maxSecondChancesPremium
        : AppConstants.maxSecondChancesFree;
    final remainingChances = maxChances - _secondChancesUsed;

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: const Icon(Icons.heart_broken,
                  color: AppColors.error, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.outOfLives,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.outOfLivesMessage,
              style: TextStyle(
                fontSize: 15.sp,
                color: theme.textSecondary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Premium: instant free second chance (no ad)
            if (isPremium)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _grantSecondChance();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.12),
                    borderRadius: AppTheme.buttonRadius,
                    border: Border.all(
                        color: AppColors.accentGold.withValues(alpha: 0.5),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium,
                          color: AppColors.accentGold, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.premiumFreeSecondChance,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: theme.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.secondChancesRemaining(remainingChances, maxChances),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: theme.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),

            // Watch Ad option (free users only)
            if (!isPremium)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _watchAdsForSecondChance();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: AppTheme.buttonRadius,
                    border: Border.all(
                        color: theme.accent.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_filled,
                          color: theme.accent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.watchAd,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: theme.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.getSecondChancePerGame(remainingChances),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: theme.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Become VIP option (free users only)
            if (!isPremium)
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );

                  if (result == true) {
                    _grantSecondChance();
                  } else {
                    _showSecondChanceDialog();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.buttonPrimary,
                    borderRadius: AppTheme.cardRadius,
                    boxShadow: [
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium,
                          color: theme.buttonText, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.becomeVip,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: theme.buttonText,
                              ),
                            ),
                            Text(
                              l10n.secondChancesAndMore,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.buttonText.withValues(alpha: 0.9),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: AppTheme.buttonRadius,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.bestBadge,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Stats
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.accentLight,
                borderRadius: AppTheme.buttonRadius,
                border: Border.all(color: theme.divider),
              ),
              child: Column(
                children: [
                  _buildStatRow('Current Score', '${_gameState.score}', theme),
                  _buildStatRow('Time', _formatTime(_elapsedTime), theme),
                  _buildStatRow(
                      'Second Chances Used', '$_secondChancesUsed', theme),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delay to let the dialog dismiss animation finish before
              // showing the game over dialog — prevents visual overlap artifact
              Future.delayed(const Duration(milliseconds: 250), () {
                if (mounted) _finalizeGameOver();
              });
            },
            child: Text(
              l10n.giveUp,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14.sp,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Watch 1 rewarded ad to get second chance
  void _watchAdsForSecondChance() async {
    bool rewarded = false;
    bool dialogClosed = false;

    // Show simple loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Builder(
                  builder: (ctx) => Text(AppLocalizations.of(ctx).loadingAd)),
            ],
          ),
        ),
      ),
    );

    // Show rewarded ad with daily limit tracking
    AdsService.showSecondChanceAd(
      onRewarded: () {
        rewarded = true;
      },
      onAdClosed: () {
        // Wait a bit to ensure onRewarded fires first if earned
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || dialogClosed) return;
          dialogClosed = true;

          Navigator.pop(context); // Close loading

          if (rewarded) {
            _grantSecondChance();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).watchFullAdToContinue),
                backgroundColor: Colors.orange,
              ),
            );
            _showSecondChanceDialog();
          }
        });
      },
    );
  }

  /// Show a rewarded ad and return true if completed
  Future<bool> _showRewardedAd() async {
    final completer = Completer<bool>();

    AdsService.showRewardedAd(
      onRewarded: () {
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdClosed: () {
        // Small delay to ensure reward callback fires first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!completer.isCompleted) completer.complete(false);
        });
      },
    );

    return completer.future;
  }

  /// Grant second chance - reduce mistakes to 2
  void _grantSecondChance() {
    setState(() {
      _secondChancesUsed++;
      _gameState = _gameState.copyWith(
        mistakes: 2, // Reduce to 2 mistakes, giving 1 life
      );
    });

    // Restart timer
    _startTimer();

    if (mounted) {
      final snackL10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 8),
              Text(snackL10n.secondChanceGranted),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Finalize game over after user chooses to give up
  void _finalizeGameOver() {
    StorageService.clearCurrentGame();

    SoundService().playGameLost();

    ref.read(statisticsProvider.notifier).recordGameLost(
          difficulty: _gameState.difficulty,
          time: _elapsedTime.inSeconds,
        );

    _showCompleteDialog(won: false, score: _gameState.score);
  }

  void _showCompleteDialog({required bool won, required int score}) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      // Removed `clipBehavior: Clip.antiAlias`: it interacts badly with the
      // Material dialog scale animation on some Android builds (MIUI /
      // Android 14+), producing a triangular "folded-corner" artifact when
      // the dialog first appears. The rounded shape from
      // `RoundedRectangleBorder` already clips the dialog surface correctly.
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (won ? Colors.amber : AppColors.error)
                    .withValues(alpha: 0.15),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: Icon(
                won ? Icons.celebration : Icons.sentiment_dissatisfied,
                color: won ? Colors.amber : AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                won ? l10n.congratulations : l10n.gameOver,
                style: TextStyle(
                  fontSize: 18,
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? l10n.congratsMessage : l10n.gameOverMessage,
              style: TextStyle(fontSize: 15, color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.accentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.divider),
              ),
              child: Column(
                children: [
                  _buildStatRow(l10n.score, '$score', theme),
                  _buildStatRow(l10n.time, _formatTime(_elapsedTime), theme),
                  _buildStatRow(l10n.mistakes, '${_gameState.mistakes}/3', theme),
                  if (_secondChancesUsed > 0)
                    _buildStatRow(
                        l10n.secondChanceTitle, '$_secondChancesUsed', theme),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(l10n.home,
                style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonPrimary,
              foregroundColor: theme.buttonText,
              shape: const RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius),
            ),
            child: Text(l10n.newGame),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [AppThemeColors? theme]) {
    final labelColor = theme?.textSecondary ?? Colors.grey.shade600;
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: theme?.textPrimary,
      letterSpacing: 0.2,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() => _isLoading = true);
    _elapsedTime = Duration.zero;
    _startNewGame().then((_) {
      setState(() {
        _isLoading = false;
        _selectedRow = null;
        _selectedCol = null;
        _isPencilMode = false;
      });
      _startTimer();
    });
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Use AppThemeManager for premium themes
    final theme = AppThemeManager.colors;
    final isDark = theme.isDark;
    final bgColor = theme.background;
    final cardColor = theme.card;
    final textColor = theme.textPrimary;
    final isAdsFree = ref.watch(adsFreeProvider);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.accent),
              const SizedBox(height: 16),
              Text(
                'Preparing puzzle...',
                style: TextStyle(color: theme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false, // Don't add safe area padding at bottom for ad
            child: Column(
              children: [
                // Top bar
                GameTopBar(
                  difficulty: _gameState.difficulty,
                  textColor: textColor,
                  onBack: () {
                    _saveGame();
                    Navigator.pop(context);
                  },
                  onSettings: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),

                // Game info
                GameInfoBar(
                  mistakes: _gameState.mistakes,
                  maxMistakes: 3,
                  score: _gameState.score,
                  comboStreak: _gameState.comboStreak,
                  comboMultiplier:
                      _getMultiplierForCombo(_gameState.comboStreak),
                  elapsedTime: _elapsedTime,
                  showComboMilestone: _showComboMilestone,
                  lastMilestoneCombo: _lastMilestoneCombo,
                  textColor: textColor,
                  isDark: isDark,
                ),

                // Sudoku grid
                Expanded(
                  child: Center(
                    child: SudokuGrid(
                      key: _gridKey,
                      gameState: _gameState,
                      selectedRow: _selectedRow,
                      selectedCol: _selectedCol,
                      onCellTap: _onCellTap,
                      completedSections: _completedSections,
                      droppingCells: _droppingCells,
                    ),
                  ),
                ),

                // Action buttons
                GameActionBar(
                  isPencilMode: _isPencilMode,
                  fastPencilEnabled: _fastPencilEnabled,
                  isAdsFree: isAdsFree,
                  hintsUsed: _gameState.hintsUsed,
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  onUndo: _onUndo,
                  onErase: _onErase,
                  onTogglePencil: _togglePencilMode,
                  onFastPencil: _onFastPencil,
                  onHint: _onHint,
                ),

                // Number pad
                GameNumberPad(
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  remainingCounts: {
                    for (var i = 1; i <= 9; i++)
                      i: _gameState.getRemainingCount(i),
                  },
                  onNumberSelected: _onNumberSelected,
                ),

                // Banner ad space (always reserve space for consistency)
                Container(
                  height: 60, // Standard banner height + padding
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: AdsService.shouldShowAds()
                      ? AdsService.getBannerAdWidget()
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Celebration effects overlay
          ..._celebrations.map((celebration) {
            return CelebrationEffect(
              key: ValueKey(celebration.id),
              position: celebration.position,
              color: AppColors.gradientStart,
              onComplete: () => _removeCelebration(celebration.id),
            );
          }),

          // Auto-complete button overlay
          if (_showAutoCompleteBtn)
            Positioned(
              bottom: 180,
              right: 16,
              child: _buildAutoCompleteButton(l10n),
            ),

          // Board completion sweep effect (after auto-complete, before win flow)
          if (_showBoardCompletion && _boardCompletionRect != null)
            Positioned.fill(
              child: BoardCompletionEffect(
                boardRect: _boardCompletionRect!,
                onComplete: () {
                  if (mounted) {
                    setState(() => _showBoardCompletion = false);
                    _onGameComplete(skipSound: true);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

}

class _CelebrationData {
  final int id;
  final Offset position;

  _CelebrationData({
    required this.id,
    required this.position,
  });
}

/// Minimal combo popup - shows at bottom, doesn't distract from gameplay
class _ComboPopup extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onDismiss;

  const _ComboPopup({
    required this.text,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_ComboPopup> createState() => _ComboPopupState();
}

class _ComboPopupState extends State<_ComboPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Faster animation
      vsync: this,
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.18, // Above number pad
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

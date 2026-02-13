import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
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
    HapticFeedback.selectionClick();
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

    HapticFeedback.lightImpact();
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
      newMistakes++;
      newCombo = 0; // Reset combo on mistake
      HapticFeedback.heavyImpact();
      SoundService().playWrongInput();
    } else {
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
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
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
        HapticFeedback.mediumImpact();
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
        HapticFeedback.mediumImpact();
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
        HapticFeedback.heavyImpact();
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
    final lastMove = moves.removeLast();

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
    if (lastMove.type == MoveType.setValue &&
        lastMove.newValue == _gameState.solution[lastMove.row][lastMove.col]) {
      newConfirmed.remove(lastMove.row * _gameState.gridSize + lastMove.col);
    }

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

    HapticFeedback.lightImpact();
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

    HapticFeedback.lightImpact();
  }

  void _onHint() async {
    // Play hint button sound
    SoundService().playHintFastPencil();

    final isAdsFree = ref.read(adsFreeProvider);

    // Premium users have unlimited hints
    if (isAdsFree) {
      _useHint();
      return;
    }

    // Free users: Check if hints are exhausted - show options dialog
    if (_gameState.hintsUsed >= AppConstants.maxHints) {
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
                        'BEST',
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
              'Cancel',
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
      _useHint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.white),
                SizedBox(width: 8),
                Text('Hint used! Thanks for watching the ad.'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not completed. Please try again.'),
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

    HapticFeedback.mediumImpact();
  }

  void _togglePencilMode() {
    setState(() {
      _isPencilMode = !_isPencilMode;
    });
    HapticFeedback.selectionClick();
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

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.flash_on, color: Colors.white),
            SizedBox(width: 8),
            Text('Fast Pencil ON'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
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

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.flash_off, color: Colors.white),
            SizedBox(width: 8),
            Text('Fast Pencil OFF'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
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
                            'Unlimited Fast Pencil',
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
                        'BEST',
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
              'Cancel',
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
          const SnackBar(
            content: Text('Ad not completed. Please try again.'),
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

  void _onGameComplete() async {
    _timer?.cancel();
    // Mark completed so _saveGame() (e.g. in dispose) won't re-persist this game
    _gameState = _gameState.copyWith(isCompleted: true);
    await StorageService.clearCurrentGame();

    // Play game complete celebration sound
    SoundService().playGameComplete();

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
    } else {
      // Premium users - add XP directly
      await _finalizeGameComplete(
        xpMultiplier: 1.0,
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
                'Double Your XP!',
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
                      const Text('Game XP'),
                      Text('+$previewXp',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (achievementXp > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Achievement Bonus'),
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
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                            'Watch Ad for 2x XP',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Get +${totalXp * 2} XP instead!',
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
                'No thanks, continue with +$totalXp XP',
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
  }) async {
    // Calculate and add XP with multiplier
    var newLevelData = await LevelService.addGameXp(
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

    // Add achievement XP bonus if any (also multiplied)
    if (achievementResult.totalXpBonus > 0) {
      final bonusXp = (achievementResult.totalXpBonus * xpMultiplier).round();
      newLevelData = await LevelService.addBonusXp(bonusXp);
    }

    // Calculate total XP earned (game + achievements)
    final xpEarned = newLevelData.totalXp - previousLevelData.totalXp;

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
          onContinue: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _onGameOver() {
    _timer?.cancel();
    // Show second chance dialog instead of game over
    _showSecondChanceDialog();
  }

  /// Show dialog offering second chance by watching ad OR becoming VIP – premium handcrafted style
  void _showSecondChanceDialog() async {
    final isAvailable = await AdsService.isSecondChanceAvailable();
    final remaining = await AdsService.getSecondChanceRemaining();

    if (!mounted) return;

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
                'Out of Lives!',
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
              'You made 3 mistakes. But don\'t give up!',
              style: TextStyle(
                fontSize: 15.sp,
                color: theme.textSecondary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Watch Ad option (if available)
            if (isAvailable)
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
                              'Watch Ad',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: theme.textPrimary,
                              ),
                            ),
                            Text(
                              'Get a second chance! ($remaining left today)',
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

            // Daily limit reached message
            if (!isAvailable && !StorageService.isAdsFree())
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.accentLight,
                  borderRadius: AppTheme.buttonRadius,
                  border: Border.all(color: theme.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_off, color: theme.textSecondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Limit Reached',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.25,
                              color: theme.textPrimary,
                            ),
                          ),
                          Text(
                            'Second chances reset tomorrow',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Become VIP option
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
                            'Become VIP',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: theme.buttonText,
                            ),
                          ),
                          Text(
                            'Unlimited lives, hints & more!',
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
                        'BEST',
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
              _finalizeGameOver();
            },
            child: Text(
              'Give Up',
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
              const SnackBar(
                content: Text('Please watch the full ad to continue.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.favorite, color: Colors.white),
              SizedBox(width: 8),
              Text('Second chance granted! You have 1 life remaining.'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Finalize game over after user chooses to give up
  void _finalizeGameOver() {
    StorageService.clearCurrentGame();

    ref.read(statisticsProvider.notifier).recordGameLost(
          difficulty: _gameState.difficulty,
          time: _elapsedTime.inSeconds,
        );

    _showCompleteDialog(won: false, score: _gameState.score);
  }

  void _showCompleteDialog({required bool won, required int score}) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              won ? Icons.celebration : Icons.sentiment_dissatisfied,
              color: won ? Colors.amber : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                won ? l10n.congratulations : l10n.gameOver,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? l10n.congratsMessage : l10n.gameOverMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(l10n.score, '$score'),
                  _buildStatRow(l10n.time, _formatTime(_elapsedTime)),
                  _buildStatRow(l10n.mistakes, '${_gameState.mistakes}/3'),
                  if (_secondChancesUsed > 0)
                    _buildStatRow(
                        l10n.secondChanceTitle, '$_secondChancesUsed'),
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
            child: Text(l10n.home),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
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
                _buildTopBar(isDark, textColor),

                // Game info
                _buildGameInfo(isDark, textColor),

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
                    ),
                  ),
                ),

                // Action buttons
                _buildActionButtons(isDark, cardColor, textColor),

                // Number pad
                _buildNumberPad(isDark, cardColor, textColor),

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
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _saveGame();
              Navigator.pop(context);
            },
            icon: Icon(Bootstrap.arrow_left, size: 22.w),
            color: textColor,
          ),
          const Spacer(),
          // Difficulty indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _gameState.difficulty,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: Icon(Bootstrap.gear, size: 22.w),
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo(bool isDark, Color textColor) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mistakes
          _buildInfoItem(
            icon: Bootstrap.x_circle,
            label: l10n.mistakes,
            value: '${_gameState.mistakes}/3',
            color: _gameState.mistakes > 0
                ? Colors.red
                : (isDark ? Colors.grey.shade400 : Colors.grey),
          ),
          // Score with combo indicator
          _buildScoreWithCombo(l10n),
          // Time
          _buildInfoItem(
            icon: Bootstrap.stopwatch,
            label: l10n.time,
            value: _formatTime(_elapsedTime),
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreWithCombo(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final combo = _gameState.comboStreak;
    final multiplier = _getMultiplierForCombo(combo);

    // Color based on combo level (more subtle)
    Color scoreColor = const Color(0xFFFFB300);
    if (multiplier >= 3.0) {
      scoreColor = Colors.deepOrange;
    } else if (multiplier >= 2.0) {
      scoreColor = Colors.orange;
    }

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Bootstrap.star_fill,
              size: 18,
              color: scoreColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${_gameState.score}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.score,
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            // Show milestone badge only when triggered
            if (_showComboMilestone) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_lastMilestoneCombo}x 🔥',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, Color cardColor, Color textColor) {
    final isAdsFree = ref.watch(adsFreeProvider);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Bootstrap.arrow_counterclockwise,
            label: l10n.undo,
            onTap: _onUndo,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
          ),
          _buildActionButton(
            icon: Bootstrap.eraser,
            label: l10n.erase,
            onTap: _onErase,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
          ),
          _buildActionButton(
            icon: Bootstrap.pencil,
            label: l10n.notes,
            onTap: _togglePencilMode,
            isActive: _isPencilMode,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
          ),
          _buildActionButton(
            icon: _fastPencilEnabled
                ? Bootstrap.lightning_charge_fill
                : Bootstrap.lightning_charge,
            label: _fastPencilEnabled ? '${l10n.fast} ON' : l10n.fast,
            onTap: _onFastPencil,
            isActive: _fastPencilEnabled,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            showAdBadge: !_fastPencilEnabled && !isAdsFree,
          ),
          _buildActionButton(
            icon: Bootstrap.lightbulb,
            label: l10n.hint,
            onTap: _onHint,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            showAdBadge:
                !isAdsFree && _gameState.hintsUsed >= AppConstants.maxHints,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isVip = false,
    bool showAdBadge = false,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    // Ranked ile aynı tasarım - sadece küçük turuncu badge
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.gradientStart.withValues(alpha: 0.15)
              : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: AppColors.gradientStart.withValues(alpha: 0.5))
              : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? AppColors.gradientStart
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                if (showAdBadge || isVip)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Bootstrap.play_fill,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: isActive
                    ? AppColors.gradientStart
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          final number = index + 1;
          final remaining = _gameState.getRemainingCount(number);
          final isCompleted = remaining == 0;

          return GestureDetector(
            onTap: isCompleted ? null : () => _onNumberSelected(number),
            child: Container(
              width: 36.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    : cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: (isCompleted || isDark)
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? (isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400)
                          : textColor,
                    ),
                  ),
                  if (!isCompleted)
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
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

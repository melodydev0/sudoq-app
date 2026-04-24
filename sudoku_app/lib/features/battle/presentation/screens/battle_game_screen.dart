import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/haptic_service.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/game_state.dart';
import '../../../../core/models/battle_models.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/battle_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/user_sync_service.dart';
import '../../../../core/services/local_duel_stats_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/celebration_effect.dart';
import '../../../game/presentation/widgets/sudoku_grid.dart';
import '../../../game/presentation/widgets/game_number_pad.dart';
import '../../../game/presentation/widgets/auto_complete_button.dart';
import '../widgets/battle_header.dart';
import '../widgets/battle_countdown_overlay.dart';
import 'battle_result_screen.dart';

/// Data class for celebration effects
class _CelebrationData {
  final int id;
  final Offset position;

  _CelebrationData({required this.id, required this.position});
}

class BattleGameScreen extends StatefulWidget {
  final String battleId;

  const BattleGameScreen({
    super.key,
    required this.battleId,
  });

  @override
  State<BattleGameScreen> createState() => _BattleGameScreenState();
}

class _BattleGameScreenState extends State<BattleGameScreen> {
  BattleRoom? _battle;
  StreamSubscription? _battleSubscription;

  late GameState _gameState;
  int? _selectedRow;
  int? _selectedCol;
  bool _isPencilMode = false;
  bool _isLoading = true;

  Timer? _timer;
  Timer? _botTimer; // Timer for bot progress simulation
  Duration _elapsedTime = Duration.zero;

  // Countdown
  int _countdown = 3;
  bool _isCountingDown = true;

  // Game finished
  bool _isFinished = false;

  // Visual effects - Celebration effects
  final List<_CelebrationData> _celebrations = [];
  final GlobalKey _gridKey = GlobalKey();

  // Completed sections tracking (for row/col/box completion effects)
  final List<CompletedSection> _completedSections = [];
  final Set<String> _previouslyCompleted = {};

  // Auto-complete overlay button
  bool _showAutoCompleteBtn = false;
  Set<int> _droppingCells = {};

  // Board completion effect (shown after auto-complete before navigating)
  bool _showBoardCompletion = false;
  Rect? _boardCompletionRect;

  @override
  void initState() {
    super.initState();
    _initBattle();
  }

  @override
  void dispose() {
    _battleSubscription?.cancel();
    _timer?.cancel();
    _botTimer?.cancel();
    super.dispose();
  }

  void _initBattle() async {
    // Check if this is a local test battle
    final isLocalTest = widget.battleId.startsWith('test_');

    if (isLocalTest) {
      debugPrint('[PlayAI] BattleGameScreen _initBattle: isLocalTest=true');
      final battle = BattleService.getLocalTestBattle();
      debugPrint(
          '[PlayAI] getLocalTestBattle: ${battle != null ? battle.id : "null"}');
      if (battle != null && mounted) {
        _initGameState(battle);
      } else if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).failedToCreateBattle),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        });
      }
      return;
    }

    // For real battles: Listen to battle updates from Firestore
    _battleSubscription =
        BattleService.battleStream(widget.battleId).listen((battle) {
      if (battle != null && mounted) {
        setState(() => _battle = battle);

        // Check if game should start
        if (battle.status == BattleStatus.countdown && _isCountingDown) {
          _startCountdown();
        }

        // Check if game finished
        if (battle.status == BattleStatus.finished && !_isFinished) {
          _onBattleFinished();
        }
      }
    });

    // Get initial battle data
    final battle = await BattleService.getBattle(widget.battleId);
    if (battle != null && mounted) {
      _initGameState(battle);
    }
  }

  void _initGameState(BattleRoom battle) {
    if (battle.puzzle == null || battle.solution == null) return;

    _gameState = GameState(
      puzzle: battle.puzzle!,
      solution: battle.solution!,
      currentGrid: battle.puzzle!.map((row) => List<int>.from(row)).toList(),
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      difficulty: battle.difficulty,
      gridSize: 9,
      score: 0,
    );

    setState(() {
      _battle = battle;
      _isLoading = false;
    });

    // If test battle, skip countdown and start immediately
    if (battle.isTestBattle) {
      setState(() => _isCountingDown = false);
      _startTimer();
      _startBotSimulation();
      SoundService().playGameStart();
    }
  }

  void _startBotSimulation() {
    _scheduleNextBotMove();
  }

  void _scheduleNextBotMove() {
    if (!mounted || _isFinished) return;

    // Get random interval based on AI difficulty
    final intervalSeconds = BattleService.getBotMoveInterval();

    _botTimer?.cancel();
    _botTimer = Timer(Duration(seconds: intervalSeconds), () {
      if (!mounted || _isFinished) return;
      _simulateLocalBotProgress();
      _scheduleNextBotMove(); // Schedule next move with new random interval
    });
  }

  void _simulateLocalBotProgress() {
    if (_battle == null || !_battle!.isTestBattle) return;

    final botPlayer = _battle!.player2;
    if (botPlayer == null) return;

    // Bot makes progress (1 cell per update)
    final currentProgress = botPlayer.progress;
    final currentCorrect = botPlayer.correctCells;

    // Max progress based on AI difficulty:
    // - easy (Rookie): 85% max - user should easily win
    // - medium (Pro): 95% max - user has time pressure
    // - hard (Master): 100% - bot can win!
    final difficulty = BattleService.currentAiDifficulty;
    final maxProgress = switch (difficulty) {
      'easy' => 85,
      'medium' => 95,
      'hard' => 100,
      _ => 90,
    };

    if (currentProgress < maxProgress) {
      final newCorrect = currentCorrect + 1;
      final totalCells = _battle!.totalCells;
      final newProgress =
          totalCells > 0 ? ((newCorrect / totalCells) * 100).round() : 0;

      // Check if bot won (only possible in hard mode)
      if (newProgress >= 100 && difficulty == 'hard') {
        _onBotWins();
        return;
      }

      // Update local battle with new bot progress
      final updatedBot = botPlayer.copyWith(
        progress: newProgress.clamp(0, maxProgress),
        correctCells: newCorrect,
      );

      final updatedBattle = BattleRoom(
        id: _battle!.id,
        status: _battle!.status,
        difficulty: _battle!.difficulty,
        createdAt: _battle!.createdAt,
        startedAt: _battle!.startedAt,
        finishedAt: _battle!.finishedAt,
        player1: _battle!.player1,
        player2: updatedBot,
        puzzle: _battle!.puzzle,
        solution: _battle!.solution,
        winnerId: _battle!.winnerId,
        totalCells: _battle!.totalCells,
        isTestBattle: _battle!.isTestBattle,
      );

      BattleService.updateLocalTestBattle(updatedBattle);
      if (mounted) {
        setState(() => _battle = updatedBattle);
      }
    }
  }

  void _startCountdown() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      HapticService.mediumImpact();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() => _isCountingDown = false);

    // Start the game
    await BattleService.startBattle(widget.battleId);
    _startTimer();
    SoundService().playGameStart();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isFinished) {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);
        });
      }
    });
  }

  void _onCellTap(int row, int col) {
    if (_isCountingDown || _isFinished) return;

    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
    HapticService.selectionClick();
  }

  void _onNumberSelected(int number) {
    if (_isCountingDown || _isFinished) return;
    if (_selectedRow == null || _selectedCol == null) return;
    if (_gameState.isFixedCell(_selectedRow!, _selectedCol!)) return;
    if (_gameState.isConfirmedCorrectCell(_selectedRow!, _selectedCol!)) return;

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

    newGrid[row][col] = number;
    newNotes[row][col].clear();

    final isCorrect = number == _gameState.solution[row][col];
    int newMistakes = _gameState.mistakes;

    if (!isCorrect) {
      newMistakes++;
      HapticService.heavyImpact();
      SoundService().playWrongInput();
    } else {
      // Play correct input sound
      SoundService().playCorrectInput();
      HapticService.mediumImpact();

      // Trigger celebration effect
      _triggerCelebration(row, col);

      // Remove related notes
      _removeRelatedNotes(newNotes, row, col, number);

      // Auto-remove wrong instances of this number in same row/column/box
      _removeWrongDuplicates(newGrid, row, col, number);

      // Check for section completions (row, column, box) and play sounds
      final isGameComplete = _checkCompletion(newGrid);
      if (!isGameComplete) {
        _checkSectionCompletions(newGrid, row, col);
      }
    }

    final newConfirmed = Set<int>.from(_gameState.confirmedCorrectCells);
    if (isCorrect) {
      newConfirmed.add(row * _gameState.gridSize + col);
    }

    setState(() {
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
        mistakes: newMistakes,
        confirmedCorrectCells: newConfirmed,
      );
    });

    // Update progress — force-write immediately on wrong answer so opponent
    // sees the updated mistake count without waiting for the throttle window.
    _updateProgress(forceWrite: !isCorrect);

    // Check if 3 mistakes - game over (lose)
    if (newMistakes >= AppConstants.maxMistakes) {
      _onGameOverByMistakes();
      return;
    }

    // Check if finished
    if (_checkCompletion(newGrid)) {
      _onGameComplete();
    } else {
      _checkAutoComplete();
    }
  }

  /// Remove wrong instances of a number in same row, column, and box
  /// when the correct instance is placed
  void _removeWrongDuplicates(
      List<List<int>> grid, int row, int col, int number) {
    const size = 9;
    const boxSize = 3;

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

  /// Check for completed rows, columns, and boxes - play sounds and add visual effects
  void _checkSectionCompletions(List<List<int>> grid, int row, int col) {
    const size = 9;
    const boxSize = 3;
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
    for (int col = 0; col < 9; col++) {
      if (grid[row][col] != _gameState.solution[row][col]) {
        return false;
      }
    }
    return true;
  }

  bool _isColComplete(List<List<int>> grid, int col) {
    for (int row = 0; row < 9; row++) {
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

  /// Trigger celebration particle effect at cell position
  void _triggerCelebration(int row, int col) {
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final gridPosition = gridBox.localToGlobal(Offset.zero);
    final cellSize = gridBox.size.width / 9;

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

    // Play note sound
    SoundService().playHintFastPencil();
    HapticService.selectionClick();

    setState(() {
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
      );
    });
  }

  void _removeRelatedNotes(
      List<List<Set<int>>> notes, int row, int col, int number) {
    const size = 9;
    const boxSize = 3;

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

  void _updateProgress({bool forceWrite = false}) {
    if (_battle == null) return;

    // Count total cells to fill (empty cells in original puzzle)
    int totalCells = _battle!.totalCells;
    if (totalCells == 0) {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (_gameState.puzzle[r][c] == 0) {
            totalCells++;
          }
        }
      }
    }

    // Only count cells we filled correctly
    int filledCorrectly = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_gameState.puzzle[r][c] == 0 &&
            _gameState.currentGrid[r][c] == _gameState.solution[r][c]) {
          filledCorrectly++;
        }
      }
    }

    final progress =
        totalCells > 0 ? ((filledCorrectly / totalCells) * 100).round() : 0;

    // For test battles, update locally
    if (_battle!.isTestBattle) {
      _updateLocalPlayerProgress(filledCorrectly, progress);
    } else {
      // For real battles, update in Firestore
      BattleService.updateProgress(
        battleId: widget.battleId,
        correctCells: filledCorrectly,
        totalCells: totalCells,
        mistakes: _gameState.mistakes,
        forceWrite: forceWrite,
      );
    }
  }

  void _updateLocalPlayerProgress(int correctCells, int progress) {
    if (_battle == null) return;

    final myPlayer = _battle!.player1;
    if (myPlayer == null) return;

    final updatedPlayer = myPlayer.copyWith(
      correctCells: correctCells,
      progress: progress,
      mistakes: _gameState.mistakes,
    );

    final updatedBattle = BattleRoom(
      id: _battle!.id,
      status: _battle!.status,
      difficulty: _battle!.difficulty,
      createdAt: _battle!.createdAt,
      startedAt: _battle!.startedAt,
      finishedAt: _battle!.finishedAt,
      player1: updatedPlayer,
      player2: _battle!.player2,
      puzzle: _battle!.puzzle,
      solution: _battle!.solution,
      winnerId: _battle!.winnerId,
      totalCells: _battle!.totalCells,
      isTestBattle: _battle!.isTestBattle,
    );

    BattleService.updateLocalTestBattle(updatedBattle);
    if (mounted) {
      setState(() => _battle = updatedBattle);
    }
  }

  bool _checkCompletion(List<List<int>> grid) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] != _gameState.solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  void _checkAutoComplete() {
    if (_isFinished) return;
    int remainingEmpty = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
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
    if (_isFinished) return;

    // Collect empty cells that need filling
    final emptyCells = <(int, int)>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_gameState.puzzle[r][c] == 0 &&
            _gameState.currentGrid[r][c] == 0) {
          emptyCells.add((r, c));
        }
      }
    }

    // Capture grid rect before modifying state
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
      final cellKey = r * 9 + c;

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

  void _onGameComplete({bool skipSound = false}) async {
    setState(() => _isFinished = true);
    _timer?.cancel();
    _botTimer?.cancel();

    if (!skipSound) {
      SoundService().playGameComplete();
      HapticService.heavyImpact();
    }

    if (_battle?.isTestBattle ?? false) {
      // For test battles, go directly to result
      _navigateToResult(won: true);
    } else {
      // For online duels: finishBattle updates Firestore, but the stream guard
      // (!_isFinished) will already be false for the winner, so _onBattleFinished
      // never fires. Navigate directly after finishBattle completes.
      // A timeout prevents a hanging network call from blocking navigation forever.
      try {
        await BattleService.finishBattle(widget.battleId)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Even if finishBattle fails/times out, still navigate to show result
      }
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BattleResultScreen(
                  battleId: widget.battleId,
                  completionTime: _elapsedTime,
                  mistakes: _gameState.mistakes,
                ),
              ),
            );
          }
        });
      }
    }
  }

  void _onBotWins() {
    setState(() => _isFinished = true);
    _timer?.cancel();
    _botTimer?.cancel();

    HapticService.heavyImpact();
    SoundService().playGameLost(); // Loss sound

    // Show bot wins dialog
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.emoji_events, color: theme.warning, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.botWins,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.botWinsMessage,
          style: TextStyle(
            color: theme.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResult(won: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonPrimary,
              foregroundColor: theme.buttonText,
              shape: const RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius),
              elevation: 1,
              shadowColor: theme.textPrimary.withValues(alpha: 0.08),
            ),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _onGameOverByMistakes() {
    setState(() => _isFinished = true);
    _timer?.cancel();
    _botTimer?.cancel();

    HapticService.heavyImpact();
    SoundService().playGameLost();

    // For online battles: immediately notify opponent and set winner in Firestore
    // so the opponent's stream sees status=finished and navigates to the result screen.
    // Fire-and-forget so the dialog appears without delay.
    if (!(_battle?.isTestBattle ?? true)) {
      BattleService.resignBattle(widget.battleId);
    }

    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    // Show game over dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.gameOver,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.youMade3MistakesOpponentWins,
          style: TextStyle(
            color: theme.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResult(won: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonPrimary,
              foregroundColor: theme.buttonText,
              shape: const RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius),
              elevation: 1,
              shadowColor: theme.textPrimary.withValues(alpha: 0.08),
            ),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _navigateToResult({required bool won}) {
    if (!mounted) return;

    // Get ELO change based on AI difficulty
    final aiConfig =
        BattleService.aiDifficulties[BattleService.currentAiDifficulty] ??
            BattleService.aiDifficulties['medium']!;
    final eloWin = aiConfig['eloWin'] as int? ?? 25;
    final eloLoss = aiConfig['eloLoss'] as int? ?? 20;

    // Calculate ELO change to show
    final eloChangeToShow = won ? eloWin : eloLoss;

    // Pre-calculate ELO endpoints to avoid race condition with the microtask
    // that persists to SharedPreferences after navigation.
    final currentElo = LocalDuelStatsService.elo;
    final calculatedNewElo = won
        ? currentElo + eloChangeToShow
        : (currentElo - eloChangeToShow).clamp(0, 9999);

    // Detect rank-up now while we still have the old ELO value
    final oldRank = LocalDuelStatsService.getRankFromElo(currentElo);
    final newRank = LocalDuelStatsService.getRankFromElo(calculatedNewElo);
    final rankUpFrom = (won && oldRank != newRank) ? oldRank : null;
    final rankUpTo = (won && oldRank != newRank) ? newRank : null;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BattleResultScreen(
          battleId: widget.battleId,
          completionTime: _elapsedTime,
          mistakes: _gameState.mistakes,
          forcedResult: won ? 'win' : 'lose',
          eloChange: eloChangeToShow,
          startElo: currentElo,
          newElo: calculatedNewElo,
          rankUpFrom: rankUpFrom,
          rankUpTo: rankUpTo,
        ),
      ),
    );

    // Record stats in background (non-blocking)
    Future.microtask(() async {
      if (won) {
        await LocalDuelStatsService.recordWin(eloWin);
      } else {
        await LocalDuelStatsService.recordLoss(eloLoss);
      }
      // Cloud sync in background
      UserSyncService.syncToCloud();
    });
  }

  void _onBattleFinished() {
    setState(() => _isFinished = true);
    _timer?.cancel();

    // Update this player's stats (they are the loser — the winner's stats are
    // already updated on the winner's device inside _checkBattleEnd).
    BattleService.updateMyBattleStats(widget.battleId);

    // Navigate to result screen
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BattleResultScreen(
              battleId: widget.battleId,
              completionTime: _elapsedTime,
              mistakes: _gameState.mistakes,
            ),
          ),
        );
      }
    });
  }

  void _onUndo() {
    // Simplified undo - just clear selected cell
    if (_selectedRow == null || _selectedCol == null) return;
    if (_gameState.isFixedCell(_selectedRow!, _selectedCol!)) return;
    if (_gameState.isConfirmedCorrectCell(_selectedRow!, _selectedCol!)) return;

    final row = _selectedRow!;
    final col = _selectedCol!;

    final newGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();
    newGrid[row][col] = 0;

    setState(() {
      _gameState = _gameState.copyWith(currentGrid: newGrid);
    });

    HapticService.lightImpact();
  }

  void _onErase() {
    if (_selectedRow == null || _selectedCol == null) return;
    if (_gameState.isFixedCell(_selectedRow!, _selectedCol!)) return;
    if (_gameState.isConfirmedCorrectCell(_selectedRow!, _selectedCol!)) return;

    final row = _selectedRow!;
    final col = _selectedCol!;

    final newGrid =
        _gameState.currentGrid.map((r) => List<int>.from(r)).toList();
    final newNotes = _gameState.notes
        .map((r) => r.map((c) => Set<int>.from(c)).toList())
        .toList();

    newGrid[row][col] = 0;
    newNotes[row][col].clear();

    setState(() {
      _gameState = _gameState.copyWith(
        currentGrid: newGrid,
        notes: newNotes,
      );
    });

    HapticService.lightImpact();
  }

  void _showResignDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemeManager.colors;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      // Use an explicit fade-only transition. The default Material dialog
      // transition combines a scale + clip which, together with our rounded
      // AlertDialog, produces a triangular "folded-corner" artifact on some
      // Android devices (MIUI / Android 14+). A pure fade avoids that clip
      // race.
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: AppTheme.buttonRadius,
              ),
              child: const Icon(Icons.flag, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.resignConfirm,
              style: TextStyle(color: theme.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          l10n.resignDescription,
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Delay to let dismiss animation finish before navigating
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) _resign();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius),
            ),
            child: Text(l10n.resignButton),
          ),
        ],
      ),
    );
  }

  void _resign() async {
    setState(() => _isFinished = true);
    _timer?.cancel();
    _botTimer?.cancel();

    // For online battles, notify server
    if (!(_battle?.isTestBattle ?? true)) {
      await BattleService.resignBattle(widget.battleId);
    }

    // Navigate to result as loss
    _navigateToResult(won: false);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    final l10n = AppLocalizations.of(context);

    if (_isLoading || _battle == null) {
      return Scaffold(
        backgroundColor: theme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isTestBattle = _battle!.isTestBattle;
    final myBattlePlayer = isTestBattle
        ? _battle!.player1
        : _battle!.getSelf(AuthService.userId ?? '');
    final opponentBattlePlayer = isTestBattle
        ? _battle!.player2
        : _battle!.getOpponent(AuthService.userId ?? '');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showResignDialog();
      },
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header with players info and progress
                  BattleHeader(
                    myPlayer: BattlePlayerInfo(
                      displayName: AuthService.displayName,
                      photoUrl: AuthService.photoUrl,
                      equippedFrame: myBattlePlayer?.equippedFrame,
                      countryCode: myBattlePlayer?.countryCode,
                      avatarAsset: myBattlePlayer?.avatarAsset,
                      mistakes: _gameState.mistakes,
                      progress: myBattlePlayer?.progress ?? 0,
                    ),
                    opponent: BattlePlayerInfo(
                      displayName:
                          opponentBattlePlayer?.displayName ?? l10n.opponent,
                      photoUrl: opponentBattlePlayer?.photoUrl,
                      equippedFrame: opponentBattlePlayer?.equippedFrame,
                      countryCode: opponentBattlePlayer?.countryCode,
                      avatarAsset: opponentBattlePlayer?.avatarAsset,
                      mistakes: opponentBattlePlayer?.mistakes ?? 0,
                      progress: opponentBattlePlayer?.progress ?? 0,
                    ),
                    score: _calculateScore(),
                    elapsedTime: _elapsedTime,
                    onResign: _showResignDialog,
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
                  _buildActionButtons(theme),

                  // Number pad
                  GameNumberPad(
                    isDark: theme.isDark,
                    cardColor: theme.card,
                    textColor: theme.textPrimary,
                    remainingCounts: {
                      for (var i = 1; i <= 9; i++)
                        i: _gameState.getRemainingCount(i),
                    },
                    onNumberSelected: _onNumberSelected,
                  ),

                  // Banner ad space
                  Container(
                    height: 60,
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: AdsService.shouldShowAds()
                        ? AdsService.getBannerAdWidget()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Countdown overlay
            if (_isCountingDown) BattleCountdownOverlay(countdown: _countdown),

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

            // Board completion sweep effect (after auto-complete, before result)
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
      ),
    );
  }

  // Calculate score based on correct cells and time
  int _calculateScore() {
    int correctCells = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_gameState.puzzle[r][c] == 0 &&
            _gameState.currentGrid[r][c] == _gameState.solution[r][c]) {
          correctCells++;
        }
      }
    }
    // Score formula: correct cells * 100 + time bonus
    return correctCells * 100;
  }

  Widget _buildActionButtons(AppThemeColors theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Bootstrap.arrow_counterclockwise,
            label: l10n.undo,
            onTap: _onUndo,
            theme: theme,
          ),
          _buildActionButton(
            icon: Bootstrap.eraser,
            label: l10n.erase,
            onTap: _onErase,
            theme: theme,
          ),
          _buildActionButton(
            icon: Bootstrap.pencil,
            label: l10n.notes,
            onTap: () => setState(() => _isPencilMode = !_isPencilMode),
            theme: theme,
            isActive: _isPencilMode,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppThemeColors theme,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.gradientStart.withValues(alpha: 0.15)
              : theme.card,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: AppColors.gradientStart.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.gradientStart : theme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: isActive ? AppColors.gradientStart : theme.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

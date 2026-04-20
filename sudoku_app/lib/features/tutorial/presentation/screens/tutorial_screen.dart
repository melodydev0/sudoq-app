import 'package:flutter/material.dart';
import 'package:sudoku_app/core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_manager.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive_utils.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _handController;
  late AnimationController _pulseController;
  late AnimationController _highlightController;
  late AnimationController _successController;

  // Tutorial grid state
  List<List<int>> _grid = [];
  int? _selectedRow;
  int? _selectedCol;
  bool _isPencilMode = false;
  List<List<Set<int>>> _notes = [];

  // Tutorial step tracking for each page
  int _page2Step = 0; // 0: tap cell, 1: tap number, 2: done
  int _page3Step = 0; // 0: tap pencil, 1: tap cell, 2: tap number, 3: done
  int _page4Step = 0; // 0: tap cell, 1: tap hint, 2: done

  @override
  void initState() {
    super.initState();
    _initGrid();
    _initAnimations();
  }

  void _initGrid() {
    _grid = [
      [0, 2, 3, 0, 0, 9, 0, 0, 0],
      [0, 0, 0, 0, 8, 0, 0, 3, 0],
      [5, 0, 0, 0, 0, 6, 4, 0, 0],
      [0, 0, 6, 0, 0, 0, 5, 0, 0],
      [0, 9, 6, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 3, 0, 6],
      [0, 8, 0, 0, 0, 0, 9, 0, 0],
      [0, 0, 0, 6, 0, 7, 0, 0, 0],
      [6, 0, 0, 4, 1, 0, 0, 0, 0],
    ];

    _notes = List.generate(
      9,
      (_) => List.generate(9, (_) => <int>{}),
    );
  }

  void _initAnimations() {
    _handController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  void _resetPageState() {
    setState(() {
      _selectedRow = null;
      _selectedCol = null;
      _isPencilMode = false;
      _page2Step = 0;
      _page3Step = 0;
      _page4Step = 0;
      _initGrid();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _handController.dispose();
    _pulseController.dispose();
    _highlightController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onCellTap(int row, int col) {
    HapticService.lightImpact();

    if (_currentPage == 1) {
      // Page 2: Tap to Place
      if (_page2Step == 0 && row == 3 && col == 3) {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
          _page2Step = 1;
        });
      }
    } else if (_currentPage == 2) {
      // Page 3: Pencil Mode
      if (_page3Step == 1 && row == 2 && col == 3) {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
          _page3Step = 2;
        });
      }
    } else if (_currentPage == 3) {
      // Page 4: Hints
      if (_page4Step == 0 && row == 3 && col == 3) {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
          _page4Step = 1;
        });
      }
    }
  }

  void _onNumberTap(int number) {
    HapticService.mediumImpact();

    if (_currentPage == 1 && _page2Step == 1) {
      // Page 2: Place number
      if (number == 7 && _selectedRow != null && _selectedCol != null) {
        setState(() {
          _grid[_selectedRow!][_selectedCol!] = number;
          _page2Step = 2;
        });
        _successController.forward(from: 0);
      }
    } else if (_currentPage == 2 && _page3Step == 2) {
      // Page 3: Add pencil note
      if (_selectedRow != null && _selectedCol != null && _isPencilMode) {
        setState(() {
          if (_notes[_selectedRow!][_selectedCol!].contains(number)) {
            _notes[_selectedRow!][_selectedCol!].remove(number);
          } else {
            _notes[_selectedRow!][_selectedCol!].add(number);
          }
          if (_notes[_selectedRow!][_selectedCol!].length >= 2) {
            _page3Step = 3;
            _successController.forward(from: 0);
          }
        });
      }
    }
  }

  void _onPencilTap() {
    HapticService.lightImpact();

    if (_currentPage == 2 && _page3Step == 0) {
      setState(() {
        _isPencilMode = true;
        _page3Step = 1;
      });
    }
  }

  void _onHintTap() {
    HapticService.mediumImpact();

    if (_currentPage == 3 && _page4Step == 1) {
      setState(() {
        _grid[_selectedRow!][_selectedCol!] = 2; // Reveal hint
        _page4Step = 2;
      });
      _successController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final theme = AppThemeManager.colors;
    return Scaffold(
      backgroundColor: theme.backgroundGradientStart,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _resetPageState();
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            l10n.howToPlay,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gradientStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1}/4',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.gradientStart,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 1: Basic Rules
  Widget _buildPage1() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: _buildTutorialGrid(
              highlightRow: 2,
              showRowHighlight: true,
              interactive: false,
            ),
          ),
          const SizedBox(height: 8),
          _buildMiniInstructionCard(
            l10n.fillTheGrid,
            l10n.eachRowColumn,
            false,
          ),
          const SizedBox(height: 8),
          _buildCompactRuleItem('1', l10n.rows19, Icons.arrow_forward_rounded),
          _buildCompactRuleItem(
              '2', l10n.columns19, Icons.arrow_downward_rounded),
          _buildCompactRuleItem('3', l10n.boxes19, Icons.crop_square_rounded),
        ],
      ),
    );
  }

  Widget _buildCompactRuleItem(String number, String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.gradientStart.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gradientStart,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(icon, color: AppColors.gradientStart, size: 16),
        ],
      ),
    );
  }

  // Page 2: Tap and Place - INTERACTIVE
  Widget _buildPage2() {
    final l10n = AppLocalizations.of(context);
    const targetRow = 3;
    const targetCol = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: _buildTutorialGrid(
              highlightRow: targetRow,
              highlightCol: targetCol,
              showCellHighlight: true,
              interactive: true,
              targetRow: targetRow,
              targetCol: targetCol,
            ),
          ),
          const SizedBox(height: 8),
          _buildInteractiveNumberPad(
            highlightNumber: _page2Step == 1 ? 7 : null,
            enabled: _page2Step == 1,
          ),
          const SizedBox(height: 8),
          _buildMiniInstructionCard(
            _page2Step == 2 ? l10n.perfect : l10n.tapToPlace,
            _page2Step == 2 ? l10n.greatJob : l10n.tapHighlightedCellThen7,
            _page2Step == 2,
          ),
        ],
      ),
    );
  }

  // Page 3: Pencil Mode - INTERACTIVE
  Widget _buildPage3() {
    final l10n = AppLocalizations.of(context);
    const targetRow = 2;
    const targetCol = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: _buildTutorialGrid(
              highlightRow: targetRow,
              highlightCol: targetCol,
              showCellHighlight: _page3Step >= 1,
              showPencilNotes: true,
              interactive: _page3Step >= 1,
              targetRow: targetRow,
              targetCol: targetCol,
            ),
          ),
          const SizedBox(height: 8),
          _buildInteractiveActionButtons(
            highlightPencil: _page3Step == 0,
            pencilEnabled: _page3Step == 0,
          ),
          const SizedBox(height: 8),
          _buildInteractiveNumberPad(
            highlightNumber: _page3Step == 2 ? 1 : null,
            enabled: _page3Step == 2,
          ),
          const SizedBox(height: 8),
          _buildMiniInstructionCard(
            _page3Step == 3 ? l10n.excellent : l10n.pencilModeTitle,
            _page3Step == 0
                ? l10n.tapPencilButton
                : _page3Step == 1
                    ? l10n.tapTheHighlightedCell
                    : _page3Step == 2
                        ? l10n.addNotes127
                        : l10n.youveMasteredNotes,
            _page3Step == 3,
          ),
        ],
      ),
    );
  }

  // Page 4: Hints - INTERACTIVE
  Widget _buildPage4() {
    final l10n = AppLocalizations.of(context);
    const targetRow = 3;
    const targetCol = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: _buildTutorialGrid(
              highlightRow: targetRow,
              highlightCol: targetCol,
              showCellHighlight: true,
              interactive: _page4Step == 0,
              targetRow: targetRow,
              targetCol: targetCol,
            ),
          ),
          const SizedBox(height: 8),
          _buildInteractiveActionButtons(
            highlightHint: _page4Step == 1,
            hintEnabled: _page4Step == 1,
          ),
          const SizedBox(height: 8),
          _buildInteractiveNumberPad(enabled: false),
          const SizedBox(height: 8),
          _buildMiniInstructionCard(
            _page4Step == 2 ? l10n.youreReady : l10n.useHintsTitle,
            _page4Step == 0
                ? l10n.tapTheHighlightedCell
                : _page4Step == 1
                    ? l10n.nowTapHintButton
                    : l10n.tutorialCompleteMsg,
            _page4Step == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialGrid({
    int? highlightRow,
    int? highlightCol,
    bool showRowHighlight = false,
    bool showCellHighlight = false,
    bool showPencilNotes = false,
    bool interactive = false,
    int? targetRow,
    int? targetCol,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            final row = index ~/ 9;
            final col = index % 9;
            final value = _grid[row][col];
            final notes = _notes[row][col];

            bool isHighlighted = showRowHighlight && row == highlightRow;
            bool isCellHighlighted =
                showCellHighlight && row == highlightRow && col == highlightCol;
            bool isSelected = _selectedRow == row && _selectedCol == col;
            bool isTarget = row == targetRow && col == targetCol;

            return GestureDetector(
              onTap: interactive && isTarget && value == 0
                  ? () => _onCellTap(row, col)
                  : null,
              child: AnimatedBuilder(
                animation: _highlightController,
                builder: (context, child) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: (col + 1) % 3 == 0 && col != 8 ? 2 : 0.5,
                      bottom: (row + 1) % 3 == 0 && row != 8 ? 2 : 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gradientStart.withValues(alpha: 0.3)
                          : (isCellHighlighted && interactive)
                              ? AppColors.gradientStart.withValues(
                                  alpha:
                                      0.15 + _highlightController.value * 0.1,
                                )
                              : isHighlighted
                                  ? AppColors.gradientStart
                                      .withValues(alpha: 0.08)
                                  : Colors.white,
                      border: Border.all(
                        color: isSelected || (isCellHighlighted && interactive)
                            ? AppColors.gradientStart
                            : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected || (isCellHighlighted && interactive)
                            ? 2
                            : 0.5,
                      ),
                    ),
                    child: Center(
                      child: showPencilNotes && notes.isNotEmpty
                          ? _buildPencilNotes(notes)
                          : Text(
                              value == 0 ? '' : '$value',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: value == 0
                                    ? Colors.transparent
                                    : AppColors.textPrimary,
                              ),
                            ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPencilNotes(Set<int> notes) {
    final sortedNotes = notes.toList()..sort();
    return Wrap(
      alignment: WrapAlignment.center,
      children: sortedNotes.map((n) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.gradientStart,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractiveNumberPad(
      {int? highlightNumber, bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          final number = index + 1;
          final isHighlighted = number == highlightNumber;

          return GestureDetector(
            onTap: enabled ? () => _onNumberTap(number) : null,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isHighlighted
                          ? AppColors.gradientStart.withValues(
                              alpha: 0.5 + _pulseController.value * 0.5,
                            )
                          : Colors.grey.withValues(alpha: 0.2),
                      width: isHighlighted ? 2 : 1,
                    ),
                    boxShadow: isHighlighted
                        ? [
                            BoxShadow(
                              color: AppColors.gradientStart.withValues(
                                alpha: 0.3 + _pulseController.value * 0.2,
                              ),
                              blurRadius: 12,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: isHighlighted
                              ? AppColors.gradientStart
                              : enabled
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${9 - index}',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInteractiveActionButtons({
    bool highlightPencil = false,
    bool highlightHint = false,
    bool pencilEnabled = false,
    bool hintEnabled = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.undo_rounded, 'Undo', false, false),
        _buildActionButton(Icons.auto_fix_off_rounded, 'Erase', false, false),
        _buildActionButton(
          Icons.edit_rounded,
          'Pencil',
          highlightPencil,
          pencilEnabled,
          showBadge: _isPencilMode,
          badgeText: 'ON',
          onTap: pencilEnabled ? _onPencilTap : null,
        ),
        _buildActionButton(
          Icons.lightbulb_outline_rounded,
          'Hint',
          highlightHint,
          hintEnabled,
          showBadge: true,
          badgeText: '3',
          onTap: hintEnabled ? _onHintTap : null,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    bool isHighlighted,
    bool enabled, {
    bool showBadge = false,
    String badgeText = '',
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? AppColors.gradientStart.withValues(
                              alpha: 0.15 + _pulseController.value * 0.1,
                            )
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHighlighted
                            ? AppColors.gradientStart
                            : Colors.grey.withValues(alpha: 0.2),
                        width: isHighlighted ? 2 : 1,
                      ),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: AppColors.gradientStart.withValues(
                                  alpha: 0.3 + _pulseController.value * 0.1,
                                ),
                                blurRadius: 15,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isHighlighted
                          ? AppColors.gradientStart
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlighted || _isPencilMode
                              ? AppColors.gradientStart
                              : AppColors.accentCoral,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                  color: isHighlighted
                      ? AppColors.gradientStart
                      : AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniInstructionCard(
      String title, String description, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.touch_app,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _previousPage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.gradientStart
                        : AppColors.gradientStart.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _nextPage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gradientStart.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _currentPage == 3
                        ? AppLocalizations.of(context).ok
                        : AppLocalizations.of(context).next,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

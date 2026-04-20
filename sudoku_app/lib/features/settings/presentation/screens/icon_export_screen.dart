import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/game_icons.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/models/cosmetic_rewards.dart';
import '../../../../core/models/achievement.dart';
import '../../../../core/models/level_system.dart';

class _ExportItem {
  final String id;
  final String outputPath;
  final Widget Function(double size) buildWidget;
  final bool isAsync;

  const _ExportItem({
    required this.id,
    required this.outputPath,
    required this.buildWidget,
    this.isAsync = false,
  });
}

class IconExportScreen extends StatefulWidget {
  const IconExportScreen({super.key});

  @override
  State<IconExportScreen> createState() => _IconExportScreenState();
}

class _IconExportScreenState extends State<IconExportScreen> {
  final Map<String, GlobalKey> _iconKeys = {};
  bool _exporting = false;
  String _status = 'Tap "Export All" to start. Scroll down to load all icons first!';
  int _exportedCount = 0;
  late final List<_ExportItem> _items;

  static const double _renderSize = 200;

  @override
  void initState() {
    super.initState();
    _items = _buildAllItems();
    for (var item in _items) {
      _iconKeys[item.id] = GlobalKey();
    }
  }

  List<_ExportItem> _buildAllItems() {
    final items = <_ExportItem>[];

    for (var frame in CosmeticRewards.frames) {
      items.add(_ExportItem(
        id: frame.id,
        outputPath: 'assets/frames/${frame.id}.png',
        buildWidget: (size) => _buildFrameIcon(frame, size),
      ));
    }
    for (var frame in CosmeticRewards.rankedFrames) {
      items.add(_ExportItem(
        id: frame.id,
        outputPath: 'assets/frames/${frame.id}.png',
        buildWidget: (size) => _buildFrameIcon(frame, size),
      ));
    }

    for (var effect in CosmeticRewards.effects) {
      items.add(_ExportItem(
        id: effect.id,
        outputPath: 'assets/effects/${effect.id}.png',
        buildWidget: (size) => _buildEffectIcon(effect, size),
      ));
    }

    for (var theme in CosmeticRewards.themes) {
      items.add(_ExportItem(
        id: theme.id,
        outputPath: 'assets/themes/${theme.id}.png',
        buildWidget: (size) => _buildThemePreview(theme, size),
      ));
    }
    for (var theme in CosmeticRewards.rankedThemes) {
      items.add(_ExportItem(
        id: theme.id,
        outputPath: 'assets/themes/${theme.id}.png',
        buildWidget: (size) => _buildThemePreview(theme, size),
      ));
    }

    final monthlyIcons = {
      1: (GameIcons.frozen_orb, [const Color(0xFF667eea), const Color(0xFF764ba2)]),
      2: (GameIcons.glass_heart, [const Color(0xFFf093fb), const Color(0xFFf5576c)]),
      3: (GameIcons.vine_flower, [const Color(0xFF11998e), const Color(0xFF38ef7d)]),
      4: (GameIcons.cut_diamond, [const Color(0xFF4facfe), const Color(0xFF00f2fe)]),
      5: (GameIcons.lotus_flower, [const Color(0xFFfa709a), const Color(0xFFfee140)]),
      6: (GameIcons.sun, [const Color(0xFFf6d365), const Color(0xFFfda085)]),
      7: (GameIcons.trophy, [const Color(0xFFFFD700), const Color(0xFFFF8C00)]),
      8: (GameIcons.crown, [const Color(0xFFf5af19), const Color(0xFFf12711)]),
      9: (GameIcons.falling_leaf, [const Color(0xFFee9ca7), const Color(0xFFffdde1)]),
      10: (GameIcons.spectre, [const Color(0xFFff9a44), const Color(0xFFfc6076)]),
      11: (GameIcons.flame, [const Color(0xFFd299c2), const Color(0xFFfef9d7)]),
      12: (GameIcons.snowflake_1, [const Color(0xFF667eea), const Color(0xFF764ba2)]),
    };
    final monthNames = ['january', 'february', 'march', 'april', 'may', 'june',
                        'july', 'august', 'september', 'october', 'november', 'december'];
    monthlyIcons.forEach((month, data) {
      final (icon, colors) = data;
      items.add(_ExportItem(
        id: 'badge_${monthNames[month - 1]}',
        outputPath: 'assets/badges/monthly/badge_${monthNames[month - 1]}.png',
        buildWidget: (size) => _buildMonthlyBadge(icon, colors, size),
        isAsync: true,
      ));
    });

    final profileBadges = {
      'badge_early_bird': ('🐦', [Colors.orange, Colors.deepOrange]),
      'badge_week_warrior': ('⚔️', [Colors.blue, Colors.indigo]),
      'badge_puzzle_master': ('🧩', [Colors.purple, Colors.deepPurple]),
      'badge_legend': ('🌟', [Colors.amber, Colors.orange]),
      'badge_champion': ('🏆', [Colors.pink, Colors.red]),
    };
    profileBadges.forEach((id, data) {
      final (emoji, colors) = data;
      items.add(_ExportItem(
        id: id,
        outputPath: 'assets/badges/profile/$id.png',
        buildWidget: (size) => _buildProfileBadge(emoji, colors, size),
      ));
    });

    // === RANKS ===
    for (var rank in RankInfo.ranks) {
      final name = rank.rank.name;
      items.add(_ExportItem(
        id: 'rank_$name',
        outputPath: rank.imagePath ?? 'assets/ranks/$name.png',
        buildWidget: (size) => _buildEmojiCircle(rank.icon, [const Color(0xFF5C6BC0), const Color(0xFF3F51B5)], size),
      ));
    }

    // === DUEL DIVISIONS ===
    final divisions = {
      'bronze': ('🥉', [const Color(0xFFCD7F32), const Color(0xFF8B4513)]),
      'silver': ('🥈', [const Color(0xFFC0C0C0), const Color(0xFF808080)]),
      'gold': ('🥇', [const Color(0xFFFFD700), const Color(0xFFDAA520)]),
      'platinum': ('💎', [const Color(0xFFE5E4E2), const Color(0xFFB4B4B4)]),
      'diamond': ('💠', [const Color(0xFF00BFFF), const Color(0xFF1E90FF)]),
      'master': ('🏆', [const Color(0xFFFFD700), const Color(0xFFFFA500)]),
      'grandmaster': ('👑', [const Color(0xFF9400D3), const Color(0xFF8A2BE2)]),
      'champion': ('🔥', [const Color(0xFFFF4500), const Color(0xFFFF6347)]),
      'default': ('🎮', [const Color(0xFF607D8B), const Color(0xFF455A64)]),
    };
    divisions.forEach((id, data) {
      final (emoji, colors) = data;
      items.add(_ExportItem(
        id: 'division_$id',
        outputPath: 'assets/divisions/$id.png',
        buildWidget: (size) => _buildEmojiCircle(emoji, colors, size),
      ));
    });

    // === LEADERBOARD MEDALS ===
    final medals = {
      'gold': ('🥇', [const Color(0xFFFFD700), const Color(0xFFFFA000)]),
      'silver': ('🥈', [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]),
      'bronze': ('🥉', [const Color(0xFFCD7F32), const Color(0xFF8B4513)]),
    };
    medals.forEach((id, data) {
      final (emoji, colors) = data;
      items.add(_ExportItem(
        id: 'medal_$id',
        outputPath: 'assets/medals/$id.png',
        buildWidget: (size) => _buildEmojiCircle(emoji, colors, size),
      ));
    });

    // === DIFFICULTY ICONS ===
    final difficulties = {
      'easy': (Bootstrap.emoji_smile_fill, [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]),
      'medium': (Bootstrap.emoji_neutral_fill, [const Color(0xFFFF9800), const Color(0xFFF57C00)]),
      'hard': (Bootstrap.emoji_frown_fill, [const Color(0xFFF44336), const Color(0xFFD32F2F)]),
      'expert': (Bootstrap.lightning_charge_fill, [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)]),
    };
    difficulties.forEach((id, data) {
      final (icon, colors) = data;
      items.add(_ExportItem(
        id: 'difficulty_$id',
        outputPath: 'assets/difficulty/$id.png',
        buildWidget: (size) => _buildIconCircle(icon, colors, size),
      ));
    });

    // === ACHIEVEMENTS ===
    final achievementList = Achievements.getDefaultAchievements();
    for (var achievement in achievementList) {
      items.add(_ExportItem(
        id: 'ach_${achievement.id}',
        outputPath: 'assets/achievements/${achievement.id}.png',
        buildWidget: (size) => _buildEmojiCircle(
          achievement.icon,
          [achievement.color, achievement.color.withValues(alpha: 0.7)],
          size,
        ),
      ));
    }

    return items;
  }

  Widget _buildGradientIcon(IconData icon, List<Color> colors, double size) {
    final safeColors = colors.length < 2
        ? [colors.first, colors.first]
        : colors;
    final colorStops = safeColors.length == 2
        ? null
        : List<double>.generate(
            safeColors.length,
            (i) => i / (safeColors.length - 1),
          );
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: size,
            foreground: Paint()
              ..shader = ui.Gradient.linear(
                Offset.zero,
                Offset(size, size),
                safeColors,
                colorStops,
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrameIcon(FrameReward frame, double size) {
    return _buildGradientIcon(
      frame.iconData ?? Icons.star,
      frame.gradientColors,
      size,
    );
  }

  Widget _buildEffectIcon(EffectReward effect, double size) {
    return _buildGradientIcon(
      effect.iconData ?? Icons.auto_awesome,
      [
        effect.primaryColor ?? Colors.amber,
        effect.secondaryColor ?? Colors.orange,
      ],
      size,
    );
  }

  Widget _buildThemePreview(ThemeReward theme, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          _forceEmojiPresentation(theme.previewAsset),
          style: _emojiStyle.copyWith(fontSize: size),
        ),
      ),
    );
  }

  Widget _buildMonthlyBadge(String iconStr, List<Color> colors, double size) {
    final safeColors = colors.length < 2
        ? [colors.first, colors.first]
        : colors;
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: safeColors,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Iconify(iconStr, size: size, color: Colors.white),
        ),
      ),
    );
  }

  static String _forceEmojiPresentation(String emoji) {
    if (emoji.isEmpty) return emoji;
    if (emoji.endsWith('\uFE0F')) return emoji;
    return '$emoji\uFE0F';
  }

  static const _emojiStyle = TextStyle(
    fontFamily: 'Segoe UI Emoji',
    fontFamilyFallback: ['Noto Color Emoji', 'Apple Color Emoji'],
  );

  Widget _buildProfileBadge(String emoji, List<Color> colors, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          _forceEmojiPresentation(emoji),
          style: _emojiStyle.copyWith(fontSize: size),
        ),
      ),
    );
  }

  Widget _buildEmojiCircle(String emoji, List<Color> colors, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          _forceEmojiPresentation(emoji),
          style: _emojiStyle.copyWith(fontSize: size),
        ),
      ),
    );
  }

  Widget _buildIconCircle(IconData icon, List<Color> colors, double size) {
    return _buildGradientIcon(icon, colors, size);
  }

  Future<void> _waitForPaint() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final completer = Future<void>.delayed(Duration.zero);
    await completer;
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<bool> _captureAndSave(String id, String outputPath) async {
    final key = _iconKeys[id];
    if (key == null) return false;

    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return false;

    if (boundary.debugNeedsPaint) {
      await _waitForPaint();
    }

    final ro = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (ro == null || ro.debugNeedsPaint) return false;

    final image = await ro.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return false;

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return true;
  }

  Future<void> _exportAll() async {
    setState(() {
      _exporting = true;
      _exportedCount = 0;
      _status = 'Waiting for all icons to render...';
    });

    // Wait for all Iconify SVGs to load and render
    await Future.delayed(const Duration(seconds: 3));
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 500));

    int success = 0;
    int failed = 0;
    final failedIds = <String>[];

    for (var item in _items) {
      try {
        if (item.isAsync) {
          await _waitForPaint();
        }

        final ok = await _captureAndSave(item.id, item.outputPath);
        if (ok) {
          success++;
        } else {
          failed++;
          failedIds.add(item.id);
        }

        setState(() {
          _exportedCount = success + failed;
          _status = 'Processing: ${item.id} ($success ok, $failed failed / ${_items.length})';
        });

        await Future.delayed(Duration(milliseconds: item.isAsync ? 200 : 50));
      } catch (e) {
        debugPrint('Failed to export ${item.id}: $e');
        failed++;
        failedIds.add(item.id);
      }
    }

    // Retry failed items once more after a long delay
    if (failedIds.isNotEmpty) {
      setState(() {
        _status = 'Retrying ${failedIds.length} failed items...';
      });
      await Future.delayed(const Duration(seconds: 2));
      await SchedulerBinding.instance.endOfFrame;
      await Future.delayed(const Duration(seconds: 1));

      for (var id in List<String>.from(failedIds)) {
        final item = _items.firstWhere((i) => i.id == id);
        try {
          final ok = await _captureAndSave(item.id, item.outputPath);
          if (ok) {
            success++;
            failed--;
            failedIds.remove(id);
          }
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (_) {}
      }
    }

    setState(() {
      _exporting = false;
      _status = failedIds.isEmpty
          ? 'Done! All $success icons exported successfully!'
          : 'Done! $success exported, $failed failed: ${failedIds.join(", ")}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text('Icon Export Tool (${_items.length} icons)'),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        actions: [
          if (_exporting)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.amber,
                  value: _items.isNotEmpty ? _exportedCount / _items.length : null,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _exportAll,
              icon: const Icon(Icons.save_alt, color: Colors.amber),
              label: const Text('Export All', style: TextStyle(color: Colors.amber)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _exporting ? Colors.blue.shade900 : Colors.green.shade900,
            child: Text(
              _status,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            // SingleChildScrollView + Wrap ensures ALL widgets are built (not lazy)
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _items.map((item) {
                  return SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: FittedBox(
                            child: RepaintBoundary(
                              key: _iconKeys[item.id],
                              child: item.buildWidget(_renderSize),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.id,
                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

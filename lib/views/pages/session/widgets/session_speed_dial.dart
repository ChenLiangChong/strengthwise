// ✅ v3.1: Session Mode 展開式 FAB（圓形動畫版 - UI/UX Pro Max 優化）
import 'package:flutter/material.dart';

/// Session Mode 快速功能按鈕
///
/// 圓形散開動畫，點擊 FAB 後向上展開：
/// - 📷 照相
/// - ✏️ 繪圖（展開子選單）
/// - 🏋️ 新增動作
///
/// UI/UX Pro Max 遵循：
/// - 動畫 150-300ms
/// - 觸控目標 >= 44px
/// - 觸控間距 >= 8px
/// - 支持 Reduced Motion
class SessionSpeedDial extends StatefulWidget {
  /// 照相回調
  final VoidCallback onPhoto;

  /// 繪圖回調（傳入模板類型）
  final void Function(String templateType) onDrawing;

  /// 新增動作回調
  final VoidCallback onAddExercise;

  /// 是否顯示新增動作按鈕
  final bool showAddExercise;

  const SessionSpeedDial({
    super.key,
    required this.onPhoto,
    required this.onDrawing,
    required this.onAddExercise,
    this.showAddExercise = true,
  });

  @override
  State<SessionSpeedDial> createState() => _SessionSpeedDialState();
}

class _SessionSpeedDialState extends State<SessionSpeedDial>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  bool _isDrawingExpanded = false;

  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // UI/UX: 150-300ms
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut, // UI/UX: ease-out for entering
      reverseCurve: Curves.easeIn, // UI/UX: ease-in for exiting
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _isDrawingExpanded = false;
        _controller.reverse();
      }
    });
  }

  void _close() {
    setState(() {
      _isOpen = false;
      _isDrawingExpanded = false;
      _controller.reverse();
    });
  }

  void _toggleDrawing() {
    setState(() {
      _isDrawingExpanded = !_isDrawingExpanded;
    });
  }

  /// 檢查是否應該減少動畫
  bool get _shouldReduceMotion {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = _shouldReduceMotion;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 繪圖子選單
        AnimatedSize(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 150),
          child: _isDrawingExpanded
              ? _buildDrawingSubMenu(colorScheme, reduceMotion)
              : const SizedBox.shrink(),
        ),

        // 主選項列表
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 新增動作
                if (widget.showAddExercise)
                  _buildAnimatedFabItem(
                    index: 2,
                    icon: Icons.fitness_center,
                    label: '新增動作',
                    color: colorScheme.tertiary,
                    reduceMotion: reduceMotion,
                    onTap: () {
                      _close();
                      widget.onAddExercise();
                    },
                  ),

                // 繪圖
                _buildAnimatedFabItem(
                  index: 1,
                  icon: _isDrawingExpanded ? Icons.close : Icons.draw,
                  label: '手繪筆記',
                  color: colorScheme.secondary,
                  reduceMotion: reduceMotion,
                  onTap: _toggleDrawing,
                ),

                // 照相
                _buildAnimatedFabItem(
                  index: 0,
                  icon: Icons.camera_alt,
                  label: '拍照',
                  color: colorScheme.primary,
                  reduceMotion: reduceMotion,
                  onTap: () {
                    _close();
                    widget.onPhoto();
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12), // UI/UX: 間距 >= 8px

        // 主 FAB（48px 符合 Material 3 標準，>= 44px 觸控目標）
        _SpeedDialMainFab(
          isOpen: _isOpen,
          onTap: _toggle,
          reduceMotion: reduceMotion,
        ),
      ],
    );
  }

  /// 動畫展開的 FAB 項目
  Widget _buildAnimatedFabItem({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required bool reduceMotion,
    required VoidCallback onTap,
  }) {
    // 計算每個項目的延遲（stagger effect）
    final delay = index * 0.15;
    final itemAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _expandAnimation,
        curve: Interval(delay, 0.6 + delay, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        // Reduced motion: 直接顯示/隱藏
        final scale = reduceMotion ? (_isOpen ? 1.0 : 0.0) : itemAnimation.value;
        final opacity = reduceMotion ? (_isOpen ? 1.0 : 0.0) : itemAnimation.value;

        if (scale == 0) return const SizedBox.shrink();

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12), // UI/UX: 間距 >= 8px
              child: _SpeedDialItem(
                icon: icon,
                label: label,
                color: color,
                heroTag: 'speed_dial_item_$index',
                onTap: onTap,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 繪圖子選單
  Widget _buildDrawingSubMenu(ColorScheme colorScheme, bool reduceMotion) {
    final templates = [
      ('note1', '三視圖', Icons.view_in_ar),
      ('note2', '正面', Icons.person),
      ('note3', '背面', Icons.accessibility_new),
      ('note4', '側面', Icons.person_outline),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: templates.reversed.map((template) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8), // UI/UX: 間距 >= 8px
            child: _SpeedDialMiniItem(
              icon: template.$3,
              label: template.$2,
              color: colorScheme.secondary.withOpacity(0.9),
              heroTag: 'drawing_template_${template.$1}',
              onTap: () {
                _close();
                widget.onDrawing(template.$1);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 主 FAB 按鈕（帶旋轉動畫）
class _SpeedDialMainFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  final bool reduceMotion;

  const _SpeedDialMainFab({
    required this.isOpen,
    required this.onTap,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        width: 56, // Material 3 FAB 標準尺寸，>= 44px
        height: 56,
        decoration: BoxDecoration(
          color: isOpen ? colorScheme.errorContainer : colorScheme.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0, // 45度旋轉
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: Icon(
              Icons.add,
              color: isOpen
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// Speed Dial 項目（標準大小）
class _SpeedDialItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String heroTag;
  final VoidCallback onTap;

  const _SpeedDialItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.heroTag,
    required this.onTap,
  });

  @override
  State<_SpeedDialItem> createState() => _SpeedDialItemState();
}

class _SpeedDialItemState extends State<_SpeedDialItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 標籤（Chip 風格）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12), // UI/UX: 間距 >= 8px
        // 圓形按鈕（48px，>= 44px 觸控目標）
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0, // UI/UX: active 狀態 scale 變化
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

/// Speed Dial 迷你項目（繪圖子選單用）
class _SpeedDialMiniItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String heroTag;
  final VoidCallback onTap;

  const _SpeedDialMiniItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.heroTag,
    required this.onTap,
  });

  @override
  State<_SpeedDialMiniItem> createState() => _SpeedDialMiniItemState();
}

class _SpeedDialMiniItemState extends State<_SpeedDialMiniItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 小標籤
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 小圓形按鈕（44px，符合最小觸控目標）
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 44, // UI/UX: 最小觸控目標 44px
              height: 44,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

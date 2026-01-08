// ✅ v3.1: 訓練行事曆展開式 FAB（參考 SessionSpeedDial）
import 'package:flutter/material.dart';

/// 訓練行事曆快速功能按鈕
///
/// 根據用戶身份和當前 Tab 顯示不同選項：
///
/// **「我的」Tab**：
/// - 學員（無教練）：➕ 新增訓練
/// - 學員（有教練）：➕ 新增訓練、⏰ 設可訓練
///
/// **「教練」Tab**（僅教練可見）：
/// - ➕ 幫學員新增訓練、⏰ 設可上課
class BookingSpeedDial extends StatefulWidget {
  /// 新增訓練（自己）
  final VoidCallback? onAddTraining;

  /// 設定可訓練時間
  final VoidCallback? onSetTrainableTime;

  /// 幫學員新增訓練
  final VoidCallback? onAddTrainingForStudent;

  /// 設定可上課時間
  final VoidCallback? onSetAvailableTime;

  /// 是否顯示「設可訓練」
  final bool showTrainableTime;

  /// 是否為教練 Tab（顯示教練選項）
  final bool isCoachTab;

  const BookingSpeedDial({
    super.key,
    this.onAddTraining,
    this.onSetTrainableTime,
    this.onAddTrainingForStudent,
    this.onSetAvailableTime,
    this.showTrainableTime = false,
    this.isCoachTab = false,
  });

  @override
  State<BookingSpeedDial> createState() => _BookingSpeedDialState();
}

class _BookingSpeedDialState extends State<BookingSpeedDial>
    with TickerProviderStateMixin {
  bool _isOpen = false;

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
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
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
        _controller.reverse();
      }
    });
  }

  void _close() {
    setState(() {
      _isOpen = false;
      _controller.reverse();
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

    // 根據 Tab 構建不同選項
    final items = widget.isCoachTab
        ? _buildCoachTabItems(colorScheme, reduceMotion)
        : _buildMyTabItems(colorScheme, reduceMotion);

    // 如果只有一個選項，直接用普通 FAB
    if (items.length == 1) {
      return FloatingActionButton(
        heroTag: 'booking_page_fab',
        onPressed: items.first.onTap,
        tooltip: items.first.label,
        child: Icon(items.first.icon),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 選項列表
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.asMap().entries.map((entry) {
                return _buildAnimatedFabItem(
                  index: entry.key,
                  item: entry.value,
                  reduceMotion: reduceMotion,
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 12),

        // 主 FAB
        _SpeedDialMainFab(
          isOpen: _isOpen,
          onTap: _toggle,
          reduceMotion: reduceMotion,
        ),
      ],
    );
  }

  /// 「我的」Tab 選項
  List<_SpeedDialItemData> _buildMyTabItems(
    ColorScheme colorScheme,
    bool reduceMotion,
  ) {
    final items = <_SpeedDialItemData>[];

    // 新增訓練
    if (widget.onAddTraining != null) {
      items.add(_SpeedDialItemData(
        icon: Icons.add_circle_outline,
        label: '新增訓練',
        color: colorScheme.primary,
        onTap: () {
          _close();
          widget.onAddTraining!();
        },
      ));
    }

    // 設可訓練（有教練才顯示）
    if (widget.showTrainableTime && widget.onSetTrainableTime != null) {
      items.add(_SpeedDialItemData(
        icon: Icons.event_available,
        label: '設可訓練',
        color: colorScheme.secondary,
        onTap: () {
          _close();
          widget.onSetTrainableTime!();
        },
      ));
    }

    return items;
  }

  /// 「教練」Tab 選項
  List<_SpeedDialItemData> _buildCoachTabItems(
    ColorScheme colorScheme,
    bool reduceMotion,
  ) {
    final items = <_SpeedDialItemData>[];

    // 幫學員新增訓練
    if (widget.onAddTrainingForStudent != null) {
      items.add(_SpeedDialItemData(
        icon: Icons.person_add,
        label: '幫學員新增訓練',
        color: colorScheme.primary,
        onTap: () {
          _close();
          widget.onAddTrainingForStudent!();
        },
      ));
    }

    // 設可上課
    if (widget.onSetAvailableTime != null) {
      items.add(_SpeedDialItemData(
        icon: Icons.schedule,
        label: '設可上課',
        color: colorScheme.tertiary,
        onTap: () {
          _close();
          widget.onSetAvailableTime!();
        },
      ));
    }

    return items;
  }

  /// 動畫展開的 FAB 項目
  Widget _buildAnimatedFabItem({
    required int index,
    required _SpeedDialItemData item,
    required bool reduceMotion,
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
        final scale =
            reduceMotion ? (_isOpen ? 1.0 : 0.0) : itemAnimation.value;
        final opacity =
            reduceMotion ? (_isOpen ? 1.0 : 0.0) : itemAnimation.value;

        if (scale == 0) return const SizedBox.shrink();

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SpeedDialItem(
                icon: item.icon,
                label: item.label,
                color: item.color,
                heroTag: 'booking_speed_dial_item_$index',
                onTap: item.onTap,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// SpeedDial 項目資料
class _SpeedDialItemData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SpeedDialItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
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
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color:
              isOpen ? colorScheme.errorContainer : colorScheme.primaryContainer,
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

/// Speed Dial 項目
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
        // 標籤
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
        const SizedBox(width: 12),
        // 圓形按鈕（48px）
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
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


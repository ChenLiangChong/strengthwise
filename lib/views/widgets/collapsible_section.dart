// ✅ Phase 3.1-B: 可折疊區塊 Widget
import 'package:flutter/material.dart';

/// 可折疊區塊 Widget
///
/// 用於首頁的「今日行程」和「我的學員」區塊，
/// 支援展開/收起動畫，並可保存展開狀態。
///
/// UX 設計原則：
/// - 動畫時長 250ms，使用 ease-out 曲線
/// - 箭頭圖標指示展開/收起方向
/// - 點擊標題列即可切換
class CollapsibleSection extends StatefulWidget {
  /// 區塊標題
  final String title;

  /// 標題前的圖標（可選）
  final IconData? icon;

  /// 區塊內容
  final Widget child;

  /// 是否預設展開
  final bool initiallyExpanded;

  /// 展開狀態變更回調
  final ValueChanged<bool>? onExpansionChanged;

  /// 標題右側額外的 Widget（如計數 Badge）
  final Widget? trailing;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.initiallyExpanded = true,
    this.onExpansionChanged,
    this.trailing,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    // 動畫控制器：250ms，符合 UX 建議
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // 高度動畫：ease-out 曲線
    _heightFactor = _controller.drive(
      CurveTween(curve: Curves.easeOut),
    );

    // 箭頭旋轉動畫：0 → 0.5（180度）
    _iconTurns = _controller.drive(
      Tween<double>(begin: 0.0, end: 0.5),
    );

    // 初始狀態
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 切換展開/收起狀態
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題列（可點擊）
        InkWell(
          onTap: _toggleExpansion,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                // 圖標
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],

                // 標題
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // 額外的 trailing widget
                if (widget.trailing != null) ...[
                  widget.trailing!,
                  const SizedBox(width: 8),
                ],

                // 旋轉箭頭
                RotationTransition(
                  turns: _iconTurns,
                  child: Icon(
                    Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 可收縮內容
        ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _heightFactor.value,
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}


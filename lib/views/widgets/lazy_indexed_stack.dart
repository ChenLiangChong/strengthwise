// ⚡ v3.1.1: 延遲初始化的 IndexedStack
//
// 首次只初始化當前頁面，然後背景自動載入其他頁面
// 大幅減少首次進入主頁面的載入時間
import 'package:flutter/material.dart';

/// 延遲初始化的 IndexedStack
///
/// 與標準 IndexedStack 不同：
/// - 標準：所有 children 在首次 build 時全部初始化
/// - Lazy：先初始化當前頁面，然後背景自動初始化其他頁面
///
/// 流程：
/// 1. 首次 build：只初始化當前頁面（立即顯示）
/// 2. 延遲 500ms 後：背景自動初始化所有其他頁面
/// 3. 用戶切換時：頁面已經準備好，不會卡頓
///
/// 使用場景：底部導航、Tab 頁面等多頁面切換
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.sizing = StackFit.loose,
    this.backgroundInitDelay = const Duration(milliseconds: 500),
  });

  /// 當前顯示的頁面索引
  final int index;

  /// 所有子頁面
  final List<Widget> children;

  /// Stack 對齊方式
  final AlignmentDirectional alignment;

  /// Stack 大小調整方式
  final StackFit sizing;

  /// 背景初始化延遲時間（預設 500ms）
  final Duration backgroundInitDelay;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  /// 記錄已初始化的頁面索引
  late Set<int> _initializedIndexes;

  /// 是否已完成背景初始化
  bool _backgroundInitCompleted = false;

  @override
  void initState() {
    super.initState();
    // 初始只標記當前頁面
    _initializedIndexes = {widget.index};

    // ⚡ 背景自動初始化其他頁面
    _scheduleBackgroundInit();
  }

  /// 排程背景初始化
  void _scheduleBackgroundInit() {
    Future.delayed(widget.backgroundInitDelay, () {
      if (!mounted || _backgroundInitCompleted) return;

      // 初始化所有其他頁面
      setState(() {
        for (int i = 0; i < widget.children.length; i++) {
          _initializedIndexes.add(i);
        }
        _backgroundInitCompleted = true;
      });

      debugPrint('[LazyIndexedStack] ✅ 背景初始化完成：${widget.children.length} 個頁面');
    });
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當索引變更時，確保該頁面已初始化（以防背景初始化還沒完成）
    if (!_initializedIndexes.contains(widget.index)) {
      setState(() {
        _initializedIndexes.add(widget.index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      sizing: widget.sizing,
      children: List.generate(widget.children.length, (index) {
        // 已初始化的頁面：顯示真實內容
        // 未初始化的頁面：顯示空容器（不觸發 initState）
        if (_initializedIndexes.contains(index)) {
          return widget.children[index];
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }
}

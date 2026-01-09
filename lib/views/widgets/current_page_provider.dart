// ⭐ v3.2: 當前頁面索引 Provider
//
// 用於讓子頁面知道自己是否是當前顯示的頁面
// 主要用於 Coach Mark 引導的觸發控制
import 'package:flutter/material.dart';

/// 當前頁面索引 Provider
///
/// 使用 InheritedWidget 傳遞當前頁面索引給子頁面
/// 子頁面可以通過 [CurrentPageProvider.of(context)] 獲取當前索引
class CurrentPageProvider extends InheritedWidget {
  const CurrentPageProvider({
    super.key,
    required this.currentIndex,
    required super.child,
  });

  /// 當前顯示的頁面索引
  final int currentIndex;

  /// 獲取當前頁面索引
  ///
  /// 如果找不到 Provider，返回 null
  static int? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<CurrentPageProvider>();
    return provider?.currentIndex;
  }

  /// 獲取當前頁面索引（必須存在）
  static int of(BuildContext context) {
    final index = maybeOf(context);
    assert(index != null, 'No CurrentPageProvider found in context');
    return index!;
  }

  /// 檢查指定索引是否是當前頁面
  ///
  /// 如果找不到 Provider，返回 true（預設顯示）
  static bool isCurrentPage(BuildContext context, int pageIndex) {
    final currentIndex = maybeOf(context);
    // 如果沒有 Provider（例如獨立頁面），預設為當前頁面
    if (currentIndex == null) return true;
    return currentIndex == pageIndex;
  }

  @override
  bool updateShouldNotify(CurrentPageProvider oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

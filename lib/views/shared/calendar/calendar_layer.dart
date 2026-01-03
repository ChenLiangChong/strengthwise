import 'package:flutter/material.dart';

/// 行事曆視覺化層抽象
///
/// 所有視覺化層都實現這個接口
/// 
/// 設計理念：
/// - 單一職責：每個 Layer 只負責一種視覺化
/// - 可組合：多個 Layer 可疊加
/// - 可擴展：添加新 Layer 不修改核心代碼
abstract class CalendarLayer {
  /// 渲染單個日期的視覺化
  ///
  /// 參數：
  /// - [context]: BuildContext
  /// - [day]: 要渲染的日期
  ///
  /// 返回：
  /// - Widget：渲染的視覺化組件
  /// - null：不渲染（跳過該日期）
  Widget? buildDay(BuildContext context, DateTime day);
}


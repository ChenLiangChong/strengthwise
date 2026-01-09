import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Coach Mark 引導工具
///
/// 封裝 tutorial_coach_mark 套件，提供統一的樣式和行為
/// 
/// 使用方式：
/// 1. 為目標 Widget 設定 GlobalKey
/// 2. 呼叫 CoachMarkHelper.show() 顯示引導
class CoachMarkHelper {
  /// 顯示 Coach Mark 引導
  /// 
  /// [context] BuildContext
  /// [targets] 引導目標列表
  /// [onFinish] 完成回調
  /// [onSkip] 跳過回調
  static void show({
    required BuildContext context,
    required List<TargetFocus> targets,
    VoidCallback? onFinish,
    VoidCallback? onSkip,
  }) {
    if (targets.isEmpty) return;
    
    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      textSkip: '跳過',
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      paddingFocus: 10,
      focusAnimationDuration: const Duration(milliseconds: 300),
      unFocusAnimationDuration: const Duration(milliseconds: 300),
      pulseAnimationDuration: const Duration(milliseconds: 1000),
      onFinish: onFinish,
      onSkip: () {
        onSkip?.call();
        return true;
      },
    );
    
    tutorial.show(context: context);
  }
  
  /// 建立單一引導目標
  /// 
  /// [key] 目標 Widget 的 GlobalKey
  /// [title] 標題
  /// [description] 描述
  /// [shape] 高亮形狀（預設圓形）
  /// [alignSkip] 跳過按鈕位置
  static TargetFocus createTarget({
    required GlobalKey key,
    required String title,
    required String description,
    ShapeLightFocus shape = ShapeLightFocus.Circle,
    Alignment alignSkip = Alignment.bottomRight,
    ContentAlign contentAlign = ContentAlign.bottom,
  }) {
    return TargetFocus(
      identify: key.toString(),
      keyTarget: key,
      shape: shape,
      alignSkip: alignSkip,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: contentAlign,
          builder: (context, controller) {
            return _CoachMarkContent(
              title: title,
              description: description,
              onNext: controller.next,
            );
          },
        ),
      ],
    );
  }
  
  /// 建立矩形引導目標（適用於按鈕、卡片等）
  static TargetFocus createRectTarget({
    required GlobalKey key,
    required String title,
    required String description,
    double radius = 8,
    Alignment alignSkip = Alignment.bottomRight,
    ContentAlign contentAlign = ContentAlign.bottom,
  }) {
    return TargetFocus(
      identify: key.toString(),
      keyTarget: key,
      shape: ShapeLightFocus.RRect,
      radius: radius,
      alignSkip: alignSkip,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: contentAlign,
          builder: (context, controller) {
            return _CoachMarkContent(
              title: title,
              description: description,
              onNext: controller.next,
            );
          },
        ),
      ],
    );
  }
  
  /// 建立多步驟引導（同一目標多個說明）
  static TargetFocus createMultiStepTarget({
    required GlobalKey key,
    required List<CoachMarkStep> steps,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 8,
  }) {
    return TargetFocus(
      identify: key.toString(),
      keyTarget: key,
      shape: shape,
      radius: radius,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: steps.map((step) {
        return TargetContent(
          align: step.align,
          builder: (context, controller) {
            return _CoachMarkContent(
              title: step.title,
              description: step.description,
              onNext: controller.next,
            );
          },
        );
      }).toList(),
    );
  }
}

/// Coach Mark 步驟資料
class CoachMarkStep {
  final String title;
  final String description;
  final ContentAlign align;
  
  const CoachMarkStep({
    required this.title,
    required this.description,
    this.align = ContentAlign.bottom,
  });
}

/// Coach Mark 內容 Widget
class _CoachMarkContent extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onNext;
  
  const _CoachMarkContent({
    required this.title,
    required this.description,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // 描述
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          // 下一步按鈕
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onNext,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '知道了',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

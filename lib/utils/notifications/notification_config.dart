/// 通知配置常數與樣式定義
class NotificationConfig {
  // 顏色定義（深淺色模式適配）
  static const successColorLight = 0xFF2E7D32;
  static const successColorDark = 0xFF81C784;
  static const errorColor = 0xFFEF4444;
  static const warningColor = 0xFFF59E0B;
  static const achievementColorLight = 0xFFF59E0B; // 琥珀色
  static const achievementColorDark = 0xFFFCD34D; // 金色
  static const systemStatusColor = 0xFFF59E0B;
  static const defaultBackgroundColor = 0xCC424242; // 灰色 70% 透明度

  // 尺寸定義
  static const double defaultWidth = 32.0; // 兩側邊距
  static const double defaultBottomMargin = 80.0; // 避開底部導航欄
  static const double defaultBorderRadius = 24.0; // 膠囊形狀
  static const double iconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double systemIconSize = 20.0;
  static const double systemWidth = 0.6; // 系統通知寬度比例
  static const double systemHeight = 48.0; // 系統通知高度

  // 時長定義
  static const defaultDuration = Duration(seconds: 3);
  static const errorDuration = Duration(seconds: 4);
  static const undoDuration = Duration(seconds: 7);
  static const achievementDuration = Duration(seconds: 4);
  static const systemDuration = Duration(seconds: 999); // 需手動關閉

  // 動畫時長
  static const scaleAnimationDuration = Duration(milliseconds: 300);
  static const shimmerDuration = Duration(milliseconds: 500);

  // 字體樣式
  static const titleFontSize = 16.0;
  static const contentFontSize = 14.0;
  static const achievementTitleFontSize = 18.0;
  static const achievementContentFontSize = 15.0;
  static const systemFontSize = 14.0;

  // 間距
  static const iconTextSpacing = 12.0;
  static const horizontalPadding = 16.0;
  static const verticalPadding = 16.0;
}


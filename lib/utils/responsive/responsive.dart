/// StrengthWise 響應式框架
///
/// 企業級響應式設計系統，支援手機、平板、桌面多種設備
/// 詳見：docs/planning/RESPONSIVE_ARCHITECTURE_DESIGN.md
///
/// ## 快速開始
///
/// ```dart
/// import 'package:strengthwise/utils/responsive/responsive.dart';
///
/// // 1. 使用 Context Extension（推薦）
/// Text(
///   '標題',
///   style: context.responsive.headlineMedium,
/// );
///
/// // 2. 響應式間距（自動對齊 4dp 網格）
/// Padding(
///   padding: EdgeInsets.all(context.spacing.md),
///   child: content,
/// );
///
/// // 3. 響應式佈局
/// ResponsiveBuilder(
///   mobile: (context, constraints) => MobileLayout(),
///   tablet: (context, constraints) => TabletLayout(),
/// )
///
/// // 4. 響應式 Grid
/// ResponsiveGrid(
///   mobileColumns: 1,
///   tabletColumns: 2,
///   desktopColumns: 3,
///   children: items,
/// )
///
/// // 5. 條件顯示
/// if (context.isMobile) { ... }
/// if (context.isTablet) { ... }
/// ```
///
/// ## 7 級精細化斷點系統
///
/// | 等級 | 代碼名稱 | 寬度範圍 | 縮放係數 | 導航模式 |
/// |------|---------|----------|----------|---------|
/// | Compact-S | mobileSmall | < 360dp | 0.88 | BottomNav |
/// | Compact | mobile | 360-599dp | 1.0 | BottomNav |
/// | Compact-L | mobileLarge | 600-719dp | 1.05 | BottomNav |
/// | Medium-S | tabletSmall | 720-839dp | 1.1 | Rail |
/// | Medium | tablet | 840-1023dp | 1.15 | Rail |
/// | Expanded | tabletLarge | 1024-1279dp | 1.15 | Drawer |
/// | Large | desktop | ≥ 1280dp | 1.2 | Drawer |
///
library;

export 'responsive_breakpoints.dart';
export 'responsive_builder.dart';
export 'responsive_extensions.dart';
export 'responsive_text_styles.dart';
export 'responsive_value.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/interfaces/i_theme_controller.dart';
import '../../../../themes/app_theme_mode.dart';

/// 主題切換組件
///
/// 提供四種模式切換：淺色、深色、粉色、跟隨系統
/// 使用 SegmentedButton 符合 Material 3 設計規範
class ProfileThemeSwitcher extends StatelessWidget {
  const ProfileThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<IThemeController>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.palette_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '外觀主題',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 使用 Wrap 讓按鈕在小螢幕上可以換行
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.light,
                  icon: Icon(Icons.wb_sunny, size: 16),
                  label: Text('淺色'),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.dark,
                  icon: Icon(Icons.nightlight_round, size: 16),
                  label: Text('深色'),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.rose,
                  icon: Icon(Icons.local_florist, size: 16),
                  label: Text('粉色'),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.system,
                  icon: Icon(Icons.phone_android, size: 16),
                  label: Text('系統'),
                ),
              ],
              selected: {themeController.themeMode},
              onSelectionChanged: (Set<AppThemeMode> newSelection) {
                themeController.setThemeMode(newSelection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.primary;
                    }
                    return colorScheme.surface;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.onPrimary;
                    }
                    return colorScheme.onSurface;
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            themeController.themeMode == AppThemeMode.system
                ? '當前跟隨系統設定'
                : '當前使用${themeController.themeModeName}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

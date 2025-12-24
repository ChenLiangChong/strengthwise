import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_theme.dart';

/// 主題測試頁面
/// 
/// 用於測試 Kinetic 設計系統的主題切換功能
/// 展示深色/淺色模式的視覺效果
class ThemeTestPage extends StatelessWidget {
  const ThemeTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinetic 設計系統測試'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================
            // 主題切換控制
            // ========================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主題模式',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('淺色'),
                          icon: Icon(Icons.wb_sunny),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('深色'),
                          icon: Icon(Icons.nightlight_round),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('系統'),
                          icon: Icon(Icons.phone_android),
                        ),
                      ],
                      selected: {themeController.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        themeController.setThemeMode(newSelection.first);
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      '當前模式：${themeController.themeModeName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ========================================
            // 色彩展示
            // ========================================
            Text(
              '色彩方案',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  children: [
                    _buildColorRow(
                      context,
                      'Primary',
                      colorScheme.primary,
                      colorScheme.onPrimary,
                    ),
                    _buildColorRow(
                      context,
                      'Secondary',
                      colorScheme.secondary,
                      colorScheme.onSecondary,
                    ),
                    _buildColorRow(
                      context,
                      'Surface',
                      colorScheme.surface,
                      colorScheme.onSurface,
                    ),
                    _buildColorRow(
                      context,
                      'Background',
                      colorScheme.background,
                      colorScheme.onBackground,
                    ),
                    _buildColorRow(
                      context,
                      'Error',
                      colorScheme.error,
                      colorScheme.onError,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ========================================
            // 字體展示
            // ========================================
            Text(
              '字體系統 (Inter)',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Large',
                      style: theme.textTheme.displayLarge,
                    ),
                    const Divider(),
                    Text(
                      'Headline Medium',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const Divider(),
                    Text(
                      'Title Medium',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Divider(),
                    Text(
                      'Body Large - 一般說明文字範例',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Divider(),
                    Text(
                      'Body Medium - 列表次要資訊範例',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Divider(),
                    Text(
                      'LABEL LARGE - 按鈕文字',
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ========================================
            // 組件展示
            // ========================================
            Text(
              '組件範例',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Elevated Button'),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Outlined Button'),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Text Button'),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: '輸入框範例',
                        hintText: '請輸入內容',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ========================================
            // 統計卡片範例
            // ========================================
            Text(
              '統計卡片範例',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '總訓練量',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '12,450',
                            style: theme.textTheme.headlineSmall,
                          ),
                          Text(
                            'kg',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '連續週數',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '4',
                            style: theme.textTheme.headlineSmall,
                          ),
                          Text(
                            '週',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(
    BuildContext context,
    String label,
    Color color,
    Color onColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check,
              color: onColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


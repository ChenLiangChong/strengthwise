// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import '../../../../models/user_model.dart';

/// 個人資料詳細資訊卡片
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距
class ProfileDetailCard extends StatelessWidget {
  final UserModel userProfile;

  const ProfileDetailCard({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMetric = userProfile.unitSystem != 'imperial';

    // 計算 BMI 和相關資訊
    final bmiData = _calculateBMIData(isMetric);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                SizedBox(width: context.spacing.sm),
                Text(
                  '詳細資訊',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.md),

            // 基本資料區塊
            if (bmiData['heightText'] != null ||
                bmiData['weightText'] != null ||
                bmiData['bmi'] != null) ...[
              _buildSectionHeader(context, '👤 基本資料', colorScheme),
              SizedBox(height: context.spacing.sm),
              Container(
                padding: EdgeInsets.all(context.spacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (bmiData['heightText'] != null)
                      _buildInfoRow(context, '身高', bmiData['heightText'] as String),
                    if (bmiData['weightText'] != null) ...[
                      if (bmiData['heightText'] != null) const Divider(height: 16),
                      _buildInfoRow(context, '體重', bmiData['weightText'] as String),
                    ],
                    if (bmiData['bmi'] != null) ...[
                      const Divider(height: 16),
                      _buildInfoRow(
                        context,
                        'BMI',
                        '${(bmiData['bmi'] as double).toStringAsFixed(1)} (${bmiData['bmiCategory']})',
                        valueColor: _getBMIColor(
                            bmiData['bmi'] as double, bmiData['bmiCategory'] as String),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: context.spacing.md),
            ],

            // 偏好設定區塊
            _buildSectionHeader(context, '⚙️ 偏好設定', colorScheme),
            SizedBox(height: context.spacing.sm),
            Container(
              padding: EdgeInsets.all(context.spacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    '單位系統',
                    isMetric ? '公制 (cm, kg)' : '英制 (ft, lb)',
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    context,
                    '角色',
                    [
                      if (userProfile.isCoach) '教練',
                      if (userProfile.isStudent) '學員',
                    ].join(' / '),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 計算 BMI 相關數據
  Map<String, dynamic> _calculateBMIData(bool isMetric) {
    final result = <String, dynamic>{};

    if (userProfile.height != null && userProfile.weight != null) {
      if (isMetric) {
        // 公制：cm, kg
        result['heightText'] = '${userProfile.height} cm';
        result['weightText'] = '${userProfile.weight} kg';

        final heightInMeters = userProfile.height! / 100;
        result['bmi'] = userProfile.weight! / (heightInMeters * heightInMeters);
      } else {
        // 英制：feet & inches, lb
        final heightInInches = userProfile.height! / 2.54;
        final feet = (heightInInches / 12).floor();
        final inches = (heightInInches % 12).round();
        result['heightText'] = '$feet\' $inches"';

        final weightInLbs = (userProfile.weight! * 2.20462).toStringAsFixed(1);
        result['weightText'] = '$weightInLbs lb';

        // BMI 計算（使用英制單位）
        result['bmi'] =
            (userProfile.weight! * 703) / (heightInInches * heightInInches);
      }

      // BMI 分類
      final bmi = result['bmi'] as double;
      if (bmi < 18.5) {
        result['bmiCategory'] = '過輕';
      } else if (bmi < 24) {
        result['bmiCategory'] = '正常';
      } else if (bmi < 27) {
        result['bmiCategory'] = '過重';
      } else {
        result['bmiCategory'] = '肥胖';
      }
    } else if (userProfile.height != null) {
      // 只有身高
      if (isMetric) {
        result['heightText'] = '${userProfile.height} cm';
      } else {
        final heightInInches = userProfile.height! / 2.54;
        final feet = (heightInInches / 12).floor();
        final inches = (heightInInches % 12).round();
        result['heightText'] = '$feet\' $inches"';
      }
    } else if (userProfile.weight != null) {
      // 只有體重
      if (isMetric) {
        result['weightText'] = '${userProfile.weight} kg';
      } else {
        final weightInLbs = (userProfile.weight! * 2.20462).toStringAsFixed(1);
        result['weightText'] = '$weightInLbs lb';
      }
    }

    return result;
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium,
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBMIColor(double bmi, String category) {
    if (category == '正常') return Colors.green;
    if (category == '過輕') return Colors.orange;
    return Colors.red;
  }
}


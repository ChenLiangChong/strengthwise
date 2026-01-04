import 'package:flutter/material.dart';
import 'package:strengthwise/models/health_assessment_models.dart';
import 'package:strengthwise/services/interfaces/i_health_assessment_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/health_assessment_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/health_assessment_summary_card.dart';
import 'package:strengthwise/views/pages/relationships/role_client/widgets/empty_my_health_assessment_card.dart';

/// 學員健康評估頁面（學員自己查看/填寫）
/// 
/// 功能：
/// 1. 查看自己的健康評估報告
/// 2. 自行填寫健康評估（如果沒有教練或想先準備）
/// 3. 編輯已有的健康評估
class MyHealthAssessmentPage extends StatefulWidget {
  final String userId;

  const MyHealthAssessmentPage({
    super.key,
    required this.userId,
  });

  @override
  State<MyHealthAssessmentPage> createState() => _MyHealthAssessmentPageState();
}

class _MyHealthAssessmentPageState extends State<MyHealthAssessmentPage> {
  late final IHealthAssessmentService _healthAssessmentService;

  HealthAssessmentModel? _healthAssessment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _healthAssessmentService = serviceLocator<IHealthAssessmentService>();
    _loadHealthAssessment();
  }

  /// 載入健康評估
  Future<void> _loadHealthAssessment() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final assessment = await _healthAssessmentService.getCurrentAssessment(
        widget.userId,
      );

      if (mounted) {
        setState(() {
          _healthAssessment = assessment;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationUtils.showError(context, '無法載入健康評估：$e');
      }
    }
  }

  /// 顯示健康評估編輯器
  Future<void> _showHealthAssessmentEditor() async {
    final result = await Navigator.push<HealthAssessmentModel>(
      context,
      MaterialPageRoute(
        builder: (context) => HealthAssessmentPage(
          clientId: widget.userId,
          clientName: '我', // 學員自填時顯示「我」
          existingAssessment: _healthAssessment,
          isClientSelfFilling: true, // ⭐ 標記為學員自填
        ),
      ),
    );

    // 如果有返回值，重新載入
    if (result != null && mounted) {
      await _loadHealthAssessment();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadHealthAssessment,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 說明文字
            _buildInfoBanner(context),
            const SizedBox(height: 16),

            // 健康評估內容
            if (_healthAssessment != null)
              HealthAssessmentSummaryCard(
                assessment: _healthAssessment!,
                onViewFull: () {
                  // TODO: 實作查看完整報告頁面（未來功能）
                  NotificationUtils.showInfo(context, '查看完整報告功能開發中');
                },
                onEdit: _showHealthAssessmentEditor,
                isClientView: true, // ⭐ 學員視角（隱藏教練備註、設定按鈕）
              )
            else
              EmptyMyHealthAssessmentCard(
                onCreateAssessment: _showHealthAssessmentEditor,
              ),
          ],
        ),
      ),
    );
  }

  /// 資訊橫幅
  Widget _buildInfoBanner(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '關於健康評估',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '您的健康評估會與所有教練同步。您可以自行填寫，教練也可以協助您填寫或更新內容。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    height: 1.4,
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


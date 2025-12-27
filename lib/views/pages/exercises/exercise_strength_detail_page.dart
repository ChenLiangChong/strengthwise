import 'package:flutter/material.dart';
import '../../../models/statistics_model.dart';
import '../../../services/interfaces/i_statistics_service.dart';
import '../../../services/interfaces/i_favorites_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import 'widgets/statistics_card.dart';
import 'widgets/strength_chart.dart';
import 'widgets/pr_records_card.dart';
import 'widgets/training_history_card.dart';

/// 動作力量進步詳情頁面
/// 
/// 顯示單個動作的完整力量進步曲線、PR 記錄、歷史訓練
class ExerciseStrengthDetailPage extends StatefulWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final TimeRange timeRange;

  const ExerciseStrengthDetailPage({
    Key? key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.timeRange,
  }) : super(key: key);

  @override
  State<ExerciseStrengthDetailPage> createState() => _ExerciseStrengthDetailPageState();
}

class _ExerciseStrengthDetailPageState extends State<ExerciseStrengthDetailPage> {
  final IStatisticsService _statisticsService = serviceLocator<IStatisticsService>();
  final IFavoritesService _favoritesService = serviceLocator<IFavoritesService>();
  
  ExerciseStrengthProgress? _progress;
  bool _isLoading = true;
  bool _isFavorite = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 載入數據
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // 載入力量進步數據
      final progressList = await _statisticsService.getStrengthProgress(
        widget.userId,
        widget.timeRange,
        limit: 100,
      );

      // 找到目標動作
      final progress = progressList.firstWhere(
        (p) => p.exerciseId == widget.exerciseId,
        orElse: () => throw Exception('找不到該動作的訓練記錄'),
      );

      // 檢查是否已收藏
      final isFavorite = await _favoritesService.isFavorite(
        widget.userId,
        widget.exerciseId,
      );

      setState(() {
        _progress = progress;
        _isFavorite = isFavorite;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 切換收藏狀態
  Future<void> _toggleFavorite() async {
    if (_progress == null) return;

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(widget.userId, widget.exerciseId);
        if (mounted) {
          NotificationUtils.showSuccess(context, '已移除收藏');
        }
      } else {
        await _favoritesService.addFavorite(
          widget.userId,
          widget.exerciseId,
          _progress!.exerciseName,
          _progress!.bodyPart,
        );
        if (mounted) {
          NotificationUtils.showSuccess(context, '已添加收藏');
        }
      }

      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '操作失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          // 收藏按鈕
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: _isLoading ? null : _toggleFavorite,
            tooltip: _isFavorite ? '取消收藏' : '添加收藏',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '載入失敗',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('重試'),
              ),
            ],
          ),
        ),
      );
    }

    if (_progress == null) {
      return const Center(child: Text('沒有數據'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 統計卡片
          StatisticsCard(progress: _progress!),
          const SizedBox(height: 16),

          // 力量進步曲線
          StrengthChart(history: _progress!.history),
          const SizedBox(height: 16),

          // PR 記錄
          PRRecordsCard(
            prRecords: _progress!.history.where((p) => p.isPR).toList(),
          ),
          const SizedBox(height: 16),

          // 歷史記錄
          TrainingHistoryCard(history: _progress!.history),
        ],
      ),
    );
  }

}


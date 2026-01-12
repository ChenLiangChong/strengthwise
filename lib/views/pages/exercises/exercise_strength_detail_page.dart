// ✅ 已響應式改造 (Phase 0) - 統計詳情頁
// v3.3+ 支援多元追蹤模式 + 傳遞數據方案
import 'package:flutter/material.dart';
import '../../../models/statistics_model.dart';
import '../../../models/tracking_mode.dart';
import '../../../models/favorite_exercise_model.dart';
import '../../../services/interfaces/i_statistics_service.dart';
import '../../../services/interfaces/i_favorites_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import 'widgets/statistics_card.dart';
import 'widgets/strength_chart.dart';
import 'widgets/pr_records_card.dart';
import 'widgets/training_history_card.dart';

/// 動作訓練詳情頁面
/// v3.3+ 支援多元追蹤模式 + 傳遞數據方案
///
/// 顯示單個動作的完整訓練曲線、PR 記錄、歷史訓練
/// 非重訓模式只顯示歷史記錄
/// 
/// **v3.3+ 傳遞數據方案**：
/// 優先使用從選擇頁面傳入的 exerciseData，避免重複查詢
/// 如果查詢詳細歷史失敗，至少顯示基本統計信息
class ExerciseStrengthDetailPage extends StatefulWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final TimeRange timeRange;
  final ExerciseWithRecord? exerciseData; // v3.3+ 從選擇頁面傳入的基本數據

  const ExerciseStrengthDetailPage({
    Key? key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.timeRange,
    this.exerciseData, // v3.3+ 可選
  }) : super(key: key);

  @override
  State<ExerciseStrengthDetailPage> createState() =>
      _ExerciseStrengthDetailPageState();
}

class _ExerciseStrengthDetailPageState
    extends State<ExerciseStrengthDetailPage> {
  final IStatisticsService _statisticsService =
      serviceLocator<IStatisticsService>();
  final IFavoritesService _favoritesService =
      serviceLocator<IFavoritesService>();

  ExerciseStrengthProgress? _progress;
  bool _isLoading = true;
  bool _isFavorite = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _hasRetried = false; // v3.3+ 避免無限重試
  bool _hasDetailedHistory = true; // v3.3+ 是否有詳細歷史記錄

  /// 載入數據
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // v3.3+ 修正：恢復使用用戶選擇的時間範圍
      // 根本問題已在 statistics_data_loader.dart 修復（統一時間判斷邏輯）
      final progressList = await _statisticsService.getStrengthProgress(
        widget.userId,
        widget.timeRange,
        limit: 1000,
      );

      // 找到目標動作
      ExerciseStrengthProgress? progress;
      try {
        progress = progressList.firstWhere(
          (p) => p.exerciseId == widget.exerciseId,
        );
      } catch (_) {
        // v3.3+ 找不到時，清除快取重試一次
        if (!_hasRetried) {
          _hasRetried = true;
          _statisticsService.clearCache();
          return _loadData();
        }
        
        // v3.3+ 如果有傳入的基本數據，使用簡化視圖
        if (widget.exerciseData != null) {
          progress = _createBasicProgress(widget.exerciseData!);
          _hasDetailedHistory = false;
        } else {
          throw Exception('找不到該動作的訓練記錄\n請確認有完成過該動作的訓練');
        }
      }

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
      // v3.3+ 如果有傳入的基本數據，顯示簡化視圖而不是錯誤
      if (widget.exerciseData != null) {
        final basicProgress = _createBasicProgress(widget.exerciseData!);
        final isFavorite = widget.exerciseData!.isFavorite;
        
        setState(() {
          _progress = basicProgress;
          _isFavorite = isFavorite;
          _hasDetailedHistory = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  /// v3.3+ 從 ExerciseWithRecord 創建基本的進度數據（無歷史記錄）
  ExerciseStrengthProgress _createBasicProgress(ExerciseWithRecord data) {
    return ExerciseStrengthProgress(
      exerciseId: data.exerciseId,
      exerciseName: data.exerciseName,
      bodyPart: data.bodyPart,
      history: [], // 無詳細歷史
      currentMax: data.maxWeight,
      previousMax: 0,
      progressPercentage: 0,
      totalSets: data.totalSets,
      averageWeight: data.maxWeight,
      trackingMode: TrackingMode.weightReps, // 預設
    );
  }

  /// 切換收藏狀態
  Future<void> _toggleFavorite() async {
    if (_progress == null) return;

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(
            widget.userId, widget.exerciseId);
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
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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

    // v3.3+ 根據追蹤模式決定顯示內容
    final isWeightBased = _progress!.isWeightBasedMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v3.3+ 非重訓模式顯示提示訊息
          if (!isWeightBased) ...[
            _buildNonWeightModeHeader(),
            const SizedBox(height: 16),
          ],
          
          // v3.3+ 重訓模式才顯示統計卡片
          if (isWeightBased) ...[
            StatisticsCard(progress: _progress!),
            const SizedBox(height: 16),

            // v3.3+ 有詳細歷史記錄才顯示圖表和 PR
            if (_hasDetailedHistory && _progress!.history.isNotEmpty) ...[
              // 力量進步曲線
              StrengthChart(history: _progress!.history),
              const SizedBox(height: 16),

              // PR 記錄
              PRRecordsCard(
                prRecords: _progress!.history.where((p) => p.isPR).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // v3.3+ 無詳細歷史記錄時顯示提示
            if (!_hasDetailedHistory) ...[
              _buildNoHistoryHint(),
              const SizedBox(height: 16),
            ],
          ],

          // 歷史記錄（有記錄才顯示）
          if (_hasDetailedHistory && _progress!.history.isNotEmpty)
            TrainingHistoryCard(history: _progress!.history)
          else if (!_hasDetailedHistory)
            _buildBasicInfoCard(),
        ],
      ),
    );
  }
  
  /// v3.3+ 無詳細歷史記錄時的提示卡片
  Widget _buildNoHistoryHint() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '詳細訓練歷史記錄載入中，或暫無完整記錄',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// v3.3+ 基本信息卡片（當無詳細歷史時顯示）
  Widget _buildBasicInfoCard() {
    final data = widget.exerciseData;
    if (data == null) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本統計',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('最大重量', data.formattedMaxWeight),
            _buildStatRow('訓練組數', '${data.totalSets} 組'),
            _buildStatRow('最後訓練', data.formattedLastTrainingDate),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  /// v3.3+ 非重訓模式的標題提示
  Widget _buildNonWeightModeHeader() {
    final trackingMode = _progress!.trackingMode;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getTrackingModeIcon(trackingMode),
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackingMode.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '此動作不追蹤重量進步，僅顯示訓練歷史記錄',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// v3.3+ 根據追蹤模式取得圖示
  IconData _getTrackingModeIcon(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.weightReps:
      case TrackingMode.weightTime:
        return Icons.fitness_center;
      case TrackingMode.repsOnly:
        return Icons.repeat;
      case TrackingMode.timeOnly:
      case TrackingMode.repsTime:
        return Icons.timer;
      case TrackingMode.distanceTime:
      case TrackingMode.distanceOnly:
        return Icons.straighten;
      case TrackingMode.calories:
        return Icons.local_fire_department;
    }
  }
}

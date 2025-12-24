import 'package:flutter/material.dart';
import '../../models/favorite_exercise_model.dart';
import '../../models/statistics_model.dart';
import '../../services/interfaces/i_favorites_service.dart';
import '../../services/service_locator.dart';
import 'mini_line_chart.dart';

/// 收藏動作列表組件
/// 
/// 顯示使用者收藏的動作及其力量進步
class FavoriteExercisesList extends StatefulWidget {
  final String userId;
  final TimeRange timeRange;
  final List<ExerciseStrengthProgress> strengthProgress; // 接收外層的統計數據
  final Function(String exerciseId)? onExerciseTap;
  final VoidCallback? onAddMoreTap;

  const FavoriteExercisesList({
    Key? key,
    required this.userId,
    required this.timeRange,
    required this.strengthProgress, // 新增參數
    this.onExerciseTap,
    this.onAddMoreTap,
  }) : super(key: key);

  @override
  State<FavoriteExercisesList> createState() => _FavoriteExercisesListState();
}

class _FavoriteExercisesListState extends State<FavoriteExercisesList> {
  final IFavoritesService _favoritesService = serviceLocator<IFavoritesService>();
  
  List<FavoriteExercise> _favorites = [];
  Map<String, ExerciseStrengthProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didUpdateWidget(FavoriteExercisesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當外層統計數據更新時，重新建立映射
    if (oldWidget.strengthProgress != widget.strengthProgress) {
      _buildProgressMap();
    }
  }

  /// 建立力量進步映射
  void _buildProgressMap() {
    final Map<String, ExerciseStrengthProgress> progressMap = {};
    for (var progress in widget.strengthProgress) {
      progressMap[progress.exerciseId] = progress;
    }
    setState(() => _progressMap = progressMap);
  }

  /// 載入收藏列表
  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    
    try {
      // 獲取收藏列表
      final favorites = await _favoritesService.getFavoriteExercises(widget.userId);
      
      if (favorites.isEmpty) {
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
        return;
      }

      // 使用外層傳入的力量進步數據
      _buildProgressMap();

      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入收藏失敗: $e')),
        );
      }
    }
  }

  /// 移除收藏
  Future<void> _removeFavorite(String exerciseId) async {
    try {
      await _favoritesService.removeFavorite(widget.userId, exerciseId);
      await _loadFavorites();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移除收藏')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除收藏失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return const SizedBox.shrink(); // 沒有收藏時不顯示
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                '我的收藏動作',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // 使用 IconButton 替代 TextButton.icon 避免佈局問題
              IconButton(
                onPressed: () => _showManageFavoritesDialog(),
                icon: const Icon(Icons.settings, size: 20),
                tooltip: '管理收藏',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // 收藏列表
        ..._favorites.map((favorite) {
          final progress = _progressMap[favorite.exerciseId];
          return _buildFavoriteCard(favorite, progress);
        }),

        // 查看所有動作按鈕
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onAddMoreTap != null) {
                  widget.onAddMoreTap!();
                } else {
                  // 默認行為：顯示提示訊息
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('請設置 onAddMoreTap 回調'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('查看更多動作記錄'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 建立收藏卡片
  Widget _buildFavoriteCard(FavoriteExercise favorite, ExerciseStrengthProgress? progress) {
    final hasProgress = progress != null;
    final progressPercentage = progress?.progressPercentage ?? 0.0;
    final isPositive = progressPercentage > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => widget.onExerciseTap?.call(favorite.exerciseId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 動作名稱
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite.exerciseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // 身體部位標籤
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getBodyPartColor(favorite.bodyPart).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                favorite.bodyPart,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getBodyPartColor(favorite.bodyPart),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // 最後訓練時間
                            Text(
                              favorite.lastViewedAt != null
                                  ? '最後查看: ${_formatDate(favorite.lastViewedAt!)}'
                                  : '尚未查看',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 移除收藏按鈕
                  IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    onPressed: () => _removeFavorite(favorite.exerciseId),
                    tooltip: '取消收藏',
                  ),
                ],
              ),
              
              // 力量進步信息
              if (hasProgress) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 進步百分比標籤
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_flat,
                            size: 16,
                            color: isPositive ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            progress.formattedProgress,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 最大重量文字
                    Expanded(
                      child: Text(
                        '最大: ${progress.formattedCurrentMax}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // 迷你曲線圖
                    if (progress.history.length >= 2)
                      MiniLineChart(
                        dataPoints: progress.history,
                        width: 100,
                        height: 40,
                        lineColor: isPositive 
                            ? Theme.of(context).colorScheme.secondary 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fillColor: isPositive 
                            ? Theme.of(context).colorScheme.secondary 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  '尚未有訓練記錄',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示管理收藏對話框
  void _showManageFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('管理收藏'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final favorite = _favorites[index];
              return ListTile(
                title: Text(favorite.exerciseName),
                subtitle: Text(favorite.bodyPart),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFavorite(favorite.exerciseId),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return '今天';
    if (difference == 1) return '昨天';
    if (difference < 7) return '$difference 天前';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks 週前';
    }
    return '${date.month}/${date.day}';
  }

  /// 根據身體部位返回顏色
  Color _getBodyPartColor(String bodyPart) {
    if (bodyPart.contains('胸')) return Colors.red;
    if (bodyPart.contains('背')) return Colors.blue;
    if (bodyPart.contains('腿')) return Theme.of(context).colorScheme.secondary;
    if (bodyPart.contains('肩')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('手')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('核心') || bodyPart.contains('腹')) return Colors.teal;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}


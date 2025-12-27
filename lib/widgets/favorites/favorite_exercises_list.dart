import 'package:flutter/material.dart';
import '../../models/favorite_exercise_model.dart';
import '../../models/statistics_model.dart';
import '../../services/interfaces/i_favorites_service.dart';
import '../../services/service_locator.dart';
import '../../utils/notification_utils.dart';
import 'widgets/favorite_list_header.dart';
import 'widgets/favorite_exercise_card.dart';
import 'widgets/favorite_view_more_button.dart';
import 'widgets/favorite_manage_dialog.dart';

/// 收藏動作列表組件
/// 
/// 顯示使用者收藏的動作及其力量進步
class FavoriteExercisesList extends StatefulWidget {
  final String userId;
  final TimeRange timeRange;
  final List<ExerciseStrengthProgress> strengthProgress;
  final Function(String exerciseId)? onExerciseTap;
  final VoidCallback? onAddMoreTap;

  const FavoriteExercisesList({
    Key? key,
    required this.userId,
    required this.timeRange,
    required this.strengthProgress,
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
      final favorites = await _favoritesService.getFavoriteExercises(widget.userId);
      
      if (favorites.isEmpty) {
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
        return;
      }

      _buildProgressMap();

      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        NotificationUtils.showError(context, '載入收藏失敗: $e');
      }
    }
  }

  /// 移除收藏
  Future<void> _removeFavorite(String exerciseId) async {
    try {
      await _favoritesService.removeFavorite(widget.userId, exerciseId);
      await _loadFavorites();
      
      if (mounted) {
        NotificationUtils.showSuccess(context, '已移除收藏');
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '移除收藏失敗: $e');
      }
    }
  }

  /// 顯示管理收藏對話框
  void _showManageFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => FavoriteManageDialog(
        favorites: _favorites,
        onRemove: _removeFavorite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FavoriteListHeader(
            onManageTap: _showManageFavoritesDialog,
          ),
          ..._favorites.map((favorite) {
            final progress = _progressMap[favorite.exerciseId];
            return FavoriteExerciseCard(
              favorite: favorite,
              progress: progress,
              onTap: () => widget.onExerciseTap?.call(favorite.exerciseId),
              onToggleFavorite: () => _removeFavorite(favorite.exerciseId),
            );
          }),
          FavoriteViewMoreButton(
            onTap: widget.onAddMoreTap,
          ),
        ],
      ),
    );
  }
}


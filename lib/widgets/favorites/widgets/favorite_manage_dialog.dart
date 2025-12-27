import 'package:flutter/material.dart';
import '../../../models/favorite_exercise_model.dart';

/// 管理收藏對話框組件
class FavoriteManageDialog extends StatelessWidget {
  final List<FavoriteExercise> favorites;
  final Function(String exerciseId) onRemove;

  const FavoriteManageDialog({
    Key? key,
    required this.favorites,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('管理收藏'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final favorite = favorites[index];
            return ListTile(
              title: Text(favorite.exerciseName),
              subtitle: Text(favorite.bodyPart),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onRemove(favorite.exerciseId),
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
    );
  }
}


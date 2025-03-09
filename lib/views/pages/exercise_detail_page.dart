import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;
  
  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    // 使用actionName，如果為空則使用name
    final displayName = (exercise.actionName != null && exercise.actionName!.isNotEmpty) 
        ? exercise.actionName! 
        : exercise.name;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        actions: [
          // 新增動作選擇按鈕
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: '添加到訓練計畫',
            onPressed: () {
              // 返回所選的動作
              Navigator.pop(context, exercise);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 圖片部分
            _buildExerciseImage(),
            
            const SizedBox(height: 16),
            
            // 英文名稱部分
            if (exercise.nameEn.isNotEmpty) ...[
              Text(
                '英文名稱',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(exercise.nameEn),
              const SizedBox(height: 16),
            ],
            
            // 分類信息部分
            Text(
              '分類資訊',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exercise.type.isNotEmpty)
                    _buildInfoRow('訓練類型', exercise.type),
                  if (exercise.bodyParts.isNotEmpty)
                    _buildInfoRow('訓練部位', exercise.bodyParts.join(', ')),
                  if (exercise.equipment.isNotEmpty)
                    _buildInfoRow('所需器材', exercise.equipment),
                  if (exercise.level1.isNotEmpty)
                    _buildInfoRow('分類 1', exercise.level1),
                  if (exercise.level2.isNotEmpty)
                    _buildInfoRow('分類 2', exercise.level2),
                  if (exercise.level3.isNotEmpty)
                    _buildInfoRow('分類 3', exercise.level3),
                  if (exercise.level4.isNotEmpty)
                    _buildInfoRow('分類 4', exercise.level4),
                  if (exercise.level5.isNotEmpty)
                    _buildInfoRow('分類 5', exercise.level5),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 描述部分
            if (exercise.description.isNotEmpty) ...[
              Text(
                '描述',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(exercise.description),
              ),
              const SizedBox(height: 16),
            ],
            
            // 視頻部分
            if (exercise.videoUrl.isNotEmpty) ...[
              Text(
                '教學影片',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('觀看教學影片'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('視頻播放功能開發中')),
                  );
                },
              ),
            ],
            
            // 添加到訓練計畫按鈕
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('添加到訓練計畫'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  // 返回所選的動作
                  Navigator.pop(context, exercise);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExerciseImage() {
    try {
      if (exercise.imageUrl.isNotEmpty) {
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              exercise.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported, size: 50),
                        SizedBox(height: 8),
                        Text('圖片無法顯示'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Center(
          child: Text('無圖片'),
        ),
      );
    } catch (e) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.red[100],
        child: Center(
          child: Text('圖片處理錯誤: ${e.toString().substring(0, 
              e.toString().length > 100 ? 100 : e.toString().length)}...'),
        ),
      );
    }
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 
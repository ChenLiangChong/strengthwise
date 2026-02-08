// ✅ 已響應式改造 (Phase 0) - 動作詳情頁
// v5.0: 全新分類欄位展示（依語系顯示對應語言）
import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/interfaces/i_exercise_controller.dart';
import 'package:strengthwise/models/exercise/exercise_labels.dart';
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 動作詳情頁 — v5.0 全新分類欄位展示
class ExerciseDetailPage extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  /// 參照表 ID → 顯示名稱
  final Map<String, String> _movementZh = {};
  final Map<String, String> _movementEn = {};
  final Map<String, String> _muscleZh = {};
  final Map<String, String> _muscleEn = {};
  Exercise get _ex => widget.exercise;

  @override
  void initState() {
    super.initState();
    _loadRefData();
  }

  /// 載入參照表資料，建立 ID → 名稱的查找映射
  Future<void> _loadRefData() async {
    final controller = serviceLocator<IExerciseController>();
    final results = await Future.wait([
      controller.getMovementPatterns(),
      controller.getMuscleGroups(),
    ]);

    if (!mounted) return;

    setState(() {
      for (final p in results[0]) {
        _movementZh[p['id'] ?? ''] = p['nameZh'] ?? '';
        _movementEn[p['id'] ?? ''] = p['nameEn'] ?? '';
      }
      for (final m in results[1]) {
        _muscleZh[m['id'] ?? ''] = m['nameZh'] ?? '';
        _muscleEn[m['id'] ?? ''] = m['nameEn'] ?? '';
      }
    });
  }

  /// 判斷是否使用英文顯示
  /// TODO: 接入 app 語言設定後改為讀取用戶偏好
  bool _isEnglish() => false;

  String _resolveMovement(String id, {required bool isEn}) =>
      isEn ? (_movementEn[id] ?? id) : (_movementZh[id] ?? id);

  String _resolveMuscle(String id, {required bool isEn}) =>
      isEn ? (_muscleEn[id] ?? id) : (_muscleZh[id] ?? id);

  @override
  Widget build(BuildContext context) {
    final isEn = _isEnglish();

    // 依語系選擇名稱
    final title = isEn ? _ex.displayNameEn : _ex.displayName;
    final subtitle = isEn ? _ex.displayName : _ex.displayNameEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isNotEmpty ? title : _ex.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: isEn ? 'Add to workout' : '添加到訓練計畫',
            onPressed: () => Navigator.pop(context, _ex),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 圖片 ──
            _ExerciseImage(imageUrl: _ex.imageUrl),
            const SizedBox(height: 16),

            // ── 副標題（另一語言名稱）──
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // ── 快速分類標籤 ──
            _QuickPropertyChips(exercise: _ex, isEn: isEn),
            const SizedBox(height: 16),

            // ── 動作模式 ──
            if (_ex.movementPatterns.isNotEmpty) ...[
              _SectionHeader(title: isEn ? 'Movement Patterns' : '動作模式'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ex.movementPatterns.map((id) {
                  return _PropertyChip(
                    label: _resolveMovement(id, isEn: isEn),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── 目標肌群 ──
            _MuscleInfoCard(
              exercise: _ex,
              isEn: isEn,
              resolveMuscle: _resolveMuscle,
            ),
            const SizedBox(height: 12),

            // ── 器材資訊 ──
            if (_ex.equipmentCategory.isNotEmpty) ...[
              _EquipmentInfoCard(exercise: _ex, isEn: isEn),
              const SizedBox(height: 12),
            ],

            // ── 追蹤模式 ──
            _TrackingModeRow(trackingMode: _ex.trackingMode, isEn: isEn),

            // ── 描述 ──
            if (_ex.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(title: isEn ? 'Description' : '描述'),
              const SizedBox(height: 8),
              Text(
                _ex.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            // ── 添加按鈕 ──
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text(isEn ? 'Add to Workout' : '添加到訓練計畫'),
                onPressed: () => Navigator.pop(context, _ex),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 子組件
// ══════════════════════════════════════════════════════════════════

/// 區塊標題
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }
}

/// 動作圖片
class _ExerciseImage extends StatelessWidget {
  final String imageUrl;
  const _ExerciseImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    if (imageUrl.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.fitness_center, size: 48)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: bgColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stack) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported, size: 48),
                  SizedBox(height: 8),
                  Text('圖片無法顯示'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 屬性標籤 Chip
class _PropertyChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  const _PropertyChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: foregroundColor,
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foregroundColor),
                const SizedBox(width: 4),
                Text(label, style: style),
              ],
            )
          : Text(label, style: style),
    );
  }
}

/// 快速分類標籤列
class _QuickPropertyChips extends StatelessWidget {
  final Exercise exercise;
  final bool isEn;
  const _QuickPropertyChips({required this.exercise, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 訓練類型
        if (exercise.trainingType.isNotEmpty)
          _PropertyChip(
            label: isEn
                ? exercise.trainingTypeEn
                : exercise.trainingType,
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
          ),

        // PPL 標籤
        for (final tag in exercise.pplTags)
          if (ExerciseLabels.ppl.containsKey(tag))
            _PropertyChip(
              label: ExerciseLabels.resolve(ExerciseLabels.ppl, tag, isEn: isEn),
              backgroundColor: cs.secondaryContainer,
              foregroundColor: cs.onSecondaryContainer,
            ),

        // 動作類型（複合/孤立）
        if (ExerciseLabels.mechanics.containsKey(exercise.mechanicsType))
          _PropertyChip(
            label: ExerciseLabels.resolve(ExerciseLabels.mechanics, exercise.mechanicsType,
                isEn: isEn),
            backgroundColor: cs.tertiaryContainer,
            foregroundColor: cs.onTertiaryContainer,
          ),

        // 難度等級
        if (ExerciseLabels.difficulty.containsKey(exercise.difficultyLevel))
          _PropertyChip(
            label: ExerciseLabels.resolve(ExerciseLabels.difficulty, exercise.difficultyLevel,
                isEn: isEn),
            backgroundColor: cs.surfaceContainerHighest,
            foregroundColor: cs.onSurface,
          ),

        // 單側動作
        if (exercise.isUnilateral)
          _PropertyChip(
            label: isEn ? 'Unilateral' : '單側',
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
            icon: Icons.swap_horiz,
          ),

        // 爆發力
        if (exercise.isExplosive)
          _PropertyChip(
            label: isEn ? 'Explosive' : '爆發力',
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
            icon: Icons.bolt,
          ),
      ],
    );
  }
}

/// 資訊行（標題 + 值）
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// 目標肌群卡片
class _MuscleInfoCard extends StatelessWidget {
  final Exercise exercise;
  final bool isEn;
  final String Function(String id, {required bool isEn}) resolveMuscle;

  const _MuscleInfoCard({
    required this.exercise,
    required this.isEn,
    required this.resolveMuscle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMuscleData = exercise.bodyPart.isNotEmpty ||
        (exercise.primaryMuscle ?? '').isNotEmpty ||
        exercise.specificMuscle.isNotEmpty ||
        exercise.synergistMuscles.isNotEmpty;

    if (!hasMuscleData) return const SizedBox.shrink();

    // 解析主動肌
    final primaryId = exercise.primaryMuscle ?? '';
    final primaryName =
        primaryId.isNotEmpty ? resolveMuscle(primaryId, isEn: isEn) : '';

    // 解析協同肌
    final synergists = exercise.synergistMuscles
        .map((id) => resolveMuscle(id, isEn: isEn))
        .toList();

    // 依語系選擇欄位值
    final bodyPart = isEn ? exercise.bodyPartEn : exercise.bodyPart;
    final specificMuscle =
        isEn ? exercise.specificMuscleEn : exercise.specificMuscle;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? 'Target Muscles' : '目標肌群',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            if (bodyPart.isNotEmpty)
              _InfoRow(
                label: isEn ? 'Body Part' : '主要部位',
                value: bodyPart,
              ),

            if (primaryName.isNotEmpty)
              _InfoRow(
                label: isEn ? 'Primary' : '主動肌',
                value: primaryName,
              ),

            if (specificMuscle.isNotEmpty)
              _InfoRow(
                label: isEn ? 'Target' : '目標肌群',
                value: specificMuscle,
              ),

            if (synergists.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      isEn ? 'Synergist' : '協同肌群',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: synergists
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(s,
                                    style: theme.textTheme.labelMedium),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 器材資訊卡片
class _EquipmentInfoCard extends StatelessWidget {
  final Exercise exercise;
  final bool isEn;
  const _EquipmentInfoCard({required this.exercise, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category =
        isEn ? exercise.equipmentCategoryEn : exercise.equipmentCategory;
    final subcategory = isEn
        ? exercise.equipmentSubcategoryEn
        : exercise.equipmentSubcategory;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? 'Equipment' : '器材資訊',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: isEn ? 'Category' : '器材分類',
              value: category,
            ),
            if (subcategory.isNotEmpty)
              _InfoRow(
                label: isEn ? 'Type' : '器材子分類',
                value: subcategory,
              ),
          ],
        ),
      ),
    );
  }
}

/// 追蹤模式顯示
class _TrackingModeRow extends StatelessWidget {
  final TrackingMode trackingMode;
  final bool isEn;
  const _TrackingModeRow({required this.trackingMode, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = isEn ? 'Tracking: ' : '追蹤模式：';

    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$prefix${trackingMode.displayName}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../controllers/interfaces/i_exercise_controller.dart';

/// 動作庫偏好設定頁面
///
/// 設定項目：
/// 1. 瀏覽模式（解剖學 / 動作模式）
/// 2. 我的器材（多選，進入動作庫時預設勾選）
class ExercisePreferencesPage extends StatefulWidget {
  final IExerciseController controller;
  final List<Map<String, String>> equipmentOptions;

  const ExercisePreferencesPage({
    super.key,
    required this.controller,
    required this.equipmentOptions,
  });

  @override
  State<ExercisePreferencesPage> createState() =>
      _ExercisePreferencesPageState();
}

class _ExercisePreferencesPageState extends State<ExercisePreferencesPage> {
  late String _browseMode;
  late Set<String> _myEquipment;

  @override
  void initState() {
    super.initState();
    _browseMode = widget.controller.preferredBrowseMode;
    _myEquipment = Set<String>.from(widget.controller.myEquipment);
  }

  Future<void> _saveBrowseMode(String mode) async {
    setState(() => _browseMode = mode);
    await widget.controller.setPreferredBrowseMode(mode);
  }

  Future<void> _toggleEquipment(String id) async {
    setState(() {
      if (_myEquipment.contains(id)) {
        _myEquipment.remove(id);
      } else {
        _myEquipment.add(id);
      }
    });
    await widget.controller.setMyEquipment(_myEquipment);
  }

  Future<void> _selectAllEquipment() async {
    setState(() {
      _myEquipment = widget.equipmentOptions
          .map((e) => e['id'] ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    });
    await widget.controller.setMyEquipment(_myEquipment);
  }

  Future<void> _clearAllEquipment() async {
    setState(() => _myEquipment = {});
    await widget.controller.setMyEquipment(_myEquipment);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('動作庫設定')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth - 32,
                maxWidth: constraints.maxWidth - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================================
                  // Section 1: 瀏覽模式
                  // =============================================
                  Text('瀏覽模式', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '選擇進入重量訓練時的預設瀏覽方式',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.swap_vert, size: 18),
                        label: const Text('動作模式'),
                        selected: _browseMode == 'pattern',
                        onSelected: (_) => _saveBrowseMode('pattern'),
                        showCheckmark: false,
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.accessibility_new, size: 18),
                        label: const Text('解剖學'),
                        selected: _browseMode == 'anatomy',
                        onSelected: (_) => _saveBrowseMode('anatomy'),
                        showCheckmark: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // =============================================
                  // Section 2: 我的器材
                  // =============================================
                  Text('我的器材', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '勾選你的健身房有的器材，進入動作庫時會自動預設篩選',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: _myEquipment.length ==
                                widget.equipmentOptions.length
                            ? _clearAllEquipment
                            : _selectAllEquipment,
                        child: Text(
                          _myEquipment.length ==
                                  widget.equipmentOptions.length
                              ? '取消全選'
                              : '全選',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.equipmentOptions.map((item) {
                    final id = item['id'] ?? '';
                    final name = item['nameZh'] ?? id;
                    final isChecked = _myEquipment.contains(id);
                    return CheckboxListTile(
                      title: Text(name),
                      value: isChecked,
                      onChanged: (_) => _toggleEquipment(id),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

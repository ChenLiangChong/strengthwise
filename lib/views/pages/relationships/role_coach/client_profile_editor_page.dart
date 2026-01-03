import 'package:flutter/material.dart';
import 'package:strengthwise/models/client_profile_model.dart';

/// 學員檔案編輯頁面
/// 
/// 用於創建或編輯學員檔案
class ClientProfileEditorPage extends StatefulWidget {
  /// 現有檔案（編輯模式）
  final ClientProfile? existingProfile;
  
  /// 學員名稱（顯示在標題）
  final String clientName;

  const ClientProfileEditorPage({
    super.key,
    this.existingProfile,
    required this.clientName,
  });

  @override
  State<ClientProfileEditorPage> createState() => _ClientProfileEditorPageState();
}

class _ClientProfileEditorPageState extends State<ClientProfileEditorPage> {
  late final TextEditingController _goalsController;
  late final TextEditingController _healthNotesController;
  late final TextEditingController _preferencesController;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _goalsController = TextEditingController(
      text: widget.existingProfile?.goals ?? '',
    );
    _healthNotesController = TextEditingController(
      text: widget.existingProfile?.healthNotes ?? '',
    );
    _preferencesController = TextEditingController(
      text: widget.existingProfile?.preferences ?? '',
    );
  }

  @override
  void dispose() {
    _goalsController.dispose();
    _healthNotesController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  /// 儲存檔案
  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profile = ClientProfile(
      goals: _goalsController.text.trim(),
      healthNotes: _healthNotesController.text.trim().isEmpty 
          ? null 
          : _healthNotesController.text.trim(),
      preferences: _preferencesController.text.trim().isEmpty 
          ? null 
          : _preferencesController.text.trim(),
      assessmentDate: widget.existingProfile?.assessmentDate ?? DateTime.now(),
    );

    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '編輯學員檔案' : '建立學員檔案'),
        actions: [
          IconButton(
            onPressed: _saveProfile,
            icon: const Icon(Icons.check),
            tooltip: '儲存',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 學員名稱提示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '學員檔案',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.clientName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 訓練目標（必填）
            TextFormField(
              controller: _goalsController,
              decoration: InputDecoration(
                labelText: '訓練目標 *',
                hintText: '例如：減重10kg、增加肌肉量、改善體態',
                prefixIcon: const Icon(Icons.flag_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: '學員的主要訓練目標',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入訓練目標';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 健康注意事項（選填）
            TextFormField(
              controller: _healthNotesController,
              decoration: InputDecoration(
                labelText: '健康注意事項',
                hintText: '例如：右膝舊傷、腰椎問題',
                prefixIcon: const Icon(Icons.healing_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: '舊傷、不適部位、需要注意的健康狀況',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            
            const SizedBox(height: 16),
            
            // 訓練偏好（選填）
            TextFormField(
              controller: _preferencesController,
              decoration: InputDecoration(
                labelText: '訓練偏好',
                hintText: '例如：偏好重訓、不喜歡跑步',
                prefixIcon: const Icon(Icons.favorite_border),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: '學員喜歡或不喜歡的訓練項目',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saveProfile(),
            ),
            
            const SizedBox(height: 24),
            
            // 提示卡片
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '使用建議',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 建議每次上課前快速回顧學員檔案\n'
                            '• 確保訓練計劃符合學員目標\n'
                            '• 注意健康狀況，避免不適動作',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 底部儲存按鈕（大按鈕）
            FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check),
              label: Text(isEdit ? '儲存變更' : '建立檔案'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


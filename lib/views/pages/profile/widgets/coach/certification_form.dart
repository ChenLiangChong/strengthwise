import 'package:flutter/material.dart';
import 'package:strengthwise/models/coach_profile/certification_model.dart';

/// 證照列表表單
/// 
/// 支援：
/// 1. 新增證照（一次新增一個）
/// 2. 刪除證照
/// 3. 結構化輸入（機構、名稱、年份）
class CertificationForm extends StatefulWidget {
  /// 證照列表
  final List<CertificationModel> certifications;

  /// 新增證照回調
  final ValueChanged<CertificationModel> onAdd;

  /// 刪除證照回調
  final ValueChanged<int> onRemove;

  const CertificationForm({
    super.key,
    required this.certifications,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<CertificationForm> createState() => _CertificationFormState();
}

class _CertificationFormState extends State<CertificationForm> {
  bool _showAddForm = false;
  final _orgController = TextEditingController();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  String? _selectedOrg;

  @override
  void dispose() {
    _orgController.dispose();
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _addCertification() {
    final org = _selectedOrg == '其他' 
        ? _orgController.text.trim()
        : _selectedOrg ?? _orgController.text.trim();
    final name = _nameController.text.trim();
    final yearText = _yearController.text.trim();
    
    if (org.isEmpty || name.isEmpty) {
      return;
    }

    final year = int.tryParse(yearText);
    
    widget.onAdd(CertificationModel(
      organization: org,
      name: name,
      year: year,
    ));

    _resetForm();
  }

  void _resetForm() {
    _orgController.clear();
    _nameController.clear();
    _yearController.clear();
    _selectedOrg = null;
    setState(() => _showAddForm = false);
  }

  /// 建立新增表單（獨立方法避免佈局問題）
  Widget _buildAddForm(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 發證機構下拉選單
            DropdownButtonFormField<String>(
              initialValue: _selectedOrg,
              decoration: const InputDecoration(
                labelText: '發證機構',
                isDense: true,
              ),
              items: CertificationOrganization.common.map((org) {
                return DropdownMenuItem(
                  value: org,
                  child: Text(org),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedOrg = value);
              },
            ),
            
            // 自定義機構輸入（當選擇「其他」時）
            if (_selectedOrg == '其他') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _orgController,
                decoration: const InputDecoration(
                  labelText: '機構名稱',
                  hintText: '請輸入機構名稱',
                  isDense: true,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 證照名稱
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '證照名稱',
                hintText: '例如：CPT、CSCS',
                isDense: true,
              ),
            ),

            const SizedBox(height: 16),

            // 取得年份
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: '取得年份（選填）',
                hintText: '例如：2020',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // 按鈕
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _resetForm,
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: _addCertification,
                  child: const Text('新增'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Text(
          '專業證照（選填）',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // 證照列表
        if (widget.certifications.isNotEmpty) ...[
          ...widget.certifications.asMap().entries.map((entry) {
            final index = entry.key;
            final cert = entry.value;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    cert.organization.isNotEmpty 
                        ? cert.organization[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(cert.shortName),
                subtitle: cert.year != null ? Text('${cert.year} 年') : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => widget.onRemove(index),
                  color: colorScheme.error,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // 新增表單
        if (_showAddForm)
          _buildAddForm(colorScheme)
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showAddForm = true),
              icon: const Icon(Icons.add),
              label: const Text('新增證照'),
            ),
          ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/session_note_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/notes/session_note_editor_page.dart';
import 'package:strengthwise/views/pages/notes/drawing_viewer_page.dart';
import 'package:strengthwise/views/pages/notes/widgets/soap_section_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 課程筆記詳情頁面
///
/// 功能：
/// - 顯示完整的 SOAP 筆記內容
/// - 顯示視覺元素（照片、手繪等）
/// - 編輯筆記
/// - 切換隱私設定
class SessionNoteDetailPage extends StatefulWidget {
  final String noteId;

  const SessionNoteDetailPage({
    Key? key,
    required this.noteId,
  }) : super(key: key);

  @override
  State<SessionNoteDetailPage> createState() => _SessionNoteDetailPageState();
}

class _SessionNoteDetailPageState extends State<SessionNoteDetailPage> {
  late final SessionNoteController _controller;
  late final IAuthController _authController;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<SessionNoteController>();
    _authController = serviceLocator<IAuthController>();
    _isInitialized = true;
    _loadNote();
  }

  /// 載入筆記
  Future<void> _loadNote() async {
    debugPrint('[NOTE_DETAIL] 🔵 開始載入筆記');
    debugPrint('[NOTE_DETAIL] 🆔 筆記 ID: ${widget.noteId}');

    setState(() => _isLoading = true);

    try {
      await _controller.loadNoteById(widget.noteId);

      final note = _controller.selectedNote;
      if (note != null) {
        debugPrint('[NOTE_DETAIL] ✅ 筆記載入成功');
        debugPrint('[NOTE_DETAIL] 👤 教練 ID: ${note.coachId}');
        debugPrint('[NOTE_DETAIL] 👨‍🎓 學員 ID: ${note.clientId}');
        debugPrint('[NOTE_DETAIL] 🔒 隱私: ${note.visibility}');
        debugPrint('[NOTE_DETAIL] 🖼️ 視覺元素數量: ${note.visualElements.length}');

        // 列出所有視覺元素
        for (var i = 0; i < note.visualElements.length; i++) {
          final element = note.visualElements[i];
          debugPrint('[NOTE_DETAIL] 📦 元素 $i: 類型=${element.type}');
          if (element is PhotoElementModel) {
            debugPrint('[NOTE_DETAIL]    📸 照片路徑: ${element.storagePath}');
          }
        }
      } else {
        debugPrint('[NOTE_DETAIL] ⚠️ 筆記為 null');
      }
    } catch (e) {
      debugPrint('[NOTE_DETAIL] ❌ 載入失敗: $e');
      debugPrint('[NOTE_DETAIL] 📋 Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入失敗: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
      debugPrint('[NOTE_DETAIL] 🔵 載入流程結束');
    }
  }

  /// 編輯筆記
  Future<void> _editNote(SessionNoteModel note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SessionNoteEditorPage(
          noteId: note.id,
        ),
      ),
    );

    // 如果有修改，重新載入
    if (result == true) {
      _loadNote();
    }
  }

  /// 切換隱私設定
  Future<void> _toggleVisibility(SessionNoteModel note) async {
    final newVisibility = note.isPrivate ? 'shared' : 'private';

    try {
      final updatedNote = note.copyWith(visibility: newVisibility);
      await _controller.updateNote(updatedNote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newVisibility == 'shared' ? '已設為共享' : '已設為私人'),
          ),
        );
      }

      // 重新載入
      _loadNote();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e')),
        );
      }
    }
  }

  /// 刪除筆記
  Future<void> _deleteNote(SessionNoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: const Text('刪除筆記'),
        content: const Text('確定要刪除此筆記嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteNote(note.id);

        if (mounted) {
          Navigator.pop(context, true); // 返回並標記為已修改
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('筆記詳情'),
          actions: [
            // 更多選項（僅教練可見）
            Consumer<SessionNoteController>(
              builder: (context, controller, child) {
                // 確保已初始化
                if (!_isInitialized) {
                  return const SizedBox.shrink();
                }

                final note = controller.selectedNote;
                final currentUser = _authController.user;

                if (note == null || currentUser == null) {
                  return const SizedBox.shrink();
                }

                // 只有教練（筆記創建者）才能編輯
                final isCoach = note.coachId == currentUser.uid;
                if (!isCoach) {
                  return const SizedBox.shrink();
                }

                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editNote(note);
                        break;
                      case 'toggle_visibility':
                        _toggleVisibility(note);
                        break;
                      case 'delete':
                        _deleteNote(note);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('編輯'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_visibility',
                      child: Row(
                        children: [
                          Icon(note.isPrivate
                              ? Icons.share_outlined
                              : Icons.lock_outlined),
                          const SizedBox(width: 8),
                          Text(note.isPrivate ? '設為共享' : '設為私人'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('刪除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Consumer<SessionNoteController>(
                builder: (context, controller, child) {
                  // 確保已初始化
                  if (!_isInitialized) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final note = controller.selectedNote;

                  if (note == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64),
                          const SizedBox(height: 16),
                          const Text('筆記不存在'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('返回'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadNote,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 筆記標題
                          _buildTitleSection(note),

                          const SizedBox(height: 16),

                          // 標題資訊卡
                          _buildHeaderCard(note),

                          const SizedBox(height: 16),

                          // 快速標籤
                          if (note.quickTags.isNotEmpty) ...[
                            _buildQuickTags(note.quickTags),
                            const SizedBox(height: 16),
                          ],

                          // SOAP 內容
                          if (note.soap != null && !note.soap!.isEmpty)
                            _buildSoapContent(note.soap!),

                          // 視覺元素
                          if (note.hasVisualElements) ...[
                            const SizedBox(height: 16),
                            _buildVisualElements(note),
                          ],

                          // 空狀態（僅教練可編輯）
                          if (note.isEmpty &&
                              note.coachId == _authController.user?.uid) ...[
                            const SizedBox(height: 32),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.note_outlined, size: 64),
                                  const SizedBox(height: 16),
                                  const Text('此筆記尚無內容'),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _editNote(note),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('開始編輯'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// 筆記標題區塊
  Widget _buildTitleSection(SessionNoteModel note) {
    final theme = Theme.of(context);

    return Text(
      note.title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 標題資訊卡
  Widget _buildHeaderCard(SessionNoteModel note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 學員資訊
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.clientName ?? '已刪除的學員',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(note.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // 隱私狀態標籤
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: note.isShared
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        note.isShared ? Icons.share : Icons.lock,
                        size: 14,
                        color: note.isShared
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.isShared ? '共享' : '私人',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: note.isShared
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 快速標籤
  Widget _buildQuickTags(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Chip(
          label: Text(tag),
          labelStyle: Theme.of(context).textTheme.labelSmall,
        );
      }).toList(),
    );
  }

  /// SOAP 內容
  Widget _buildSoapContent(SoapNoteModel soap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (soap.subjective != null && soap.subjective!.isNotEmpty)
          SoapSectionCard(
            title: 'S - 主觀描述',
            content: soap.subjective!,
            icon: Icons.person_outline,
            color: Colors.blue,
          ),
        if (soap.objective != null && soap.objective!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoapSectionCard(
            title: 'O - 客觀觀察',
            content: soap.objective!,
            icon: Icons.visibility_outlined,
            color: Colors.green,
          ),
        ],
        if (soap.assessment != null && soap.assessment!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoapSectionCard(
            title: 'A - 評估',
            content: soap.assessment!,
            icon: Icons.assessment_outlined,
            color: Colors.orange,
          ),
        ],
        if (soap.plan != null && soap.plan!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoapSectionCard(
            title: 'P - 計劃',
            content: soap.plan!,
            icon: Icons.calendar_today_outlined,
            color: Colors.purple,
          ),
        ],
      ],
    );
  }

  /// 視覺元素
  Widget _buildVisualElements(SessionNoteModel note) {
    debugPrint('[NOTE_DETAIL] 🖼️ 開始建構視覺元素 UI');
    debugPrint('[NOTE_DETAIL] 📦 總視覺元素數量: ${note.visualElements.length}');

    return Column(
      children: [
        // 繪圖元素
        if (note.hasDrawings) ...[
          _buildDrawingElements(note),
          const SizedBox(height: 16),
        ],

        // 照片元素
        _buildPhotoElements(note),
      ],
    );
  }

  /// 繪圖元素區塊
  Widget _buildDrawingElements(SessionNoteModel note) {
    final drawingElements = note.visualElements
        .where((e) => e.type == 'drawing')
        .cast<DrawingElementModel>()
        .toList();

    if (drawingElements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.draw, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '手繪標註 (${drawingElements.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 繪圖列表
            ...drawingElements.map((drawing) {
              return _buildDrawingCard(drawing);
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// 繪圖卡片
  Widget _buildDrawingCard(DrawingElementModel drawing) {
    final theme = Theme.of(context);

    // 提取底圖類型
    String templateName = '底圖';
    if (drawing.templateType != null) {
      switch (drawing.templateType) {
        case 'note1':
          templateName = '三視圖（前/側/背）';
          break;
        case 'note2':
          templateName = '前視圖';
          break;
        case 'note3':
          templateName = '側視圖';
          break;
        case 'note4':
          templateName = '背視圖';
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.draw,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(templateName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (drawing.drawingData != null)
              Text(
                '向量繪圖 • 只讀',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            if (drawing.createdAt != null)
              Text(
                '創建於 ${_formatDate(drawing.createdAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          // 打開繪圖查看器（只讀模式）
          if (drawing.drawingData != null && drawing.templateType != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DrawingViewerPage(
                  drawingData: drawing.drawingData!,
                  templateType: drawing.templateType!,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('繪圖數據不完整')),
            );
          }
        },
      ),
    );
  }

  /// 照片元素區塊
  Widget _buildPhotoElements(SessionNoteModel note) {
    // 過濾出照片元素
    final photoElements = note.visualElements
        .where((e) => e.type == 'photo')
        .cast<PhotoElementModel>()
        .toList();

    debugPrint('[NOTE_DETAIL] 📸 照片元素數量: ${photoElements.length}');

    if (photoElements.isEmpty) {
      debugPrint('[NOTE_DETAIL] ℹ️ 沒有照片元素，隱藏區塊');
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '照片 (${photoElements.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // 照片網格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: photoElements.length,
              itemBuilder: (context, index) {
                return _buildPhotoThumbnail(photoElements[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 照片縮圖
  Widget _buildPhotoThumbnail(PhotoElementModel photo) {
    debugPrint('[NOTE_DETAIL] 🖼️ 開始建構照片縮圖: ${photo.storagePath}');

    return FutureBuilder<String>(
      future: _getPhotoUrl(photo.storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('[NOTE_DETAIL] ⏳ 正在載入照片 URL...');
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          debugPrint('[NOTE_DETAIL] ❌ 照片 URL 載入失敗');
          debugPrint('[NOTE_DETAIL] 錯誤: ${snapshot.error}');
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    '載入失敗',
                    style: TextStyle(fontSize: 10, color: Colors.red[300]),
                  ),
                ],
              ),
            ),
          );
        }

        debugPrint('[NOTE_DETAIL] ✅ 照片 URL 載入成功: ${snapshot.data}');

        return GestureDetector(
          onTap: () => _showPhotoDialog(snapshot.data!, photo.caption),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(snapshot.data!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 獲取照片 URL（Supabase Storage Signed URL）
  Future<String> _getPhotoUrl(String storagePath) async {
    debugPrint('[NOTE_DETAIL] 🔗 開始獲取照片 URL');
    debugPrint('[NOTE_DETAIL] 📂 Storage 路徑: $storagePath');
    debugPrint('[NOTE_DETAIL] 🪣 Bucket: session_photos');

    try {
      final supabase = Supabase.instance.client;
      // 生成 24 小時有效的 signed URL
      final signedUrl = supabase.storage
          .from('session_photos') // ✅ 修正：使用下劃線，不是破折號
          .createSignedUrl(storagePath, 86400); // 24 小時

      debugPrint('[NOTE_DETAIL] ✅ Signed URL 生成成功');
      debugPrint('[NOTE_DETAIL] 🔗 URL: $signedUrl');

      return signedUrl;
    } catch (e) {
      debugPrint('[NOTE_DETAIL] ❌ 獲取照片 URL 失敗: $e');
      debugPrint('[NOTE_DETAIL] 📋 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// 顯示照片大圖對話框
  void _showPhotoDialog(String photoUrl, String? caption) {
    showDialog(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 照片
            InteractiveViewer(
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[900],
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text('載入失敗', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 說明
            if (caption != null && caption.isNotEmpty) ...[
              Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Text(
                  caption,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            // 關閉按鈕
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('關閉', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    // ⭐ date 已經是本地時間，不需要 .toLocal()
    return '${date.year}/${date.month}/${date.day} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

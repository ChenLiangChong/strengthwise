// ✅ 已響應式改造 (Phase 0)
// ignore_for_file: deprecated_member_use - RadioListTile API 待遷移到 RadioGroup

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:strengthwise/controllers/interfaces/i_session_note_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_drawing_controller.dart';
import 'package:strengthwise/controllers/drawing_controller.dart' show DrawingController; // 靜態方法
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';
import 'package:strengthwise/models/drawing_note_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/notes/widgets/soap_field_card.dart';
import 'package:strengthwise/views/pages/notes/widgets/photo_picker_sheet.dart';
import 'package:strengthwise/views/pages/notes/widgets/photo_upload_card.dart';
import 'package:strengthwise/views/pages/notes/widgets/uploaded_photo_grid.dart';
import 'package:strengthwise/views/pages/notes/widgets/quick_tags_section.dart';
import 'package:strengthwise/views/pages/notes/drawing_canvas_page.dart';
import 'dart:io';

/// 課程筆記編輯頁面
///
/// 響應式設計：表單區域限制最大寬度 600dp
///
/// 功能：
/// - 創建或編輯 SOAP 課程筆記
/// - S.O.A.P 四欄位輸入
/// - 隱私控制（私人/分享）
/// - 快速標籤
class SessionNoteEditorPage extends StatefulWidget {
  /// 筆記 ID（編輯模式）
  final String? noteId;

  /// 學員 ID（創建模式必填）
  final String? clientId;

  /// 關聯預約 ID
  final String? appointmentId;

  const SessionNoteEditorPage({
    Key? key,
    this.noteId,
    this.clientId,
    this.appointmentId,
  }) : super(key: key);

  @override
  State<SessionNoteEditorPage> createState() => _SessionNoteEditorPageState();
}

class _SessionNoteEditorPageState extends State<SessionNoteEditorPage> {
  late final ISessionNoteController _controller;
  late final IAuthController _authController;

  // 標題控制器
  final _titleController = TextEditingController();

  // SOAP 欄位控制器
  final _subjectiveController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _assessmentController = TextEditingController();
  final _planController = TextEditingController();

  // 隱私設定
  String _visibility = 'private';

  // 快速標籤
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    '首次評估',
    '進步顯著',
    '需要調整',
    '狀態良好',
    '需要追蹤',
    '特殊狀況',
  ];

  // 載入狀態
  bool _isLoading = false;
  bool _isSaving = false;

  // 照片列表
  final List<File> _photos = [];
  final List<String> _uploadedPhotoUrls = [];
  bool _isUploadingPhotos = false;
  double _uploadProgress = 0.0;

  // 【手繪板】臨時 Session ID 列表（新建模式下支援多次繪圖）
  final List<String> _tempSessionNoteIds = [];

  // 【每個模板對應臨時 ID（避免重複創建）】
  final Map<String, String> _tempIdsByTemplate = {};

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<ISessionNoteController>();
    _authController = serviceLocator<IAuthController>();

    // 編輯模式：載入現有筆記
    if (widget.noteId != null) {
      _loadNote();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    super.dispose();
  }

  /// 載入現有筆記
  Future<void> _loadNote() async {
    setState(() => _isLoading = true);

    try {
      await _controller.loadNoteById(widget.noteId!);
      final note = _controller.selectedNote;

      if (note != null) {
        setState(() {
          // 填充標題
          _titleController.text = note.title;

          // 填充 SOAP 欄位
          final soap = note.soap;
          if (soap != null) {
            _subjectiveController.text = soap.subjective ?? '';
            _objectiveController.text = soap.objective ?? '';
            _assessmentController.text = soap.assessment ?? '';
            _planController.text = soap.plan ?? '';
          }

          // 設定隱私
          _visibility = note.visibility;

          // 設定標籤
          _selectedTags.clear();
          _selectedTags.addAll(note.quickTags);

          // 【載入照片 URL】
          debugPrint('[NOTE_EDITOR] 📷 開始載入照片');
          debugPrint('[NOTE_EDITOR] 📊 視覺元素總數: ${note.visualElements.length}');

          _uploadedPhotoUrls.clear();
          for (int i = 0; i < note.visualElements.length; i++) {
            final element = note.visualElements[i];
            debugPrint('[NOTE_EDITOR] 📊 元素 $i: 類型=${element.runtimeType}');

            if (element is PhotoElementModel) {
              debugPrint('[NOTE_EDITOR] 🖼️ 照片元素，路徑: ${element.storagePath}');
              _uploadedPhotoUrls.add(element.storagePath);
              debugPrint('[NOTE_EDITOR] ✅ 已添加照片路徑');
            } else {
              debugPrint('[NOTE_EDITOR] ⏭️ 跳過非照片元素');
            }
          }
          debugPrint('[NOTE_EDITOR] 📷 載入 ${_uploadedPhotoUrls.length} 張照片');
          debugPrint('[NOTE_EDITOR] 🔄 UI 重新渲染，應該會顯示照片');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入筆記失敗: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 添加照片
  Future<void> _addPhoto() async {
    debugPrint('[NOTE_EDITOR] 📷 開始添加照片流程');

    // 顯示選擇器並獲取返回的 ImageSource
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const PhotoPickerSheet(),
    );

    debugPrint('[NOTE_EDITOR] 📷 用戶選擇結果: $source');

    // 如果用戶選擇了來源，開始選擇照片
    if (source != null) {
      debugPrint('[NOTE_EDITOR] 📷 準備調用 _pickImage，mounted=$mounted');
      if (mounted) {
        await _pickImage(source);
      }
    } else {
      debugPrint('[NOTE_EDITOR] ⏭️ 用戶取消了照片選擇器');
    }
  }

  /// 選擇照片
  Future<void> _pickImage(ImageSource source) async {
    debugPrint('[NOTE_EDITOR] 📷 _pickImage 開始執行');
    debugPrint('[NOTE_EDITOR] 📷 來源: $source');
    debugPrint('[NOTE_EDITOR] 📷 平台: ${Platform.operatingSystem}');
    debugPrint('[NOTE_EDITOR] 📷 mounted: $mounted');

    try {
      // Windows 平台且選擇相簿時，使用 file_picker（Web 不支援）
      if (!kIsWeb && Platform.isWindows && source == ImageSource.gallery) {
        debugPrint('[NOTE_EDITOR] 🪟 使用 file_picker（Windows 平台）');
        await _pickImageWithFilePicker();
        return;
      }

      // 其他平台使用 image_picker
      debugPrint('[NOTE_EDITOR] 📷 使用 image_picker');
      final picker = ImagePicker();

      final pickedFile = await picker
          .pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[NOTE_EDITOR] ⏰ 選擇照片超時（60秒）');
          return null;
        },
      );

      debugPrint(
          '[NOTE_EDITOR] 📷 pickImage 完成，結果: ${pickedFile != null ? "有照片" : "null"}');

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        debugPrint('[NOTE_EDITOR] ✅ 選擇了照片: ${file.path}');
        debugPrint('[NOTE_EDITOR] 📊 檔案大小: ${await file.length()} bytes');

        if (mounted) {
          setState(() {
            _photos.add(file);
          });
          debugPrint('[NOTE_EDITOR] ✅ 照片已添加到列表，總數: ${_photos.length}');
        }
      } else {
        debugPrint('[NOTE_EDITOR] ⏭️ 用戶取消了或選擇失敗');
      }
    } catch (e, stackTrace) {
      debugPrint('[NOTE_EDITOR] ❌ 選擇照片異常: $e');
      debugPrint('[NOTE_EDITOR] 📋 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選擇照片失敗: $e')),
        );
      }
    }

    debugPrint('[NOTE_EDITOR] 📷 _pickImage 執行結束');
  }

  /// 使用 file_picker 選擇照片（Windows 平台專用）
  Future<void> _pickImageWithFilePicker() async {
    debugPrint('[NOTE_EDITOR] 🪟 開始使用 file_picker...');

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      debugPrint(
          '[NOTE_EDITOR] 🪟 file_picker 完成，結果: ${result != null ? "有結果" : "null"}');

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          final file = File(path);
          debugPrint('[NOTE_EDITOR] ✅ 選擇了照片: $path');
          debugPrint('[NOTE_EDITOR] 📊 檔案大小: ${await file.length()} bytes');

          if (mounted) {
            setState(() {
              _photos.add(file);
            });
            debugPrint('[NOTE_EDITOR] ✅ 照片已添加到列表，總數: ${_photos.length}');
          }
        } else {
          debugPrint('[NOTE_EDITOR] ⏭️ 檔案路徑為 null');
        }
      } else {
        debugPrint('[NOTE_EDITOR] ⏭️ 用戶取消選擇');
      }
    } catch (e, stackTrace) {
      debugPrint('[NOTE_EDITOR] ❌ file_picker 異常: $e');
      debugPrint('[NOTE_EDITOR] 📋 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選擇照片失敗: $e')),
        );
      }
    }
  }

  /// 移除照片
  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  /// 上傳照片到 Storage
  Future<void> _uploadPhotos() async {
    if (_photos.isEmpty) return;

    setState(() {
      _isUploadingPhotos = true;
      _uploadProgress = 0.0;
    });

    try {
      final currentUser = _authController.user;
      if (currentUser == null) return;

      // 確保 clientId 存在（編輯模式從 selectedNote 取得）
      String? clientId = widget.clientId;
      final selectedNote = _controller.selectedNote;
      if (clientId == null && selectedNote != null) {
        clientId = selectedNote.clientId;
        debugPrint('[NOTE_EDITOR] 📋 從現有筆記獲得學員 ID: $clientId');
      }

      if (clientId == null) {
        throw Exception('clientId is required for uploading photos');
      }

      // 【不清空已有照片 URL，只添加新的】
      debugPrint('[NOTE_EDITOR] 📷 現有照片數量: ${_uploadedPhotoUrls.length}');

      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];

        // 上傳到 Supabase Storage（使用 clientId 作為路徑）
        final url = await _controller.uploadPhoto(
          coachId: currentUser.uid,
          clientId: clientId,
          file: photo,
        );

        if (url != null) {
          _uploadedPhotoUrls.add(url);
          debugPrint('[NOTE_EDITOR] ✅ 照片上傳成功: $url');
        }

        // 更新進度
        setState(() {
          _uploadProgress = (i + 1) / _photos.length;
        });
      }

      debugPrint('[NOTE_EDITOR] 📷 上傳後照片總數: ${_uploadedPhotoUrls.length}');

      // 【清空待上傳列表，因為已經上傳完成】
      _photos.clear();
      debugPrint('[NOTE_EDITOR] 🗑️ 已清空待上傳照片列表');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('照片上傳失敗: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploadingPhotos = false;
        _uploadProgress = 0.0;
      });
    }
  }

  /// 儲存筆記
  Future<void> _saveNote() async {
    debugPrint('[NOTE_EDITOR] 📝 開始保存筆記');

    final currentUser = _authController.user;
    if (currentUser == null) {
      debugPrint('[NOTE_EDITOR] ❌ 用戶未登入');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
      return;
    }

    debugPrint('[NOTE_EDITOR] 👤 當前用戶: ${currentUser.uid}');
    debugPrint('[NOTE_EDITOR] 📋 模式: ${widget.noteId != null ? "編輯" : "創建"}');
    debugPrint('[NOTE_EDITOR] 👥 學員 ID: ${widget.clientId}');

    // 驗證：標題必填
    if (_titleController.text.trim().isEmpty) {
      debugPrint('[NOTE_EDITOR] ⚠️ 標題為空');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入筆記標題'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 驗證：至少填寫一個欄位（排除預設提示文字）
    final hasSubjective = _subjectiveController.text.trim().isNotEmpty &&
        !_subjectiveController.text.contains('（手繪板註記筆記請填在主觀描述）');
    final hasObjective = _objectiveController.text.trim().isNotEmpty;
    final hasAssessment = _assessmentController.text.trim().isNotEmpty;
    final hasPlan = _planController.text.trim().isNotEmpty;

    if (!hasSubjective && !hasObjective && !hasAssessment && !hasPlan) {
      debugPrint('[NOTE_EDITOR] ⚠️ 沒有填寫任何欄位');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請至少填寫一個 SOAP 欄位（主觀/客觀/評估/計畫）'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 驗證：創建模式必須有 clientId
    if (widget.noteId == null && widget.clientId == null) {
      debugPrint('[NOTE_EDITOR] ❌ 創建模式缺少學員 ID');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缺少學員 ID')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 先上傳照片
      if (_photos.isNotEmpty) {
        debugPrint('[NOTE_EDITOR] 📷 開始上傳 ${_photos.length} 張照片');
        await _uploadPhotos();
        debugPrint(
            '[NOTE_EDITOR] ✅ 照片上傳完成，URL 數量: ${_uploadedPhotoUrls.length}');
      } else {
        debugPrint('[NOTE_EDITOR] ⏭️ 沒有照片需要上傳');
      }
      // 建立 SOAP 筆記（過濾預設提示文字）
      final soap = SoapNoteModel(
        subjective: _subjectiveController.text.trim().isNotEmpty &&
                !_subjectiveController.text.contains('（手繪板註記筆記請填在主觀描述）')
            ? _subjectiveController.text.trim()
            : null,
        objective: _objectiveController.text.trim().isNotEmpty
            ? _objectiveController.text.trim()
            : null,
        assessment: _assessmentController.text.trim().isNotEmpty
            ? _assessmentController.text.trim()
            : null,
        plan: _planController.text.trim().isNotEmpty
            ? _planController.text.trim()
            : null,
      );

      // 將已上傳照片 URL 轉換為 PhotoElementModel
      final photoElements = _uploadedPhotoUrls.map((url) {
        debugPrint('[NOTE_EDITOR] 📷 照片 URL: $url');
        return PhotoElementModel(storagePath: url);
      }).toList();

      debugPrint('[NOTE_EDITOR] 📊 視覺元素數量: ${photoElements.length}');

      // 【_uploadedPhotoUrls 已經反映用戶的刪除操作（UI 層刪除照片時已從列表移除）】
      // 所以這裡直接使用 _uploadedPhotoUrls 構建照片元素
      final currentPhotoElements = _uploadedPhotoUrls.map((storagePath) {
        debugPrint('[NOTE_EDITOR] 📷 照片: $storagePath');
        return PhotoElementModel(storagePath: storagePath);
      }).toList();

      debugPrint('[NOTE_EDITOR] 📊 照片元素: ${currentPhotoElements.length}');

      // 【從暫存中取出繪圖（新建和編輯模式統一邏輯）】
      final allVisualElements = <VisualElementModel>[...currentPhotoElements];

      if (_tempSessionNoteIds.isNotEmpty) {
        debugPrint(
            '[NOTE_EDITOR] 🎨 檢查暫存繪圖，共 ${_tempSessionNoteIds.length} 個臨時 ID');

        for (final tempId in _tempSessionNoteIds) {
          final tempDrawing = DrawingController.getTemporaryDrawing(tempId);
          if (tempDrawing != null) {
            debugPrint('[NOTE_EDITOR] ✅ 找到暫存繪圖: ${tempDrawing.id}');
            debugPrint('[NOTE_EDITOR] 📊 圖層數量: ${tempDrawing.layers.length}');
            debugPrint('[NOTE_EDITOR] 📋 模板類型: ${tempDrawing.templateType}');

            // 將繪圖轉換為 DrawingElementModel
            allVisualElements.add(
              DrawingElementModel(
                drawingData: tempDrawing.toJson(),
                templateType: tempDrawing.templateType,
              ),
            );
          } else {
            debugPrint('[NOTE_EDITOR] ⏭️ 未找到暫存繪圖: $tempId');
          }
        }

        debugPrint('[NOTE_EDITOR] 🎨 總共加入 ${_tempSessionNoteIds.length} 個繪圖');
      } else {
        debugPrint('[NOTE_EDITOR] ⏭️ 無暫存繪圖');
      }

      debugPrint(
          '[NOTE_EDITOR] 📊 總視覺元素數量: ${allVisualElements.length}（照片: ${currentPhotoElements.length}, 繪圖: ${_tempSessionNoteIds.length}）');

      if (widget.noteId != null) {
        // 編輯模式：更新現有筆記
        debugPrint('[NOTE_EDITOR] 📝 編輯模式：更新現有筆記');

        final existingNote = _controller.selectedNote;
        if (existingNote != null) {
          final updatedNote = existingNote.copyWith(
            soap: soap,
            visibility: _visibility,
            quickTags: _selectedTags,
            visualElements: allVisualElements,
          );

          await _controller.updateNote(updatedNote);
          debugPrint('[NOTE_EDITOR] ✅ 筆記更新成功');

          // 【清除所有暫存繪圖】
          for (final tempId in _tempSessionNoteIds) {
            DrawingController.clearTemporaryDrawing(tempId);
          }
          debugPrint(
              '[NOTE_EDITOR] 🗑️ 已清除 ${_tempSessionNoteIds.length} 個暫存繪圖');
        }
      } else {
        // 創建模式：新增筆記
        debugPrint('[NOTE_EDITOR] ➕ 創建模式：新增筆記');

        final newNote = SessionNoteModel(
          id: '', // 讓資料庫自動生成 UUID
          title: _titleController.text.trim(),
          clientId: widget.clientId!,
          coachId: currentUser.uid,
          appointmentId: widget.appointmentId,
          soap: soap,
          visualElements: allVisualElements,
          quickTags: _selectedTags,
          visibility: _visibility,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        debugPrint('[NOTE_EDITOR] 📋 筆記資料: ${newNote.toString()}');
        await _controller.createNote(newNote);
        debugPrint('[NOTE_EDITOR] ✅ 筆記創建成功');

        // 【清除所有暫存繪圖】
        for (final tempId in _tempSessionNoteIds) {
          DrawingController.clearTemporaryDrawing(tempId);
        }
        debugPrint('[NOTE_EDITOR] 🗑️ 已清除 ${_tempSessionNoteIds.length} 個暫存繪圖');
      }

      if (mounted) {
        debugPrint('[NOTE_EDITOR] ✅ 保存完成，返回上一頁');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('筆記已儲存')),
        );
        Navigator.pop(context, true); // 返回並標記為已修改
      }
    } catch (e) {
      debugPrint('[NOTE_EDITOR] ❌ 保存失敗: $e');
      debugPrint('[NOTE_EDITOR] 📋 Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
      debugPrint('[NOTE_EDITOR] 📝 保存流程結束');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.noteId != null ? '編輯筆記' : '新增筆記'),
          actions: [
            // 儲存按鈕
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: '儲存筆記',
                onPressed: _saveNote,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: context.pagePadding,
                child: Center(
                  // ✅ 表單區域限制最大寬度 600dp
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 標題輸入
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: '筆記標題 *',
                            hintText: '例如：深蹲姿勢調整、右肩活動度',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            prefixIcon: const Icon(Icons.title),
                          ),
                          maxLength: 50,
                        ),

                        SizedBox(height: context.spacing.md),

                        // SOAP 說明卡片
                        _buildSoapInfoCard(),

                        SizedBox(height: context.spacing.md),

                        // S - Subjective（主觀描述）
                        SoapFieldCard(
                          title: 'S - 主觀描述 (Subjective)',
                          hint: '學員的主觀感受與陳述\n例如：感覺腰部緊繃、昨天精神不太良好',
                          controller: _subjectiveController,
                          icon: Icons.person_outline,
                          color: Colors.blue,
                        ),

                        SizedBox(height: context.spacing.md),

                        // O - Objective（客觀觀察）
                        SoapFieldCard(
                          title: 'O - 客觀觀察 (Objective)',
                          hint: '教練的客觀觀察\n例如：深蹲姿勢改善、核心穩定度提升',
                          controller: _objectiveController,
                          icon: Icons.visibility_outlined,
                          color: Colors.green,
                        ),

                        SizedBox(height: context.spacing.md),

                        // A - Assessment（評估）
                        SoapFieldCard(
                          title: 'A - 評估 (Assessment)',
                          hint: '專業評估與分析\n例如：整體進步良好，需加強髖關節活動度',
                          controller: _assessmentController,
                          icon: Icons.assessment_outlined,
                          color: Colors.orange,
                        ),

                        SizedBox(height: context.spacing.md),

                        // P - Plan（計畫）
                        SoapFieldCard(
                          title: 'P - 計畫 (Plan)',
                          hint: '下一步訓練計畫\n例如：增加伸展動作，維持當前訓練強度',
                          controller: _planController,
                          icon: Icons.calendar_today_outlined,
                          color: Colors.purple,
                        ),

                        SizedBox(height: context.spacing.lg),

                        // 快速標籤
                        _buildQuickTags(),

                        SizedBox(height: context.spacing.lg),

                        // 照片上傳
                        _buildPhotoSection(),

                        SizedBox(height: context.spacing.lg),

                        // 手繪板區域（Phase 4A）
                        _buildDrawingSection(),

                        SizedBox(height: context.spacing.lg),

                        // 隱私控制
                        _buildPrivacyControl(),

                        SizedBox(height: context.spacing.xl),

                        // 底部保存按鈕（最小觸控目標 48dp）
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveNote,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              _isSaving ? '儲存中...' : '儲存筆記',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),

                        SizedBox(height: context.spacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// SOAP 說明卡片
  Widget _buildSoapInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'SOAP 是醫療與訓練界標準的筆記方式，不需要填滿所有欄位',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 快速標籤選擇器（復用公用元件）
  Widget _buildQuickTags() {
    return QuickTagsSection(
      availableTags: _availableTags,
      selectedTags: _selectedTags,
      onTagsChanged: (newTags) {
        setState(() {
          _selectedTags.clear();
          _selectedTags.addAll(newTags);
        });
      },
    );
  }

  /// 隱私控制
  Widget _buildPrivacyControl() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '隱私設定',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('私人'),
                subtitle: const Text('僅教練自己可以查看'),
                value: 'private',
                groupValue: _visibility,
                onChanged: (value) {
                  setState(() => _visibility = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('分享'),
                subtitle: const Text('學員也可以查看此筆記'),
                value: 'shared',
                groupValue: _visibility,
                onChanged: (value) {
                  setState(() => _visibility = value!);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 手繪板區域（Phase 4A）
  Widget _buildDrawingSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '手繪標註',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // 說明卡片
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.draw, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '在身體圖上標註姿勢問題、疼痛點或訓練重點',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 模板按鈕列表（4 個選項）
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
          children: [
            _buildTemplateButton(
              icon: Icons.view_in_ar,
              label: '三視圖',
              templateType: TemplateType.note1,
            ),
            _buildTemplateButton(
              icon: Icons.person,
              label: '正面',
              templateType: TemplateType.note2,
            ),
            _buildTemplateButton(
              icon: Icons.accessibility_new,
              label: '背面',
              templateType: TemplateType.note3,
            ),
            _buildTemplateButton(
              icon: Icons.person_outline,
              label: '側面',
              templateType: TemplateType.note4,
            ),
          ],
        ),
      ],
    );
  }

  /// 模板選擇按鈕
  Widget _buildTemplateButton({
    required IconData icon,
    required String label,
    required TemplateType templateType,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDrawingCanvas(templateType),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: Colors.blue),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 開啟手繪畫布【新版：暫存模式，不自動創建筆記】
  Future<void> _openDrawingCanvas(TemplateType templateType) async {
    debugPrint('[NOTE_EDITOR] 🎨 開啟繪圖模式');
    debugPrint('[NOTE_EDITOR] 📋 模板類型: ${templateType.name}');
    debugPrint(
        '[NOTE_EDITOR] 📋 模式: ${widget.noteId != null ? "編輯" : "創建（暫存）"}');

    // 驗證必要資料（新建模式）
    if (widget.noteId == null) {
      final currentUser = _authController.user;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先登入')),
        );
        return;
      }

      if (widget.clientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('缺少學員資料')),
        );
        return;
      }
    }

    // 【新版邏輯：使用臨時 ID，不創建資料庫筆記】
    String sessionNoteId;
    final String templateKey = templateType.name; // 安全轉換

    // 【創建和編輯模式都使用臨時 ID（避免自動保存到資料庫）】
    if (_tempIdsByTemplate.containsKey(templateKey)) {
      // 重複使用已有的臨時 ID
      sessionNoteId = _tempIdsByTemplate[templateKey]!;
      debugPrint('[NOTE_EDITOR] ♻️ 重複使用已有 ID（模板: ${templateType.name}）');
    } else {
      // 創建新的臨時 ID
      sessionNoteId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      _tempIdsByTemplate[templateKey] = sessionNoteId;
      _tempSessionNoteIds.add(sessionNoteId);
      debugPrint('[NOTE_EDITOR] 🆕 創建新臨時 ID（模板: ${templateType.name}）');
      debugPrint(
          '[NOTE_EDITOR] 📋 記錄臨時 ID，目前總數: ${_tempSessionNoteIds.length} 個');

      // 【編輯模式：嘗試從資料庫中載入現有繪圖，複製並存到暫存】
      if (widget.noteId != null) {
        debugPrint('[NOTE_EDITOR] 📂 編輯模式：嘗試載入現有繪圖到暫存');
        final existingNote = _controller.selectedNote;
        if (existingNote != null) {
          // 從 visualElements 中找到該模板的繪圖
          final existingDrawing = existingNote.visualElements
              .whereType<DrawingElementModel>()
              .where((element) => element.templateType == templateType.name)
              .firstOrNull;

          if (existingDrawing != null && existingDrawing.drawingData != null) {
            debugPrint(
                '[NOTE_EDITOR] ✅ 找到現有繪圖，複製到暫存（模板: ${templateType.name}）');
            // 將繪圖資料轉換為 DrawingNoteModel 並保存到暫存
            try {
              final drawingModel =
                  DrawingNoteModel.fromJson(existingDrawing.drawingData!);
              // 修改 sessionNoteId 為臨時 ID
              final tempDrawingModel =
                  drawingModel.copyWith(sessionNoteId: sessionNoteId);
              DrawingController.setTemporaryDrawing(
                  sessionNoteId, tempDrawingModel);
              debugPrint(
                  '[NOTE_EDITOR] ✅ 現有繪圖已複製到暫存（Session ID: $sessionNoteId）');
            } catch (e) {
              debugPrint('[NOTE_EDITOR] ⚠️ 載入現有繪圖失敗: $e');
            }
          } else {
            debugPrint('[NOTE_EDITOR] ⏭️ 該模板無現有繪圖');
          }
        }
      }
    }

    debugPrint('[NOTE_EDITOR] 🆔 使用臨時 Session ID: $sessionNoteId');

    // 【提示用戶這是暫存（新建和編輯模式都適用）】
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💡 提示：繪圖暫存本地，點擊「儲存筆記」統一上傳'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 進入手繪畫布
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => serviceLocator<IDrawingController>(),
          child: DrawingCanvasPage(
            sessionNoteId: sessionNoteId,
            templateType: templateType.name,
          ),
        ),
      ),
    );

    // 【返回後：新建和編輯模式都用暫存】
    if (!mounted) return;

    debugPrint('[NOTE_EDITOR] 🔙 繪圖已暫存（Session ID: $sessionNoteId）');
    debugPrint('[NOTE_EDITOR] 💡 用戶需點擊「儲存筆記」統一上傳');
  }

  /// 照片上傳區域
  Widget _buildPhotoSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '照片',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_uploadedPhotoUrls.length + _photos.length})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_uploadedPhotoUrls.isNotEmpty || _photos.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '已傳: ${_uploadedPhotoUrls.length}, 待傳: ${_photos.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // 【已上傳照片列表（編輯模式）- 復用公用元件】
        if (_uploadedPhotoUrls.isNotEmpty) ...[
          UploadedPhotoGrid(
            storagePaths: _uploadedPhotoUrls,
            onRemove: (index) {
              setState(() {
                _uploadedPhotoUrls.removeAt(index);
              });
            },
          ),
          const SizedBox(height: 8),
        ],

        // 待上傳照片列表（新增模式）
        if (_photos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return PhotoUploadCard(
                photo: _photos[index],
                onRemove: () => _removePhoto(index),
                isUploading: _isUploadingPhotos,
                uploadProgress: _isUploadingPhotos ? _uploadProgress : null,
              );
            },
          ),
          const SizedBox(height: 8),
        ],

        // 添加照片按鈕
        OutlinedButton.icon(
          onPressed: _isUploadingPhotos ? null : _addPhoto,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('添加照片'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

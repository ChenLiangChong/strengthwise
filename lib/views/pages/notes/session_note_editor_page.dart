import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:strengthwise/controllers/session_note_controller.dart';
import 'package:strengthwise/controllers/drawing_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';
import 'package:strengthwise/models/drawing_note_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/notes/widgets/soap_field_card.dart';
import 'package:strengthwise/views/pages/notes/widgets/photo_picker_sheet.dart';
import 'package:strengthwise/views/pages/notes/widgets/photo_upload_card.dart';
import 'package:strengthwise/views/pages/drawing_canvas_page.dart';
import 'dart:io';

/// 課程筆記編輯器頁面
/// 
/// 功能：
/// - 創建或編輯 SOAP 格式筆記
/// - S.O.A.P 四欄位輸入
/// - 隱私控制（私人/共享）
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
  late final SessionNoteController _controller;
  late final IAuthController _authController;
  
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
    '動作改善',
    '疼痛追蹤',
    '目標達成',
  ];
  
  // 載入狀態
  bool _isLoading = false;
  bool _isSaving = false;
  
  // 照片列表
  final List<File> _photos = [];
  final List<String> _uploadedPhotoUrls = [];
  bool _isUploadingPhotos = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<SessionNoteController>();
    _authController = serviceLocator<IAuthController>();
    
    // 編輯模式：載入現有筆記
    if (widget.noteId != null) {
      _loadNote();
    }
  }

  @override
  void dispose() {
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
        // 填充 SOAP 欄位
        if (note.soap != null) {
          _subjectiveController.text = note.soap!.subjective ?? '';
          _objectiveController.text = note.soap!.objective ?? '';
          _assessmentController.text = note.soap!.assessment ?? '';
          _planController.text = note.soap!.plan ?? '';
        }
        
        // 設定隱私
        _visibility = note.visibility;
        
        // 設定標籤
        _selectedTags.clear();
        _selectedTags.addAll(note.quickTags);
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

  /// 新增照片
  Future<void> _addPhoto() async {
    debugPrint('[NOTE_EDITOR] 🔵 開始新增照片流程');
    
    // 顯示選擇器並獲取返回的 ImageSource
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const PhotoPickerSheet(),
    );
    
    debugPrint('[NOTE_EDITOR] 🔵 用戶選擇結果: $source');
    
    // 如果用戶選擇了來源，開始選擇照片
    if (source != null) {
      debugPrint('[NOTE_EDITOR] 🔵 開始調用 _pickImage，mounted=$mounted');
      if (mounted) {
        await _pickImage(source);
      }
    } else {
      debugPrint('[NOTE_EDITOR] ℹ️ 用戶取消選擇或關閉彈窗');
    }
  }
  
  /// 選擇照片
  Future<void> _pickImage(ImageSource source) async {
    debugPrint('[NOTE_EDITOR] 📷 _pickImage 開始執行');
    debugPrint('[NOTE_EDITOR] 📷 來源: $source');
    debugPrint('[NOTE_EDITOR] 📷 平台: ${Platform.operatingSystem}');
    debugPrint('[NOTE_EDITOR] 📷 mounted: $mounted');
    
    try {
      // Windows 平台且選擇相簿時，使用 file_picker
      if (Platform.isWindows && source == ImageSource.gallery) {
        debugPrint('[NOTE_EDITOR] 🪟 使用 file_picker（Windows 平台）');
        await _pickImageWithFilePicker();
        return;
      }
      
      // 其他平台使用 image_picker
      debugPrint('[NOTE_EDITOR] 📷 使用 image_picker');
      final picker = ImagePicker();
      
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[NOTE_EDITOR] ⏰ 照片選擇超時（60秒）');
          return null;
        },
      );

      debugPrint('[NOTE_EDITOR] 📷 pickImage 完成，結果: ${pickedFile != null ? "有照片" : "null"}');

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        debugPrint('[NOTE_EDITOR] ✅ 照片選擇成功: ${file.path}');
        debugPrint('[NOTE_EDITOR] 📦 檔案大小: ${await file.length()} bytes');
        
        if (mounted) {
          setState(() {
            _photos.add(file);
          });
          debugPrint('[NOTE_EDITOR] ✅ 照片已添加到列表，總數: ${_photos.length}');
        }
      } else {
        debugPrint('[NOTE_EDITOR] ℹ️ 用戶取消選擇或選擇失敗');
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

      debugPrint('[NOTE_EDITOR] 🪟 file_picker 完成，結果: ${result != null ? "有檔案" : "null"}');

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          final file = File(path);
          debugPrint('[NOTE_EDITOR] ✅ 照片選擇成功: $path');
          debugPrint('[NOTE_EDITOR] 📦 檔案大小: ${await file.length()} bytes');
          
          if (mounted) {
            setState(() {
              _photos.add(file);
            });
            debugPrint('[NOTE_EDITOR] ✅ 照片已添加到列表，總數: ${_photos.length}');
          }
        } else {
          debugPrint('[NOTE_EDITOR] ⚠️ 檔案路徑為 null');
        }
      } else {
        debugPrint('[NOTE_EDITOR] ℹ️ 用戶取消選擇');
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
      if (clientId == null && _controller.selectedNote != null) {
        clientId = _controller.selectedNote!.clientId;
        debugPrint('[NOTE_EDITOR] 📋 從現有筆記取得學員 ID: $clientId');
      }
      
      if (clientId == null) {
        throw Exception('clientId is required for uploading photos');
      }
      
      _uploadedPhotoUrls.clear();
      
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
        }
        
        // 更新進度
        setState(() {
          _uploadProgress = (i + 1) / _photos.length;
        });
      }
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
    debugPrint('[NOTE_EDITOR] 🔵 開始保存筆記');
    
    final currentUser = _authController.user;
    if (currentUser == null) {
      debugPrint('[NOTE_EDITOR] ❌ 用戶未登入');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
      return;
    }
    
    debugPrint('[NOTE_EDITOR] 👤 當前用戶: ${currentUser.uid}');
    debugPrint('[NOTE_EDITOR] 📝 模式: ${widget.noteId != null ? "編輯" : "創建"}');
    debugPrint('[NOTE_EDITOR] 👨‍🎓 學員 ID: ${widget.clientId}');
    
    // 驗證：至少填寫一個欄位（排除預設提示文字）
    final hasSubjective = _subjectiveController.text.trim().isNotEmpty && 
        !_subjectiveController.text.contains('（手繪標註筆記，請補充主觀描述）');
    final hasObjective = _objectiveController.text.trim().isNotEmpty;
    final hasAssessment = _assessmentController.text.trim().isNotEmpty;
    final hasPlan = _planController.text.trim().isNotEmpty;
    
    if (!hasSubjective && !hasObjective && !hasAssessment && !hasPlan) {
      debugPrint('[NOTE_EDITOR] ⚠️ 沒有填寫任何欄位');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請至少填寫一個 SOAP 欄位（主觀/客觀/評估/計劃）'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 驗證：創建模式需要 clientId
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
        debugPrint('[NOTE_EDITOR] ✅ 照片上傳完成，URL 數量: ${_uploadedPhotoUrls.length}');
      } else {
        debugPrint('[NOTE_EDITOR] ℹ️ 沒有照片需要上傳');
      }
      // 建立 SOAP 筆記（排除預設提示文字）
      final soap = SoapNoteModel(
        subjective: _subjectiveController.text.trim().isNotEmpty && 
            !_subjectiveController.text.contains('（手繪標註筆記，請補充主觀描述）')
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
      
      // 將上傳的照片 URL 轉換為 PhotoElementModel
      final photoElements = _uploadedPhotoUrls.map((url) {
        debugPrint('[NOTE_EDITOR] 📸 照片 URL: $url');
        return PhotoElementModel(storagePath: url);
      }).toList();
      
      debugPrint('[NOTE_EDITOR] 🖼️ 視覺元素數量: ${photoElements.length}');
      
      if (widget.noteId != null) {
        // 編輯模式：更新現有筆記
        debugPrint('[NOTE_EDITOR] 🔄 編輯模式：更新現有筆記');
        
        // ⭐ 重新載入最新筆記數據（確保包含最新的繪圖）
        debugPrint('[NOTE_EDITOR] 🔄 重新載入最新筆記數據...');
        await _controller.loadNoteById(widget.noteId!);
        
        final existingNote = _controller.selectedNote;
        if (existingNote != null) {
          debugPrint('[NOTE_EDITOR] 📦 現有視覺元素數量: ${existingNote.visualElements.length}');
          
          // 合併現有的視覺元素和新上傳的照片
          final allVisualElements = [
            ...existingNote.visualElements,
            ...photoElements,
          ];
          
          debugPrint('[NOTE_EDITOR] 🔗 合併後視覺元素總數: ${allVisualElements.length}');
          
          final updatedNote = existingNote.copyWith(
            soap: soap,
            visibility: _visibility,
            quickTags: _selectedTags,
            visualElements: allVisualElements,
          );
          
          await _controller.updateNote(updatedNote);
          debugPrint('[NOTE_EDITOR] ✅ 筆記更新成功');
        }
      } else {
        // 創建模式：新增筆記
        debugPrint('[NOTE_EDITOR] ➕ 創建模式：新增筆記');
        
        final newNote = SessionNoteModel(
          id: '', // 讓資料庫自動生成 UUID
          clientId: widget.clientId!,
          coachId: currentUser.uid,
          appointmentId: widget.appointmentId,
          soap: soap,
          visualElements: photoElements,
          quickTags: _selectedTags,
          visibility: _visibility,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        debugPrint('[NOTE_EDITOR] 📦 筆記資料: ${newNote.toString()}');
        await _controller.createNote(newNote);
        debugPrint('[NOTE_EDITOR] ✅ 筆記創建成功');
      }
      
      if (mounted) {
        debugPrint('[NOTE_EDITOR] 🎉 保存完成，返回上一頁');
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
      debugPrint('[NOTE_EDITOR] 🔵 保存流程結束');
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SOAP 說明卡片
                    _buildSoapInfoCard(),
                    
                    const SizedBox(height: 16),
                    
                    // S - Subjective（主觀描述）
                    SoapFieldCard(
                      title: 'S - 主觀描述 (Subjective)',
                      hint: '學員的主觀感受與陳述\n例如：感覺腰部緊繃、今天精神狀態良好',
                      controller: _subjectiveController,
                      icon: Icons.person_outline,
                      color: Colors.blue,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // O - Objective（客觀觀察）
                    SoapFieldCard(
                      title: 'O - 客觀觀察 (Objective)',
                      hint: '教練的客觀觀察\n例如：深蹲姿勢改善、核心穩定度提升',
                      controller: _objectiveController,
                      icon: Icons.visibility_outlined,
                      color: Colors.green,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // A - Assessment（評估）
                    SoapFieldCard(
                      title: 'A - 評估 (Assessment)',
                      hint: '專業評估與分析\n例如：整體進步良好，需加強髖關節活動度',
                      controller: _assessmentController,
                      icon: Icons.assessment_outlined,
                      color: Colors.orange,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // P - Plan（計劃）
                    SoapFieldCard(
                      title: 'P - 計劃 (Plan)',
                      hint: '下一步訓練計劃\n例如：增加髖關節伸展動作、維持當前重量訓練',
                      controller: _planController,
                      icon: Icons.calendar_today_outlined,
                      color: Colors.purple,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 快速標籤
                    _buildQuickTags(),
                    
                    const SizedBox(height: 24),
                    
                    // 照片上傳
                    _buildPhotoSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 手繪板功能（Phase 4A）⭐
                    _buildDrawingSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 隱私控制
                    _buildPrivacyControl(),
                    
                    const SizedBox(height: 32),
                    
                    // 底部保存按鈕（更明顯）
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
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
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  /// SOAP 說明卡片
  Widget _buildSoapInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                'SOAP 格式是醫療與教練領域的標準記錄方式，不需要填滿所有欄位',
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

  /// 快速標籤選擇器
  Widget _buildQuickTags() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速標籤',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
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
                subtitle: const Text('只有教練自己可以查看'),
                value: 'private',
                groupValue: _visibility,
                onChanged: (value) {
                  setState(() => _visibility = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('共享'),
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
                    '在身體圖上標註姿勢問題、疼痛點、訓練重點',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 模板選擇按鈕（4 個）
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
              label: '前視圖',
              templateType: TemplateType.note2,
            ),
            _buildTemplateButton(
              icon: Icons.accessibility_new,
              label: '側視圖',
              templateType: TemplateType.note3,
            ),
            _buildTemplateButton(
              icon: Icons.person_outline,
              label: '背視圖',
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 打開手繪板
  Future<void> _openDrawingCanvas(TemplateType templateType) async {
    String noteId;
    
    // 如果是新建筆記，自動創建臨時筆記
    if (widget.noteId == null) {
      // 驗證必要資料
      final currentUser = _authController.user;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先登入')),
        );
        return;
      }
      
      if (widget.clientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('缺少學員資訊')),
        );
        return;
      }
      
      // 顯示載入中
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        // 自動創建臨時筆記（給預設提示，避免忘記填寫）
        final tempNote = SessionNoteModel(
          id: '', // 讓資料庫自動生成 UUID
          coachId: currentUser.uid,
          clientId: widget.clientId!,
          appointmentId: widget.appointmentId,
          soap: SoapNoteModel(
            subjective: _subjectiveController.text.trim().isEmpty 
                ? '（手繪標註筆記，請補充主觀描述）' 
                : _subjectiveController.text.trim(),
            objective: _objectiveController.text.trim(),
            assessment: _assessmentController.text.trim(),
            plan: _planController.text.trim(),
          ),
          visibility: _visibility,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final createdNote = await _controller.createNote(tempNote);
        if (createdNote == null) {
          throw Exception('創建筆記失敗');
        }
        noteId = createdNote.id;
        
        // 關閉載入對話框
        if (mounted) Navigator.of(context).pop();
        
        // 提示用戶
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已自動保存筆記，可以開始繪圖。繪圖完成後請記得填寫 SOAP 欄位'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        // 更新頁面 - 這樣返回時就是編輯模式
        // 注意：這裡無法直接修改 widget.noteId
        // 所以我們需要記錄這個臨時 ID
      } catch (e) {
        // 關閉載入對話框
        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('創建筆記失敗: $e')),
          );
        }
        return;
      }
    } else {
      noteId = widget.noteId!;
    }

    // 進入手繪板頁面
    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => serviceLocator<DrawingController>(),
          child: DrawingCanvasPage(
            sessionNoteId: noteId,
            templateType: templateType.name,
          ),
        ),
      ),
    );
    
    // 返回後重新載入筆記（如果是自動創建的）
    if (widget.noteId == null && mounted) {
      // 重新載入以顯示繪圖結果
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SessionNoteEditorPage(
            noteId: noteId,
            clientId: widget.clientId,
            appointmentId: widget.appointmentId,
          ),
        ),
      );
    }
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
              '(${_photos.length})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 照片網格
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
        
        // 新增照片按鈕
        OutlinedButton.icon(
          onPressed: _isUploadingPhotos ? null : _addPhoto,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('新增照片'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}



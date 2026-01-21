// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/notes/widgets/soap_field_card.dart';
import 'package:strengthwise/views/pages/notes/widgets/uploaded_photo_grid.dart';
import 'package:strengthwise/views/pages/notes/widgets/quick_tags_section.dart';

/// Session Mode 課程筆記區塊
///
/// 複用現有的 SoapFieldCard 組件
class SessionNotesSection extends StatefulWidget {
  /// 初始 SOAP 數據
  final SoapNoteModel? initialSoap;

  /// SOAP 變更回調
  final ValueChanged<SoapNoteModel>? onSoapChanged;

  /// 是否唯讀
  final bool readOnly;

  /// ⭐ v3.1: 視覺元素列表（照片、繪圖）
  final List<VisualElementModel>? visualElements;

  /// ⭐ v3.1: 快速標籤
  final List<String>? quickTags;

  /// ⭐ v3.1: 快速標籤變更回調
  final ValueChanged<List<String>>? onTagsChanged;

  const SessionNotesSection({
    super.key,
    this.initialSoap,
    this.onSoapChanged,
    this.readOnly = false,
    this.visualElements,
    this.quickTags,
    this.onTagsChanged,
  });

  @override
  State<SessionNotesSection> createState() => _SessionNotesSectionState();
}

class _SessionNotesSectionState extends State<SessionNotesSection> {
  late final TextEditingController _subjectiveController;
  late final TextEditingController _objectiveController;
  late final TextEditingController _assessmentController;
  late final TextEditingController _planController;

  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _subjectiveController = TextEditingController(
      text: widget.initialSoap?.subjective ?? '',
    );
    _objectiveController = TextEditingController(
      text: widget.initialSoap?.objective ?? '',
    );
    _assessmentController = TextEditingController(
      text: widget.initialSoap?.assessment ?? '',
    );
    _planController = TextEditingController(
      text: widget.initialSoap?.plan ?? '',
    );

    // 監聯變更
    _subjectiveController.addListener(_notifyChange);
    _objectiveController.addListener(_notifyChange);
    _assessmentController.addListener(_notifyChange);
    _planController.addListener(_notifyChange);
  }

  @override
  void didUpdateWidget(covariant SessionNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ⭐ v3.1: 當外部 SOAP 資料變更時（例如 Realtime 更新），同步到 TextController
    // 但要避免在本地編輯時覆蓋（檢查是否真的不同）
    if (widget.initialSoap != oldWidget.initialSoap && widget.readOnly) {
      // 只有 readOnly 模式（學員端）才需要同步外部更新
      _syncControllersFromSoap(widget.initialSoap);
    }
  }

  /// 從 SoapNoteModel 同步到 TextEditingController
  void _syncControllersFromSoap(SoapNoteModel? soap) {
    final newSubjective = soap?.subjective ?? '';
    final newObjective = soap?.objective ?? '';
    final newAssessment = soap?.assessment ?? '';
    final newPlan = soap?.plan ?? '';

    // 只有真的不同才更新（避免無限迴圈）
    if (_subjectiveController.text != newSubjective) {
      _subjectiveController.text = newSubjective;
    }
    if (_objectiveController.text != newObjective) {
      _objectiveController.text = newObjective;
    }
    if (_assessmentController.text != newAssessment) {
      _assessmentController.text = newAssessment;
    }
    if (_planController.text != newPlan) {
      _planController.text = newPlan;
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

  void _notifyChange() {
    if (widget.onSoapChanged != null) {
      widget.onSoapChanged!(SoapNoteModel(
        subjective: _subjectiveController.text,
        objective: _objectiveController.text,
        assessment: _assessmentController.text,
        plan: _planController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 計算填寫進度
    final filledCount = [
      _subjectiveController.text.isNotEmpty,
      _objectiveController.text.isNotEmpty,
      _assessmentController.text.isNotEmpty,
      _planController.text.isNotEmpty,
    ].where((filled) => filled).length;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // 標題列（可收合）
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: context.cardPadding,
              child: Row(
                children: [
                  Icon(Icons.notes, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '課程筆記',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 進度指示
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: filledCount == 4
                          ? AppTheme.successLight.withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$filledCount/4',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: filledCount == 4
                            ? AppTheme.successLight
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // SOAP 欄位（複用現有組件）
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                0,
                context.spacing.md,
                context.spacing.md,
              ),
              child: Column(
                children: [
                  // S - Subjective（主觀）
                  SoapFieldCard(
                    title: 'S - 主觀資料',
                    hint: '學員自述：今天感覺如何？哪裡不舒服？',
                    controller: _subjectiveController,
                    icon: Icons.person,
                    color: AppTheme.soapSubjective,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // O - Objective（客觀）
                  SoapFieldCard(
                    title: 'O - 客觀資料',
                    hint: '教練觀察：動作表現、姿勢問題、體能狀態',
                    controller: _objectiveController,
                    icon: Icons.visibility,
                    color: AppTheme.soapObjective,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // A - Assessment（評估）
                  SoapFieldCard(
                    title: 'A - 評估分析',
                    hint: '問題分析：可能的原因、需要注意的地方',
                    controller: _assessmentController,
                    icon: Icons.analytics,
                    color: AppTheme.soapAssessment,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // P - Plan（計畫）
                  SoapFieldCard(
                    title: 'P - 後續計畫',
                    hint: '下次課程計畫、回家功課、注意事項',
                    controller: _planController,
                    icon: Icons.flag,
                    color: AppTheme.soapPlan,
                    maxLines: 3,
                  ),

                  // ⭐ v3.1: 快速標籤
                  const SizedBox(height: 16),
                  QuickTagsSection(
                    selectedTags: widget.quickTags ?? [],
                    onTagsChanged: widget.readOnly ? null : widget.onTagsChanged,
                    readOnly: widget.readOnly,
                  ),

                  // ⭐ v3.1: 照片和繪圖顯示區塊
                  if (_hasVisualElements) ...[
                    const SizedBox(height: 16),
                    _buildVisualElementsSection(colorScheme),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 是否有視覺元素
  bool get _hasVisualElements =>
      widget.visualElements != null && widget.visualElements!.isNotEmpty;

  /// 取得照片路徑列表
  List<String> get _photoPaths {
    if (widget.visualElements == null) return [];
    return widget.visualElements!
        .whereType<PhotoElementModel>()
        .map((e) => e.storagePath)
        .toList();
  }

  /// 視覺元素區塊（復用 UploadedPhotoGrid）
  Widget _buildVisualElementsSection(ColorScheme colorScheme) {
    final photoPaths = _photoPaths;
    
    if (photoPaths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '附件照片 (${photoPaths.length})',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ⭐ 復用公用元件
        UploadedPhotoGrid(
          storagePaths: photoPaths,
          horizontal: true,
          horizontalHeight: 100,
          // Session Mode 中不允許刪除，所以不傳 onRemove
        ),
      ],
    );
  }

  /// 取得當前 SOAP 數據
  SoapNoteModel get soapNote => SoapNoteModel(
        subjective: _subjectiveController.text,
        objective: _objectiveController.text,
        assessment: _assessmentController.text,
        plan: _planController.text,
      );

  /// 檢查是否有填寫內容
  bool get hasContent =>
      _subjectiveController.text.isNotEmpty ||
      _objectiveController.text.isNotEmpty ||
      _assessmentController.text.isNotEmpty ||
      _planController.text.isNotEmpty;
}


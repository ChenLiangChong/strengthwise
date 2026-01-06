// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 課程筆記卡片組件
/// 
/// 顯示單個筆記的摘要資訊
class SessionNoteCard extends StatelessWidget {
  final SessionNoteModel note;
  final String? clientName; // ⭐ 學員名稱（教練模式）
  final String? coachName;  // ⭐ 教練名稱（學員模式）
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SessionNoteCard({
    Key? key,
    required this.note,
    this.clientName,
    this.coachName,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.md), // ⭐ 響應式間距
      elevation: 0, // ⭐ 移除陰影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md), // ⭐ 響應式內距
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題列：筆記標題 + 狀態標籤
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(width: context.spacing.sm),
                  
                  // 共享狀態標籤（使用 Flexible 防止溢出）
                  Flexible(
                    child: note.isShared
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacing.sm,
                              vertical: context.spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.share,
                                  size: 12,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                SizedBox(width: context.spacing.xs),
                                Flexible(
                                  child: Text(
                                    '已共享',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacing.sm,
                              vertical: context.spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '私人',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                ],
              ),
              
              SizedBox(height: context.spacing.sm),
              
              // 副標題：學員/教練名稱 + 創建日期
              Row(
                children: [
                  // ⭐ 頭像 + 名稱（限制寬度，防止 email 溢出）
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.surfaceVariant,
                    child: Text(
                      _getPersonInitial(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.xs),
                  
                  // 名稱（可能是 email，需要限制寬度）
                  Expanded(
                    child: Text(
                      _getPersonName(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: coachName == '已刪除的教練' ? Colors.grey : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(width: context.spacing.sm),
                  
                  // 創建日期
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: context.spacing.xs),
                  Text(
                    _formatSessionDate(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: context.spacing.sm),
              
              // SOAP 筆記預覽
              if (note.soap != null && !note.soap!.isEmpty) ...[
                _buildSoapPreview(context, note.soap!),
                SizedBox(height: context.spacing.sm),
              ],
              
              // 底部資訊列：視覺元素數量 + 更新時間（使用 Wrap 防止溢出）
              Row(
                children: [
                  // 左側資訊（可換行）
                  Expanded(
                    child: Wrap(
                      spacing: context.spacing.sm,
                      runSpacing: context.spacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // 繪圖數量
                        if (note.hasDrawings)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.draw,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              SizedBox(width: context.spacing.xs),
                              Text(
                                '${_getDrawingCount(note)} 個繪圖',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        
                        // 照片數量
                        if (_getPhotoCount(note) > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: context.spacing.xs),
                              Text(
                                '${_getPhotoCount(note)} 張照片',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        
                        // 更新時間
                        Text(
                          '更新於 ${_formatUpdateTime(note.updatedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 刪除按鈕（固定在右側）
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    tooltip: '刪除筆記',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 獲取人名首字母（用於頭像）
  String _getPersonInitial() {
    // 優先顯示教練名稱（學員模式）
    if (coachName != null && coachName!.isNotEmpty) {
      if (coachName == '已刪除的教練') {
        return '?';
      }
      return coachName![0].toUpperCase();
    }
    // 其次顯示學員名稱（教練模式）
    if (clientName != null && clientName!.isNotEmpty) {
      return clientName![0].toUpperCase();
    }
    return '學';
  }

  /// 獲取顯示的人名
  String _getPersonName() {
    // 優先顯示教練名稱（學員模式）
    if (coachName != null) {
      return coachName!;
    }
    // 其次顯示學員名稱（教練模式）
    if (clientName != null) {
      return clientName!;
    }
    // ⭐ 處理已刪除的用戶（ID 為 null）
    if (note.clientId == null) {
      return '已刪除的學員';
    }
    // 後備方案：顯示 ID 前綴
    return '學員 ${note.clientId!.substring(0, 8)}...';
  }

  /// SOAP 筆記預覽
  Widget _buildSoapPreview(BuildContext context, SoapNoteModel soap) {
    final theme = Theme.of(context);
    
    // 找出第一個有內容的欄位作為預覽
    String? preview;
    if (soap.subjective != null && soap.subjective!.isNotEmpty) {
      preview = 'S: ${soap.subjective}';
    } else if (soap.objective != null && soap.objective!.isNotEmpty) {
      preview = 'O: ${soap.objective}';
    } else if (soap.assessment != null && soap.assessment!.isNotEmpty) {
      preview = 'A: ${soap.assessment}';
    } else if (soap.plan != null && soap.plan!.isNotEmpty) {
      preview = 'P: ${soap.plan}';
    }
    
    if (preview == null) return const SizedBox.shrink();
    
    return Text(
      preview,
      style: theme.textTheme.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 格式化課程日期（使用 DateTimeUtils）
  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    // ⭐ date 已經是本地時間，不需要 .toLocal()
    
    // 使用 DateTimeUtils 比較 UTC 日期
    if (DateTimeUtils.isSameUtcDate(date, now)) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (DateTimeUtils.isSameUtcDate(date, yesterday)) {
      return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    // 其他日期顯示完整日期
    return '${date.year}/${date.month}/${date.day} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化更新時間
  String _formatUpdateTime(DateTime date) {
    final now = DateTime.now();
    // ⭐ date 已經是本地時間，不需要 .toLocal()
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
  
  /// 獲取繪圖數量
  int _getDrawingCount(SessionNoteModel note) {
    return note.visualElements
        .where((e) => e.type == 'drawing')
        .length;
  }
  
  /// 獲取照片數量
  int _getPhotoCount(SessionNoteModel note) {
    return note.visualElements
        .where((e) => e.type == 'photo')
        .length;
  }
}


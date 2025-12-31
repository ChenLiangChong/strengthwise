import 'package:flutter/material.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/utils/datetime_utils.dart';

/// 課程筆記卡片組件
/// 
/// 顯示單個筆記的摘要資訊
class SessionNoteCard extends StatelessWidget {
  final SessionNoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SessionNoteCard({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題列：學員 ID + 狀態標籤
              Row(
                children: [
                  // 學員 ID（TODO: 未來版本從 UserService 查詢名稱）
                  Expanded(
                    child: Text(
                      '學員 ${note.clientId.substring(0, 8)}...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // 共享狀態標籤
                  if (note.isShared)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          const SizedBox(width: 4),
                          Text(
                            '已共享',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 創建日期（使用 DateTimeUtils）
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatSessionDate(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // SOAP 筆記預覽
              if (note.soap != null && !note.soap!.isEmpty) ...[
                _buildSoapPreview(context, note.soap!),
                const SizedBox(height: 8),
              ],
              
              // 底部資訊列：視覺元素數量 + 更新時間
              Row(
                children: [
                  // 繪圖數量
                  if (note.hasDrawings)
                    Row(
                      children: [
                        Icon(
                          Icons.draw,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getDrawingCount(note)} 個繪圖',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  
                  // 照片數量
                  if (_getPhotoCount(note) > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getPhotoCount(note)} 張照片',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  
                  // 更新時間（使用 DateTimeUtils）
                  Expanded(
                    child: Text(
                      '更新於 ${_formatUpdateTime(note.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // 刪除按鈕
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
    final localDate = date.toLocal();
    
    // 使用 DateTimeUtils 比較 UTC 日期
    if (DateTimeUtils.isSameUtcDate(localDate, now)) {
      return '今天 ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (DateTimeUtils.isSameUtcDate(localDate, yesterday)) {
      return '昨天 ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    }
    
    // 其他日期顯示完整日期
    return '${localDate.year}/${localDate.month}/${localDate.day} '
           '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化更新時間
  String _formatUpdateTime(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final difference = now.difference(localDate);
    
    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${localDate.year}/${localDate.month}/${localDate.day}';
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


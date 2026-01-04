import 'package:flutter/material.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/utils/datetime_utils.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              
              const SizedBox(height: 12),
              
              // 副標題：學員/教練名稱 + 創建日期
              Row(
                children: [
                  // ⭐ 頭像（首字母）
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
                  const SizedBox(width: 8),
                  
                  // 學員/教練名稱
                  Text(
                    _getPersonName(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: coachName == '已刪除的教練' ? Colors.grey : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 創建日期
                  Icon(
                    Icons.calendar_today,
                    size: 12,
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


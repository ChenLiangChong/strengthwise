// ✅ v3.1: 已上傳照片網格（公用元件）
// ✅ v3.7: MVVM 修復 - 透過 Controller 獲取簽名 URL
import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/session_note_controller.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 已上傳照片網格
///
/// 公用元件，可在以下頁面復用：
/// - SessionNoteEditorPage（編輯課程筆記）
/// - SessionNotesSection（Session Mode 課程筆記區塊）
class UploadedPhotoGrid extends StatelessWidget {
  /// 照片 Storage 路徑列表
  final List<String> storagePaths;

  /// 刪除照片回調（null 時不顯示刪除按鈕）
  final ValueChanged<int>? onRemove;

  /// 點擊照片回調（用於放大查看）
  final ValueChanged<int>? onTap;

  /// 網格列數
  final int crossAxisCount;

  /// 是否使用水平滾動列表（而非網格）
  final bool horizontal;

  /// 水平列表時的高度
  final double horizontalHeight;

  const UploadedPhotoGrid({
    super.key,
    required this.storagePaths,
    this.onRemove,
    this.onTap,
    this.crossAxisCount = 3,
    this.horizontal = false,
    this.horizontalHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (storagePaths.isEmpty) return const SizedBox.shrink();

    if (horizontal) {
      return SizedBox(
        height: horizontalHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: storagePaths.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => SizedBox(
            width: horizontalHeight,
            child: _buildPhotoItem(context, index),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: storagePaths.length,
      itemBuilder: (context, index) => _buildPhotoItem(context, index),
    );
  }

  Widget _buildPhotoItem(BuildContext context, int index) {
    final storagePath = storagePaths[index];
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _getSignedUrl(storagePath),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: onTap != null ? () => onTap!(index) : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 照片顯示
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPhotoWidget(context, snapshot, colorScheme),
              ),
              // 刪除按鈕
              if (onRemove != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildRemoveButton(context, index),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoWidget(
    BuildContext context,
    AsyncSnapshot<String> snapshot,
    ColorScheme colorScheme,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
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
      return Container(
        color: colorScheme.errorContainer,
        child: Center(
          child: Icon(Icons.broken_image, color: colorScheme.onErrorContainer),
        ),
      );
    }

    return Image.network(
      snapshot.data!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[PHOTO_GRID] ❌ 照片載入錯誤: $error');
        return Container(
          color: colorScheme.errorContainer,
          child: Center(
            child: Icon(Icons.broken_image, color: colorScheme.onErrorContainer),
          ),
        );
      },
    );
  }

  Widget _buildRemoveButton(BuildContext context, int index) {
    return CircleAvatar(
      backgroundColor: Colors.black54,
      radius: 14,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.close, size: 14, color: Colors.white),
        onPressed: () => onRemove!(index),
      ),
    );
  }

  /// 取得 Storage 簽名 URL
  /// ⭐ v3.7: MVVM 修復 - 透過 Controller 獲取（不直接訪問 Supabase）
  static Future<String> _getSignedUrl(String storagePath) async {
    final controller = serviceLocator<SessionNoteController>();
    final signedUrl = await controller.generateSignedUrl(
      bucket: 'session_photos',
      path: storagePath,
    );
    
    if (signedUrl == null) {
      throw Exception('無法生成簽名 URL');
    }
    
    return signedUrl;
  }
}


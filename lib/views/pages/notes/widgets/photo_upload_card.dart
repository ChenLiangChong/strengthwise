import 'package:flutter/material.dart';
import 'dart:io';

/// 照片上傳卡片
/// 
/// 顯示待上傳的照片，並支援刪除
class PhotoUploadCard extends StatelessWidget {
  final File photo;
  final VoidCallback onRemove;
  final bool isUploading;
  final double? uploadProgress;

  const PhotoUploadCard({
    Key? key,
    required this.photo,
    required this.onRemove,
    this.isUploading = false,
    this.uploadProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 照片預覽
          AspectRatio(
            aspectRatio: 1,
            child: Image.file(
              photo,
              fit: BoxFit.cover,
            ),
          ),
          
          // 上傳進度遮罩
          if (isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: uploadProgress,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                      if (uploadProgress != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${(uploadProgress! * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          
              // 刪除按鈕
          if (!isUploading)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


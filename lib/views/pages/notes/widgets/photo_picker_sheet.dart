import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 照片選擇底部彈窗
/// 
/// 功能：
/// - 相機拍照
/// - 相簿選擇
/// 
/// 使用方式：通過 Navigator.pop 返回 ImageSource
class PhotoPickerSheet extends StatelessWidget {
  const PhotoPickerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () {
              Navigator.pop(context, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('從相簿選擇'),
            onTap: () {
              Navigator.pop(context, ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('取消'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}


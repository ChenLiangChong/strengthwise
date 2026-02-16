import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// 個人資料頭像編輯元件
class ProfileAvatarEditor extends StatelessWidget {
  final String? photoURL;
  final File? avatarFile;
  final Uint8List? avatarBytes; // ⭐ v5.3: Web 跨平台支援
  final VoidCallback onPickImage;

  const ProfileAvatarEditor({
    super.key,
    this.photoURL,
    this.avatarFile,
    this.avatarBytes,
    required this.onPickImage,
  });

  ImageProvider? _getImageProvider() {
    // ⭐ v5.3: 優先使用 bytes（Web），再用 File（原生），最後用 URL
    if (avatarBytes != null) {
      return MemoryImage(avatarBytes!);
    }
    if (avatarFile != null) {
      return FileImage(avatarFile!);
    }
    if (photoURL != null) {
      return NetworkImage(photoURL!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            backgroundImage: _getImageProvider(),
            child: avatarFile == null && avatarBytes == null && photoURL == null
                ? Icon(Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: onPickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

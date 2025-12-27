import 'package:flutter/material.dart';
import 'dart:io';

/// 個人資料頭像編輯元件
class ProfileAvatarEditor extends StatelessWidget {
  final String? photoURL;
  final File? avatarFile;
  final VoidCallback onPickImage;

  const ProfileAvatarEditor({
    super.key,
    this.photoURL,
    this.avatarFile,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            backgroundImage: avatarFile != null
                ? FileImage(avatarFile!)
                : (photoURL != null
                    ? NetworkImage(photoURL!) as ImageProvider
                    : null),
            child: avatarFile == null && photoURL == null
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
                color: Colors.blue,
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


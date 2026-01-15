// ✅ 已響應式改造 (Phase 0) - CoachProfileContent 組件處理
// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/profile/widgets/coach/coach_profile_content.dart';
import 'package:strengthwise/views/pages/profile/coach_profile_form_page.dart';

/// 教練公開檔案檢視頁面
///
/// 兩種模式：
/// - [isOwner] = true: 個人版（有編輯入口）
/// - [isOwner] = false: 學員版（只讀）- 不建議使用，改用 CoachProfileContent
class CoachProfileViewPage extends StatelessWidget {
  final bool isOwner;
  final String? coachId;
  final String? email;

  const CoachProfileViewPage({
    super.key,
    this.isOwner = true,
    this.coachId,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    // ⭐ v3.6: 透過 IAuthController 取得當前用戶
    final authController = serviceLocator<IAuthController>();
    final currentUser = authController.user;
    final targetId = coachId ?? currentUser?.uid;
    final targetEmail = email ?? currentUser?.email;

    if (targetId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('教練檔案'),
        ),
        body: const Center(
          child: Text('無法獲取用戶 ID'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? '我的教練檔案' : '教練檔案'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '編輯',
              onPressed: () => _navigateToEdit(context),
            ),
        ],
      ),
      body: CoachProfileContent(
        coachId: targetId,
        email: targetEmail,
        isEditable: isOwner,
        showContactInfo: true,
        emptyStateTitle: isOwner ? '尚未建立教練檔案' : '此教練尚未建立檔案',
        emptyStateSubtitle: isOwner ? '建立您的專業檔案，讓學員認識您' : '請稍後再試',
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachProfileFormPage()),
    );
  }
}

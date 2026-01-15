// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/profile/widgets/coach/coach_profile_content.dart';

/// 教練中心 - 我的檔案 Tab
///
/// 顯示教練自己的公開檔案，可編輯
class CoachProfileTab extends StatelessWidget {
  const CoachProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    // ⭐ v3.6: 透過 IAuthController 取得當前用戶
    final authController = serviceLocator<IAuthController>();
    final currentUser = authController.user;
    final coachId = currentUser?.uid;
    final email = currentUser?.email;

    if (coachId == null) {
      return const Center(
        child: Text('無法獲取當前用戶 ID'),
      );
    }

    return CoachProfileContent(
      coachId: coachId,
      email: email,
      isEditable: true,
      showContactInfo: true,
      emptyStateTitle: '尚未建立教練檔案',
      emptyStateSubtitle: '建立您的專業檔案，讓學員認識您',
    );
  }
}

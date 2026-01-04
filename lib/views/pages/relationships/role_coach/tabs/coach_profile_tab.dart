import 'package:flutter/material.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/profile/widgets/coach/coach_profile_content.dart';

/// 教練中心 - 我的檔案 Tab
///
/// 顯示教練自己的公開檔案，可編輯
class CoachProfileTab extends StatelessWidget {
  const CoachProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = serviceLocator<IAuthService>();
    final currentUser = authService.getCurrentUser();
    final coachId = currentUser?['uid'] as String?;
    final email = currentUser?['email'] as String?;

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

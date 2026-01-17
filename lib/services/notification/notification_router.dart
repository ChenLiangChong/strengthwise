import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 頁面導入
import 'package:strengthwise/views/pages/home/main_home_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/coach_hub_page.dart';
import 'package:strengthwise/views/pages/relationships/role_client/client_hub_page.dart';

/// 通知路由器 ⭐ v3.9
///
/// 統一處理所有 FCM 通知點擊導航
/// 
/// 跳轉規則：
/// - 預約相關 → 首頁 / 教練中心 / 學員中心
/// - 時段相關 → 行事曆 Tab（內部 Tab 0 或 1）
/// - 關係相關 → 不推播
/// - 課程筆記 → 不推播
class NotificationRouter {
  final GlobalKey<NavigatorState> navigatorKey;
  
  /// 待處理的通知（當 navigator 還沒準備好時暫存）
  Map<String, dynamic>? _pendingNotification;

  NotificationRouter({required this.navigatorKey});

  /// 處理通知點擊
  ///
  /// [data] FCM 通知的 payload 數據
  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    if (kDebugMode) {
      debugPrint('[NotificationRouter] 處理通知點擊: type=$type, data=$data');
    }

    _navigateByType(type, data);
  }

  /// 根據通知類型導航
  void _navigateByType(String? type, Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    
    if (navigator == null) {
      // Navigator 還沒準備好，暫存通知並延遲重試
      if (kDebugMode) {
        debugPrint('[NotificationRouter] Navigator 未準備好，延遲重試...');
      }
      _pendingNotification = data;
      _retryNavigation();
      return;
    }

    // 根據類型決定跳轉目標
    switch (type) {
      // ==================== 跳到首頁 ====================
      case 'new_appointment':      // 學員預約
      case 'appointment_confirmed': // 確認預約
      case 'session_reminder':      // 課程提醒（含問卷提示）
      case 'readiness_submitted':   // 問卷已填
        _navigateToMainHome(navigator, tabIndex: 0);
        break;

      // ==================== 跳到學員中心 ====================
      case 'appointment_rejected':  // 被拒絕 → 學員收到
        _navigateToClientHub(navigator);
        break;

      // ==================== 跳到教練中心或學員中心（根據角色）====================
      case 'appointment_cancelled':
        // 需要根據 data 判斷是教練取消還是學員取消
        // cancelled_by: 'coach' 或 'client'
        final cancelledBy = data['cancelled_by'] as String?;
        if (cancelledBy == 'coach') {
          // 教練取消 → 通知學員 → 跳到學員中心
          _navigateToClientHub(navigator);
        } else {
          // 學員取消 → 通知教練 → 跳到教練中心
          _navigateToCoachHub(navigator);
        }
        break;

      // ==================== 跳到行事曆 Tab 0 (🎓 我的) ====================
      case 'coach_slot_created':    // 教練新增時段 → 學員收到
      case 'coach_slot_updated':    // 教練修改時段 → 學員收到
        _navigateToMainHome(navigator, tabIndex: 1, bookingTabIndex: 0);
        break;

      // ==================== 跳到行事曆 Tab 1 (🏋️ 教練) ====================
      case 'client_availability_created':  // 學員新增時段 → 教練收到
      case 'client_availability_updated':  // 學員更新時段 → 教練收到
        _navigateToMainHome(navigator, tabIndex: 1, bookingTabIndex: 1);
        break;

      // ==================== 預設跳到首頁 ====================
      default:
        _navigateToMainHome(navigator, tabIndex: 0);
        break;
    }
  }

  /// 導航到 MainHomePage
  void _navigateToMainHome(
    NavigatorState navigator, {
    required int tabIndex,
    int bookingTabIndex = 0,
  }) {
    if (kDebugMode) {
      debugPrint('[NotificationRouter] 導航到 MainHomePage Tab $tabIndex (bookingTab: $bookingTabIndex)');
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainHomePage(
          initialIndex: tabIndex,
          bookingTabIndex: bookingTabIndex,
        ),
      ),
      (route) => false,
    );
  }

  /// 導航到教練中心
  void _navigateToCoachHub(NavigatorState navigator) {
    if (kDebugMode) {
      debugPrint('[NotificationRouter] 導航到 CoachHubPage');
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainHomePage(initialIndex: 0)),
      (route) => false,
    );
    
    // 延遲後再 push CoachHubPage（確保 MainHomePage 已載入）
    Future.delayed(const Duration(milliseconds: 100), () {
      navigator.push(
        MaterialPageRoute(builder: (_) => const CoachHubPage()),
      );
    });
  }

  /// 導航到學員中心
  void _navigateToClientHub(NavigatorState navigator) {
    if (kDebugMode) {
      debugPrint('[NotificationRouter] 導航到 ClientHubPage');
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainHomePage(initialIndex: 0)),
      (route) => false,
    );
    
    // 延遲後再 push ClientHubPage（確保 MainHomePage 已載入）
    Future.delayed(const Duration(milliseconds: 100), () {
      navigator.push(
        MaterialPageRoute(builder: (_) => const ClientHubPage()),
      );
    });
  }

  /// 延遲重試導航
  void _retryNavigation() {
    // 延遲 500ms 後重試，最多重試 10 次（5 秒）
    int retryCount = 0;
    const maxRetries = 10;
    
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      retryCount++;
      
      if (navigatorKey.currentState != null) {
        timer.cancel();
        if (_pendingNotification != null) {
          if (kDebugMode) {
            debugPrint('[NotificationRouter] 重試成功，執行導航');
          }
          final data = _pendingNotification!;
          _pendingNotification = null;
          final type = data['type'] as String?;
          _navigateByType(type, data);
        }
      } else if (retryCount >= maxRetries) {
        timer.cancel();
        if (kDebugMode) {
          debugPrint('[NotificationRouter] 重試超時，放棄導航');
        }
        _pendingNotification = null;
      }
    });
  }
}

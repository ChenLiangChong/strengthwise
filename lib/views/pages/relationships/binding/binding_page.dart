// ✅ 已響應式改造 (Phase 0) - Tab 子組件處理
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'widgets/my_qrcode_tab.dart';
import 'widgets/scan_qrcode_tab.dart';

/// 教練學員綁定頁面
///
/// 使用 TabBar + TabBarView 實現：
/// - Tab 1: 顯示我的 QR Code
/// - Tab 2: 掃描對方 QR Code
///
/// Material 3 設計，支援左右滑動切換
class BindingPage extends StatefulWidget {
  final String currentRole; // 'coach' or 'client'
  final String userName;
  final String userEmail;

  const BindingPage({
    super.key,
    required this.currentRole,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<BindingPage> createState() => _BindingPageState();
}

class _BindingPageState extends State<BindingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CoachingRelationshipController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = serviceLocator<CoachingRelationshipController>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCoach = widget.currentRole == 'coach';

    return ChangeNotifierProvider<CoachingRelationshipController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isCoach ? '邀請學員' : '綁定教練'),
              Text(
                isCoach
                    ? '掃描學員 QR Code 或分享您的 QR Code'
                    : '掃描教練 QR Code 或分享您的 QR Code',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                icon: Icon(Icons.qr_code),
                text: '我的碼',
              ),
              Tab(
                icon: Icon(Icons.qr_code_scanner),
                text: '掃描碼',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: 我的 QR Code
            MyQRCodeTab(
              currentRole: widget.currentRole,
              userName: widget.userName,
              userEmail: widget.userEmail,
            ),

            // Tab 2: 掃描 QR Code
            ScanQRCodeTab(
              myRole: widget.currentRole,
            ),
          ],
        ),
      ),
    );
  }
}

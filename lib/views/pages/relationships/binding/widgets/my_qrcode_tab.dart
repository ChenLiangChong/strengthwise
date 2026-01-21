import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:strengthwise/controllers/interfaces/i_coaching_relationship_controller.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 我的 QR Code Tab（共用 Widget）
///
/// 用於顯示當前用戶的 QR Code，供對方掃描
class MyQRCodeTab extends StatefulWidget {
  final String currentRole; // 'coach' 或 'client'
  final String userName;
  final String userEmail;

  const MyQRCodeTab({
    super.key,
    required this.currentRole,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<MyQRCodeTab> createState() => _MyQRCodeTabState();
}

class _MyQRCodeTabState extends State<MyQRCodeTab> {
  String? _qrString;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    final controller = serviceLocator<ICoachingRelationshipController>();
    try {
      final qrData = await controller.generateMyQRData(widget.currentRole);
      if (mounted) {
        setState(() {
          _qrString = qrData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_qrString == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            const Text('無法生成 QR Code'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _generateQRCode,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // 標題
          Text(
            widget.currentRole == 'coach' ? '我的教練 QR Code' : '我的學員 QR Code',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // 說明文字
          Text(
            widget.currentRole == 'coach'
                ? '請學員掃描此 QR Code 來加入您'
                : '請教練掃描此 QR Code 來邀請您',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // QR Code 卡片（Material 3 設計）
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // QR Code 容器（深淺模式自適應背景）
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, // QR Code 必須白色背景才能掃描
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrString!,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      embeddedImage: const AssetImage('assets/icon/icon.png'),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 用戶資訊（高對比度文字）
                  Text(
                    widget.userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 使用說明（Material 3 卡片）
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '使用說明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    '1',
                    widget.currentRole == 'coach'
                        ? '請學員使用 StrengthWise App 掃描此碼'
                        : '請教練使用 StrengthWise App 掃描此碼',
                    colorScheme,
                  ),
                  _buildTipItem(
                    '2',
                    '掃描成功後會自動建立綁定關係',
                    colorScheme,
                  ),
                  _buildTipItem(
                    '3',
                    '請確保網路連線穩定',
                    colorScheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String number, String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

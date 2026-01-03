import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/utils/notification_utils.dart';

/// 掃描 QR Code Tab（共用 Widget）
///
/// 用於掃描對方的 QR Code 並建立綁定關係
class ScanQRCodeTab extends StatefulWidget {
  final String myRole; // 'coach' 或 'client'

  const ScanQRCodeTab({
    super.key,
    required this.myRole,
  });

  @override
  State<ScanQRCodeTab> createState() => _ScanQRCodeTabState();
}

class _ScanQRCodeTabState extends State<ScanQRCodeTab> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  /// 檢查相機權限
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _initScanner();
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
      if (result.isGranted) {
        _initScanner();
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  /// 初始化掃描器
  void _initScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  /// 顯示權限設定對話框
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要相機權限'),
        content: const Text('請在系統設定中開啟相機權限，才能掃描 QR Code'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('前往設定'),
          ),
        ],
      ),
    );
  }

  /// 處理掃描結果
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // 暫停掃描
    _scannerController?.stop();

    final controller =
        Provider.of<CoachingRelationshipController>(context, listen: false);

    // 執行綁定
    final success = await controller.scanAndBind(
      qrData: code,
      myRole: widget.myRole,
    );

    if (!mounted) return;

    if (success) {
      NotificationUtils.showSuccess(
        context,
        widget.myRole == 'coach' ? '成功邀請學員！' : '成功加入教練！',
      );
      // 等待通知顯示
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      // 返回 BindingPage 並標記成功
      Navigator.of(context).pop(true);
    } else {
      NotificationUtils.showError(
        context,
        controller.errorMessage ?? '綁定失敗',
      );
      // 恢復掃描
      setState(() {
        _isProcessing = false;
      });
      _scannerController?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '需要相機權限',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '請授予相機權限以掃描 QR Code',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _checkCameraPermission,
              icon: const Icon(Icons.settings),
              label: const Text('授予權限'),
            ),
          ],
        ),
      );
    }

    if (_scannerController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // 掃描器
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),

        // 掃描框
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // 上方說明
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.myRole == 'coach' ? '對準學員的 QR Code' : '對準教練的 QR Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '將 QR Code 置於掃描框內',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // 處理中覆蓋層
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在建立綁定關係...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

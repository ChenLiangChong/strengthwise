import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 頂部動態島風格休息計時器（2025 最佳實踐）
///
/// 模仿 iOS Dynamic Island，顯示在螢幕頂部
/// 支援最小化/展開，讓使用者在瀏覽其他頁面時也能看到剩餘時間
///
/// 設計文檔：docs/UI_UX_GUIDELINES.md
/// 靈感來源：iOS Live Activity
class RestTimerOverlay {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static int _remainingSeconds = 0;
  static bool _isExpanded = false;

  /// 顯示休息計時器
  ///
  /// [context] 構建上下文
  /// [durationInSeconds] 休息時長（秒）
  /// [onComplete] 計時結束回調
  static void show(
    BuildContext context, {
    required int durationInSeconds,
    VoidCallback? onComplete,
  }) {
    // 如果已有計時器，先移除
    hide();

    _remainingSeconds = durationInSeconds;
    _isExpanded = false;

    // 創建 Overlay Entry
    _overlayEntry = OverlayEntry(
      builder: (context) => _RestTimerWidget(
        remainingSeconds: _remainingSeconds,
        onDismiss: () {
          hide();
        },
        onToggleExpand: () {
          _isExpanded = !_isExpanded;
          _overlayEntry?.markNeedsBuild();
        },
        isExpanded: _isExpanded,
      ),
    );

    // 插入 Overlay
    Overlay.of(context).insert(_overlayEntry!);

    // 啟動計時器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        // 計時結束
        timer.cancel();
        _timer = null;

        // 觸覺回饋（連續兩次重度震動）
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 200), () {
          HapticFeedback.heavyImpact();
        });

        // 執行回調
        onComplete?.call();

        // 自動關閉
        Future.delayed(const Duration(seconds: 2), () {
          hide();
        });
      }

      // 更新 UI
      _overlayEntry?.markNeedsBuild();
    });
  }

  /// 隱藏休息計時器
  static void hide() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 獲取剩餘秒數
  static int get remainingSeconds => _remainingSeconds;

  /// 是否正在運行
  static bool get isRunning => _timer != null && _timer!.isActive;
}

/// 休息計時器 Widget（內部使用）
class _RestTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final VoidCallback onDismiss;
  final VoidCallback onToggleExpand;
  final bool isExpanded;

  const _RestTimerWidget({
    required this.remainingSeconds,
    required this.onDismiss,
    required this.onToggleExpand,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished = remainingSeconds <= 0;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onToggleExpand();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isExpanded ? MediaQuery.of(context).size.width * 0.9 : 240,
            height: isExpanded ? 120 : 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // 深色膠囊背景
              color: isFinished
                  ? (isDark
                      ? const Color(0xFF81C784) // 粉綠（完成）
                      : const Color(0xFF2E7D32))
                  : (isDark
                      ? const Color(0xFF1E293B) // 深灰（進行中）
                      : const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(isExpanded ? 24 : 24),
              boxShadow: [
                BoxShadow(
                  color: (isFinished
                          ? const Color(0xFF81C784)
                          : Colors.black)
                      .withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
          )
              .animate()
              .scale(
                duration: 300.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 200.ms),
        ),
      ),
    );
  }

  /// 收合狀態（膠囊）
  Widget _buildCollapsedContent() {
    final isFinished = remainingSeconds <= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 圖示
        Icon(
          isFinished ? Icons.check_circle : Icons.timer_outlined,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        // 時間顯示
        Expanded(
          child: Text(
            isFinished ? '休息結束！' : _formatTime(remainingSeconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        // 關閉按鈕
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onDismiss();
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(
              Icons.close,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  /// 展開狀態（大卡片）
  Widget _buildExpandedContent() {
    final isFinished = remainingSeconds <= 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 圖示
        Icon(
          isFinished ? Icons.check_circle : Icons.timer_outlined,
          color: Colors.white,
          size: 32,
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 2000.ms, delay: 500.ms),
        const SizedBox(height: 12),
        // 時間顯示
        Text(
          isFinished ? '休息結束！' : _formatTime(remainingSeconds),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        // 副標題
        Text(
          isFinished ? '準備好開始下一組' : '剩餘休息時間',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 格式化時間（mm:ss）
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}


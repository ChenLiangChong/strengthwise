import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:strengthwise/themes/app_theme.dart';

/// 休息倒數計時器組件
/// 
/// ⭐ v2.9.1 新增
/// 
/// 功能：
/// - 完成一組後自動開始倒數
/// - 顯示剩餘休息時間
/// - 倒數結束時震動提醒
/// - 可手動跳過休息
class RestTimerWidget extends StatefulWidget {
  /// 休息時間（秒）
  final int restSeconds;
  
  /// 是否啟動計時器
  final bool isActive;
  
  /// 計時結束回調
  final VoidCallback? onComplete;
  
  /// 跳過休息回調
  final VoidCallback? onSkip;
  
  const RestTimerWidget({
    super.key,
    required this.restSeconds,
    required this.isActive,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> 
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.restSeconds;
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    if (widget.isActive) {
      _startTimer();
    }
  }
  
  @override
  void didUpdateWidget(RestTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 當 isActive 變為 true 時啟動計時器
    if (widget.isActive && !oldWidget.isActive) {
      _remainingSeconds = widget.restSeconds;
      _startTimer();
    }
    
    // 當 isActive 變為 false 時停止計時器
    if (!widget.isActive && oldWidget.isActive) {
      _stopTimer();
    }
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            
            // 最後 3 秒脈衝動畫
            if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
              _pulseController.forward().then((_) => _pulseController.reverse());
            }
          } else {
            _onTimerComplete();
          }
        });
      }
    });
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  void _onTimerComplete() {
    _stopTimer();
    HapticFeedback.heavyImpact(); // 震動提醒
    widget.onComplete?.call();
  }
  
  void _skipRest() {
    _stopTimer();
    HapticFeedback.lightImpact();
    widget.onSkip?.call();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _remainingSeconds / widget.restSeconds;
    final isUrgent = _remainingSeconds <= 3;
    
    // ⭐ v2.9.1: 緊湊橫幅式設計（高度 ~64dp）
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        
        return Transform.scale(
          scale: isUrgent ? scale : 1.0,
          child: Container(
            width: double.infinity, // 確保有寬度約束
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: 4, // 減少垂直 margin
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isUrgent 
                  ? colorScheme.error.withOpacity(0.15)
                  : colorScheme.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUrgent ? colorScheme.error : colorScheme.primary,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // 圓形進度指示器 + 時間（48x48）
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 進度圓環
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUrgent ? colorScheme.error : colorScheme.primary,
                          ),
                        ),
                      ),
                      // 圖標
                      Icon(
                        Icons.timer,
                        size: 20,
                        color: isUrgent ? colorScheme.error : colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingMd),
                
                // 時間顯示
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '休息中',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isUrgent 
                              ? colorScheme.error 
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isUrgent 
                              ? colorScheme.error 
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 跳過按鈕（使用 SizedBox 包裝確保有約束）
                SizedBox(
                  width: 64,
                  child: TextButton(
                    onPressed: _skipRest,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '跳過',
                      style: TextStyle(
                        color: isUrgent 
                            ? colorScheme.error 
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}


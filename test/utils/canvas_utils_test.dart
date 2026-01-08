import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/utils/canvas_utils.dart';

/// CanvasUtils 測試
///
/// P0 Utils 層 - 8 個測試案例
void main() {
  group('CanvasUtils', () {
    // =========================================================================
    // cos 和 sin 數學函數
    // =========================================================================
    group('數學函數', () {
      test('cos(0) = 1', () {
        expect(CanvasUtils.cos(0), closeTo(1.0, 0.0001));
      });

      test('cos(π) = -1', () {
        expect(CanvasUtils.cos(math.pi), closeTo(-1.0, 0.0001));
      });

      test('cos(π/2) = 0', () {
        expect(CanvasUtils.cos(math.pi / 2), closeTo(0.0, 0.0001));
      });

      test('sin(0) = 0', () {
        expect(CanvasUtils.sin(0), closeTo(0.0, 0.0001));
      });

      test('sin(π/2) = 1', () {
        expect(CanvasUtils.sin(math.pi / 2), closeTo(1.0, 0.0001));
      });

      test('sin(π) = 0', () {
        expect(CanvasUtils.sin(math.pi), closeTo(0.0, 0.0001));
      });

      test('sin²(x) + cos²(x) = 1', () {
        for (double x = 0; x < 2 * math.pi; x += 0.1) {
          final sinX = CanvasUtils.sin(x);
          final cosX = CanvasUtils.cos(x);
          expect(sinX * sinX + cosX * cosX, closeTo(1.0, 0.0001));
        }
      });

      test('負角度計算正確', () {
        expect(CanvasUtils.cos(-math.pi), closeTo(-1.0, 0.0001));
        expect(CanvasUtils.sin(-math.pi / 2), closeTo(-1.0, 0.0001));
      });
    });
  });
}

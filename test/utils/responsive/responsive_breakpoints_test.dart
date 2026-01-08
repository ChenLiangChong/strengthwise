import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/utils/responsive/responsive_breakpoints.dart';

/// ResponsiveBreakpoints 測試
///
/// P7 優先級 - 15 個測試案例
void main() {
  group('ResponsiveBreakpoints', () {
    // =========================================================================
    // P7-312: getScaleFactor
    // =========================================================================
    group('getScaleFactor', () {
      test('極小螢幕 (<320) 返回 0.8', () {
        expect(ResponsiveBreakpoints.getScaleFactor(280), 0.8);
        expect(ResponsiveBreakpoints.getScaleFactor(319), 0.8);
      });

      test('小型手機 (320-359) 返回 0.88', () {
        expect(ResponsiveBreakpoints.getScaleFactor(320), 0.88);
        expect(ResponsiveBreakpoints.getScaleFactor(359), 0.88);
      });

      test('中小手機 (360-389) 返回 0.94', () {
        expect(ResponsiveBreakpoints.getScaleFactor(360), 0.94);
        expect(ResponsiveBreakpoints.getScaleFactor(389), 0.94);
      });

      test('標準手機 (390-429) 返回 1.0', () {
        expect(ResponsiveBreakpoints.getScaleFactor(390), 1.0);
        expect(ResponsiveBreakpoints.getScaleFactor(429), 1.0);
      });

      test('大型手機 (430-599) 返回 1.05', () {
        expect(ResponsiveBreakpoints.getScaleFactor(430), 1.05);
        expect(ResponsiveBreakpoints.getScaleFactor(599), 1.05);
      });

      test('平板/桌面 (>=600) 返回 1.0', () {
        expect(ResponsiveBreakpoints.getScaleFactor(600), 1.0);
        expect(ResponsiveBreakpoints.getScaleFactor(1024), 1.0);
        expect(ResponsiveBreakpoints.getScaleFactor(1920), 1.0);
      });
    });

    // =========================================================================
    // P7-313: getScreenType
    // =========================================================================
    group('getScreenType', () {
      test('返回 mobileSmall (<=359)', () {
        expect(
            ResponsiveBreakpoints.getScreenType(320), ScreenType.mobileSmall);
        expect(
            ResponsiveBreakpoints.getScreenType(359), ScreenType.mobileSmall);
      });

      test('返回 mobile (360-599)', () {
        expect(ResponsiveBreakpoints.getScreenType(360), ScreenType.mobile);
        expect(ResponsiveBreakpoints.getScreenType(599), ScreenType.mobile);
      });

      test('返回 mobileLarge (600-719)', () {
        expect(
            ResponsiveBreakpoints.getScreenType(600), ScreenType.mobileLarge);
        expect(
            ResponsiveBreakpoints.getScreenType(719), ScreenType.mobileLarge);
      });

      test('返回 tabletSmall (720-839)', () {
        expect(
            ResponsiveBreakpoints.getScreenType(720), ScreenType.tabletSmall);
        expect(
            ResponsiveBreakpoints.getScreenType(839), ScreenType.tabletSmall);
      });

      test('返回 tablet (840-1023)', () {
        expect(ResponsiveBreakpoints.getScreenType(840), ScreenType.tablet);
        expect(ResponsiveBreakpoints.getScreenType(1023), ScreenType.tablet);
      });

      test('返回 tabletLarge (1024-1279)', () {
        expect(
            ResponsiveBreakpoints.getScreenType(1024), ScreenType.tabletLarge);
        expect(
            ResponsiveBreakpoints.getScreenType(1279), ScreenType.tabletLarge);
      });

      test('返回 desktop (>=1280)', () {
        expect(ResponsiveBreakpoints.getScreenType(1280), ScreenType.desktop);
        expect(ResponsiveBreakpoints.getScreenType(1920), ScreenType.desktop);
      });
    });

    // =========================================================================
    // P7-314/315/316: isMobile/isTablet/isDesktop
    // =========================================================================
    group('裝置類型判斷', () {
      test('isMobile 正確判斷', () {
        expect(ResponsiveBreakpoints.isMobile(360), isTrue);
        expect(ResponsiveBreakpoints.isMobile(719), isTrue);
        expect(ResponsiveBreakpoints.isMobile(720), isFalse);
      });

      test('isTablet 正確判斷', () {
        expect(ResponsiveBreakpoints.isTablet(719), isFalse);
        expect(ResponsiveBreakpoints.isTablet(720), isTrue);
        expect(ResponsiveBreakpoints.isTablet(1279), isTrue);
        expect(ResponsiveBreakpoints.isTablet(1280), isFalse);
      });

      test('isDesktop 正確判斷', () {
        expect(ResponsiveBreakpoints.isDesktop(1279), isFalse);
        expect(ResponsiveBreakpoints.isDesktop(1280), isTrue);
        expect(ResponsiveBreakpoints.isDesktop(1920), isTrue);
      });
    });

    // =========================================================================
    // P7-317: 斷點邊界值
    // =========================================================================
    group('斷點邊界值', () {
      test('常量值正確定義', () {
        expect(ResponsiveBreakpoints.mobileSmallMax, 359);
        expect(ResponsiveBreakpoints.mobileMax, 599);
        expect(ResponsiveBreakpoints.mobileLargeMax, 719);
        expect(ResponsiveBreakpoints.tabletSmallMax, 839);
        expect(ResponsiveBreakpoints.tabletMax, 1023);
        expect(ResponsiveBreakpoints.tabletLargeMax, 1279);
      });

      test('設備參考尺寸正確', () {
        expect(ResponsiveBreakpoints.iphoneSe, 375);
        expect(ResponsiveBreakpoints.iphone14, 390);
        expect(ResponsiveBreakpoints.ipadMini, 744);
        expect(ResponsiveBreakpoints.ipadAir, 820);
      });
    });
  });

  group('ScreenType', () {
    // =========================================================================
    // 枚舉值完整性
    // =========================================================================
    test('包含所有預期類型', () {
      expect(ScreenType.values.length, 7);
      expect(ScreenType.values, contains(ScreenType.mobileSmall));
      expect(ScreenType.values, contains(ScreenType.mobile));
      expect(ScreenType.values, contains(ScreenType.mobileLarge));
      expect(ScreenType.values, contains(ScreenType.tabletSmall));
      expect(ScreenType.values, contains(ScreenType.tablet));
      expect(ScreenType.values, contains(ScreenType.tabletLarge));
      expect(ScreenType.values, contains(ScreenType.desktop));
    });
  });
}

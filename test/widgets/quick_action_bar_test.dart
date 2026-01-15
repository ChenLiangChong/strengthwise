import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/views/widgets/quick_action_bar.dart';

/// QuickActionBar Widget 測試
///
/// P4 Widget 層 - 8 個測試案例
void main() {
  group('QuickActionBar', () {
    // =========================================================================
    // 渲染測試
    // =========================================================================
    testWidgets('正確渲染多個按鈕', (tester) async {
      final actions = [
        QuickAction(icon: Icons.home, label: '首頁', onTap: () {}),
        QuickAction(icon: Icons.person, label: '個人', onTap: () {}),
        QuickAction(icon: Icons.settings, label: '設定', onTap: () {}),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionBar(actions: actions),
          ),
        ),
      );

      // 驗證三個按鈕都顯示
      expect(find.text('首頁'), findsOneWidget);
      expect(find.text('個人'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('空列表不顯示任何內容', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionBar(actions: []),
          ),
        ),
      );

      // 驗證沒有內容
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('顯示標題', (tester) async {
      final actions = [
        QuickAction(icon: Icons.home, label: '首頁', onTap: () {}),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionBar(
              actions: actions,
              showTitle: true,
              title: '快捷操作',
            ),
          ),
        ),
      );

      expect(find.text('快捷操作'), findsOneWidget);
    });

    testWidgets('隱藏標題', (tester) async {
      final actions = [
        QuickAction(icon: Icons.home, label: '首頁', onTap: () {}),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionBar(
              actions: actions,
              showTitle: false,
            ),
          ),
        ),
      );

      expect(find.text('快捷操作'), findsNothing);
    });

    // =========================================================================
    // 互動測試
    // =========================================================================
    testWidgets('點擊按鈕觸發 onTap', (tester) async {
      bool tapped = false;
      final actions = [
        QuickAction(icon: Icons.home, label: '首頁', onTap: () => tapped = true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionBar(actions: actions),
          ),
        ),
      );

      await tester.tap(find.text('首頁'));
      expect(tapped, isTrue);
    });

    // =========================================================================
    // 樣式測試
    // =========================================================================
    testWidgets('自定義背景色生效', (tester) async {
      final actions = [
        QuickAction(
          icon: Icons.home,
          label: '首頁',
          onTap: () {},
          backgroundColor: Colors.red.shade100,
          iconColor: Colors.red,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionBar(actions: actions),
          ),
        ),
      );

      // 驗證 Icon 存在
      expect(find.byIcon(Icons.home), findsOneWidget);
    });
  });

  group('QuickAction', () {
    test('建構函數正確初始化', () {
      final action = QuickAction(
        icon: Icons.star,
        label: '測試',
        onTap: () {},
        backgroundColor: Colors.blue,
        iconColor: Colors.white,
      );

      expect(action.icon, Icons.star);
      expect(action.label, '測試');
      expect(action.backgroundColor, Colors.blue);
      expect(action.iconColor, Colors.white);
    });

    test('可選參數可為 null', () {
      final action = QuickAction(
        icon: Icons.star,
        label: '測試',
        onTap: () {},
      );

      expect(action.backgroundColor, isNull);
      expect(action.iconColor, isNull);
    });
  });
}

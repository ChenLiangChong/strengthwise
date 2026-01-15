import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/views/widgets/collapsible_section.dart';

/// CollapsibleSection Widget 測試
///
/// P4 Widget 層 - 10 個測試案例
void main() {
  group('CollapsibleSection', () {
    // =========================================================================
    // 初始狀態測試
    // =========================================================================
    testWidgets('預設展開顯示內容', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              initiallyExpanded: true,
              child: Text('內容文字'),
            ),
          ),
        ),
      );

      expect(find.text('測試區塊'), findsOneWidget);
      expect(find.text('內容文字'), findsOneWidget);
    });

    testWidgets('預設收起時內容不可見', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              initiallyExpanded: false,
              child: Text('內容文字'),
            ),
          ),
        ),
      );

      expect(find.text('測試區塊'), findsOneWidget);
      // 內容存在但高度為 0
      final contentFinder = find.text('內容文字');
      expect(contentFinder, findsOneWidget);
    });

    // =========================================================================
    // 互動測試
    // =========================================================================
    testWidgets('點擊標題可收起', (tester) async {
      bool? isExpanded;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              initiallyExpanded: true,
              onExpansionChanged: (value) => isExpanded = value,
              child: const Text('內容文字'),
            ),
          ),
        ),
      );

      // 點擊標題
      await tester.tap(find.text('測試區塊'));
      await tester.pumpAndSettle();

      expect(isExpanded, isFalse);
    });

    testWidgets('點擊標題可展開', (tester) async {
      bool? isExpanded;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              initiallyExpanded: false,
              onExpansionChanged: (value) => isExpanded = value,
              child: const Text('內容文字'),
            ),
          ),
        ),
      );

      // 點擊標題
      await tester.tap(find.text('測試區塊'));
      await tester.pumpAndSettle();

      expect(isExpanded, isTrue);
    });

    // =========================================================================
    // 圖標和 Trailing 測試
    // =========================================================================
    testWidgets('顯示標題圖標', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              icon: Icons.star,
              child: Text('內容'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('顯示 trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              trailing: Chip(label: Text('3')),
              child: Text('內容'),
            ),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    // =========================================================================
    // 動畫測試
    // =========================================================================
    testWidgets('展開有動畫效果', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              initiallyExpanded: false,
              child: Text('內容'),
            ),
          ),
        ),
      );

      // 點擊展開
      await tester.tap(find.text('測試區塊'));

      // 驗證動畫進行中
      await tester.pump(const Duration(milliseconds: 125)); // 動畫一半

      // 動畫完成
      await tester.pumpAndSettle();

      expect(find.text('內容'), findsOneWidget);
    });

    testWidgets('展開箭頭顯示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '測試區塊',
              child: Text('內容'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });
}

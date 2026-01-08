import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/views/pages/statistics/widgets/empty_state_widget.dart';

/// EmptyStateWidget 測試
///
/// P4 優先級 - 5 個測試案例
void main() {
  group('EmptyStateWidget', () {
    // =========================================================================
    // P4-272: 基本渲染
    // =========================================================================
    testWidgets('顯示圖標和標題', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '沒有資料',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('沒有資料'), findsOneWidget);
    });

    // =========================================================================
    // P4-273: 副標題
    // =========================================================================
    testWidgets('顯示副標題', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '沒有資料',
              subtitle: '請稍後再試',
            ),
          ),
        ),
      );

      expect(find.text('請稍後再試'), findsOneWidget);
    });

    testWidgets('無副標題時不顯示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '沒有資料',
            ),
          ),
        ),
      );

      expect(find.text('請稍後再試'), findsNothing);
    });

    // =========================================================================
    // P4-274: 自訂圖標大小
    // =========================================================================
    testWidgets('自訂 iconSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '沒有資料',
              iconSize: 100.0,
            ),
          ),
        ),
      );

      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });

    // =========================================================================
    // P4-275: 居中顯示
    // =========================================================================
    testWidgets('內容居中', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '沒有資料',
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsWidgets);
    });
  });
}

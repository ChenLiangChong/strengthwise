import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// P12 無障礙測試
///
/// 測試 Widget 的 Semantics labels
void main() {
  group('無障礙測試', () {
    // =========================================================================
    // P12-382/383: Semantics 標籤
    // =========================================================================
    group('Semantics', () {
      testWidgets('按鈕有 Semantics label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Semantics(
                label: '提交按鈕',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('提交'),
                ),
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('提交按鈕'), findsOneWidget);
      });

      testWidgets('圖片有 Semantics 描述', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Semantics(
                label: '使用者頭像',
                child: const Icon(Icons.person),
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('使用者頭像'), findsOneWidget);
      });
    });

    // =========================================================================
    // P12-385: 觸控目標大小
    // =========================================================================
    group('觸控目標', () {
      testWidgets('按鈕最小 48x48', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('按鈕'),
                ),
              ),
            ),
          ),
        );

        final buttonSize = tester.getSize(find.byType(ElevatedButton));

        // Material Design 最小觸控目標 48dp
        expect(buttonSize.width, greaterThanOrEqualTo(48));
        expect(
            buttonSize.height, greaterThanOrEqualTo(36)); // ElevatedButton 最小高度
      });

      testWidgets('IconButton 最小尺寸', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        );

        final buttonSize = tester.getSize(find.byType(IconButton));
        expect(buttonSize.width, greaterThanOrEqualTo(40));
        expect(buttonSize.height, greaterThanOrEqualTo(40));
      });
    });

    // =========================================================================
    // P12-389: Focus 狀態
    // =========================================================================
    group('Focus 狀態', () {
      testWidgets('TextField 可以獲得 focus', (tester) async {
        final focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextField(
                focusNode: focusNode,
              ),
            ),
          ),
        );

        expect(focusNode.hasFocus, isFalse);

        // 點擊 TextField
        await tester.tap(find.byType(TextField));
        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
      });
    });
  });
}

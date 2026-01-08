import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/utils/body_part_utils.dart';

/// BodyPartUtils 測試
///
/// P0 優先級 - 6 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P0
void main() {
  group('BodyPartUtils', () {
    // =========================================================================
    // P0-13-17: getBodyPartIcon - 部位 → 圖標
    // =========================================================================
    group('getBodyPartIcon', () {
      test('胸部返回正確圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('胸部');

        // Assert
        expect(result, Icons.self_improvement);
      });

      test('背部返回正確圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('背部');

        // Assert
        expect(result, Icons.accessibility_new);
      });

      test('腿部返回正確圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('腿部');

        // Assert
        expect(result, Icons.directions_run);
      });

      test('肩部返回正確圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('肩部');

        // Assert
        expect(result, Icons.sports_gymnastics);
      });

      test('手臂返回正確圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('手臂');

        // Assert
        expect(result, Icons.back_hand);
      });

      test('核心返回正確圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('核心');

        // Assert
        expect(result, Icons.sports_martial_arts);
      });

      // P0-17: 未知部位預設值
      test('未知部位返回預設圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('未知部位');

        // Assert
        expect(result, Icons.fitness_center);
      });

      // P0-18: 空字串處理
      test('空字串返回預設圖標', () {
        // Act
        final result = BodyPartUtils.getBodyPartIcon('');

        // Assert
        expect(result, Icons.fitness_center);
      });
    });

    // =========================================================================
    // P0-15: getBodyPartColor - 部位 → 顏色
    // =========================================================================
    group('getBodyPartColor', () {
      testWidgets('胸部關鍵字返回紅色', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final result = BodyPartUtils.getBodyPartColor(context, '胸部');

                // Assert
                expect(result, Colors.red);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('背部關鍵字返回藍色', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final result = BodyPartUtils.getBodyPartColor(context, '背部');

                // Assert
                expect(result, Colors.blue);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('核心關鍵字返回 Teal', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final resultCore =
                    BodyPartUtils.getBodyPartColor(context, '核心');
                final resultAbs = BodyPartUtils.getBodyPartColor(context, '腹部');

                // Assert
                expect(resultCore, Colors.teal);
                expect(resultAbs, Colors.teal);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('腿部使用主題 secondary 顏色', (tester) async {
        const testColor = Colors.purple;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                secondary: testColor,
              ),
            ),
            home: Builder(
              builder: (context) {
                // Act
                final result = BodyPartUtils.getBodyPartColor(context, '腿部');

                // Assert
                expect(result, testColor);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('肩部和手臂使用主題 primary 顏色', (tester) async {
        const testColor = Colors.green;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                primary: testColor,
              ),
            ),
            home: Builder(
              builder: (context) {
                // Act
                final resultShoulder =
                    BodyPartUtils.getBodyPartColor(context, '肩部');
                final resultArm = BodyPartUtils.getBodyPartColor(context, '手臂');

                // Assert
                expect(resultShoulder, testColor);
                expect(resultArm, testColor);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('未知部位返回 onSurfaceVariant 顏色', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final result = BodyPartUtils.getBodyPartColor(context, '未知部位');
                final expected = Theme.of(context).colorScheme.onSurfaceVariant;

                // Assert
                expect(result, expected);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('包含關鍵字即可匹配（胸肌 → 紅色）', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act - 測試部分匹配
                final result = BodyPartUtils.getBodyPartColor(context, '上胸肌');

                // Assert
                expect(result, Colors.red);
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    // =========================================================================
    // buildBodyPartTag - Widget 測試
    // =========================================================================
    group('buildBodyPartTag', () {
      testWidgets('建立正確的標籤 Widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Act
                final widget = BodyPartUtils.buildBodyPartTag(context, '胸部');

                // Assert
                return widget;
              },
            ),
          ),
        );

        // 驗證文字顯示
        expect(find.text('胸部'), findsOneWidget);
      });

      testWidgets('標籤有正確的裝飾', (tester) async {
        late Widget tagWidget;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tagWidget = BodyPartUtils.buildBodyPartTag(context, '背部');
                return tagWidget;
              },
            ),
          ),
        );

        // 驗證是 Container
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('背部'),
            matching: find.byType(Container),
          ),
        );
        expect(container.decoration, isNotNull);
      });
    });
  });
}

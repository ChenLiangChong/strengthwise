import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/statistics/muscle_group_balance.dart';

/// MuscleGroupBalance 及其相關類別測試
void main() {
  group('MuscleGroupCategory', () {
    test('應該有 5 種肌群類別', () {
      expect(MuscleGroupCategory.values.length, 5);
    });

    test('包含所有預期的肌群類別', () {
      expect(MuscleGroupCategory.values, contains(MuscleGroupCategory.push));
      expect(MuscleGroupCategory.values, contains(MuscleGroupCategory.pull));
      expect(MuscleGroupCategory.values, contains(MuscleGroupCategory.legs));
      expect(MuscleGroupCategory.values, contains(MuscleGroupCategory.core));
      expect(MuscleGroupCategory.values, contains(MuscleGroupCategory.other));
    });

    group('displayName', () {
      test('push → 推（胸肩三頭）', () {
        expect(MuscleGroupCategory.push.displayName, '推（胸肩三頭）');
      });

      test('pull → 拉（背二頭）', () {
        expect(MuscleGroupCategory.pull.displayName, '拉（背二頭）');
      });

      test('legs → 腿部', () {
        expect(MuscleGroupCategory.legs.displayName, '腿部');
      });

      test('所有類別都有顯示名稱', () {
        for (final category in MuscleGroupCategory.values) {
          expect(category.displayName, isNotEmpty);
        }
      });
    });

    group('emoji', () {
      test('push → 💪', () {
        expect(MuscleGroupCategory.push.emoji, '💪');
      });

      test('legs → 🦵', () {
        expect(MuscleGroupCategory.legs.emoji, '🦵');
      });

      test('所有類別都有 emoji', () {
        for (final category in MuscleGroupCategory.values) {
          expect(category.emoji, isNotEmpty);
        }
      });
    });
  });

  group('MuscleGroupBalanceStats', () {
    MuscleGroupBalanceStats createTestStats() {
      return MuscleGroupBalanceStats(
        category: MuscleGroupCategory.push,
        totalVolume: 5000.0,
        workoutCount: 10,
        exerciseCount: 15,
        percentage: 0.35,
        topExercises: ['臥推', '肩推', '飛鳥'],
      );
    }

    test('應該正確建立實例', () {
      final stats = createTestStats();

      expect(stats.category, MuscleGroupCategory.push);
      expect(stats.totalVolume, 5000.0);
      expect(stats.workoutCount, 10);
      expect(stats.exerciseCount, 15);
      expect(stats.percentage, 0.35);
      expect(stats.topExercises, ['臥推', '肩推', '飛鳥']);
    });

    group('formattedVolume', () {
      test('≥1000 應該顯示為 k kg', () {
        final stats = MuscleGroupBalanceStats(
          category: MuscleGroupCategory.push,
          totalVolume: 5000.0,
          workoutCount: 1,
          exerciseCount: 1,
          percentage: 0.5,
          topExercises: [],
        );

        expect(stats.formattedVolume, '5.0k kg');
      });

      test('<1000 應該顯示為 kg', () {
        final stats = MuscleGroupBalanceStats(
          category: MuscleGroupCategory.push,
          totalVolume: 500.0,
          workoutCount: 1,
          exerciseCount: 1,
          percentage: 0.5,
          topExercises: [],
        );

        expect(stats.formattedVolume, '500 kg');
      });
    });

    test('formattedPercentage 應該正確格式化', () {
      final stats = createTestStats();

      expect(stats.formattedPercentage, '35%');
    });

    test('toString 應該返回可讀格式', () {
      final stats = createTestStats();
      final str = stats.toString();

      expect(str, contains('推'));
      expect(str, contains('35%'));
    });
  });

  group('MuscleGroupBalance', () {
    MuscleGroupBalance createTestBalance() {
      return MuscleGroupBalance(
        stats: [
          MuscleGroupBalanceStats(
            category: MuscleGroupCategory.push,
            totalVolume: 5000.0,
            workoutCount: 10,
            exerciseCount: 15,
            percentage: 0.35,
            topExercises: ['臥推'],
          ),
          MuscleGroupBalanceStats(
            category: MuscleGroupCategory.pull,
            totalVolume: 4500.0,
            workoutCount: 8,
            exerciseCount: 12,
            percentage: 0.32,
            topExercises: ['划船'],
          ),
          MuscleGroupBalanceStats(
            category: MuscleGroupCategory.legs,
            totalVolume: 4000.0,
            workoutCount: 6,
            exerciseCount: 10,
            percentage: 0.28,
            topExercises: ['深蹲'],
          ),
        ],
        isPushPullBalanced: true,
        pushPullRatio: 1.1,
        balanceStatus: '平衡良好',
        recommendations: ['繼續保持目前的訓練比例'],
      );
    }

    test('應該正確建立實例', () {
      final balance = createTestBalance();

      expect(balance.stats.length, 3);
      expect(balance.isPushPullBalanced, isTrue);
      expect(balance.pushPullRatio, 1.1);
      expect(balance.balanceStatus, '平衡良好');
    });

    test('pushStats 應該返回推動作統計', () {
      final balance = createTestBalance();

      expect(balance.pushStats, isNotNull);
      expect(balance.pushStats!.category, MuscleGroupCategory.push);
    });

    test('pullStats 應該返回拉動作統計', () {
      final balance = createTestBalance();

      expect(balance.pullStats, isNotNull);
      expect(balance.pullStats!.category, MuscleGroupCategory.pull);
    });

    test('legStats 應該返回腿部統計', () {
      final balance = createTestBalance();

      expect(balance.legStats, isNotNull);
      expect(balance.legStats!.category, MuscleGroupCategory.legs);
    });

    test('stats 為空時 getter 應該返回 null', () {
      final balance = MuscleGroupBalance(
        stats: [],
        isPushPullBalanced: false,
        pushPullRatio: 0.0,
        balanceStatus: '無數據',
        recommendations: [],
      );

      expect(balance.pushStats, isNull);
      expect(balance.pullStats, isNull);
      expect(balance.legStats, isNull);
    });

    test('toString 應該返回可讀格式', () {
      final balance = createTestBalance();
      final str = balance.toString();

      expect(str, contains('平衡良好'));
    });
  });
}

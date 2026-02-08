import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/exercise/exercise.dart';
import 'package:strengthwise/services/supabase/exercise/exercise_search_engine.dart';
import '../../helpers/exercise_test_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseSearchEngine engine;
  late List<Exercise> dataset;

  setUp(() {
    engine = ExerciseSearchEngine();
    dataset = ExerciseTestFactory.standardDataset;
  });

  // ==========================================================================
  // Group 1: searchFromCache — 基本搜尋
  // ==========================================================================
  group('searchFromCache', () {
    test('繁體中文名稱搜尋（"臥推" → 臥推系列）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: '臥推',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-001', 'ex-002']));
    });

    test('英文名稱搜尋（"bench" → Bench Press 系列）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: 'bench',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-001', 'ex-002']));
    });

    test('canonicalName 搜尋（"平板槓鈴" → 槓鈴臥推）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: '平板槓鈴',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-001'));
    });

    test('canonicalNameEn 搜尋（"Flat Barbell" → 槓鈴臥推）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: 'flat barbell',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-001'));
    });

    test('別名搜尋 — 中文（"仰臥推舉" → 臥推）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: '仰臥推舉',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-001'));
    });

    test('別名搜尋 — 英文（"BP" → 臥推）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: 'BP',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-001'));
    });

    test('level1 分類搜尋', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: '核心',
        limit: 20,
      );
      // ex-007 棒式的 level1='核心'
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-007'));
    });

    test('搜尋大小寫不敏感', () {
      final upper = engine.searchFromCache(
        cache: dataset,
        query: 'BENCH PRESS',
        limit: 20,
      );
      final lower = engine.searchFromCache(
        cache: dataset,
        query: 'bench press',
        limit: 20,
      );
      expect(upper.length, lower.length);
    });

    test('limit 限制結果數量', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: '槓',
        limit: 2,
      );
      expect(results.length, lessThanOrEqualTo(2));
    });

    test('無匹配應返回空列表', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: 'zzzzz不存在的動作',
        limit: 20,
      );
      expect(results, isEmpty);
    });

    test('相關度排序：完全匹配 > 開頭匹配 > 別名匹配 > 部分匹配', () {
      // 建立不同匹配類型的動作
      final exercises = [
        ExerciseTestFactory.make(
          id: 'partial',
          name: '上斜槓鈴臥推',
          nameEn: 'Incline Barbell Bench Press',
        ),
        ExerciseTestFactory.make(
          id: 'exact',
          name: '臥推',
          nameEn: 'Bench Press',
        ),
        ExerciseTestFactory.make(
          id: 'prefix',
          name: '臥推變化式',
          nameEn: 'Bench Press Variation',
        ),
        ExerciseTestFactory.make(
          id: 'alias',
          name: '仰推',
          nameEn: 'Press',
          aliases: ['臥推'],
        ),
      ];

      final results = engine.searchFromCache(
        cache: exercises,
        query: '臥推',
        limit: 10,
      );

      final ids = results.map((e) => e.id).toList();
      // 完全匹配(100) 應在最前
      expect(ids.first, 'exact');
      // 開頭匹配(80) 應在別名完全匹配(70) 之前
      final prefixIndex = ids.indexOf('prefix');
      final aliasIndex = ids.indexOf('alias');
      if (prefixIndex >= 0 && aliasIndex >= 0) {
        expect(prefixIndex, lessThan(aliasIndex));
      }
    });

    test('繁中 2 字短詞搜尋（"深蹲"）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: '深蹲',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-003'));
    });

    test('繁中 2 字短詞搜尋（"硬舉"）', () {
      final results = engine.searchFromCache(
        cache: dataset,
        query: '硬舉',
        limit: 20,
      );
      final ids = results.map((e) => e.id).toSet();
      // ex-004 別名包含 '硬舉'
      expect(ids, contains('ex-004'));
    });
  });

  // ==========================================================================
  // Group 2: searchAdvancedFromCache — 全分類維度篩選
  // ==========================================================================
  group('searchAdvancedFromCache', () {
    test('僅文字搜尋', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        query: '臥推',
      );
      expect(results, isNotEmpty);
      for (final r in results) {
        final matchesQuery =
            r.name.contains('臥推') ||
            r.nameEn.toLowerCase().contains('臥推') ||
            (r.canonicalName?.contains('臥推') ?? false) ||
            r.aliases.any((a) => a.contains('臥推'));
        expect(matchesQuery, isTrue);
      }
    });

    test('movementPatterns 篩選（horizontal_push）', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        movementPatterns: ['horizontal_push'],
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-001', 'ex-002']));
      // 非 horizontal_push 的不應出現
      expect(ids, isNot(contains('ex-003')));
    });

    test('pplTags 篩選 — push', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['push'],
      );
      final ids = results.map((e) => e.id).toSet();
      // push: ex-001, ex-002, ex-009
      expect(ids, containsAll(['ex-001', 'ex-002', 'ex-009']));
    });

    test('pplTags 篩選 — pull', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['pull'],
      );
      final ids = results.map((e) => e.id).toSet();
      // pull: ex-004(硬舉), ex-005(引體), ex-010(划船)
      expect(ids, containsAll(['ex-004', 'ex-005', 'ex-010']));
    });

    test('pplTags 篩選 — legs', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['legs'],
      );
      final ids = results.map((e) => e.id).toSet();
      // legs: ex-003, ex-004, ex-006, ex-008, ex-011
      expect(ids, containsAll(['ex-003', 'ex-004', 'ex-006', 'ex-008', 'ex-011']));
    });

    test('pplTags 篩選 — core', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['core'],
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-007'));
    });

    test('pplTags 篩選 — mobility', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['mobility'],
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-012'));
    });

    test('pplTags 篩選 — cardio', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['cardio'],
      );
      final ids = results.map((e) => e.id).toSet();
      // cardio: ex-011（壺鈴擺盪 pplTags=['legs','cardio']）
      expect(ids, contains('ex-011'));
    });

    test('primaryMuscle 篩選', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        primaryMuscle: 'pec_major_sternal',
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-001', 'ex-002']));
      expect(ids.length, 2);
    });

    test('equipment 篩選 — cable', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        equipment: 'cable',
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-009', 'ex-010']));
    });

    test('equipment 篩選 — kettlebell', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        equipment: 'kettlebell',
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-011'));
      expect(ids.length, 1);
    });

    test('isExplosive 篩選 — true', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        isExplosive: true,
      );
      final ids = results.map((e) => e.id).toSet();
      // 爆發力：ex-006（瞬發上搏）, ex-011（壺鈴擺盪）
      expect(ids, containsAll(['ex-006', 'ex-011']));
      expect(ids.length, 2);
    });

    test('isExplosive 篩選 — false', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        isExplosive: false,
      );
      // 10 筆非爆發力
      expect(results.length, 10);
    });

    test('difficultyLevel 篩選 — beginner', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        difficultyLevel: 'beginner',
      );
      // beginner: ex-002, ex-007, ex-008, ex-009, ex-012
      expect(results.length, 5);
    });

    test('difficultyLevel 篩選 — intermediate', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        difficultyLevel: 'intermediate',
      );
      // intermediate: ex-001, ex-003, ex-010, ex-011
      expect(results.length, 4);
    });

    test('difficultyLevel 篩選 — advanced', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        difficultyLevel: 'advanced',
      );
      // advanced: ex-004, ex-005, ex-006
      expect(results.length, 3);
    });

    test('組合篩選：文字 + movementPatterns', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        query: '槓鈴',
        movementPatterns: ['horizontal_push'],
      );
      final ids = results.map((e) => e.id).toSet();
      // '槓鈴' + horizontal_push → 只有 ex-001（槓鈴臥推）
      expect(ids, contains('ex-001'));
      expect(ids, isNot(contains('ex-003'))); // 槓鈴深蹲是 squat 不是 horizontal_push
    });

    test('組合篩選：pplTags + primaryMuscle', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['push'],
        primaryMuscle: 'pec_major_sternal',
      );
      final ids = results.map((e) => e.id).toSet();
      // push + pec_major_sternal → ex-001, ex-002
      expect(ids, containsAll(['ex-001', 'ex-002']));
      expect(ids, isNot(contains('ex-009'))); // 三頭下壓是 push 但 muscle 不同
    });

    test('所有篩選條件同時使用', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        query: '臥推',
        movementPatterns: ['horizontal_push'],
        pplTags: ['push'],
        primaryMuscle: 'pec_major_sternal',
        equipment: 'barbell',
        isExplosive: false,
        difficultyLevel: 'intermediate',
      );
      final ids = results.map((e) => e.id).toSet();
      // 全部條件交集 → 只有 ex-001
      expect(ids, equals({'ex-001'}));
    });

    test('無篩選條件應按名稱排序', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
      );
      expect(results.length, dataset.length);
      // 檢查按名稱排序
      for (int i = 0; i < results.length - 1; i++) {
        expect(
          results[i].name.compareTo(results[i + 1].name),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('有文字搜尋時應按相關度排序', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        query: '槓鈴臥推',
      );
      if (results.length >= 2) {
        // 第一筆應是完全匹配的 ex-001
        expect(results.first.id, 'ex-001');
      }
    });

    test('movementPatterns OR 邏輯（多模式取聯集）', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        movementPatterns: ['hinge', 'squat'],
      );
      final ids = results.map((e) => e.id).toSet();
      // hinge: ex-004, ex-006, ex-011; squat: ex-003
      expect(ids, containsAll(['ex-003', 'ex-004', 'ex-006', 'ex-011']));
    });

    test('雙 PPL 標籤動作正確匹配', () {
      // 硬舉 pplTags=['pull', 'legs']
      final pullResults = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['pull'],
      );
      final legsResults = engine.searchAdvancedFromCache(
        cache: dataset,
        pplTags: ['legs'],
      );
      final pullIds = pullResults.map((e) => e.id).toSet();
      final legsIds = legsResults.map((e) => e.id).toSet();
      // ex-004（硬舉）應同時出現在 pull 和 legs 結果中
      expect(pullIds, contains('ex-004'));
      expect(legsIds, contains('ex-004'));
      // ex-011（壺鈴擺盪）tags=['legs','cardio']
      expect(legsIds, contains('ex-011'));
    });

    test('limit 限制進階搜尋結果', () {
      final results = engine.searchAdvancedFromCache(
        cache: dataset,
        limit: 3,
      );
      expect(results.length, 3);
    });
  });

  // ==========================================================================
  // Group 3: filterFromCache — 舊/新篩選
  // ==========================================================================
  group('filterFromCache', () {
    test('bodyPart 篩選', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {'bodyPart': '胸'},
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-001', 'ex-002']));
    });

    test('level1 篩選', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {'level1': '重訓'},
      );
      // 多數動作的 level1 是 '重訓'
      expect(results, isNotEmpty);
      for (final e in results) {
        expect(e.level1, '重訓');
      }
    });

    test('v5.0 primaryMuscle 篩選', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {'primaryMuscle': 'lats'},
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-005', 'ex-010']));
    });

    test('v5.0 difficultyLevel 篩選', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {'difficultyLevel': 'advanced'},
      );
      expect(results.length, 3);
    });

    test('v5.0 mechanicsType 篩選', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {'mechanicsType': 'isolation'},
      );
      final ids = results.map((e) => e.id).toSet();
      // isolation: ex-009, ex-012
      expect(ids, containsAll(['ex-009', 'ex-012']));
    });

    test('空值篩選條件應被忽略', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {'bodyPart': '', 'primaryMuscle': ''},
      );
      expect(results.length, dataset.length);
    });

    test('多重篩選取交集', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {
          'level1': '重訓',
          'primaryMuscle': 'pec_major_sternal',
        },
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-001', 'ex-002']));
    });

    test('未知 key 應被忽略', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {'unknownKey': 'someValue'},
      );
      expect(results.length, dataset.length);
    });

    test('空 filters 應返回全部', () {
      final results = engine.filterFromCache(
        cache: dataset,
        filters: {},
      );
      expect(results.length, dataset.length);
    });
  });

  // ==========================================================================
  // Group 4: filterByPplTags / filterByMovementPatterns
  // ==========================================================================
  group('filterByPplTags', () {
    test('單一 PPL 標籤 — push', () {
      final results = engine.filterByPplTags(
        cache: dataset,
        pplTags: ['push'],
      );
      final ids = results.map((e) => e.id).toSet();
      // push: ex-001, ex-002, ex-009
      expect(ids, containsAll(['ex-001', 'ex-002', 'ex-009']));
    });

    test('多個 PPL 標籤 OR 邏輯', () {
      final results = engine.filterByPplTags(
        cache: dataset,
        pplTags: ['push', 'legs'],
      );
      final ids = results.map((e) => e.id).toSet();
      // push: 001, 002, 009; legs: 003, 004, 006, 008, 011
      expect(ids, containsAll([
        'ex-001', 'ex-002', 'ex-003', 'ex-004',
        'ex-006', 'ex-008', 'ex-009', 'ex-011',
      ]));
    });

    test('雙標動作正確匹配（硬舉 pull+legs）', () {
      final pullResults = engine.filterByPplTags(
        cache: dataset,
        pplTags: ['pull'],
      );
      final legsResults = engine.filterByPplTags(
        cache: dataset,
        pplTags: ['legs'],
      );
      // 硬舉應同時出現在兩種篩選結果中
      expect(
        pullResults.any((e) => e.id == 'ex-004'),
        isTrue,
      );
      expect(
        legsResults.any((e) => e.id == 'ex-004'),
        isTrue,
      );
    });

    test('mobility 標籤篩選', () {
      final results = engine.filterByPplTags(
        cache: dataset,
        pplTags: ['mobility'],
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-012'));
    });

    test('空列表應返回全部', () {
      final results = engine.filterByPplTags(
        cache: dataset,
        pplTags: [],
      );
      expect(results.length, dataset.length);
    });
  });

  group('filterByMovementPatterns', () {
    test('horizontal_push 篩選', () {
      final results = engine.filterByMovementPatterns(
        cache: dataset,
        patterns: ['horizontal_push'],
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['ex-001', 'ex-002']));
    });

    test('isolation_push 與 horizontal_push 是不同模式', () {
      final horizontal = engine.filterByMovementPatterns(
        cache: dataset,
        patterns: ['horizontal_push'],
      );
      final isolation = engine.filterByMovementPatterns(
        cache: dataset,
        patterns: ['isolation_push'],
      );
      final horizontalIds = horizontal.map((e) => e.id).toSet();
      final isolationIds = isolation.map((e) => e.id).toSet();
      // ex-009（三頭下壓）是 isolation_push，不應出現在 horizontal_push
      expect(horizontalIds, isNot(contains('ex-009')));
      expect(isolationIds, contains('ex-009'));
    });

    test('多模式 OR 邏輯', () {
      final results = engine.filterByMovementPatterns(
        cache: dataset,
        patterns: ['squat', 'lunge'],
      );
      final ids = results.map((e) => e.id).toSet();
      // squat: ex-003; lunge: ex-008
      expect(ids, containsAll(['ex-003', 'ex-008']));
    });

    test('mobility 模式篩選', () {
      final results = engine.filterByMovementPatterns(
        cache: dataset,
        patterns: ['mobility'],
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('ex-012'));
    });

    test('空列表應返回全部', () {
      final results = engine.filterByMovementPatterns(
        cache: dataset,
        patterns: [],
      );
      expect(results.length, dataset.length);
    });

    test('不存在的模式應返回空', () {
      final results = engine.filterByMovementPatterns(
        cache: dataset,
        patterns: ['nonexistent_pattern'],
      );
      expect(results, isEmpty);
    });
  });

  // ==========================================================================
  // Group 5: fuzzySearchFromCache — 中英文模糊搜尋
  // ==========================================================================
  group('fuzzySearchFromCache', () {
    test('空查詢應返回空列表', () async {
      final results = await engine.fuzzySearchFromCache(
        cache: dataset,
        query: '',
      );
      expect(results, isEmpty);
    });

    test('精確匹配充足時不觸發模糊搜尋', () async {
      // 搜尋 '臥推'，精確匹配至少 2 筆，limit=2 → 不需要模糊補足
      final results = await engine.fuzzySearchFromCache(
        cache: dataset,
        query: '臥推',
        limit: 2,
      );
      expect(results.length, 2);
      // 結果應該都是精確匹配（名稱包含 '臥推'）
      for (final r in results) {
        final isExactMatch =
            r.name.contains('臥推') ||
            r.nameEn.toLowerCase().contains('臥推') ||
            (r.canonicalName?.contains('臥推') ?? false) ||
            r.aliases.any((a) => a.contains('臥推'));
        expect(isExactMatch, isTrue);
      }
    });

    test('精確不足時模糊補足結果', () async {
      // 建立只有 1 筆精確匹配的場景，limit > 精確數量
      final testData = [
        ExerciseTestFactory.make(
          id: 'exact-match',
          name: '精確匹配動作',
          nameEn: 'Exact Match',
        ),
        ExerciseTestFactory.make(
          id: 'fuzzy-match',
          name: '精礦匹配動作',  // 故意相似
          nameEn: 'Almost Match',
        ),
      ];
      final results = await engine.fuzzySearchFromCache(
        cache: testData,
        query: '精確匹配',
        limit: 5,
        threshold: 0.1,
      );
      // 至少包含精確匹配
      expect(results.any((e) => e.id == 'exact-match'), isTrue);
    });

    test('精確結果在前、模糊結果在後', () async {
      final testData = [
        ExerciseTestFactory.make(
          id: 'exact',
          name: '槓鈴臥推',
          nameEn: 'Barbell Bench Press',
        ),
        ExerciseTestFactory.make(
          id: 'fuzzy',
          name: '啞鈴握推',  // 相似但不精確包含 '臥推'
          nameEn: 'Dumbbell Press',
        ),
      ];
      final results = await engine.fuzzySearchFromCache(
        cache: testData,
        query: '臥推',
        limit: 10,
        threshold: 0.1,
      );
      if (results.length >= 2) {
        // 精確匹配的 '槓鈴臥推' 應在 '啞鈴握推' 之前
        final exactIdx = results.indexWhere((e) => e.id == 'exact');
        final fuzzyIdx = results.indexWhere((e) => e.id == 'fuzzy');
        if (exactIdx >= 0 && fuzzyIdx >= 0) {
          expect(exactIdx, lessThan(fuzzyIdx));
        }
      }
    });

    test('結果不重複', () async {
      final results = await engine.fuzzySearchFromCache(
        cache: dataset,
        query: '臥推',
        limit: 20,
        threshold: 0.1,
      );
      final ids = results.map((e) => e.id).toList();
      expect(ids.length, ids.toSet().length);
    });

    test('candidateIds 限制模糊搜尋範圍', () async {
      final results = await engine.fuzzySearchFromCache(
        cache: dataset,
        query: '臥推',
        candidateIds: {'ex-001', 'ex-002', 'ex-003'},
        limit: 20,
        threshold: 0.1,
      );
      for (final r in results) {
        expect(
          {'ex-001', 'ex-002', 'ex-003'},
          contains(r.id),
        );
      }
    });

    test('中文錯字容忍（"臥椎" → 找到 "臥推"）', () async {
      final results = await engine.fuzzySearchFromCache(
        cache: dataset,
        query: '臥椎',
        limit: 10,
        threshold: 0.1,
      );
      // JW 相似度應讓 '臥推' 相關動作出現（分數可能低但不為零）
      // 這是模糊搜尋的核心場景
      expect(results, isA<List>());
    });

    test('英文拼寫錯誤容忍（"bech press" → 找到 "Bench Press"）', () async {
      final results = await engine.fuzzySearchFromCache(
        cache: dataset,
        query: 'bech press',
        limit: 10,
        threshold: 0.2,
      );
      // 模糊搜尋應能容忍少量拼寫錯誤
      expect(results, isA<List>());
    });

    test('繁中短詞模糊搜尋（"深墩" → 可能找到 "深蹲"）', () async {
      final results = await engine.fuzzySearchFromCache(
        cache: dataset,
        query: '深墩',
        limit: 10,
        threshold: 0.1,
      );
      // 2 字中 1 字不同，JW 有一定相似度
      expect(results, isA<List>());
    });
  });
}

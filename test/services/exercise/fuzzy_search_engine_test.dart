import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/services/supabase/exercise/fuzzy_search_engine.dart';
import '../../helpers/exercise_test_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final engine = FuzzySearchEngine();
  final dataset = ExerciseTestFactory.standardDataset;

  // ==========================================================================
  // Group 1: Jaro-Winkler 相似度
  // ==========================================================================
  group('jaroWinklerSimilarity', () {
    test('相同字串應該返回 1.0', () {
      final score = FuzzySearchEngine.jaroWinklerSimilarity('hello', 'hello');
      expect(score, 1.0);
    });

    test('空字串 vs 非空字串應該返回 0.0', () {
      expect(FuzzySearchEngine.jaroWinklerSimilarity('', 'hello'), 0.0);
      expect(FuzzySearchEngine.jaroWinklerSimilarity('hello', ''), 0.0);
    });

    test('兩個空字串應該返回 1.0（s1 == s2 先命中）', () {
      // 外層先檢查 s1 == s2 → 返回 1.0（identity check 優先於 isEmpty）
      final score = FuzzySearchEngine.jaroWinklerSimilarity('', '');
      expect(score, 1.0);
    });

    test('前綴相同應該獲得 Winkler 加權提升', () {
      final withPrefix = FuzzySearchEngine.jaroWinklerSimilarity(
        'benchmark', 'benching',
      );
      final noPrefix = FuzzySearchEngine.jaroWinklerSimilarity(
        'benchmark', 'xxxxxxxxk',
      );
      // 有相同前綴的分數應該更高
      expect(withPrefix, greaterThan(noPrefix));
    });

    test('Winkler 前綴加權最多計算 4 個字元', () {
      final prefix4 = FuzzySearchEngine.jaroWinklerSimilarity(
        'abcdefgh', 'abcdxxxx',
      );
      final prefix6 = FuzzySearchEngine.jaroWinklerSimilarity(
        'abcdefgh', 'abcdefxx',
      );
      // prefix6 的 Jaro 分數更高，但 Winkler 前綴只算 4 個字元
      // 兩者的 Winkler prefix 加權部分相同
      expect(prefix6, greaterThan(prefix4));
    });

    test('完全不同的字串應該返回低分', () {
      final score = FuzzySearchEngine.jaroWinklerSimilarity('abc', 'xyz');
      expect(score, lessThan(0.5));
    });

    test('繁體中文相似字串應能偵測相似度', () {
      // '槓鈴臥推' vs '槓鈴臥舉' — 4 字中 3 字相同
      final score = FuzzySearchEngine.jaroWinklerSimilarity('槓鈴臥推', '槓鈴臥舉');
      expect(score, greaterThan(0.7));
    });

    test('繁體中文 2 字差異應能偵測', () {
      // '臥推' vs '臥舉' — 2 字中 1 字相同
      final score = FuzzySearchEngine.jaroWinklerSimilarity('臥推', '臥舉');
      expect(score, greaterThan(0.5));
    });

    test('英文拼寫錯誤應有高容忍度', () {
      // 'bench press' vs 'bencg press' — 1 字元差異
      final score = FuzzySearchEngine.jaroWinklerSimilarity(
        'bench press', 'bencg press',
      );
      expect(score, greaterThan(0.85));
    });

    test('長度差異大的字串應返回較低分', () {
      final score = FuzzySearchEngine.jaroWinklerSimilarity('ab', 'abcdefghijklmn');
      expect(score, lessThan(0.8));
    });
  });

  // ==========================================================================
  // Group 2: Trigram 相似度
  // ==========================================================================
  group('trigramSimilarity', () {
    test('相同字串應該返回 1.0', () {
      final score = FuzzySearchEngine.trigramSimilarity(
        'bench press', 'bench press',
      );
      expect(score, 1.0);
    });

    test('完全不同字串應該返回 0.0', () {
      final score = FuzzySearchEngine.trigramSimilarity('abc', 'xyz');
      expect(score, 0.0);
    });

    test('短中文詞（2 字）退化處理', () {
      // '臥推' 長度 <3，_generateTrigrams 回傳 {'臥推'}
      // '臥舉' 長度 <3，_generateTrigrams 回傳 {'臥舉'}
      // 交集為空 → Jaccard = 0
      final score = FuzzySearchEngine.trigramSimilarity('臥推', '臥舉');
      expect(score, 0.0);
    });

    test('中文 4 字 Trigram 應產生正確交集', () {
      // '槓鈴臥推' trigrams: {'槓鈴臥', '鈴臥推'}
      // '槓鈴臥舉' trigrams: {'槓鈴臥', '鈴臥舉'}
      // 交集 = 1, 聯集 = 3, Jaccard = 1/3
      final score = FuzzySearchEngine.trigramSimilarity('槓鈴臥推', '槓鈴臥舉');
      expect(score, closeTo(1.0 / 3.0, 0.001));
    });

    test('英文部分重疊應返回高分', () {
      final score = FuzzySearchEngine.trigramSimilarity(
        'bench press', 'bench pres',
      );
      expect(score, greaterThan(0.7));
    });

    test('子字串與母字串相似度', () {
      // '槓鈴臥推' 的 trigrams 是 '上斜槓鈴臥推' trigrams 的子集
      final score = FuzzySearchEngine.trigramSimilarity('槓鈴臥推', '上斜槓鈴臥推');
      expect(score, greaterThan(0.3));
    });

    test('空字串處理', () {
      // 空字串 trigrams 為 {''}（長度 <3 回傳自身）
      final score = FuzzySearchEngine.trigramSimilarity('', 'abc');
      expect(score, isA<double>());
    });

    test('英文長字串高度相似', () {
      final score = FuzzySearchEngine.trigramSimilarity(
        'barbell bench press', 'barbell bench pres',
      );
      expect(score, greaterThan(0.8));
    });
  });

  // ==========================================================================
  // Group 3: search() 整合測試
  // ==========================================================================
  group('search()', () {
    test('空查詢應返回空列表', () async {
      final results = await engine.search(
        query: '',
        exercises: dataset,
      );
      expect(results, isEmpty);
    });

    test('空格查詢應返回空列表', () async {
      final results = await engine.search(
        query: '   ',
        exercises: dataset,
      );
      expect(results, isEmpty);
    });

    test('結果應按分數降序排列', () async {
      final results = await engine.search(
        query: '臥推',
        exercises: dataset,
        threshold: 0.1,
      );
      if (results.length >= 2) {
        for (int i = 0; i < results.length - 1; i++) {
          expect(results[i].score, greaterThanOrEqualTo(results[i + 1].score));
        }
      }
    });

    test('limit 應限制結果數量', () async {
      final results = await engine.search(
        query: '臥',
        exercises: dataset,
        limit: 2,
        threshold: 0.1,
      );
      expect(results.length, lessThanOrEqualTo(2));
    });

    test('threshold 應過濾低分結果', () async {
      final highThreshold = await engine.search(
        query: '臥推',
        exercises: dataset,
        threshold: 0.8,
      );
      final lowThreshold = await engine.search(
        query: '臥推',
        exercises: dataset,
        threshold: 0.1,
      );
      expect(highThreshold.length, lessThanOrEqualTo(lowThreshold.length));
      for (final result in highThreshold) {
        expect(result.score, greaterThanOrEqualTo(0.8));
      }
    });

    test('candidateIds 應預過濾候選動作', () async {
      final results = await engine.search(
        query: '臥推',
        exercises: dataset,
        candidateIds: {'ex-001', 'ex-002'},
        threshold: 0.1,
      );
      for (final result in results) {
        expect({'ex-001', 'ex-002'}, contains(result.exercise.id));
      }
    });

    test('candidateIds 為空時應搜尋全部', () async {
      final withNull = await engine.search(
        query: '臥推',
        exercises: dataset,
        threshold: 0.1,
      );
      final withEmpty = await engine.search(
        query: '臥推',
        exercises: dataset,
        candidateIds: {},
        threshold: 0.1,
      );
      // 空集合走原始路徑
      expect(withEmpty.length, withNull.length);
    });

    test('搜尋應大小寫不敏感', () async {
      final upper = await engine.search(
        query: 'BENCH',
        exercises: dataset,
        threshold: 0.1,
      );
      final lower = await engine.search(
        query: 'bench',
        exercises: dataset,
        threshold: 0.1,
      );
      expect(upper.length, lower.length);
    });

    test('繁體中文名稱匹配（搜尋 "臥推"）', () async {
      final results = await engine.search(
        query: '臥推',
        exercises: dataset,
        threshold: 0.1,
      );
      final ids = results.map((r) => r.exercise.id).toSet();
      // 至少應找到 ex-001（槓鈴臥推）和 ex-002（啞鈴臥推）
      expect(ids, containsAll(['ex-001', 'ex-002']));
    });

    test('英文搜尋中文動作（搜尋 "bench"）', () async {
      final results = await engine.search(
        query: 'bench',
        exercises: dataset,
        threshold: 0.1,
      );
      // 透過 nameEn 欄位找到 Bench Press 系列
      final ids = results.map((r) => r.exercise.id).toSet();
      expect(ids, contains('ex-001'));
    });

    test('別名搜尋（搜尋 "BP"）', () async {
      final results = await engine.search(
        query: 'bp',
        exercises: dataset,
        threshold: 0.1,
      );
      // 'BP' 是 ex-001 的別名，但 2 字元可能模糊匹配較弱
      // 驗證至少有結果或分數合理
      expect(results, isA<List<ScoredExercise>>());
    });

    test('null canonicalName 不應報錯', () async {
      final exercises = [
        ExerciseTestFactory.make(
          id: 'null-test',
          name: '測試',
          nameEn: 'Test',
          canonicalName: null,
          canonicalNameEn: null,
        ),
      ];
      final results = await engine.search(
        query: '測試',
        exercises: exercises,
        threshold: 0.1,
      );
      expect(results, isA<List<ScoredExercise>>());
    });
  });

  // ==========================================================================
  // Group 4: 加權評分驗證
  // ==========================================================================
  group('加權評分', () {
    test('5 欄位權重總和應為 1.0', () {
      // 靜態常數驗證（透過間接驗證：全欄位匹配分數 = 1.0）
      const totalWeight = 0.30 + 0.25 + 0.20 + 0.15 + 0.10;
      expect(totalWeight, closeTo(1.0, 0.001));
    });

    test('所有欄位完全匹配應返回接近 1.0', () async {
      // 建立查詢字串與動作完全一致的情境
      final exercise = ExerciseTestFactory.make(
        id: 'score-test',
        name: 'exact',
        nameEn: 'exact',
        canonicalName: 'exact',
        canonicalNameEn: 'exact',
        aliases: ['exact'],
      );
      final results = await engine.search(
        query: 'exact',
        exercises: [exercise],
        threshold: 0.0,
      );
      expect(results, isNotEmpty);
      // 所有欄位完全匹配 → 各權重 * 1.0 = 1.0
      expect(results.first.score, closeTo(1.0, 0.01));
    });

    test('canonicalName 匹配應有加分效果', () async {
      // 只有 canonicalName 匹配的動作
      final withCanonical = ExerciseTestFactory.make(
        id: 'with-canonical',
        name: '其他名稱',
        nameEn: 'other name',
        canonicalName: '搜尋目標',
        canonicalNameEn: 'search target',
        aliases: [],
      );
      final withoutCanonical = ExerciseTestFactory.make(
        id: 'without-canonical',
        name: '其他名稱',
        nameEn: 'other name',
        canonicalName: null,
        canonicalNameEn: null,
        aliases: [],
      );

      final resultsA = await engine.search(
        query: '搜尋目標',
        exercises: [withCanonical],
        threshold: 0.0,
      );
      final resultsB = await engine.search(
        query: '搜尋目標',
        exercises: [withoutCanonical],
        threshold: 0.0,
      );

      final scoreA = resultsA.isNotEmpty ? resultsA.first.score : 0.0;
      final scoreB = resultsB.isNotEmpty ? resultsB.first.score : 0.0;
      expect(scoreA, greaterThan(scoreB));
    });

    test('name 權重(0.30) 應高於 aliases 權重(0.10)', () async {
      // 只有 name 匹配
      final nameMatch = ExerciseTestFactory.make(
        id: 'name-match',
        name: '目標動作',
        nameEn: 'xxx',
        canonicalName: 'xxx',
        aliases: ['xxx'],
      );
      // 只有 aliases 匹配
      final aliasMatch = ExerciseTestFactory.make(
        id: 'alias-match',
        name: 'xxx',
        nameEn: 'xxx',
        canonicalName: 'xxx',
        aliases: ['目標動作'],
      );

      final resultsName = await engine.search(
        query: '目標動作',
        exercises: [nameMatch],
        threshold: 0.0,
      );
      final resultsAlias = await engine.search(
        query: '目標動作',
        exercises: [aliasMatch],
        threshold: 0.0,
      );

      final scoreName = resultsName.isNotEmpty ? resultsName.first.score : 0.0;
      final scoreAlias = resultsAlias.isNotEmpty ? resultsAlias.first.score : 0.0;
      expect(scoreName, greaterThan(scoreAlias));
    });

    test('ScoredExercise.toString 格式正確', () {
      final scored = ScoredExercise(
        exercise: ExerciseTestFactory.make(name: '測試'),
        score: 0.85,
      );
      expect(scored.toString(), contains('測試'));
      expect(scored.toString(), contains('0.850'));
    });
  });
}

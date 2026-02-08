import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:strengthwise/models/tracking_mode.dart';
import 'package:strengthwise/services/cache/exercise_local_cache_service.dart';
import '../../helpers/exercise_test_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseLocalCacheService service;
  late String tempDir;

  setUpAll(() async {
    // 建立臨時目錄供 Hive 使用
    tempDir = '${Directory.systemTemp.path}/hive_test_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(tempDir).create(recursive: true);
    Hive.init(tempDir);
  });

  setUp(() async {
    service = ExerciseLocalCacheService();
    await service.initialize();
  });

  tearDown(() async {
    await service.close();
    // 清理 Hive boxes
    try {
      if (await Hive.boxExists('exercises_cache')) {
        await Hive.deleteBoxFromDisk('exercises_cache');
      }
      if (await Hive.boxExists('exercises_search_index')) {
        await Hive.deleteBoxFromDisk('exercises_search_index');
      }
    } catch (_) {
      // 忽略清理錯誤
    }
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      await Directory(tempDir).delete(recursive: true);
    } catch (_) {
      // 忽略清理錯誤
    }
  });

  // ==========================================================================
  // Group 1: 初始化
  // ==========================================================================
  group('初始化', () {
    test('正常初始化成功', () async {
      // setUp 已經初始化，驗證 service 可用
      expect(service.getCacheInfo()['initialized'], isTrue);
    });

    test('重複初始化不報錯', () async {
      // 第二次初始化（setUp 已經做過一次）
      await service.initialize();
      expect(service.getCacheInfo()['initialized'], isTrue);
    });
  });

  // ==========================================================================
  // Group 2: 保存與載入 Round-trip
  // ==========================================================================
  group('保存與載入 Round-trip', () {
    test('基本欄位完整保留（id, name, nameEn）', () async {
      final exercises = [
        ExerciseTestFactory.make(
          id: 'round-trip-1',
          name: '測試動作',
          nameEn: 'Test Exercise',
        ),
      ];
      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'round-trip-1');
      expect(loaded.first.name, '測試動作');
      expect(loaded.first.nameEn, 'Test Exercise');
    });

    test('v5.0 全部新欄位完整保留', () async {
      final exercises = [
        ExerciseTestFactory.make(
          id: 'v5-fields',
          name: '槓鈴臥推',
          nameEn: 'Barbell Bench Press',
          canonicalName: '平板槓鈴臥推',
          canonicalNameEn: 'Flat Barbell Bench Press',
          movementPatterns: ['horizontal_push'],
          pplTags: ['push'],
          primaryMuscle: 'pec_major_sternal',
          synergistMuscles: ['anterior_deltoid', 'triceps'],
          mechanicsType: 'compound',
          isUnilateral: false,
          difficultyLevel: 'intermediate',
          isExplosive: false,
          aliases: ['仰臥推舉', 'BP', 'Bench Press'],
        ),
      ];
      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      final e = loaded.first;
      expect(e.canonicalName, '平板槓鈴臥推');
      expect(e.canonicalNameEn, 'Flat Barbell Bench Press');
      expect(e.movementPatterns, ['horizontal_push']);
      expect(e.pplTags, ['push']);
      expect(e.primaryMuscle, 'pec_major_sternal');
      expect(e.synergistMuscles, ['anterior_deltoid', 'triceps']);
      expect(e.mechanicsType, 'compound');
      expect(e.isUnilateral, false);
      expect(e.difficultyLevel, 'intermediate');
      expect(e.isExplosive, false);
      expect(e.aliases, ['仰臥推舉', 'BP', 'Bench Press']);
    });

    test('trackingMode 正確 round-trip（7 種模式）', () async {
      final modes = [
        TrackingMode.weightReps,
        TrackingMode.repsOnly,
        TrackingMode.repsTime,
        TrackingMode.weightTime,
        TrackingMode.distanceTime,
        TrackingMode.timeOnly,
        TrackingMode.calories,
      ];

      final exercises = modes.asMap().entries.map((entry) {
        return ExerciseTestFactory.make(
          id: 'mode-${entry.key}',
          trackingMode: entry.value,
        );
      }).toList();

      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      expect(loaded.length, modes.length);
      for (int i = 0; i < modes.length; i++) {
        final loadedExercise = loaded.firstWhere((e) => e.id == 'mode-$i');
        expect(loadedExercise.trackingMode, modes[i]);
      }
    });

    test('列表欄位完整 round-trip', () async {
      final exercises = [
        ExerciseTestFactory.make(
          id: 'list-fields',
          movementPatterns: ['horizontal_push', 'isolation_push'],
          pplTags: ['push', 'core'],
          synergistMuscles: ['anterior_deltoid', 'triceps', 'abs'],
          aliases: ['別名一', '別名二', 'Alias Three'],
        ),
      ];
      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      final e = loaded.first;
      expect(e.movementPatterns, ['horizontal_push', 'isolation_push']);
      expect(e.pplTags, ['push', 'core']);
      expect(e.synergistMuscles, ['anterior_deltoid', 'triceps', 'abs']);
      expect(e.aliases, ['別名一', '別名二', 'Alias Three']);
    });

    test('nullable 欄位正確保留（null 不變成空字串）', () async {
      final exercises = [
        ExerciseTestFactory.make(
          id: 'nullable-test',
          canonicalName: null,
          canonicalNameEn: null,
          primaryMuscle: null,
        ),
      ];
      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      final e = loaded.first;
      // ExerciseMapper.fromSupabase 對 null 值返回 null
      expect(e.canonicalName, isNull);
      expect(e.canonicalNameEn, isNull);
      expect(e.primaryMuscle, isNull);
    });

    test('bool 欄位正確 round-trip', () async {
      final exercises = [
        ExerciseTestFactory.make(
          id: 'bool-true',
          isUnilateral: true,
          isExplosive: true,
        ),
        ExerciseTestFactory.make(
          id: 'bool-false',
          isUnilateral: false,
          isExplosive: false,
        ),
      ];
      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      final trueExercise = loaded.firstWhere((e) => e.id == 'bool-true');
      expect(trueExercise.isUnilateral, true);
      expect(trueExercise.isExplosive, true);

      final falseExercise = loaded.firstWhere((e) => e.id == 'bool-false');
      expect(falseExercise.isUnilateral, false);
      expect(falseExercise.isExplosive, false);
    });

    test('大量動作保存載入（100 筆）', () async {
      final exercises = List.generate(100, (i) {
        return ExerciseTestFactory.make(
          id: 'bulk-$i',
          name: '批量動作 $i',
          nameEn: 'Bulk Exercise $i',
        );
      });
      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      expect(loaded.length, 100);
    });

    test('空列表保存載入', () async {
      await service.saveExercises([]);
      // 空列表保存後，loadExercises 應返回空列表
      final loaded = await service.loadExercises();
      expect(loaded, isEmpty);
    });

    test('版本號正確更新', () async {
      await service.saveExercises([
        ExerciseTestFactory.make(id: 'version-test'),
      ]);
      final info = service.getCacheInfo();
      expect(info['version'], ExerciseLocalCacheService.currentCacheVersion);
    });

    test('繁體中文字元在 Hive 序列化後正確保留', () async {
      final exercises = [
        ExerciseTestFactory.make(
          id: 'chinese-test',
          name: '槓鈴臥推',
          nameEn: 'Barbell Bench Press',
          canonicalName: '平板槓鈴臥推',
          aliases: ['仰臥推舉', '胸推'],
          bodyParts: ['胸'],
          bodyPart: '胸',
          level1: '重訓',
          level2: '胸',
        ),
      ];
      await service.saveExercises(exercises);
      final loaded = await service.loadExercises();

      final e = loaded.first;
      expect(e.name, '槓鈴臥推');
      expect(e.canonicalName, '平板槓鈴臥推');
      expect(e.aliases, ['仰臥推舉', '胸推']);
      expect(e.bodyPart, '胸');
    });
  });

  // ==========================================================================
  // Group 3: isCacheValid / clearCache / getCacheInfo
  // ==========================================================================
  group('快取狀態管理', () {
    test('有效快取應返回 true', () async {
      await service.saveExercises([
        ExerciseTestFactory.make(id: 'valid-1'),
      ]);
      expect(service.isCacheValid(), isTrue);
    });

    test('無資料時應返回 false', () {
      // 剛初始化的 service，沒有保存過資料
      expect(service.isCacheValid(), isFalse);
    });

    test('清除後應返回 false', () async {
      await service.saveExercises([
        ExerciseTestFactory.make(id: 'clear-1'),
      ]);
      expect(service.isCacheValid(), isTrue);

      await service.clearCache();
      expect(service.isCacheValid(), isFalse);
    });

    test('清除後載入應返回空列表', () async {
      await service.saveExercises([
        ExerciseTestFactory.make(id: 'clear-load-1'),
      ]);
      await service.clearCache();

      final loaded = await service.loadExercises();
      expect(loaded, isEmpty);
    });

    test('getCacheInfo 返回正確計數', () async {
      final exercises = [
        ExerciseTestFactory.make(id: 'info-1'),
        ExerciseTestFactory.make(id: 'info-2'),
        ExerciseTestFactory.make(id: 'info-3'),
      ];
      await service.saveExercises(exercises);

      final info = service.getCacheInfo();
      expect(info['initialized'], isTrue);
      expect(info['isValid'], isTrue);
      expect(info['exerciseCount'], 3);
      expect(info['version'], ExerciseLocalCacheService.currentCacheVersion);
      expect(info['lastUpdate'], isNotNull);
    });

    test('未保存時 getCacheInfo exerciseCount 為 0', () {
      final info = service.getCacheInfo();
      expect(info['exerciseCount'], 0);
    });
  });

  // ==========================================================================
  // Group 4: Trigram 索引建構
  // ==========================================================================
  group('Trigram 索引', () {
    test('保存後搜尋索引自動建構', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);

      // 等待背景索引建構完成
      await Future.delayed(const Duration(seconds: 3));

      expect(service.isSearchIndexValid(), isTrue);
    });

    test('索引版本與快取版本一致', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      final info = service.getSearchIndexInfo();
      expect(info['version'], ExerciseLocalCacheService.currentCacheVersion);
    });

    test('getTrigramIndex 返回正確結構', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      final index = service.getTrigramIndex();
      expect(index, isNotNull);
      expect(index, isA<Map<String, List<String>>>());
      // 應有 trigram 鍵
      expect(index!.isNotEmpty, isTrue);
      // 每個值應是動作 ID 列表
      for (final entry in index.entries) {
        expect(entry.key.length, lessThanOrEqualTo(3));
        expect(entry.value, isA<List<String>>());
      }
    });

    test('索引包含中文名稱的 trigrams', () async {
      await service.saveExercises([
        ExerciseTestFactory.make(
          id: 'trigram-zh',
          name: '槓鈴臥推',
          nameEn: 'Bench Press',
        ),
      ]);
      await Future.delayed(const Duration(seconds: 3));

      final index = service.getTrigramIndex();
      expect(index, isNotNull);
      // '槓鈴臥推' 應產生 trigrams '槓鈴臥' 和 '鈴臥推'
      expect(index!.containsKey('槓鈴臥'), isTrue);
      expect(index.containsKey('鈴臥推'), isTrue);
      // 這些 trigram 應指向 'trigram-zh'
      expect(index['槓鈴臥'], contains('trigram-zh'));
      expect(index['鈴臥推'], contains('trigram-zh'));
    });

    test('索引包含英文名稱 + canonicalName + aliases', () async {
      await service.saveExercises([
        ExerciseTestFactory.make(
          id: 'trigram-all',
          name: '短名',
          nameEn: 'Barbell Bench Press',
          canonicalName: '平板槓鈴臥推',
          aliases: ['仰臥推舉'],
        ),
      ]);
      await Future.delayed(const Duration(seconds: 3));

      final index = service.getTrigramIndex();
      expect(index, isNotNull);
      // 英文 'bench' trigrams 應存在
      expect(index!.containsKey('bar'), isTrue);
      expect(index.containsKey('ben'), isTrue);
      // canonicalName trigrams
      expect(index.containsKey('平板槓'), isTrue);
      // alias trigrams
      expect(index.containsKey('仰臥推'), isTrue);
    });

    test('索引不重複 ID', () async {
      await service.saveExercises([
        ExerciseTestFactory.make(
          id: 'no-dup',
          name: '重複名',
          nameEn: '重複名', // 故意與 name 相同
          canonicalName: '重複名',
        ),
      ]);
      await Future.delayed(const Duration(seconds: 3));

      final index = service.getTrigramIndex();
      expect(index, isNotNull);
      // 即使多個欄位產生相同 trigram，ID 不應重複
      for (final ids in index!.values) {
        final idSet = ids.toSet();
        expect(ids.length, idSet.length);
      }
    });
  });

  // ==========================================================================
  // Group 5: filterCandidatesByTrigram
  // ==========================================================================
  group('filterCandidatesByTrigram', () {
    test('中文查詢過濾候選', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      final candidates = service.filterCandidatesByTrigram('槓鈴臥推');
      // 應找到含 '槓鈴臥推' trigrams 的動作
      expect(candidates, contains('ex-001'));
    });

    test('短查詢（<2 字元）返回空集合', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      final candidates = service.filterCandidatesByTrigram('臥');
      expect(candidates, isEmpty);
    });

    test('2 字元查詢退化為全字串匹配', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      // '臥推' 長度=2，_generateTrigrams 返回 ['臥推']
      final candidates = service.filterCandidatesByTrigram('臥推');
      // 索引中應有 '臥推' 這個 key（因為某些動作名稱包含此子字串）
      expect(candidates, isA<Set<String>>());
    });

    test('索引不存在時返回空集合', () async {
      // 不保存任何動作，索引不存在
      final candidates = service.filterCandidatesByTrigram('槓鈴臥推');
      expect(candidates, isEmpty);
    });

    test('minMatchCount 過濾低匹配候選', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      final lowThreshold = service.filterCandidatesByTrigram(
        '槓鈴臥推',
        minMatchCount: 1,
      );
      final highThreshold = service.filterCandidatesByTrigram(
        '槓鈴臥推',
        minMatchCount: 2,
      );
      // 高閾值結果應 <= 低閾值結果
      expect(highThreshold.length, lessThanOrEqualTo(lowThreshold.length));
    });

    test('英文查詢多 trigram 匹配', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      final candidates = service.filterCandidatesByTrigram('bench press');
      // 應找到 Bench Press 相關動作
      expect(candidates, contains('ex-001'));
    });
  });

  // ==========================================================================
  // Group 6: 邊界情況
  // ==========================================================================
  group('邊界情況', () {
    test('close 後 getCacheInfo 安全處理', () async {
      await service.close();
      final info = service.getCacheInfo();
      expect(info['initialized'], isFalse);
    });

    test('close 後 isCacheValid 返回 false', () async {
      await service.close();
      expect(service.isCacheValid(), isFalse);
    });

    test('close 後 getTrigramIndex 返回 null', () async {
      await service.close();
      expect(service.getTrigramIndex(), isNull);
    });

    test('getSearchIndexInfo 結構正確', () async {
      await service.saveExercises(ExerciseTestFactory.standardDataset);
      await Future.delayed(const Duration(seconds: 3));

      final info = service.getSearchIndexInfo();
      expect(info['initialized'], isTrue);
      expect(info['isValid'], isTrue);
      expect(info['trigramCount'], isA<int>());
      expect(info['trigramCount'], greaterThan(0));
      expect(info['version'], ExerciseLocalCacheService.currentCacheVersion);
    });

    test('未初始化時 getSearchIndexInfo 返回正確', () async {
      await service.close();
      final info = service.getSearchIndexInfo();
      expect(info['initialized'], isFalse);
    });
  });
}

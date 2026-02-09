import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/app_version_config.dart';

void main() {
  group('AppVersionConfig', () {
    group('fromSupabase', () {
      test('正確解析完整資料', () {
        final config = AppVersionConfig.fromSupabase({
          'key': 'app_version',
          'value': {
            'latest_version': '1.2.0',
            'update_url_android': 'https://play.google.com/store/apps/details?id=com.test',
            'update_url_ios': 'https://apps.apple.com/app/test/id123',
            'release_notes': '效能優化與穩定性提升',
          },
          'updated_at': '2026-02-09T00:00:00+00:00',
        });

        expect(config.latestVersion, '1.2.0');
        expect(config.updateUrlAndroid, 'https://play.google.com/store/apps/details?id=com.test');
        expect(config.updateUrlIos, 'https://apps.apple.com/app/test/id123');
        expect(config.releaseNotes, '效能優化與穩定性提升');
        expect(config.updatedAt, isNotNull);
      });

      test('處理缺失欄位使用預設值', () {
        final config = AppVersionConfig.fromSupabase({
          'key': 'app_version',
          'value': <String, dynamic>{},
          'updated_at': null,
        });

        expect(config.latestVersion, '0.0.0');
        expect(config.updateUrlAndroid, isNull);
        expect(config.updateUrlIos, isNull);
        expect(config.releaseNotes, isNull);
        expect(config.updatedAt, isNull);
      });

      test('處理部分欄位', () {
        final config = AppVersionConfig.fromSupabase({
          'key': 'app_version',
          'value': {
            'latest_version': '1.0.0',
          },
          'updated_at': null,
        });

        expect(config.latestVersion, '1.0.0');
        expect(config.updateUrlAndroid, isNull);
        expect(config.releaseNotes, isNull);
      });
    });

    group('toMap', () {
      test('正確轉換為 Map', () {
        const config = AppVersionConfig(
          latestVersion: '1.2.0',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.test',
          updateUrlIos: 'https://apps.apple.com/app/test/id123',
          releaseNotes: '新功能',
        );

        final map = config.toMap();
        expect(map['key'], 'app_version');

        final value = map['value'] as Map<String, dynamic>;
        expect(value['latest_version'], '1.2.0');
        expect(value['update_url_android'], 'https://play.google.com/store/apps/details?id=com.test');
        expect(value['update_url_ios'], 'https://apps.apple.com/app/test/id123');
        expect(value['release_notes'], '新功能');
      });
    });

    test('toString 格式正確', () {
      const config = AppVersionConfig(latestVersion: '1.2.0');
      expect(config.toString(), 'AppVersionConfig(latest: 1.2.0)');
    });
  });
}

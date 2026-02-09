import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/utils/version_utils.dart';

void main() {
  group('VersionUtils', () {
    group('compare', () {
      test('相同版本返回 0', () {
        expect(VersionUtils.compare('1.0.0', '1.0.0'), 0);
      });

      test('major 版本較高返回正數', () {
        expect(VersionUtils.compare('2.0.0', '1.0.0'), greaterThan(0));
      });

      test('major 版本較低返回負數', () {
        expect(VersionUtils.compare('1.0.0', '2.0.0'), lessThan(0));
      });

      test('minor 版本較高返回正數', () {
        expect(VersionUtils.compare('1.2.0', '1.1.0'), greaterThan(0));
      });

      test('minor 版本較低返回負數', () {
        expect(VersionUtils.compare('1.0.0', '1.1.0'), lessThan(0));
      });

      test('patch 版本較高返回正數', () {
        expect(VersionUtils.compare('1.0.2', '1.0.1'), greaterThan(0));
      });

      test('patch 版本較低返回負數', () {
        expect(VersionUtils.compare('1.0.0', '1.0.1'), lessThan(0));
      });

      test('移除 v 前綴', () {
        expect(VersionUtils.compare('v1.0.0', '1.0.0'), 0);
        expect(VersionUtils.compare('v2.0.0', 'v1.0.0'), greaterThan(0));
      });

      test('移除 build number (+N)', () {
        expect(VersionUtils.compare('1.1.1+16', '1.1.1'), 0);
        expect(VersionUtils.compare('1.1.1+16', '1.1.1+99'), 0);
      });

      test('不完整版本號補 0', () {
        expect(VersionUtils.compare('1.0', '1.0.0'), 0);
        expect(VersionUtils.compare('1', '1.0.0'), 0);
      });

      test('複雜組合比較', () {
        expect(VersionUtils.compare('1.1.1', '1.2.0'), lessThan(0));
        expect(VersionUtils.compare('2.0.0', '1.99.99'), greaterThan(0));
        expect(VersionUtils.compare('1.10.0', '1.9.0'), greaterThan(0));
      });
    });

    group('hasUpdate', () {
      test('有更新可用', () {
        expect(VersionUtils.hasUpdate('1.0.0', '1.1.0'), isTrue);
      });

      test('已是最新版本', () {
        expect(VersionUtils.hasUpdate('1.1.0', '1.1.0'), isFalse);
      });

      test('高於最新版本', () {
        expect(VersionUtils.hasUpdate('2.0.0', '1.1.0'), isFalse);
      });

      test('帶 build number 的比較', () {
        expect(VersionUtils.hasUpdate('1.1.1+16', '1.2.0'), isTrue);
        expect(VersionUtils.hasUpdate('1.1.1+16', '1.1.1'), isFalse);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/user/user_mapper.dart';

/// UserMapper 測試
///
/// P1 Models 層 - 12 個測試案例
void main() {
  group('UserMapper', () {
    // =========================================================================
    // fromMap
    // =========================================================================
    group('fromMap', () {
      test('正確解析完整數據', () {
        final map = {
          'uid': 'user-001',
          'email': 'test@example.com',
          'displayName': '測試用戶',
          'isCoach': true,
          'isStudent': false,
          'height': 175.0,
          'weight': 70.0,
        };

        final user = UserMapper.fromMap(map);
        expect(user.uid, 'user-001');
        expect(user.email, 'test@example.com');
        expect(user.displayName, '測試用戶');
        expect(user.isCoach, true);
        expect(user.isStudent, false);
      });

      test('處理缺失欄位', () {
        final map = {'uid': 'user-002'};
        final user = UserMapper.fromMap(map);
        expect(user.uid, 'user-002');
        expect(user.email, '');
        expect(user.isCoach, false);
        expect(user.isStudent, true); // 預設為學員
      });

      test('向後相容 isTrainer/isTrainee', () {
        final map = {
          'uid': 'user-003',
          'isTrainer': true,
          'isTrainee': false,
        };
        final user = UserMapper.fromMap(map);
        expect(user.isCoach, true);
        expect(user.isStudent, false);
      });

      test('新欄位優先於舊欄位', () {
        final map = {
          'uid': 'user-004',
          'isCoach': false,
          'isTrainer': true, // 舊欄位，應被忽略
        };
        final user = UserMapper.fromMap(map);
        expect(user.isCoach, false);
      });
    });

    // =========================================================================
    // fromSupabase
    // =========================================================================
    group('fromSupabase', () {
      test('正確解析 snake_case 欄位', () {
        final json = {
          'id': 'user-005',
          'email': 'supabase@example.com',
          'display_name': 'Supabase 用戶',
          'is_coach': true,
          'is_student': true,
          'height': 180.5,
          'weight': 75.3,
        };

        final user = UserMapper.fromSupabase(json);
        expect(user.uid, 'user-005');
        expect(user.email, 'supabase@example.com');
        expect(user.displayName, 'Supabase 用戶');
        expect(user.isCoach, true);
        expect(user.height, 180.5);
      });

      test('處理 null 值', () {
        final json = {
          'id': 'user-006',
          'display_name': null,
          'height': null,
        };
        final user = UserMapper.fromSupabase(json);
        expect(user.displayName, isNull);
        expect(user.height, isNull);
      });
    });

    // =========================================================================
    // toMap
    // =========================================================================
    group('toMap', () {
      test('正確轉換為 Map', () {
        final user = UserModel(
          uid: 'user-007',
          email: 'map@example.com',
          displayName: 'Map 用戶',
          isCoach: true,
          isStudent: false,
          height: 170.0,
        );

        final map = UserMapper.toMap(user);
        expect(map['uid'], 'user-007');
        expect(map['email'], 'map@example.com');
        expect(map['displayName'], 'Map 用戶');
        expect(map['isCoach'], true);
        expect(map['isStudent'], false);
        expect(map['height'], 170.0);
      });
    });

    // =========================================================================
    // 往返轉換
    // =========================================================================
    group('往返轉換', () {
      test('toMap → fromMap 往返正確', () {
        final original = UserModel(
          uid: 'user-008',
          email: 'roundtrip@example.com',
          displayName: '往返測試',
          isCoach: true,
          isStudent: true,
          height: 165.5,
          weight: 55.0,
          gender: '女',
        );

        final map = UserMapper.toMap(original);
        final restored = UserMapper.fromMap(map);

        expect(restored.uid, original.uid);
        expect(restored.email, original.email);
        expect(restored.displayName, original.displayName);
        expect(restored.isCoach, original.isCoach);
        expect(restored.height, original.height);
        expect(restored.gender, original.gender);
      });
    });
  });
}

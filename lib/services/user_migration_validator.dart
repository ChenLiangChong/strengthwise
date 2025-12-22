import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'error_handling_service.dart';

/// 使用者資料遷移驗證工具
///
/// 用於驗證遷移功能是否正常運作
class UserMigrationValidator {
  final FirebaseFirestore _firestore;
  final ErrorHandlingService _errorService;

  UserMigrationValidator({
    FirebaseFirestore? firestore,
    ErrorHandlingService? errorService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _errorService = errorService ?? ErrorHandlingService();

  /// 驗證用戶資料遷移是否成功
  ///
  /// 檢查項目：
  /// 1. users 集合中是否有該用戶資料
  /// 2. 所有必要欄位是否正確遷移
  /// 3. 欄位名稱是否正確轉換（isTrainer → isCoach）
  /// 4. 舊資料是否標記為已遷移
  Future<Map<String, dynamic>> validateMigration(String uid) async {
    try {
      _logDebug('開始驗證用戶資料遷移: $uid');

      final results = <String, dynamic>{
        'uid': uid,
        'passed': true,
        'checks': <String, dynamic>{},
      };

      // 1. 檢查 users 集合中是否有資料
      final newUserDoc = await _firestore.collection('users').doc(uid).get();
      if (!newUserDoc.exists) {
        results['passed'] = false;
        results['checks']['users_exists'] = {
          'status': 'failed',
          'message': 'users 集合中沒有該用戶資料',
        };
        return results;
      }

      results['checks']['users_exists'] = {
        'status': 'passed',
        'message': 'users 集合中存在該用戶資料',
      };

      final newUserData = newUserDoc.data()!;

      // 2. 檢查必要欄位是否存在
      final requiredFields = ['uid', 'email', 'isCoach', 'isStudent'];
      final missingFields = <String>[];

      for (final field in requiredFields) {
        if (!newUserData.containsKey(field)) {
          missingFields.add(field);
        }
      }

      if (missingFields.isNotEmpty) {
        results['passed'] = false;
        results['checks']['required_fields'] = {
          'status': 'failed',
          'message': '缺少必要欄位: ${missingFields.join(", ")}',
          'missing': missingFields,
        };
      } else {
        results['checks']['required_fields'] = {
          'status': 'passed',
          'message': '所有必要欄位都存在',
        };
      }

      // 3. 檢查欄位名稱是否正確（不應該有舊欄位名稱）
      final oldFieldNames = ['isTrainer', 'isTrainee', 'createdAt'];
      final foundOldFields = <String>[];

      for (final oldField in oldFieldNames) {
        if (newUserData.containsKey(oldField)) {
          foundOldFields.add(oldField);
        }
      }

      if (foundOldFields.isNotEmpty) {
        results['checks']['old_field_names'] = {
          'status': 'warning',
          'message': '發現舊欄位名稱（應該已轉換）: ${foundOldFields.join(", ")}',
          'found': foundOldFields,
        };
      } else {
        results['checks']['old_field_names'] = {
          'status': 'passed',
          'message': '沒有發現舊欄位名稱',
        };
      }

      // 4. 檢查 UserModel 是否能正確解析
      try {
        final userModel = UserModel.fromMap({...newUserData, 'uid': uid});

        results['checks']['model_parsing'] = {
          'status': 'passed',
          'message': 'UserModel 可以正確解析資料',
          'data': {
            'isCoach': userModel.isCoach,
            'isStudent': userModel.isStudent,
            'hasBio': userModel.bio != null,
            'hasBirthDate': userModel.birthDate != null,
            'hasUnitSystem': userModel.unitSystem != null,
            'hasLastLogin': userModel.lastLogin != null,
          },
        };
      } catch (e) {
        results['passed'] = false;
        results['checks']['model_parsing'] = {
          'status': 'failed',
          'message': 'UserModel 解析失敗: $e',
        };
      }

      // 5. 檢查舊資料是否標記為已遷移
      final oldUserDoc = await _firestore.collection('user').doc(uid).get();
      if (oldUserDoc.exists) {
        final oldUserData = oldUserDoc.data();
        if (oldUserData != null && oldUserData['migrated'] == true) {
          results['checks']['old_data_marked'] = {
            'status': 'passed',
            'message': '舊資料已標記為已遷移',
            'migratedAt': oldUserData['migratedAt'],
          };
        } else {
          results['checks']['old_data_marked'] = {
            'status': 'warning',
            'message': '舊資料存在但未標記為已遷移（可能需要執行遷移）',
          };
        }
      } else {
        results['checks']['old_data_marked'] = {
          'status': 'info',
          'message': '沒有舊資料（可能已經刪除或從未存在）',
        };
      }

      _logDebug('驗證完成: ${results['passed'] ? "通過" : "失敗"}');
      return results;
    } catch (e) {
      _logError('驗證失敗: $uid, 錯誤: $e');
      return {
        'uid': uid,
        'passed': false,
        'error': e.toString(),
      };
    }
  }

  /// 驗證所有用戶的遷移狀態
  Future<Map<String, dynamic>> validateAllMigrations() async {
    try {
      _logDebug('開始驗證所有用戶的遷移狀態');

      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      int passedCount = 0;
      int failedCount = 0;
      final failedUsers = <String>[];

      for (final doc in usersSnapshot.docs) {
        final result = await validateMigration(doc.id);
        if (result['passed'] == true) {
          passedCount++;
        } else {
          failedCount++;
          failedUsers.add(doc.id);
        }
      }

      final summary = {
        'total': totalUsers,
        'passed': passedCount,
        'failed': failedCount,
        'failedUsers': failedUsers,
      };

      _logDebug('驗證完成: $summary');
      return summary;
    } catch (e) {
      _logError('批次驗證失敗: $e');
      return {
        'total': 0,
        'passed': 0,
        'failed': 0,
        'error': e.toString(),
      };
    }
  }

  /// 比較新舊資料，顯示遷移前後的差異
  Future<Map<String, dynamic>> compareOldAndNewData(String uid) async {
    try {
      _logDebug('開始比較新舊資料: $uid');

      final oldUserDoc = await _firestore.collection('user').doc(uid).get();
      final newUserDoc = await _firestore.collection('users').doc(uid).get();

      final comparison = {
        'uid': uid,
        'oldDataExists': oldUserDoc.exists,
        'newDataExists': newUserDoc.exists,
        'oldData': oldUserDoc.exists ? oldUserDoc.data() : null,
        'newData': newUserDoc.exists ? newUserDoc.data() : null,
        'fieldMapping': <String, dynamic>{},
      };

      if (oldUserDoc.exists && newUserDoc.exists) {
        final oldData = oldUserDoc.data()!;
        final newData = newUserDoc.data()!;

        // 欄位映射對比
        comparison['fieldMapping'] = {
          'isTrainer → isCoach': {
            'old': oldData['isTrainer'],
            'new': newData['isCoach'],
            'match': oldData['isTrainer'] == newData['isCoach'],
          },
          'isTrainee → isStudent': {
            'old': oldData['isTrainee'],
            'new': newData['isStudent'],
            'match': oldData['isTrainee'] == newData['isStudent'],
          },
          'createdAt → profileCreatedAt': {
            'old': oldData['createdAt'],
            'new': newData['profileCreatedAt'],
            'match': oldData['createdAt']?.toString() ==
                newData['profileCreatedAt']?.toString(),
          },
          'bio': {
            'old': oldData['bio'],
            'new': newData['bio'],
            'match': oldData['bio'] == newData['bio'],
          },
          'unitSystem': {
            'old': oldData['unitSystem'],
            'new': newData['unitSystem'],
            'match': oldData['unitSystem'] == newData['unitSystem'],
          },
          'lastLogin': {
            'old': oldData['lastLogin'],
            'new': newData['lastLogin'],
            'match': oldData['lastLogin']?.toString() ==
                newData['lastLogin']?.toString(),
          },
        };
      }

      return comparison;
    } catch (e) {
      _logError('比較資料失敗: $uid, 錯誤: $e');
      return {
        'uid': uid,
        'error': e.toString(),
      };
    }
  }

  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[VALIDATION] $message');
    }
  }

  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[VALIDATION ERROR] $message');
    }
    _errorService.logError(message, type: 'UserMigrationValidationError');
  }
}

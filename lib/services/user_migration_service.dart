import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'error_handling_service.dart';

/// 使用者資料遷移服務
/// 
/// 負責將資料從舊的 `user` 集合遷移到新的 `users` 集合
/// 支援欄位名稱轉換和資料合併
class UserMigrationService {
  final FirebaseFirestore _firestore;
  final ErrorHandlingService _errorService;
  
  UserMigrationService({
    FirebaseFirestore? firestore,
    ErrorHandlingService? errorService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _errorService = errorService ?? ErrorHandlingService();
  
  /// 遷移用戶資料從 user 集合到 users 集合
  /// 
  /// 此方法應在應用啟動時或用戶登入時執行一次
  /// 
  /// 遷移策略：
  /// 1. 檢查 users/{uid} 是否存在
  /// 2. 檢查 user/{uid} 是否存在
  /// 3. 如果舊資料存在且新資料缺少欄位，合併資料
  /// 4. 將合併後的資料寫入 users/{uid}
  /// 5. 標記 user/{uid} 為已遷移（添加 migrated: true）
  Future<bool> migrateUserData(String uid) async {
    try {
      _logDebug('開始遷移用戶資料: $uid');
      
      // 1. 檢查 users/{uid} 是否存在
      final newUserDoc = await _firestore.collection('users').doc(uid).get();
      final newUserData = newUserDoc.exists ? newUserDoc.data() : null;
      
      // 2. 檢查 user/{uid} 是否存在
      final oldUserDoc = await _firestore.collection('user').doc(uid).get();
      
      if (!oldUserDoc.exists) {
        _logDebug('舊用戶資料不存在，無需遷移: $uid');
        return false;
      }
      
      final oldUserData = oldUserDoc.data();
      if (oldUserData == null) {
        _logDebug('舊用戶資料為空，無需遷移: $uid');
        return false;
      }
      
      // 檢查是否已經遷移過
      if (oldUserData['migrated'] == true) {
        _logDebug('用戶資料已遷移過: $uid');
        return false;
      }
      
      _logDebug('發現需要遷移的舊用戶資料: $uid');
      
      // 3. 合併資料
      final mergedData = _mergeUserData(newUserData, oldUserData, uid);
      
      // 4. 將合併後的資料寫入 users/{uid}
      await _firestore.collection('users').doc(uid).set(
        mergedData, 
        SetOptions(merge: true)
      );
      
      _logDebug('用戶資料已寫入 users 集合: $uid');
      
      // 5. 標記 user/{uid} 為已遷移
      await _firestore.collection('user').doc(uid).update({
        'migrated': true,
        'migratedAt': FieldValue.serverTimestamp(),
      });
      
      _logDebug('用戶資料遷移完成: $uid');
      return true;
    } catch (e) {
      _logError('遷移用戶資料失敗: $uid, 錯誤: $e');
      return false;
    }
  }
  
  /// 合併新舊用戶資料
  /// 
  /// 策略：
  /// - 優先使用 users 集合的資料
  /// - 從 user 集合補充缺少的欄位
  /// - 轉換欄位名稱（isTrainer → isCoach, isTrainee → isStudent）
  Map<String, dynamic> _mergeUserData(
    Map<String, dynamic>? newData,
    Map<String, dynamic> oldData,
    String uid,
  ) {
    final merged = <String, dynamic>{
      'uid': uid,
    };
    
    // 如果有新資料，先複製所有新資料
    if (newData != null) {
      merged.addAll(newData);
    }
    
    // 基本欄位：優先使用新資料，如果沒有則使用舊資料
    merged['email'] ??= oldData['email'];
    merged['displayName'] ??= oldData['displayName'];
    merged['photoURL'] ??= oldData['photoURL'];
    merged['nickname'] ??= oldData['nickname'];
    merged['gender'] ??= oldData['gender'];
    merged['height'] ??= oldData['height'];
    merged['weight'] ??= oldData['weight'];
    merged['age'] ??= oldData['age'];
    
    // 新增欄位：從舊資料補充
    merged['birthDate'] ??= oldData['birthDate'];
    merged['bio'] ??= oldData['bio'];
    merged['unitSystem'] ??= oldData['unitSystem'];
    merged['lastLogin'] ??= oldData['lastLogin'];
    
    // 身份欄位：轉換舊欄位名稱
    // 優先使用新欄位，如果沒有則轉換舊欄位
    if (!merged.containsKey('isCoach')) {
      merged['isCoach'] = oldData['isTrainer'] ?? false;
    }
    if (!merged.containsKey('isStudent')) {
      merged['isStudent'] = oldData['isTrainee'] ?? true;
    }
    
    // 時間戳記：轉換舊欄位名稱
    if (!merged.containsKey('profileCreatedAt')) {
      merged['profileCreatedAt'] = oldData['createdAt'] ?? oldData['profileCreatedAt'];
    }
    if (!merged.containsKey('profileUpdatedAt')) {
      merged['profileUpdatedAt'] = FieldValue.serverTimestamp();
    }
    
    _logDebug('資料合併完成，合併了 ${merged.keys.length} 個欄位');
    return merged;
  }
  
  /// 批次遷移所有需要遷移的用戶
  /// 
  /// 注意：此方法會遷移所有 user 集合中的文檔
  /// 僅在需要批次遷移時使用（例如：資料庫初始化）
  Future<Map<String, dynamic>> migrateAllUsers() async {
    try {
      _logDebug('開始批次遷移所有用戶資料');
      
      final oldUsersSnapshot = await _firestore.collection('user').get();
      final totalUsers = oldUsersSnapshot.docs.length;
      
      int successCount = 0;
      int skipCount = 0;
      int failCount = 0;
      
      for (final doc in oldUsersSnapshot.docs) {
        final result = await migrateUserData(doc.id);
        if (result) {
          successCount++;
        } else {
          // 檢查是否因為已遷移而跳過
          final data = doc.data();
          if (data['migrated'] == true) {
            skipCount++;
          } else {
            failCount++;
          }
        }
      }
      
      final summary = {
        'total': totalUsers,
        'success': successCount,
        'skipped': skipCount,
        'failed': failCount,
      };
      
      _logDebug('批次遷移完成: $summary');
      return summary;
    } catch (e) {
      _logError('批次遷移失敗: $e');
      return {
        'total': 0,
        'success': 0,
        'skipped': 0,
        'failed': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// 檢查用戶是否需要遷移
  Future<bool> needsMigration(String uid) async {
    try {
      final oldUserDoc = await _firestore.collection('user').doc(uid).get();
      
      if (!oldUserDoc.exists) {
        return false;
      }
      
      final data = oldUserDoc.data();
      if (data == null) {
        return false;
      }
      
      // 如果已經標記為已遷移，則不需要遷移
      return data['migrated'] != true;
    } catch (e) {
      _logError('檢查遷移狀態失敗: $uid, 錯誤: $e');
      return false;
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[MIGRATION] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[MIGRATION ERROR] $message');
    }
    _errorService.logError(message, type: 'UserMigrationError');
  }
}


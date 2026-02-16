import 'dart:io';
import 'dart:typed_data';
import '../../models/user_model.dart';

/// 用戶服務接口
/// 
/// 定義與用戶資料相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class IUserService {
  /// 檢查用戶是否已完成資料設置
  Future<bool> isProfileCompleted();
  
  /// 獲取當前用戶的完整資料
  Future<UserModel?> getCurrentUserProfile();
  
  /// 獲取指定用戶的完整資料（by UID）
  Future<UserModel?> getUserProfile(String userId);
  
  /// 更新用戶資料
  Future<bool> updateUserProfile({
    String? displayName,
    String? nickname,
    String? gender,
    bool? genderVisible,  // 性別是否公開
    double? height,
    double? weight,
    int? age,
    DateTime? birthDate,  // 新增：生日
    bool? isCoach,
    bool? isStudent,
    String? bio,          // 新增：個人簡介
    String? unitSystem,   // 新增：單位系統
    File? avatarFile,
    Uint8List? avatarBytes, // ⭐ v5.3: Web 跨平台頭像上傳
  });
  
  /// 切換用戶角色
  Future<bool> toggleUserRole(bool isCoach);
  
  /// 更新用戶體重（由身體數據記錄觸發）
  /// 
  /// 當新增身體數據記錄時，自動同步最新體重到用戶基本資料
  Future<bool> updateUserWeight(String userId, double weight);
  
  /// 刪除用戶帳號及所有關聯資料
  /// 
  /// 注意：此操作不可逆，會刪除：
  /// - 教練學員關係
  /// - 預約記錄
  /// - 訓練計劃與記錄
  /// - 身體數據
  /// - 統計資料
  /// 
  /// 保留：
  /// - 自訂動作（custom_exercises，user_id 設為 NULL）
  Future<Map<String, dynamic>> deleteUserAccount();
} 
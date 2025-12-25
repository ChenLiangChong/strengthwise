import 'dart:io';
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
  
  /// 更新用戶資料
  Future<bool> updateUserProfile({
    String? displayName,
    String? nickname,
    String? gender,
    double? height,
    double? weight,
    int? age,
    DateTime? birthDate,  // 新增：生日
    bool? isCoach,
    bool? isStudent,
    String? bio,          // 新增：個人簡介
    String? unitSystem,   // 新增：單位系統
    File? avatarFile,
  });
  
  /// 切換用戶角色
  Future<bool> toggleUserRole(bool isCoach);
  
  /// 更新用戶體重（由身體數據記錄觸發）
  /// 
  /// 當新增身體數據記錄時，自動同步最新體重到用戶基本資料
  Future<bool> updateUserWeight(String userId, double weight);
} 
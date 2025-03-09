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
    bool? isCoach,
    bool? isStudent,
    File? avatarFile,
  });
  
  /// 切換用戶角色
  Future<bool> toggleUserRole(bool isCoach);
} 
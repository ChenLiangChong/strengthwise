import '../../models/user_model.dart';

/// 身份驗證用戶管理器
///
/// 負責用戶數據的轉換和管理
class AuthUserManager {
  /// 從服務層數據創建用戶模型
  static UserModel? createUserFromData(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    
    final uid = userData['uid'];
    if (uid == null || uid is! String) return null;
    
    final email = userData['email'];
    if (email == null || email is! String) return null;
    
    return UserModel(
      uid: uid,
      email: email,
      displayName: userData['displayName'] as String?,
      photoURL: userData['photoURL'] as String?,
    );
  }
  
  /// 從多個數據源創建用戶模型（處理異常情況）
  static UserModel? createUserFromDataSafe(
    Map<String, dynamic>? userData, {
    required Future<Map<String, dynamic>?> Function() fallbackGetter,
  }) {
    if (userData != null) {
      return createUserFromData(userData);
    }
    
    // 嘗試從備用來源獲取
    return null;
  }
}


import '../../models/user_model.dart';

/// 身份驗證控制器接口
/// 
/// 定義與用戶身份驗證相關的業務邏輯操作。
abstract class IAuthController {
  /// 當前登入狀態
  bool get isLoggedIn;
  
  /// 載入狀態
  bool get isLoading;
  
  /// 錯誤信息
  String? get errorMessage;
  
  /// 當前用戶
  UserModel? get user;
  
  /// 使用電子郵件和密碼登入
  Future<bool> signInWithEmail(String email, String password);
  
  /// 使用電子郵件和密碼註冊
  Future<bool> registerWithEmail(String email, String password);
  
  /// 使用Google登入
  Future<bool> signInWithGoogle();
  
  /// 登出
  Future<void> signOut();
} 
/// 身份驗證服務接口
/// 
/// 定義與用戶身份驗證相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class IAuthService {
  /// 檢查用戶是否已登入
  bool isUserLoggedIn();
  
  /// 獲取當前用戶資訊
  Map<String, dynamic>? getCurrentUser();
  
  /// 使用Google登入
  Future<Map<String, dynamic>?> signInWithGoogle();
  
  /// 使用電子郵件和密碼登入
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password);
  
  /// 使用電子郵件和密碼註冊
  Future<Map<String, dynamic>?> registerWithEmail(String email, String password);
  
  /// 登出
  Future<void> signOut();
} 
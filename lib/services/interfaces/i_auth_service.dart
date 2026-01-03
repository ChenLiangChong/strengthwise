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
  
  /// ✅ 檢查當前用戶是否為 OAuth 登入（Google 等）
  /// 返回: true = OAuth 登入, false = Email 登入
  bool isOAuthUser();
  
  /// ✅ 為 OAuth 用戶設置密碼（啟用 Email 登入）
  /// [newPassword] 新密碼（至少 6 個字符）
  /// 返回: true = 成功, false = 失敗
  Future<bool> setPasswordForOAuthUser(String newPassword);
  
  /// ✅ 檢查 OAuth 用戶是否已設置密碼
  /// 返回: true = 已設置密碼, false = 尚未設置密碼
  bool hasPassword();
} 
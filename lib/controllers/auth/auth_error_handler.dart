/// 身份驗證錯誤處理器
///
/// 負責將技術錯誤轉換為用戶友好的錯誤消息
class AuthErrorHandler {
  /// 將技術錯誤轉換為用戶友好的消息
  static String getUserFriendlyError(String errorMsg, dynamic originalError) {
    final errorString = originalError?.toString() ?? errorMsg;
    
    // Supabase Auth 常見錯誤
    if (_isInvalidCredentials(errorString)) {
      return '找不到該用戶，請檢查您的電子郵件或密碼';
    }
    
    if (_isWrongPassword(errorString)) {
      return '密碼不正確';
    }
    
    if (_isInvalidEmail(errorString)) {
      return '電子郵件格式無效';
    }
    
    if (_isUserDisabled(errorString)) {
      return '該帳戶已被停用';
    }
    
    if (_isEmailAlreadyInUse(errorString)) {
      return '該電子郵件已被註冊';
    }
    
    if (_isWeakPassword(errorString)) {
      return '密碼強度太弱，請使用更複雜的密碼';
    }
    
    if (_isNetworkError(errorString)) {
      return '網絡連接失敗，請檢查您的網絡連接';
    }
    
    if (_isRateLimitError(errorString)) {
      return '登入嘗試次數過多，請稍後再試';
    }
    
    // Google登入錯誤
    if (_isGoogleSignInError(errorString)) {
      return 'Google登入失敗，請稍後再試';
    }
    
    // 模擬器相關錯誤
    if (_isEmulatorError(errorString)) {
      return "Google 登入在模擬器上不可用。請使用真實設備測試，或使用電子郵件登入功能。";
    }
    
    // 其他常見錯誤模式
    if (_isNetworkRelated(errorMsg)) {
      return '網絡連接錯誤，請檢查您的網絡連接';
    }
    
    if (_isTimeoutError(errorMsg)) {
      return '連接超時，請稍後再試';
    }
    
    if (_isCredentialError(errorMsg)) {
      return '登入憑證無效';
    }
    
    // 默認錯誤消息
    return '登入失敗，請稍後再試';
  }
  
  // 私有輔助方法
  static bool _isInvalidCredentials(String error) {
    return error.contains('Invalid login credentials') || 
           error.contains('user-not-found');
  }
  
  static bool _isWrongPassword(String error) {
    return error.contains('wrong-password');
  }
  
  static bool _isInvalidEmail(String error) {
    return error.contains('invalid-email') || 
           error.contains('Invalid email');
  }
  
  static bool _isUserDisabled(String error) {
    return error.contains('user-disabled') || 
           error.contains('User is disabled');
  }
  
  static bool _isEmailAlreadyInUse(String error) {
    return error.contains('email-already-in-use') || 
           error.contains('already registered');
  }
  
  static bool _isWeakPassword(String error) {
    return error.contains('weak-password') || 
           error.contains('Password should be');
  }
  
  static bool _isNetworkError(String error) {
    return error.contains('network') || 
           error.contains('Network');
  }
  
  static bool _isRateLimitError(String error) {
    return error.contains('too-many-requests') || 
           error.contains('rate limit');
  }
  
  static bool _isGoogleSignInError(String error) {
    return error.contains('GoogleSignIn');
  }
  
  static bool _isEmulatorError(String error) {
    return error.contains('模擬器') || error.contains('真實設備');
  }
  
  static bool _isNetworkRelated(String error) {
    return error.toLowerCase().contains('network');
  }
  
  static bool _isTimeoutError(String error) {
    return error.toLowerCase().contains('timeout');
  }
  
  static bool _isCredentialError(String error) {
    return error.toLowerCase().contains('credential');
  }
}


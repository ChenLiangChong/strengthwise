/// 身份驗證驗證器
///
/// 提供電子郵件和密碼驗證功能
class AuthValidators {
  /// 檢查電子郵件格式是否有效
  static bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// 檢查密碼強度
  /// 
  /// 返回值: 0 (弱) 到 3 (強)
  static int getPasswordStrength(String password) {
    if (password.length < 6) return 0;
    
    int strength = 0;
    
    // 長度足夠 (8+ 字符)
    if (password.length >= 8) strength++;
    
    // 包含大小寫字母
    if (RegExp(r'[A-Z]').hasMatch(password) && 
        RegExp(r'[a-z]').hasMatch(password)) {
      strength++;
    }
    
    // 包含數字
    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
    }
    
    // 包含特殊字符
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength++;
    }
    
    return strength > 3 ? 3 : strength;
  }
  
  /// 獲取密碼強度描述
  static String getPasswordStrengthDescription(int strength) {
    switch (strength) {
      case 0:
        return '非常弱';
      case 1:
        return '弱';
      case 2:
        return '中等';
      case 3:
        return '強';
      default:
        return '未知';
    }
  }
  
  /// 檢查密碼是否符合最低要求
  static bool isPasswordValid(String password) {
    return password.length >= 6;
  }
}


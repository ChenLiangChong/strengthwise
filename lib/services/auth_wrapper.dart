import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// 簡單的包裝類，避免直接使用可能有問題的 Firebase 方法
class AuthWrapper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // 檢查用戶是否已登入
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
  
  // 獲取當前用戶信息的安全方法
  Map<String, dynamic>? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    };
  }
  
  // Google 登入 - 完全重寫，使用平台特定代碼
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // 正常流程取得 GoogleSignInAccount...
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // 嘗試登入但不使用返回值
      await _auth.signInWithCredential(credential);
      
      // 直接從 currentUser 取得登入資訊
      final user = _auth.currentUser;
      if (user == null) return null;
      
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
      };
    } catch (e) {
      print("Google 登入錯誤: $e");
      return null;
    }
  }
  
  // 登出方法
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 新增電子郵件登入方法
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) return null;
      
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };
    } catch (e) {
      print("電子郵件登入錯誤: $e");
      return null;
    }
  }

  // 新增電子郵件註冊方法
  Future<Map<String, dynamic>?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) return null;
      
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };
    } catch (e) {
      print("電子郵件註冊錯誤: $e");
      return null;
    }
  }
} 
import 'package:flutter/material.dart';
import '../controllers/interfaces/i_auth_controller.dart';
import '../services/service_locator.dart';
import '../services/core/error_handling_service.dart';
import '../utils/notification_utils.dart';
import 'main_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;

  late final IAuthController _authController;
  late final ErrorHandlingService _errorService;

  @override
  void initState() {
    super.initState();
    // 從服務定位器獲取控制器
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  /// 統一處理登入結果和導航
  /// [authAction] 認證操作（返回是否成功）
  /// [customErrorHandler] 自定義錯誤處理（可選）
  Future<void> _handleAuthResult(
    Future<bool> Function() authAction, {
    void Function(String errorMsg)? customErrorHandler,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authAction();
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainHomePage()),
        );
      } else if (mounted) {
        final errorMsg = _authController.errorMessage ?? '登入失敗，請稍後再試';
        if (customErrorHandler != null) {
          customErrorHandler(errorMsg);
        } else {
          NotificationUtils.showError(context, errorMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    await _handleAuthResult(() async {
      return _isSignUp
          ? await _authController.registerWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            )
          : await _authController.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            );
    });
  }

  Future<void> _handleGoogleSignIn() async {
    await _handleAuthResult(
      () => _authController.signInWithGoogle(),
      customErrorHandler: (errorMsg) {
        // 檢查是否為模擬器相關錯誤
        String displayMsg = errorMsg;
        if (errorMsg.contains('模擬器') || errorMsg.contains('真實設備')) {
          displayMsg = 'Google 登入在模擬器上不可用。\n請使用真實設備測試，或使用下方的電子郵件登入功能。';
        }

        NotificationUtils.showError(
          context,
          displayMsg,
          duration: const Duration(seconds: 5),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const FlutterLogo(size: 100),
                const SizedBox(height: 32),

                // 標題
                Text(
                  _isSignUp ? '註冊新帳號' : '歡迎回來',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 電子郵件輸入
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '電子郵件',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入電子郵件';
                    }
                    // ⚡ 改進的電子郵件驗證：支援更多格式
                    // 允許數字開頭、連續點號、加號等常見格式
                    final emailRegex = RegExp(
                      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return '請輸入有效的電子郵件格式';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密碼輸入
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密碼',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入密碼';
                    }
                    if (_isSignUp && value.length < 6) {
                      return '密碼長度至少需要6個字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 提交按鈕
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            _isSignUp ? '註冊' : '登入',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 切換註冊/登入模式
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(_isSignUp ? '已有帳號？點此登入' : '沒有帳號？點此註冊'),
                ),
                const SizedBox(height: 24),

                const Text(
                  '或者使用以下方式登入',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Google登入按鈕
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('使用 Google 帳號登入'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

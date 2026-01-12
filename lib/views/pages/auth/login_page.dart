// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/interfaces/i_user_service.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/home/main_home_page.dart';
import 'package:strengthwise/views/pages/profile/profile_settings_page.dart';

/// 登入頁面
///
/// 響應式設計：居中顯示，最大寬度 400dp
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
        // ✅ 檢查用戶是否完成個人資料設置
        final userService = serviceLocator<IUserService>();
        final isProfileCompleted = await userService.isProfileCompleted();

        if (!isProfileCompleted) {
          // 首次登入，跳轉到個人資料設定頁面
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ProfileSettingsPage(isFirstTimeSetup: true),
            ),
          );
        } else {
          // 已完成設定，直接進入主頁
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainHomePage()),
          );
        }
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
    // Web 平台：OAuth 會重定向整個頁面到 Google
    // 不需要處理返回值，只需顯示 Loading 並等待重定向
    if (kIsWeb) {
      setState(() {
        _isLoading = true;
      });
      await _authController.signInWithGoogle();
      // 頁面會重定向到 Google，這行之後的代碼可能不會執行
      // 當用戶從 Google 返回時，App 會重新載入，Auth State 會自動處理
      return;
    }

    // 非 Web 平台：使用原本的結果處理邏輯
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: context.pagePadding,
            child: Center(
              // ✅ 登入表單限制最大寬度 400dp
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/splash/splash_logo.png',
                        width: 120,
                        height: 120,
                      ),
                      SizedBox(height: context.spacing.xl),

                      // 標題
                      Text(
                        _isSignUp ? '註冊新帳號' : '歡迎回來',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.lg),

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
                              r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
                          if (!emailRegex.hasMatch(value.trim())) {
                            return '請輸入有效的電子郵件格式';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: context.spacing.md),

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
                      SizedBox(height: context.spacing.lg),

                      // 提交按鈕（最小觸控目標 48dp）
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isSignUp ? '註冊' : '登入',
                                  style: textTheme.labelLarge,
                                ),
                        ),
                      ),
                      SizedBox(height: context.spacing.md),

                      // 切換註冊/登入模式
                      TextButton(
                        onPressed: _toggleMode,
                        child: Text(_isSignUp ? '已有帳號？點此登入' : '沒有帳號？點此註冊'),
                      ),
                      SizedBox(height: context.spacing.lg),

                      Text(
                        '或者使用以下方式登入',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: context.spacing.md),

                      // Google 登入按鈕
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text('使用 Google 帳號登入'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

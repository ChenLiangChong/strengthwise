import 'package:flutter/material.dart';
import 'main_home_page.dart';
import '../services/auth_wrapper.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      
      try {
        final authWrapper = AuthWrapper();
        Map<String, dynamic>? userData;
        
        if (_isLogin) {
          userData = await authWrapper.signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } else {
          userData = await authWrapper.registerWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
        }
        
        if (!mounted) return;
        
        if (userData != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainHomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("登入失敗，請稍後再試"))
          );
        }
      } catch (e) {
        print("登入表單錯誤: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("登入時發生錯誤"))
        );
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? '登入' : '註冊'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),
              FlutterLogo(size: 80),
              SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '電子郵件',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入電子郵件';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '請輸入有效的電子郵件';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '密碼',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入密碼';
                  }
                  if (value.length < 6) {
                    return '密碼長度至少為6位';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              if (mounted && mounted)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    mounted ? '' : '',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? '登入' : '註冊',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin ? '沒有帳號? 去註冊' : '已有帳號? 去登入'),
              ),
              SizedBox(height: 20),
              Divider(thickness: 1),
              SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() { 
                          _isLoading = true; 
                        });
                        
                        try {
                          final authWrapper = AuthWrapper();
                          print("準備調用 Google 登入...");
                          final userData = await authWrapper.signInWithGoogle();
                          
                          if (userData != null && mounted) {
                            print("登入成功，導航到主頁");
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => MainHomePage()),
                            );
                          } else if (mounted) {
                            print("登入失敗，顯示提示");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Google 登入失敗，請稍後再試"))
                            );
                          }
                        } catch (e) {
                          print("前端 Google 登入錯誤: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("登入過程發生錯誤: ${e.toString().substring(0, math.min(50, e.toString().length))}..."))
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                ),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('使用Google帳號登入', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/auth/auth_validators.dart';

/// AuthValidators 測試
///
/// P10 優先級 - 15 個測試案例（安全/Edge Cases）
void main() {
  group('AuthValidators', () {
    // =========================================================================
    // isEmailValid
    // =========================================================================
    group('isEmailValid', () {
      test('有效郵件格式', () {
        expect(AuthValidators.isEmailValid('test@example.com'), isTrue);
        expect(AuthValidators.isEmailValid('user.name@domain.co'), isTrue);
        expect(AuthValidators.isEmailValid('user+tag@domain.org'), isTrue);
      });

      test('無效郵件格式', () {
        expect(AuthValidators.isEmailValid('invalid'), isFalse);
        expect(AuthValidators.isEmailValid('invalid@'), isFalse);
        expect(AuthValidators.isEmailValid('@domain.com'), isFalse);
        expect(AuthValidators.isEmailValid('test@.com'), isFalse);
      });

      test('空字串返回 false', () {
        expect(AuthValidators.isEmailValid(''), isFalse);
      });
    });

    // =========================================================================
    // getPasswordStrength
    // =========================================================================
    group('getPasswordStrength', () {
      test('短密碼 (<8) 返回 0', () {
        expect(AuthValidators.getPasswordStrength('abc'), 0);
        expect(AuthValidators.getPasswordStrength('12345'), 0);
        expect(AuthValidators.getPasswordStrength('abcdefg'), 0);
      });

      test('長密碼 (8+) 加 1 分', () {
        expect(AuthValidators.getPasswordStrength('abcdefgh'),
            greaterThanOrEqualTo(1));
      });

      test('包含大小寫加分', () {
        expect(AuthValidators.getPasswordStrength('Abcdefgh'),
            greaterThanOrEqualTo(2));
      });

      test('包含數字加分', () {
        expect(AuthValidators.getPasswordStrength('Abcdefg1'),
            greaterThanOrEqualTo(2));
      });

      test('強密碼返回 3', () {
        expect(AuthValidators.getPasswordStrength('Abcdef1!'), 3);
        expect(AuthValidators.getPasswordStrength('StrongP@ss123'), 3);
      });

      test('最大值為 3', () {
        expect(AuthValidators.getPasswordStrength('SuperStrong@Pass123!'), 3);
      });
    });

    // =========================================================================
    // getPasswordStrengthDescription
    // =========================================================================
    group('getPasswordStrengthDescription', () {
      test('返回正確描述', () {
        expect(AuthValidators.getPasswordStrengthDescription(0), '非常弱');
        expect(AuthValidators.getPasswordStrengthDescription(1), '弱');
        expect(AuthValidators.getPasswordStrengthDescription(2), '中等');
        expect(AuthValidators.getPasswordStrengthDescription(3), '強');
      });

      test('無效值返回未知', () {
        expect(AuthValidators.getPasswordStrengthDescription(-1), '未知');
        expect(AuthValidators.getPasswordStrengthDescription(5), '未知');
      });
    });

    // =========================================================================
    // isPasswordValid
    // =========================================================================
    group('isPasswordValid', () {
      test('>=8 字符且含字母+數字返回 true', () {
        expect(AuthValidators.isPasswordValid('abcdef12'), isTrue);
        expect(AuthValidators.isPasswordValid('Test1234'), isTrue);
        expect(AuthValidators.isPasswordValid('password1'), isTrue);
      });

      test('<8 字符返回 false', () {
        expect(AuthValidators.isPasswordValid('abc123'), isFalse);
        expect(AuthValidators.isPasswordValid('ab1'), isFalse);
      });

      test('只有字母（無數字）返回 false', () {
        expect(AuthValidators.isPasswordValid('abcdefgh'), isFalse);
      });

      test('只有數字（無字母）返回 false', () {
        expect(AuthValidators.isPasswordValid('12345678'), isFalse);
      });

      test('空字串返回 false', () {
        expect(AuthValidators.isPasswordValid(''), isFalse);
      });
    });
  });
}

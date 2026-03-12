import 'package:flutter_test/flutter_test.dart';
import 'package:igaranti/services/validation_service.dart';

void main() {
  group('ValidationService Tests', () {
    group('Email Validation', () {
      test('Valid email should pass', () {
        final result = ValidationService.validateEmail('test@example.com');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Empty email should fail', () {
        final result = ValidationService.validateEmail('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Email adresi gerekli');
      });

      test('Null email should fail', () {
        final result = ValidationService.validateEmail(null);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Email adresi gerekli');
      });

      test('Invalid email format should fail', () {
        final result = ValidationService.validateEmail('invalid-email');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Geçerli bir email adresi girin');
      });

      test('Too long email should fail', () {
        final longEmail = '${'a' * 250}@example.com';
        final result = ValidationService.validateEmail(longEmail);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Email adresi çok uzun');
      });
    });

    group('Password Validation', () {
      test('Valid password should pass', () {
        final result = ValidationService.validatePassword('Password123');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Empty password should fail', () {
        final result = ValidationService.validatePassword('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Şifre gerekli');
      });

      test('Short password should fail', () {
        final result = ValidationService.validatePassword('123');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Şifre en az 6 karakter olmalıdır');
      });

      test('Password without uppercase should fail', () {
        final result = ValidationService.validatePassword('password123');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Şifrede en az bir büyük harf olmalı');
      });

      test('Password without lowercase should fail', () {
        final result = ValidationService.validatePassword('PASSWORD123');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Şifrede en az bir küçük harf olmalı');
      });

      test('Password without digit should fail', () {
        final result = ValidationService.validatePassword('Password');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Şifrede en az bir rakam olmalı');
      });
    });

    group('Product Name Validation', () {
      test('Valid product name should pass', () {
        final result = ValidationService.validateProductName('iPhone 13');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Empty product name should fail', () {
        final result = ValidationService.validateProductName('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Ürün adı gerekli');
      });

      test('Short product name should fail', () {
        final result = ValidationService.validateProductName('A');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Ürün adı en az 2 karakter olmalı');
      });

      test('Too long product name should fail', () {
        final longName = '${'a' * 101}';
        final result = ValidationService.validateProductName(longName);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Ürün adı çok uzun (max 100 karakter)');
      });

      test('Product name with dangerous chars should fail', () {
        final result = ValidationService.validateProductName('Product<script>');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Ürün adı geçersiz karakterler içeriyor');
      });
    });

    group('Brand Validation', () {
      test('Valid brand should pass', () {
        final result = ValidationService.validateBrand('Apple');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Empty brand should fail', () {
        final result = ValidationService.validateBrand('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Marka gerekli');
      });

      test('Short brand should fail', () {
        final result = ValidationService.validateBrand('A');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Marka en az 2 karakter olmalı');
      });
    });

    group('Model Validation', () {
      test('Valid model should pass', () {
        final result = ValidationService.validateModel('Pro Max');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Empty model should pass (optional field)', () {
        final result = ValidationService.validateModel('');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Null model should pass (optional field)', () {
        final result = ValidationService.validateModel(null);
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });
    });

    group('Warranty Months Validation', () {
      test('Valid warranty months should pass', () {
        final result = ValidationService.validateWarrantyMonths(24);
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Zero warranty months should fail', () {
        final result = ValidationService.validateWarrantyMonths(0);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Garanti süresi en az 1 ay olmalı');
      });

      test('Negative warranty months should fail', () {
        final result = ValidationService.validateWarrantyMonths(-5);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Garanti süresi en az 1 ay olmalı');
      });

      test('Too high warranty months should fail', () {
        final result = ValidationService.validateWarrantyMonths(150);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Garanti süresi çok uzun (max 120 ay)');
      });
    });

    group('Purchase Date Validation', () {
      test('Valid purchase date should pass', () {
        final date = DateTime.now().subtract(const Duration(days: 30));
        final result = ValidationService.validatePurchaseDate(date);
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Null purchase date should fail', () {
        final result = ValidationService.validatePurchaseDate(null);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Satın alma tarihi gerekli');
      });

      test('Future date should fail', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final result = ValidationService.validatePurchaseDate(futureDate);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Tarih gelecekte olamaz');
      });

      test('Too old date should fail', () {
        final oldDate = DateTime(1990);
        final result = ValidationService.validatePurchaseDate(oldDate);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Tarih çok eski');
      });
    });

    group('File Validation', () {
      test('Valid image file should pass', () {
        final result = ValidationService.validateFile('image.jpg');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Valid PDF file should pass', () {
        final result = ValidationService.validateFile('document.pdf');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('Empty file path should fail', () {
        final result = ValidationService.validateFile('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Dosya seçilmedi');
      });

      test('Unsupported file type should fail', () {
        final result = ValidationService.validateFile('file.txt');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Desteklenmeyen dosya formatı');
      });
    });

    group('Form Validation', () {
      test('Valid product form should pass all validations', () {
        final results = ValidationService.validateProductForm(
          name: 'iPhone 13',
          brand: 'Apple',
          model: 'Pro Max',
          warrantyMonths: 24,
          purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        for (final entry in results.entries) {
          expect(entry.value.isValid, true, reason: '${entry.key} should be valid');
          expect(entry.value.errorMessage, null, reason: '${entry.key} should not have error');
        }
      });

      test('Invalid product form should fail validations', () {
        final results = ValidationService.validateProductForm(
          name: '', // Invalid
          brand: 'A', // Invalid
          warrantyMonths: 0, // Invalid
          purchaseDate: null, // Invalid
        );

        expect(results['name']!.isValid, false);
        expect(results['brand']!.isValid, false);
        expect(results['warrantyMonths']!.isValid, false);
        expect(results['purchaseDate']!.isValid, false);
      });

      test('Valid login form should pass', () {
        final results = ValidationService.validateLoginForm(
          email: 'test@example.com',
          password: 'Password123',
        );

        expect(results['email']!.isValid, true);
        expect(results['password']!.isValid, true);
      });

      test('Valid register form should pass', () {
        final results = ValidationService.validateRegisterForm(
          email: 'test@example.com',
          password: 'Password123',
          confirmPassword: 'Password123',
        );

        expect(results['email']!.isValid, true);
        expect(results['password']!.isValid, true);
        expect(results['confirmPassword']!.isValid, true);
      });

      test('Register form with mismatched passwords should fail', () {
        final results = ValidationService.validateRegisterForm(
          email: 'test@example.com',
          password: 'Password123',
          confirmPassword: 'DifferentPassword',
        );

        expect(results['email']!.isValid, true);
        expect(results['password']!.isValid, true);
        expect(results['confirmPassword']!.isValid, false);
        expect(results['confirmPassword']!.errorMessage, 'Şifreler eşleşmiyor');
      });
    });

    group('Helper Functions', () {
      test('containsUppercase should detect uppercase letters', () {
        expect(ValidationService.containsUppercase('hello'), false);
        expect(ValidationService.containsUppercase('Hello'), true);
        expect(ValidationService.containsUppercase('HELLO'), true);
      });

      test('containsLowercase should detect lowercase letters', () {
        expect(ValidationService.containsLowercase('HELLO'), false);
        expect(ValidationService.containsLowercase('Hello'), true);
        expect(ValidationService.containsLowercase('hello'), true);
      });

      test('containsDigit should detect digits', () {
        expect(ValidationService.containsDigit('hello'), false);
        expect(ValidationService.containsDigit('hello123'), true);
        expect(ValidationService.containsDigit('123'), true);
      });

      test('containsInvalidChars should detect dangerous characters', () {
        expect(ValidationService.containsInvalidChars('hello'), false);
        expect(ValidationService.containsInvalidChars('hello<script>'), true);
        expect(ValidationService.containsInvalidChars('hello"world'), true);
        expect(ValidationService.containsInvalidChars('hello&world'), true);
        expect(ValidationService.containsInvalidChars('hello\'world'), true);
        expect(ValidationService.containsInvalidChars('hello<world'), true);
        expect(ValidationService.containsInvalidChars('hello>world'), true);
      });
    });
  });
}

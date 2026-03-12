import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandlerService {
  static void handleError(BuildContext context, dynamic error, {String? customMessage}) {
    debugPrint('❌ Error occurred: $error');
    
    String userMessage = _getUserFriendlyMessage(error, customMessage);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(userMessage)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showWarningMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String _getUserFriendlyMessage(dynamic error, String? customMessage) {
    if (customMessage != null) return customMessage;

    // Firebase Auth hataları
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Bu email ile kayıtlı kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Şifre hatalı. Lütfen tekrar deneyin.';
        case 'email-already-in-use':
          return 'Bu email zaten kullanımda.';
        case 'weak-password':
          return 'Şifre en az 6 karakter olmalıdır.';
        case 'invalid-email':
          return 'Geçersiz email adresi.';
        case 'user-disabled':
          return 'Hesabınız devre dışı bırakılmış.';
        case 'too-many-requests':
          return 'Çok fazla deneme. Lütfen bekleyin.';
        case 'network-request-failed':
          return 'İnternet bağlantınızı kontrol edin.';
        default:
          return 'Giriş hatası: ${error.message}';
      }
    }

    // Firebase Firestore hataları
    if (error.toString().contains('permission-denied')) {
      return 'Bu işlem için yetkiniz yok.';
    }
    if (error.toString().contains('not-found')) {
      return 'İstenen veri bulunamadı.';
    }
    if (error.toString().contains('unavailable')) {
      return 'Sunucu şu anda mevcut değil. Lütfen tekrar deneyin.';
    }
    if (error.toString().contains('deadline-exceeded')) {
      return 'İşlem zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
    }

    // Network hataları
    if (error.toString().contains('network') || error.toString().contains('connection')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }

    // Dosya yükleme hataları
    if (error.toString().contains('storage')) {
      return 'Dosya yüklenirken hata oluştu. Lütfen tekrar deneyin.';
    }

    // Genel hata mesajı
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable');
  }

  static bool isAuthError(dynamic error) {
    return error is FirebaseAuthException ||
           error.toString().contains('auth/') ||
           error.toString().contains('unauthenticated');
  }

  static bool isPermissionError(dynamic error) {
    return error.toString().contains('permission-denied') ||
           error.toString().contains('access-denied');
  }
}

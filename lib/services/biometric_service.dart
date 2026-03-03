import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isDeviceSupported() async {
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      return isSupported;
    } catch (e) {
      print('Biyometrik destek kontrolü hatası: $e');
      return false;
    }
  }

  static Future<bool> authenticate({
    String reason = 'iGaranti uygulamasına erişmek için kimliğinizi doğrulayın',
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biyometrik doğrulama hatası: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Biyometrik doğrulama hatası: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      print('Biyometrik türleri kontrolü hatası: $e');
      return [];
    }
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      print('Biyometrik kontrol hatası: $e');
      return false;
    }
  }

  static void stopAuthentication() {
    _auth.stopAuthentication();
  }
}

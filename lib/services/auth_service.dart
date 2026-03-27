import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: '465161482930-5jm3l56p225a7k5g9r3tp353lf8hmn0s.apps.googleusercontent.com',
  );

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google ile Giriş
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("Google Sign-In başlatılıyor...");
      
      // 1. Mevcut oturumu kontrol et ve temizle
      await _googleSignIn.signOut();
      
      // 2. Google oturum açma işlemini başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("Kullanıcı Google girişini iptal etti");
        return null;
      }

      debugPrint("Google kullanıcısı alındı: ${googleUser.email}");

      // 3. Google kimlik doğrulaması ayrıntılarını al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint("Google auth alındı, idToken: ${googleAuth.idToken != null ? 'var' : 'yok'}");

      // 4. Token kontrolü
      if (googleAuth.idToken == null) {
        debugPrint("Google idToken alınamadı");
        return null;
      }

      // 5. Firebase için yeni bir kimlik belgesi oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("Firebase credential oluşturuldu");

      // 6. Firebase'de oturum aç
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      debugPrint("Google ile giriş başarılı: ${userCredential.user?.email}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Hatası: ${e.code} - ${e.message}");
      _handleFirebaseError(e);
      return null;
    } catch (e) {
      debugPrint("Google SignIn Genel Hatası: $e");
      rethrow;
    }
  }

  // Apple ile Giriş
  Future<User?> signInWithApple() async {
    try {
      debugPrint("Apple Sign-In başlatılıyor...");
      
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      debugPrint("Apple ile giriş başarılı: ${userCredential.user?.email}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Hatası: ${e.code} - ${e.message}");
      _handleFirebaseError(e);
      return null;
    } catch (e) {
      debugPrint("Apple SignIn Genel Hatası: $e");
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Email/Password ile Giriş
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      debugPrint("Email ile giriş başarılı: ${userCredential.user?.email}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Email Auth Hatası: ${e.code} - ${e.message}");
      _handleFirebaseError(e);
      return null;
    } catch (e) {
      debugPrint("Email SignIn Genel Hatası: $e");
      rethrow;
    }
  }

  // Email/Password ile Kayıt
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      debugPrint("Email ile kayıt başarılı: ${userCredential.user?.email}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Email Kayıt Hatası: ${e.code} - ${e.message}");
      _handleFirebaseError(e);
      return null;
    } catch (e) {
      debugPrint("Email SignUp Genel Hatası: $e");
      rethrow;
    }
  }

  // Şifre Sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("Şifre sıfırlama email'i gönderildi: $email");
    } on FirebaseAuthException catch (e) {
      debugPrint("Şifre Sıfırlama Hatası: ${e.code} - ${e.message}");
      _handleFirebaseError(e);
    } catch (e) {
      debugPrint("Şifre Sıfırlama Genel Hatası: $e");
      rethrow;
    }
  }

  // Email Doğrulama Gönder
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint("Email doğrulama bağlantısı gönderildi: ${user.email}");
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Email Doğrulama Hatası: ${e.code} - ${e.message}");
      _handleFirebaseError(e);
    } catch (e) {
      debugPrint("Email Doğrulama Genel Hatası: $e");
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint("Çıkış yapıldı");
    } catch (e) {
      debugPrint("Çıkış hatası: $e");
    }
  }

  // Firebase hata yönetimi
  void _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        debugPrint('Bu email ile kayıtlı kullanıcı bulunamadı.');
        break;
      case 'wrong-password':
        debugPrint('Hatalı şifre.');
        break;
      case 'email-already-in-use':
        debugPrint('Bu email zaten kullanımda.');
        break;
      case 'weak-password':
        debugPrint('Şifre çok zayıf.');
        break;
      case 'invalid-email':
        debugPrint('Geçersiz email formatı.');
        break;
      case 'user-disabled':
        debugPrint('Kullanıcı hesabı devre dışı bırakılmış.');
        break;
      case 'too-many-requests':
        debugPrint('Çok fazla deneme. Lütfen sonra tekrar deneyin.');
        break;
      case 'network-request-failed':
        debugPrint('İnternet bağlantısı hatası.');
        break;
      default:
        debugPrint('Bilinmeyen auth hatası: ${e.code}');
    }
  }
}

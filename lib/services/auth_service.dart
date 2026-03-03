import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // E-posta ve Şifre ile Kayıt
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Kayıt Hatası: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Kayıt Hatası: $e");
      return null;
    }
  }

  // E-posta ve Şifre ile Giriş
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print("Giriş Hatası: $e");
      return null;
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
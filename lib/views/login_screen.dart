import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

import '../services/error_handler_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen email ve şifre girin.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (user != null) {
          if (!user.emailVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Lütfen önce email adresinizi doğrulayın."),
              ),
            );
            // Doğrulanmış olsun veya olmasın, ilk rotaya (main.dart'taki StreamBuilder'a) dön.
            // main.dart oradan EmailVerificationScreen veya MainScreen'i otomatik açacaktır.
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (mounted && user != null) {
        // Google ile girişte genellikle email zaten doğrulanmıştır.
        // Eğer değilse bile kullanıcıya bir şans veriyoruz veya main.dart'ın kontrol etmesini bekliyoruz.
        // Ekranları temizleyip köke (main.dart) dönüyoruz.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithApple();

      if (mounted && user != null) {
        // Ekranları temizleyip köke (main.dart) dönüyoruz.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePasswordReset() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifre sıfırlama için önce email adresinizi yazın."),
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        ErrorHandlerService.showSuccessMessage(
          context,
          "Şifre sıfırlama bağlantısı gönderildi.",
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Default dark background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Color(0xFF00D4FF),
              ),
              const SizedBox(height: 20),
              const Text(
                "iGaranti'ye Hoş Geldiniz",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Colors.white60,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white60,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handlePasswordReset,
                  child: const Text(
                    "Şifremi Unuttum",
                    style: TextStyle(color: Color(0xFF00D4FF)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _handleEmailSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4FF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Giriş Yap",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "VEYA",
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _handleGoogleSignIn,
                        icon: const Icon(Icons.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        label: const Text(
                          "Google ile Giriş Yap",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _handleAppleSignIn,
                          icon: const Icon(Icons.apple, size: 28),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          label: const Text(
                            "Apple ile Giriş Yap",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Hesabınız yok mu?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Kayıt Ol",
                            style: TextStyle(
                              color: Color(0xFF00D4FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

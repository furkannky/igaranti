import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _handleRegister() async {
    final user = await _authService.register(_emailController.text, _passwordController.text);
    if (user != null) {
      if (mounted) Navigator.pop(context); // Giriş ekranına dön veya Dashboard'a git
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt başarısız.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hesap Oluştur")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-posta")),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Şifre")),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _handleRegister, child: const Text("Kayıt Ol")),
          ],
        ),
      ),
    );
  }
}
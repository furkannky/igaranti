import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

class BiometricAuthScreen extends StatefulWidget {
  final Widget targetScreen;
  
  const BiometricAuthScreen({super.key, required this.targetScreen});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  bool _isAuthenticating = false;
  bool _authenticationFailed = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authenticationFailed = false;
    });

    final bool authenticated = await BiometricService.authenticate(
      reason: 'iGaranti uygulamasına erişmek için kimliğinizi doğrulayın',
    );

    if (authenticated) {
      if (mounted) {
        // Başarılı doğrulama, hedef ekrana git
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.targetScreen),
        );
      }
    } else {
      setState(() {
        _isAuthenticating = false;
        _authenticationFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo veya İkon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Başlık
              const Text(
                'iGaranti',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Açıklama
              const Text(
                'Uygulamaya erişmek için kimliğinizi doğrulayın',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Doğrulama Durumu
              if (_isAuthenticating)
                const Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Doğrulanıyor...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              else if (_authenticationFailed)
                Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Doğrulama Başarısız',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tekrar denemek için aşağıdaki butona basın',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
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

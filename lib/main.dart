import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:igaranti/controllers/product_controller.dart';
import 'package:igaranti/views/email_verification_screen.dart';
import 'package:igaranti/views/main_screen.dart';
import 'package:igaranti/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Türkçe locale'i başlat
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';

  runApp(const IGarantiApp());
}

class IGarantiApp extends StatefulWidget {
  const IGarantiApp({super.key});

  @override
  State<IGarantiApp> createState() => _IGarantiAppState();
}

class _IGarantiAppState extends State<IGarantiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Uygulama arka plandan geri geldiğinde auth state'i yenile
      FirebaseAuth.instance.currentUser?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductController(),
      child: MaterialApp(
        title: 'iGaranti',
        debugShowCheckedModeBanner: false,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Sadece koyu mod
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              if (!snapshot.data!.emailVerified) {
                return const EmailVerificationScreen();
              }
              return MainScreen(key: ValueKey(snapshot.data!.uid));
            }

            // Giriş yapmamış kullanıcılar için misafir modunda ana ekranı göster
            return const MainScreen(key: ValueKey('guest'));
          },
        ),
      ),
    );
  }
}

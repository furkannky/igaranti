import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'add_product_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Color bgColor = const Color(0xFF1A1A2E);
  final Color accentColor = const Color(0xFF00D4FF);
  int _currentIndex = 0;

  List<Widget> get _pages => [
    DashboardScreen(
      onTabChange: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    ),
    const AddProductScreen(), // Need to adjust AddProductScreen later to handle inner nav properly
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: bgColor,
          selectedItemColor: accentColor,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Panel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Ürün Ekle',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Bildirimler',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

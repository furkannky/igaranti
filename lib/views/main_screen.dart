import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dashboard_screen.dart';
import 'add_product_screen.dart';
import 'products_list_screen.dart';
import 'profile_screen.dart';
import '../models/product_filter_type.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Color bgColor = const Color(0xFF1A1A2E);
  final Color accentColor = const Color(0xFF00D4FF);
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late List<Widget> _pages;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(
        onTabChange: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        },
      ),
      AddProductScreen(
        onSaveCompleted: () {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        },
      ),
      const ProductsListScreen(
        filterType: ProductFilterType.all,
        title: 'Ürünlerim',
      ),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePopInvoked(bool didPop, [dynamic result]) {
    if (didPop) return;

    if (_currentIndex != 0) {
      // Ana sayfada değilse, ana sayfaya (Dashboard) dön
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Ana sayfadaysa, çıkış yapmak için çift tıklama bekle
      final now = DateTime.now();
      if (_lastPressedAt == null ||
          now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
        _lastPressedAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Çıkmak için bir kez daha geri tuşuna basın"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // 2 saniye içinde tekrar basılırsa uygulamadan çık
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        backgroundColor: bgColor,
        // PageView for smooth horizontal transition between tabs
        body: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe if preferred, otherwise can enable
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _pages,
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
          decoration: BoxDecoration(
            color: const Color(
              0xFF1E1E30,
            ), // Slightly different from bgColor for visibility
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                blurRadius: 15,
                color: Colors.black.withValues(alpha: .3),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.white10,
              hoverColor: Colors.white10,
              gap: 6,
              activeColor: Colors.white,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: accentColor.withValues(
                alpha: 0.2,
              ), // Pill background for active tab
              color: Colors.white54,
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Ana Sayfa'),
                GButton(icon: Icons.add_circle_outline_rounded, text: 'Ekle'),
                GButton(icon: Icons.list_alt_rounded, text: 'Ürünlerim'),
                GButton(icon: Icons.settings_rounded, text: 'Ayarlar'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

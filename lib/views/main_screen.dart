import 'package:flutter/material.dart';
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

  // We keep a PageController to allow smooth swiping between the tabs
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
    DashboardScreen(
      onTabChange: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      },
    ),
    const ProductsListScreen(
      filterType: ProductFilterType.all,
      title: 'Ürünlerim',
    ),
    AddProductScreen(
      onSaveCompleted: () {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      },
    ),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: .5),
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
            child: GNav(
              rippleColor: Colors.grey[800]!,
              hoverColor: Colors.grey[900]!,
              gap: 8,
              activeColor: bgColor,
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: accentColor,
              color: Colors.white60,
              tabs: const [
                GButton(icon: Icons.dashboard_rounded, text: 'Panel'),
                GButton(icon: Icons.inventory_2_outlined, text: 'Ürünlerim'),
                GButton(icon: Icons.add_circle_outline_rounded, text: 'Ekle'),
                GButton(icon: Icons.person_outline_rounded, text: 'Profil'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutQuint,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  }

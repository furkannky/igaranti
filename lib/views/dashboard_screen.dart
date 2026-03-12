import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../models/product_filter_type.dart';
import '../services/notification_service.dart';

import 'category_search_screen.dart';
import 'products_list_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color bgColor = const Color(0xFF1A1A2E);
  final Color accentColor = const Color(0xFF00D4FF);

  Stream<List<ProductModel>>? _productsStream;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productsStream ??= Provider.of<ProductController>(
      context,
      listen: false,
    ).getProducts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return SafeArea(
      child: Container(
        color: bgColor,
        child: _buildMainDashboard(isLoggedIn),
      ),
    );
  }

  Widget _buildMainDashboard(bool isLoggedIn) {
    return StreamBuilder<List<ProductModel>>(
      stream: isLoggedIn ? _productsStream : Stream.value([]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Hata: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];
        final isGuest = !isLoggedIn;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "🛡️ Garanti Takip Sistemi",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isGuest)
                        Container(
                          margin: const EdgeInsets.only(left: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            "Misafir",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isLoggedIn)
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStatsGrid(products, isGuest)),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    if (isGuest)
                      SliverToBoxAdapter(child: _buildGuestPromptCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    const SliverToBoxAdapter(
                      child: Text(
                        "Hızlı İşlemler",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _buildQuickActions(isGuest)),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  
  Widget _buildStatsGrid(List<ProductModel> products, bool isGuest) {
    int activeCount = products.where((p) => p.remainingDays > 0).length;
    int expiredCount = products.where((p) => p.remainingDays <= 0).length;
    int lowCount = products
        .where((p) => p.remainingDays > 0 && p.remainingDays <= 30)
        .length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildStatCard(
          "Toplam Ürün",
          products.length.toString(),
          Icons.inventory_2,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductsListScreen(
                  filterType: ProductFilterType.all,
                  title: "Tüm Ürünler",
                ),
              ),
            );
          },
          isGuest,
        ),
        _buildStatCard(
          "Aktif Garanti",
          activeCount.toString(),
          Icons.check_circle,
          Colors.green,
          () {
            if (activeCount == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aktif garantili ürününüz bulunmamaktadır.'),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductsListScreen(
                  filterType: ProductFilterType.active,
                  title: "Aktif Garantiler",
                ),
              ),
            );
          },
          isGuest,
        ),
        _buildStatCard(
          "Yaklaşan Bitiş",
          lowCount.toString(),
          Icons.warning,
          Colors.orange,
          () {
            if (lowCount == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Yaklaşan bitiş süresi olan ürününüz bulunmamaktadır.',
                  ),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductsListScreen(
                  filterType: ProductFilterType.expiring,
                  title: "Yaklaşan Bitişler",
                ),
              ),
            );
          },
          isGuest,
        ),
        _buildStatCard(
          "Biten Garanti",
          expiredCount.toString(),
          Icons.error,
          Colors.red,
          () {
            if (expiredCount == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Garantisi biten ürününüz bulunmamaktadır.'),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductsListScreen(
                  filterType: ProductFilterType.expired,
                  title: "Biten Garantiler",
                ),
              ),
            );
          },
          isGuest,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isGuest,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isGuest ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: isGuest ? 0.2 : 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color.withValues(alpha: isGuest ? 0.5 : 1.0), size: 40),
            const SizedBox(height: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: isGuest ? 0.7 : 1.0),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isGuest ? 0.5 : 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestPromptCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.withValues(alpha: 0.8),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Ürün eklemek için giriş yapın",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Garanti takip sisteminin tüm özelliklerini kullanmak ve ürün eklemek için hesabınıza giriş yapın.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Giriş Yap",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Kayıt ol ekranına yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Kayıt Ol",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isGuest) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 15;
        final double itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildQuickActionItem(
                "Kategoriler",
                Icons.category,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategorySearchScreen(),
                    ),
                  );
                },
                isGuest,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickActionItem(
                "Ürün Ekle",
                Icons.add_circle_outline,
                isGuest ? Colors.orange : Colors.green,
                () {
                  if (isGuest) {
                    // Misafir ise giriş yapmaya yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  } else {
                    // Giriş yapmış ise ürün ekleme ekranına yönlendir
                    widget.onTabChange?.call(2); // 3. tab (index 2) = Ürün Ekle
                  }
                },
                isGuest,
              ),
            ),
            if (isGuest)
              SizedBox(
                width: itemWidth,
                child: _buildQuickActionItem(
                  "Profil",
                  Icons.person_outline,
                  Colors.grey,
                  () {
                    // Misafir profil ekranı veya giriş yönlendirmesi
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profil özellikleri için giriş yapın"),
                      ),
                    );
                  },
                  isGuest,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isGuest,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isGuest ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: isGuest ? 0.3 : 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: isGuest ? 0.6 : 1.0), size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isGuest ? 0.7 : 1.0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

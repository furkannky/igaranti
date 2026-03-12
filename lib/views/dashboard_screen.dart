import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../models/product_filter_type.dart';
import '../services/notification_service.dart';

import 'category_search_screen.dart';
import 'products_list_screen.dart';
import 'notifications_screen.dart';

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
    return SafeArea(
      child: Container(
        color: bgColor,
        child: StreamBuilder<List<ProductModel>>(
          stream: _productsStream,
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

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        SliverToBoxAdapter(child: _buildStatsGrid(products)),
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
                        SliverToBoxAdapter(child: _buildQuickActions()),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<ProductModel> products) {
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
                builder: (context) => const ProductsListScreen(
                  filterType: ProductFilterType.all,
                  title: "Tüm Ürünler",
                ),
              ),
            );
          },
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
                builder: (context) => const ProductsListScreen(
                  filterType: ProductFilterType.active,
                  title: "Aktif Garantiler",
                ),
              ),
            );
          },
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
                builder: (context) => const ProductsListScreen(
                  filterType: ProductFilterType.expiring,
                  title: "Yaklaşan Bitişler",
                ),
              ),
            );
          },
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
                builder: (context) => const ProductsListScreen(
                  filterType: ProductFilterType.expired,
                  title: "Biten Garantiler",
                ),
              ),
            );
          },
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
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
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
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
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

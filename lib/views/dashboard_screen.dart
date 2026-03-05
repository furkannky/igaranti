import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import 'package:intl/intl.dart';
import 'product_detail_screen.dart';
import 'category_search_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color bgColor = const Color(0xFF1A1A2E);
  final Color accentColor = const Color(0xFF00D4FF);

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Stream<List<ProductModel>>? _productsStream;
  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    _notificationsEnabled = await _settingsService.getNotificationsEnabled();
    if (mounted) setState(() {});
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
    _searchController.dispose();
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
            final filteredProducts = products.where((p) {
              final matchesName = p.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
              final matchesBrand = p.brand.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
              return matchesName || matchesBrand;
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: kToolbarHeight,
                    child: Center(
                      child: Text(
                        "iGaranti Panel",
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  if (!_notificationsEnabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_off,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Bildirimler kapalı - Ayarlardan aktif edin",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        const SliverToBoxAdapter(
                          child: Text(
                            "Son Ürünler",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        SliverToBoxAdapter(child: _buildSearchBar()),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        if (filteredProducts.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Text(
                                  "Kayıtlı/aranan ürün bulunamadı.",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildProductCard(filteredProducts[index]),
                              childCount: filteredProducts.length,
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
        ),
        _buildStatCard(
          "Aktif Garanti",
          activeCount.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          "Yaklaşan Bitiş",
          lowCount.toString(),
          Icons.warning,
          Colors.orange,
        ),
        _buildStatCard(
          "Biten Garanti",
          expiredCount.toString(),
          Icons.error,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 10;
        final double itemWidth = (constraints.maxWidth - spacing * 2) / 3;
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
            SizedBox(
              width: itemWidth,
              child: _buildQuickActionItem(
                "Bildirimler",
                Icons.notifications,
                Colors.orange,
                () {
                  if (widget.onTabChange != null) widget.onTabChange!(2);
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickActionItem(
                "Ürün Ekle",
                Icons.add_circle,
                Colors.green,
                () {
                  if (widget.onTabChange != null) widget.onTabChange!(1);
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: "Ürün veya marka ara...",
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    searchQuery = "";
                  });
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (val) {
        setState(() {
          searchQuery = val.trim();
        });
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    Color statusColor = product.remainingDays < 30
        ? Colors.orange
        : Colors.green;
    if (product.remainingDays <= 0) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2, color: statusColor),
          ),
          title: Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            "${product.brand} - ${product.category}",
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.remainingDays > 0
                    ? "${product.remainingDays} gün"
                    : "Süresi Doldu",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(product.expiryDate),
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

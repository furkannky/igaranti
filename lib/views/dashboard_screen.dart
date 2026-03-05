import 'package:flutter/material.dart';
import 'package:igaranti/views/add_product_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import 'package:intl/intl.dart';
import 'product_detail_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Arama metnini tutacak değişken
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Stream<List<ProductModel>>? _productsStream; // Stream'i önbelleğe alıyoruz
  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();
  bool _notificationsEnabled = true;
  int _pendingNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    _notificationsEnabled = await _settingsService.getNotificationsEnabled();
    _updatePendingNotificationCount();
  }

  Future<void> _updatePendingNotificationCount() async {
    final pendingNotifications = await _notificationService
        .getPendingNotifications();
    setState(() {
      _pendingNotificationCount = pendingNotifications.length;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Stream sadece bir kere alınır, setState tetiklendiğinde (her tuş basışında)
    // yeni bir Firestore sorgusu atılması (ve ekranın sıfırlanması) engellenir.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "iGaranti Takip",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "Profil",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ).then((_) => _loadNotificationSettings());
            },
            icon: Stack(
              children: [
                Icon(
                  _notificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_none,
                  color: _notificationsEnabled
                      ? Colors.blueAccent
                      : Colors.grey,
                ),
                if (_pendingNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_pendingNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Veriler çekilirken bir hata oluştu:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint("❌ Gösterilecek ürün yok");
            return const Center(child: Text("Henüz kayıtlı ürünün yok."));
          }

          // Filtreleme Mantığı:
          // Arama kutusu boşsa tüm liste, doluysa filtrelenmiş liste döner.
          final filteredProducts = snapshot.data!.where((p) {
            final matchesName = p.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            final matchesBrand = p.brand.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            return matchesName || matchesBrand;
          }).toList();

          return Column(
            children: [
              _buildStats(
                snapshot.data!,
              ), // İstatistikler her zaman genel listeyi baz alsın
              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Ürün veya marka ara...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.blueAccent,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = "";
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) {
                          setState(() {
                            searchQuery = val.trim();
                          });
                        },
                        onChanged: (val) {
                          // Her harf girişinde canlı arama yapmak ve
                          // çarpı ikonunun anlık çıkıp/kaybolmasını sağlamak için:
                          setState(() {
                            searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Ürün Listesi
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Text("Aranan kriterde ürün bulunamadı."),
                      )
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(filteredProducts[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Yardımcı Widgetlar ---

  Widget _buildStats(List<ProductModel> products) {
    final expiringSoon = products
        .where((p) => p.remainingDays <= 7 && p.remainingDays > 0)
        .length;
    final expired = products.where((p) => p.remainingDays <= 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expiringSoon > 0
              ? Colors.orange.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Toplam", products.length.toString(), Colors.blue),
              _statItem(
                "Aktif",
                products.where((p) => p.remainingDays > 0).length.toString(),
                Colors.green,
              ),
              _statItem("Biten", expired.toString(), Colors.red),
            ],
          ),
          if (expiringSoon > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "$expiringSoon ürünün garantisi 7 gün içinde bitecek!",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!_notificationsEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
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
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    Color statusColor = product.remainingDays < 30
        ? Colors.orange
        : Colors.green;
    if (product.remainingDays <= 0) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(Icons.inventory_2, color: statusColor),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("${product.brand} - ${product.category}"),
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
              Text(
                DateFormat('dd/MM/yyyy').format(product.expiryDate),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

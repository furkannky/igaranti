import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../models/product_filter_type.dart';
import 'package:intl/intl.dart';
import 'product_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProductsListScreen extends StatefulWidget {
  final ProductFilterType filterType;
  final String title;

  const ProductsListScreen({
    super.key,
    required this.filterType,
    required this.title,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final Color bgColor = const Color(0xFF1A1A2E);
  final Color accentColor = const Color(0xFF00D4FF);
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();
  Stream<List<ProductModel>>? _productsStream;

  // Crash prevention flag
  final bool _isNavigating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sıralama tipi değiştiğinde yeni stream'i dinlemek için her seferinde güncellemeliyiz
    _productsStream = Provider.of<ProductController>(
      context,
      listen:
          true, // Listen true olmalı ki controller notify edince burası tekrar çalışsın
    ).getProducts();
  }

  @override
  bool get wantKeepAlive => true;

  List<ProductModel> _getSampleProducts() {
    return [
      ProductModel(
        id: 'sample1',
        name: 'iPhone 14 Pro',
        brand: 'Apple',
        model: 'A2889',
        category: 'Elektronik',
        purchaseDate: DateTime.now().subtract(const Duration(days: 200)),
        warrantyMonths: 24,
      ),
      ProductModel(
        id: 'sample2',
        name: 'Samsung Galaxy S23',
        brand: 'Samsung',
        model: 'SM-S911B',
        category: 'Elektronik',
        purchaseDate: DateTime.now().subtract(const Duration(days: 150)),
        warrantyMonths: 24,
      ),
      ProductModel(
        id: 'sample3',
        name: 'Dyson V15',
        brand: 'Dyson',
        model: 'V15 Detect',
        category: 'Ev Gereçleri',
        purchaseDate: DateTime.now().subtract(const Duration(days: 400)),
        warrantyMonths: 24,
      ),
      ProductModel(
        id: 'sample4',
        name: 'MacBook Air M2',
        brand: 'Apple',
        model: 'MLY33',
        category: 'Elektronik',
        purchaseDate: DateTime.now().subtract(const Duration(days: 100)),
        warrantyMonths: 12,
      ),
      ProductModel(
        id: 'sample5',
        name: 'Beko NoFrost',
        brand: 'Beko',
        model: 'GN163123X',
        category: 'Mutfak',
        purchaseDate: DateTime.now().subtract(const Duration(days: 700)),
        warrantyMonths: 36,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<ProductController>(
            builder: (context, controller, child) {
              return PopupMenuButton<ProductSortType>(
                icon: const Icon(Icons.sort_rounded),
                tooltip: "Sıralama",
                onSelected: (ProductSortType result) {
                  controller.setSortType(result);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<ProductSortType>>[
                      PopupMenuItem<ProductSortType>(
                        value: ProductSortType.shortestWarranty,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                              color:
                                  controller.sortType ==
                                      ProductSortType.shortestWarranty
                                  ? accentColor
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kalan: Azdan Çoğa',
                              style: TextStyle(
                                color:
                                    controller.sortType ==
                                        ProductSortType.shortestWarranty
                                    ? accentColor
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<ProductSortType>(
                        value: ProductSortType.longestWarranty,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                              color:
                                  controller.sortType ==
                                      ProductSortType.longestWarranty
                                  ? accentColor
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kalan: Çoktan Aza',
                              style: TextStyle(
                                color:
                                    controller.sortType ==
                                        ProductSortType.longestWarranty
                                    ? accentColor
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
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

          List<ProductModel> allProducts = snapshot.data ?? [];
          List<ProductModel> filteredProducts = allProducts;
          final isGuest = FirebaseAuth.instance.currentUser == null;

          // Misafir kullanıcı için örnek veriler
          if (isGuest && allProducts.isEmpty) {
            allProducts = _getSampleProducts();
          }

          // Apply base filter
          switch (widget.filterType) {
            case ProductFilterType.all:
              break;
            case ProductFilterType.active:
              filteredProducts = allProducts
                  .where((p) => p.remainingDays > 0)
                  .toList();
              break;
            case ProductFilterType.expiring:
              filteredProducts = allProducts
                  .where((p) => p.remainingDays > 0 && p.remainingDays <= 30)
                  .toList();
              break;
            case ProductFilterType.expired:
              filteredProducts = allProducts
                  .where((p) => p.remainingDays <= 0)
                  .toList();
              break;
          }

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            final searchQuery = _searchQuery.toLowerCase();
            filteredProducts = filteredProducts.where((p) {
              return p.name.toLowerCase().contains(searchQuery) ||
                  p.brand.toLowerCase().contains(searchQuery);
            }).toList();
          }

          return Column(
            children: [
              // Misafir kullanıcı için bilgilendirme mesajı
              if (isGuest)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Bu farazi örnek ürünlerdir. Kendi ürünlerinizi ekleyince gerçek ürünleriniz görünecektir.",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Ürün veya marka ara...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.requestFocus();
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
                  onChanged: (value) {
                    // Listener handles the state update
                  },
                ),
              ),

              // Filtre Sonuçları
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState(
                        context,
                        isGuest: FirebaseAuth.instance.currentUser == null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(
                            filteredProducts[index],
                            isGuest,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, bool isGuest) {
    Color statusColor;
    String statusText;

    if (product.remainingDays > 30) {
      statusColor = const Color(0xFF00E676); // Green A400
      int months = product.remainingDays ~/ 30;
      statusText = "Devam Ediyor ($months ay)";
    } else if (product.remainingDays > 0) {
      statusColor = const Color(0xFFFFC400); // Amber A400
      statusText = "Yakında Bitecek (${product.remainingDays} gün kaldı)";
    } else {
      statusColor = const Color(0xFFFF1744); // Red A400
      statusText = "Süresi Doldu";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(
        0xFF1E1E36,
      ), // A slightly lighter/vibrant dark blue instead of green
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          if (isGuest) {
            _showGuestProductDialog(context);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category Chip and Delete Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(product.category),
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              product.category,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                      size: 22,
                    ),
                    onPressed: () {
                      _showDeleteConfirmation(context, product);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Name
              Text(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize:
                      22, // Biraz küçültüldü ki altına gelecek alanla dengeli dursun
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Brand & Model
              Text(
                "${product.brand} • ${product.model}",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Purchase Date Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Alış: ${DateFormat('dd.MM.yyyy').format(product.purchaseDate)}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      product.remainingDays > 0
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('elektronik')) return Icons.tv;
    if (category.toLowerCase().contains('beyaz eşya')) return Icons.kitchen;
    if (category.toLowerCase().contains('bilgisayar')) return Icons.computer;
    if (category.toLowerCase().contains('telefon')) return Icons.smartphone;
    return Icons.category;
  }

  void _showGuestProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Örnek Ürün", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Bu bir farazi örnek üründür. Kendi ürünlerinizi eklediğinizde, burada gördüğünüz gibi gerçek ürünleriniz görünecektir. Detayları görmek ve ürün eklemek için giriş yapmalısınız.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              "Giriş Yap",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Ürünü Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          '${product.name} ürününü silmek istediğinize emin misiniz?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ProductController>(
                context,
                listen: false,
              ).deleteProduct(product.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Ürün silindi')));
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isGuest}) {
    final bool isSearching = _searchController.text.isNotEmpty;

    String title = "Kasa Boş";
    String subtitle =
        "Henüz hiç ürün eklememişsiniz. İlk ürününüzü ekleyerek takibe başlayın!";
    IconData icon = Icons.inventory_2_rounded;

    if (isGuest) {
      title = "Oturum Açın";
      subtitle =
          "Ürünlerinizi ve garanti sürelerinizi takip etmek için giriş yapmalısınız.";
      icon = Icons.lock_outline_rounded;
    } else if (isSearching) {
      title = "Sonuç Bulunamadı";
      subtitle =
          "Aradığınız kriterlere uygun ürün bulunamadı. Lütfen aramayı düzenleyin.";
      icon = Icons.search_off_rounded;
    } else {
      // Filter specific empty states
      switch (widget.filterType) {
        case ProductFilterType.active:
          title = "Aktif Garanti Yok";
          subtitle =
              "Şu anda garanti süresi devam eden bir ürününüz bulunmuyor.";
          icon = Icons.check_circle_outline_rounded;
          break;
        case ProductFilterType.expiring:
          title = "Yaklaşan Bitiş Yok";
          subtitle =
              "Önümüzdeki 30 gün içinde garantisi bitecek bir ürününüz bulunmuyor. Her şey yolunda!";
          icon = Icons.notifications_none_rounded;
          break;
        case ProductFilterType.expired:
          title = "Biten Garanti Yok";
          subtitle = "Garantisi dolmuş herhangi bir ürününüz bulunmamaktadır.";
          icon = Icons.history_rounded;
          break;
        case ProductFilterType.all:
          title = "Kasa Boş";
          subtitle =
              "Henüz hiç ürün eklememişsiniz. İlk ürününüzü ekleyerek takibe başlayın!";
          icon = Icons.inventory_2_rounded;
          break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 16.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00D4FF,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 60,
                              color: const Color(0xFF00D4FF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          if (isGuest)
                            ElevatedButton(
                              onPressed: () {
                                if (_isNavigating) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4FF),
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Giriş Yap",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (isSearching)
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00D4FF),
                                side: const BorderSide(
                                  color: Color(0xFF00D4FF),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Aramayı Temizle",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () {
                                // Notify the user or use a scaffold messenger for now
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Yeni ürün eklemek için '+' butonuna tıklayın.",
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("Ürün Ekle"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4FF),
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

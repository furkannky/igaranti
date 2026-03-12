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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productsStream ??= Provider.of<ProductController>(
      context,
      listen: false,
    ).getProducts();
  }

  @override
  bool get wantKeepAlive => true;

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
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white54,
                            ),
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FirebaseAuth.instance.currentUser == null
                                  ? Icons.login_rounded
                                  : Icons.inbox_rounded,
                              size: 60,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              FirebaseAuth.instance.currentUser == null
                                  ? "Ürünlerinizi görmek için giriş yapmalısınız."
                                  : "Kayıtlı/aranan ürün bulunamadı.",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (FirebaseAuth.instance.currentUser == null) ...[
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
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
                                ),
                                child: const Text(
                                  "Giriş Yap",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildProductCard(ProductModel product) {
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
                        mainAxisSize: MainAxisSize.min,
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
                              style: const TextStyle(
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
                    icon: const Icon(
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
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Purchase Date Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Alış: ${DateFormat('dd.MM.yyyy').format(product.purchaseDate)}",
                      style: const TextStyle(
                        color: Colors.white,
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
}

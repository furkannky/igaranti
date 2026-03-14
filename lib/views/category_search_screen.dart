import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart';

class CategorySearchScreen extends StatefulWidget {
  const CategorySearchScreen({super.key});

  @override
  State<CategorySearchScreen> createState() => _CategorySearchScreenState();
}

class _CategorySearchScreenState extends State<CategorySearchScreen> {
  final Map<String, IconData> _categoryIcons = {
    'Elektronik': Icons.devices,
    'Mutfak': Icons.kitchen,
    'Ev Gereçleri': Icons.home,
    'Mobilya': Icons.chair,
    'Diğer': Icons.category,
  };

  final Map<String, Color> _categoryColors = {
    'Elektronik': Colors.blue,
    'Mutfak': Colors.orange,
    'Ev Gereçleri': Colors.green,
    'Mobilya': Colors.brown,
    'Diğer': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kategorilere Göre Ara",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ProductController>(
        builder: (context, productController, child) {
          return StreamBuilder<List<ProductModel>>(
            stream: productController.getProducts(),
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

              final isGuest = FirebaseAuth.instance.currentUser == null;
              final products = snapshot.data ?? [];

              Map<String, int> categories = _getCategoriesWithCounts(products);
              int totalProductsCount = products.length;

              // Misafir kullanıcı için mock veriler
              if (isGuest && products.isEmpty) {
                categories = {
                  'Elektronik': 12,
                  'Mutfak': 5,
                  'Ev Gereçleri': 3,
                  'Mobilya': 2,
                };
                totalProductsCount = 22;
              }

              return Column(
                children: [
                  // Misafir kullanıcı için bilgilendirme mesajı
                  if (isGuest)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Kategorilerdeki ürünler farazi örneklerdir. Kendi ürünlerinizi ekleyince gerçek ürünleriniz görünecektir.",
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
                  // Kategori İstatistikleri
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kategori Dağılımı",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...categories.entries.map((entry) {
                          return _buildCategoryStat(
                            entry.key,
                            totalProductsCount,
                            entry.value,
                          );
                        }),
                      ],
                    ),
                  ),

                  // Kategori Kartları
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                      itemCount: categories.keys.length,
                      itemBuilder: (context, index) {
                        final category = categories.keys.elementAt(index);
                        final count = categories[category]!;
                        return _buildCategoryCard(
                          category,
                          count,
                          products,
                          isGuest,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<String, int> _getCategoriesWithCounts(List<ProductModel> products) {
    final Map<String, int> categoryCounts = {};
    for (final product in products) {
      categoryCounts[product.category] =
          (categoryCounts[product.category] ?? 0) + 1;
    }
    return categoryCounts;
  }

  Widget _buildCategoryStat(
    String category,
    int totalProducts,
    int categoryProducts,
  ) {
    final percentage = totalProducts > 0
        ? (categoryProducts / totalProducts * 100).round()
        : 0;
    final color = _categoryColors[category] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _categoryIcons[category] ?? Icons.category,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            "$categoryProducts ürün ($percentage%)",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String category,
    int count,
    List<ProductModel> allProducts,
    bool isGuest,
  ) {
    final icon = _categoryIcons[category] ?? Icons.category;
    final color = _categoryColors[category] ?? Colors.grey;
    final categoryProducts = allProducts
        .where((p) => p.category == category)
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryProductsScreen(
                category: category,
                products: categoryProducts,
                isGuest: isGuest,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$count ürün",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryProductsScreen extends StatelessWidget {
  final String category;
  final List<ProductModel> products;
  final bool isGuest;

  const CategoryProductsScreen({
    super.key,
    required this.category,
    required this.products,
    this.isGuest = false,
  });

  List<ProductModel> _getSampleProducts() {
    return [
      ProductModel(
        id: 'sample1',
        name: '$category Örnek Ürün 1',
        brand: 'Örnek Marka',
        model: 'Örnek Model A',
        category: category,
        purchaseDate: DateTime.now().subtract(const Duration(days: 365)),
        warrantyMonths: 24,
      ),
      ProductModel(
        id: 'sample2',
        name: '$category Örnek Ürün 2',
        brand: 'Örnek Marka',
        model: 'Örnek Model B',
        category: category,
        purchaseDate: DateTime.now().subtract(const Duration(days: 700)),
        warrantyMonths: 24,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final displayProducts = isGuest ? _getSampleProducts() : products;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$category Kategorisi",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          if (isGuest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.withValues(alpha: 0.2),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Şu anda kategorideki ürünlerin farazi örneklerini görüyorsunuz. Kendi ürünlerinizi ekleyince bu görünümdeki gibi gerçek ürünleriniz görünecektir.",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: displayProducts.isEmpty
                ? const Center(child: Text("Bu kategoride ürün bulunmuyor."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(context, displayProducts[index]);
                    },
                  ),
          ),
          if (isGuest)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Ürünlerimi Görmek İçin Giriş Yap",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    Color statusColor = product.remainingDays < 30
        ? Colors.orange
        : Colors.green;
    if (product.remainingDays <= 0) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (isGuest) {
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
                    child: const Text("Giriş Yap", style: TextStyle(color: Colors.blueAccent)),
                  ),
                ],
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.2),
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
                DateFormat('dd.MM.yyyy').format(product.expiryDate),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';
import 'product_detail_screen.dart';

class CategoryFilterScreen extends StatefulWidget {
  const CategoryFilterScreen({super.key});

  @override
  State<CategoryFilterScreen> createState() => _CategoryFilterScreenState();
}

class _CategoryFilterScreenState extends State<CategoryFilterScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kategori Filtresi",
          style: TextStyle(fontWeight: FontWeight.bold),
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

          final allProducts = snapshot.data ?? [];
          final categories = _getCategoriesWithCounts(allProducts);

          List<ProductModel> filteredProducts = allProducts;
          if (_selectedCategory != null) {
            filteredProducts = allProducts
                .where((p) => p.category == _selectedCategory)
                .toList();
          }

          // Arama filtresi
          if (_searchController.text.isNotEmpty) {
            final searchQuery = _searchController.text.toLowerCase();
            filteredProducts = filteredProducts.where((p) {
              return p.name.toLowerCase().contains(searchQuery) ||
                  p.brand.toLowerCase().contains(searchQuery);
            }).toList();
          }

          return Column(
            children: [
              // Kategori Seçimi
              Container(
                height: 120,
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.keys.length + 1, // +1 for "Tümü"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "Tümü" seçeneği
                      return _buildCategoryChip(
                        "Tümü",
                        allProducts.length,
                        Icons.apps,
                        Colors.grey,
                        _selectedCategory == null,
                        () {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                      );
                    }

                    final category = categories.keys.elementAt(index - 1);
                    final count = categories[category]!;
                    final icon = _categoryIcons[category] ?? Icons.category;
                    final color = _categoryColors[category] ?? Colors.grey;

                    return _buildCategoryChip(
                      category,
                      count,
                      icon,
                      color,
                      _selectedCategory == category,
                      () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  },
                ),
              ),

              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _selectedCategory != null
                        ? "$_selectedCategory kategorisinde ara..."
                        : "Tüm ürünlerde ara...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Filtre Sonuçları
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          _selectedCategory != null
                              ? "$_selectedCategory kategorisinde ürün bulunamadı."
                              : "Ürün bulunamadı.",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
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

  Map<String, int> _getCategoriesWithCounts(List<ProductModel> products) {
    final Map<String, int> categoryCounts = {};
    for (final product in products) {
      categoryCounts[product.category] =
          (categoryCounts[product.category] ?? 0) + 1;
    }
    return categoryCounts;
  }

  Widget _buildCategoryChip(
    String category,
    int count,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 24),
              const SizedBox(height: 4),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "$count",
                style: TextStyle(
                  color: isSelected
                      ? Colors.white70
                      : color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    Color statusColor = product.remainingDays < 30
        ? Colors.orange
        : Colors.green;
    if (product.remainingDays <= 0) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
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

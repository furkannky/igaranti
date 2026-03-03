import 'package:flutter/material.dart';
import 'package:igaranti/services/auth_service.dart';
import 'package:igaranti/views/add_product_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Arama metnini tutacak değişken
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("iGaranti Takip", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productController.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz kayıtlı ürünün yok."));
          }

          // Filtreleme Mantığı:
          // Arama kutusu boşsa tüm liste, doluysa filtrelenmiş liste döner.
          final filteredProducts = snapshot.data!.where((p) {
            final matchesName = p.name.toLowerCase().contains(searchQuery.toLowerCase());
            final matchesBrand = p.brand.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesName || matchesBrand;
          }).toList();

          return Column(
            children: [
              _buildStats(snapshot.data!), // İstatistikler her zaman genel listeyi baz alsın

              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Ürün veya marka ara...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (val) {
                    // Kullanıcı yazdıkça UI güncellenir
                    setState(() {
                      searchQuery = val;
                    });
                  },
                ),
              ),

              // Ürün Listesi
              Expanded(
                child: filteredProducts.isEmpty 
                  ? const Center(child: Text("Aranan kriterde ürün bulunamadı."))
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
            MaterialPageRoute(builder: (context) => const AddProductScreen())
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Yardımcı Widgetlar ---

  Widget _buildStats(List<ProductModel> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Toplam", products.length.toString()),
          _statItem("Aktif", products.where((p) => p.remainingDays > 0).length.toString()),
          _statItem("Biten", products.where((p) => p.remainingDays <= 0).length.toString()),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    Color statusColor = product.remainingDays < 30 ? Colors.orange : Colors.green;
    if (product.remainingDays <= 0) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.inventory_2, color: statusColor),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${product.brand} - ${product.category}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              product.remainingDays > 0 ? "${product.remainingDays} gün" : "Süresi Doldu",
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            Text(DateFormat('dd/MM/yyyy').format(product.expiryDate), style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
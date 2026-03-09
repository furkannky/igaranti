import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:igaranti/services/pdf_service.dart';
import 'package:igaranti/services/calendar_service.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../controllers/product_controller.dart';
import 'edit_product_screen.dart';
import 'add_service_record_screen.dart'; // YENİ EKLENDİ

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? product;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final productController = Provider.of<ProductController>(context, listen: false);
    final products = await productController.getProducts().first;
    final foundProduct = products.firstWhere((p) => p.id == widget.productId);
    
    setState(() {
      product = foundProduct;
      isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Edit ekranından döndüğünde veriyi yenile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProduct();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Ürün Detayı")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Garanti durumu rengi hesaplama
    Color statusColor = product!.remainingDays < 30
        ? Colors.orange
        : Colors.green;
    if (product!.remainingDays <= 0) statusColor = Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(product!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: product!),
                ),
              );
              // Edit ekranından döndüğünde veriyi yenile
              if (result == true && mounted) {
                _loadProduct();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final success = await CalendarService.addWarrantyExpiryReminder(
                productName: product!.name,
                brand: product!.brand,
                expiryDate: product!.expiryDate,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Takvim hatırlatıcısı eklendi!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Takvim eklenemedi!')),
                );
              }
            },
            tooltip: "Takvim Ekle",
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfService.generateProductReport(product!),
            tooltip: "PDF Raporu Oluştur",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ürün Bilgi Kartı (Özet Bilgiler)
            _buildInfoCard(statusColor),
            const SizedBox(height: 25),

            // 2. Fatura Görseli Bölümü
            const Text(
              "Fatura ve Belgeler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInvoiceSection(),
            const SizedBox(height: 25),

            // 3. Yaşam Döngüsü (Servis Kayıtları) Bölümü
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Yaşam Döngüsü",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Yeni Kayıt Ekleme Butonu
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddServiceRecordScreen(product: product!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_moderator, size: 20),
                  label: const Text("Yeni Kayıt"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildServiceHistoryList(),
            const SizedBox(height: 25),

            // 4. Destek ve Servis Butonları
            const Text(
              "Destek",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {}, // Marka destek hattı araması için
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.phone_forwarded),
                label: const Text("Yetkili Servis ile İletişime Geç"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Fatura / Görsel Bölümü Widget'ı
  Widget _buildInvoiceSection() {
    // Tüm görselleri topla (Eski ve Yeni)
    List<String> allImages = [];
    if (product!.imageUrls != null && product!.imageUrls!.isNotEmpty) {
      allImages.addAll(product!.imageUrls!);
    } else if (product!.invoiceImageUrl != null) {
      allImages.add(product!.invoiceImageUrl!);
    }

    if (allImages.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 50, color: Colors.white54),
            SizedBox(height: 8),
            Text(
              "Fatura veya Görsel Eklenmemiş",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // Birden fazla fotoğraf varsa yatay scroll edilebilir liste göster
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          final imageUrl = allImages[index];
          return GestureDetector(
            onTap: () {
              // Görseli tam ekran açma işlevi eklenebilir
              debugPrint("Resme tıklandı: $imageUrl");
            },
            child: Container(
              width: 140, // Sabit genişlik
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Servis Geçmişi Listesi Widget'ı
  Widget _buildServiceHistoryList() {
    if (product!.serviceHistory == null || product!.serviceHistory!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Text(
            "Henüz bir servis veya bakım kaydı bulunmuyor.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: product!.serviceHistory!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = product!.serviceHistory![index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              child: const Icon(
                Icons.build_circle_outlined,
                color: Colors.blue,
              ),
            ),
            title: Text(
              record.description,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(DateFormat('dd MMMM yyyy').format(record.date)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${record.price.toStringAsFixed(2)} TL",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (record.documentUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: InkWell(
                      onTap: () {
                        // TODO: İleride tam ekran belge görüntüleme (Zoom) yapılacak
                        debugPrint("Belgeye tıklandı: ${record.documentUrl}");
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attachment,
                            size: 16,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Belge",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Üst Bilgi Kartı
  Widget _buildInfoCard(Color statusColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product!.brand,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      product!.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product!.remainingDays > 0 ? "GARANTİ VAR" : "SÜRESİ DOLDU",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _infoRow(
              "Satın Alma:",
              DateFormat('dd/MM/yyyy').format(product!.purchaseDate),
            ),
            const SizedBox(height: 8),
            _infoRow(
              "Garanti Bitiş:",
              DateFormat('dd/MM/yyyy').format(product!.expiryDate),
            ),
            const SizedBox(height: 8),
            _infoRow(
              "Kalan Süre:",
              "${product!.remainingDays} Gün",
              valueColor: statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 15),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:igaranti/services/calendar_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../controllers/product_controller.dart';
import 'edit_product_screen.dart';
import 'add_service_record_screen.dart'; // YENİ EKLENDİ
import 'login_screen.dart';
import 'pdf_viewer_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);
    final isGuest = FirebaseAuth.instance.currentUser == null;
    
    if (isGuest) {
      return _buildGuestView();
    }

    return StreamBuilder<List<ProductModel>>(
      stream: productController.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("Ürün Detayı")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Hata")),
            body: Center(child: Text("Bir hata oluştu: ${snapshot.error}")),
          );
        }

        final products = snapshot.data ?? [];
        final product = products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () => ProductModel(
            name: "Yükleniyor...",
            brand: "",
            model: "",
            purchaseDate: DateTime.now(),
            warrantyMonths: 0,
            category: "",
          ),
        );

        if (product.id == null && product.name == "Yükleniyor...") {
           return Scaffold(
            appBar: AppBar(title: const Text("Ürün Bulunamadı")),
            body: const Center(child: Text("Ürün bulunamadı veya silinmiş.")),
          );
        }

        // Garanti durumu rengi hesaplama
        Color statusColor = product.remainingDays < 30 ? Colors.orange : Colors.green;
        if (product.remainingDays <= 0) statusColor = Colors.red;

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductScreen(product: product),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final success = await CalendarService.addWarrantyExpiryReminder(
                    productName: product.name,
                    brand: product.brand,
                    expiryDate: product.expiryDate,
                  );
                  if (success) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Takvim hatırlatıcısı eklendi!')),
                    );
                  }
                },
                tooltip: "Takvim Ekle",
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(product, statusColor),
                const SizedBox(height: 15),
                if (product.note != null && product.note!.trim().isNotEmpty) ...[
                  _buildNoteSection(product),
                  const SizedBox(height: 25),
                ],
                if (product.imageUrls != null && product.imageUrls!.isNotEmpty) ...[
                  const Text("Ürün Fotoğrafları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildProductPhotosSection(product),
                  const SizedBox(height: 25),
                ],
                const Text("Fatura ve Belgeler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildInvoiceSection(product),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Yaşam Döngüsü", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddServiceRecordScreen(product: product)),
                        );
                      },
                      icon: const Icon(Icons.add_moderator, size: 20),
                      label: const Text("Yeni Kayıt"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildServiceHistoryList(product),
                const SizedBox(height: 25),
                if (product.supportNumber != null && product.supportNumber!.isNotEmpty) ...[
                  const Text("Destek", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildSupportButton(product),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteSection(ProductModel product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_alt_outlined, size: 18, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text("Notlar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(product.note!.trim(), style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSupportButton(ProductModel product) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _callSupportNumber(product.supportNumber!),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          foregroundColor: Colors.green,
        ),
        icon: const Icon(Icons.phone_forwarded),
        label: Text("${product.supportNumber!} • Ara"),
      ),
    );
  }

  // Ürün Fotoğrafları Bölümü Widget'ı
  Widget _buildProductPhotosSection(ProductModel product) {
    if (product.imageUrls == null || product.imageUrls!.isEmpty) return const SizedBox.shrink();
    
    final List<String> imageFiles = product.imageUrls!.where((url) => 
        !ProductModel.isPdfUrl(url)).toList();

    if (imageFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageFiles.length,
        itemBuilder: (context, index) {
          final imageUrl = imageFiles[index];
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl, 'product_image_$imageUrl'),
            child: Hero(
              tag: 'product_image_$imageUrl',
              child: Container(
                width: 140, // Sabit genişlik
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Resim yükleme hatası: $imageUrl - $error');
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Resim\nYüklenemedi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Fatura / Görsel Bölümü Widget'ı
  Widget _buildInvoiceSection(ProductModel product) {
    if (product.invoiceImageUrl == null || product.invoiceImageUrl?.isEmpty == true) {
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
              "Fatura veya Belge Eklenmemiş",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    final imageUrl = product.invoiceImageUrl!;
    final isPdf = imageUrl.toLowerCase().contains('.pdf');
    
    debugPrint('🔍 Fatura URL: $imageUrl');
    debugPrint('🔍 PDF mi?: $isPdf');

    // Sadece PDF ise göster, resim ise gösterme
    if (!isPdf) {
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
              "Fatura veya Belge Eklenmemiş",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // PDF'i PDFViewerScreen'de aç
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(
              pdfUrl: imageUrl,
              title: 'Garanti Belgesi/Fatura',
            ),
          ),
        );
      },
      child: Hero(
        tag: 'invoice_$imageUrl',
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: Colors.redAccent,
                size: 50,
              ),
              SizedBox(height: 8),
              Text(
                "PDF Belgesini Gör",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, String heroTag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          extendBodyBehindAppBar: true,
          body: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Tam ekran resim hatası: $imageUrl - $error');
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 80,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Resim Yüklenemedi',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Servis Geçmişi Listesi Widget'ı
  Widget _buildServiceHistoryList(ProductModel product) {
    if (product.serviceHistory == null || product.serviceHistory!.isEmpty) {
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
      itemCount: product.serviceHistory!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = product.serviceHistory![index];
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
            subtitle: Text(DateFormat('dd.MM.yyyy').format(record.date)),
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
  Widget _buildInfoCard(ProductModel product, Color statusColor) {
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
                      product.brand.trim().isEmpty ? "Belirtilmemiş" : product.brand,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      product.name,
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
                    product.remainingDays > 0 ? "GARANTİ VAR" : "SÜRESİ DOLDU",
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
              DateFormat('dd.MM.yyyy').format(product.purchaseDate),
            ),
            const SizedBox(height: 8),
            _infoRow(
              "Garanti Bitiş:",
              DateFormat('dd.MM.yyyy').format(product.expiryDate),
            ),
            const SizedBox(height: 8),
            _infoRow(
              "Kalan Süre:",
              "${product.remainingDays} Gün",
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

  Future<void> _callSupportNumber(String phoneNumber) async {
    try {
      // Telefon numarasını temizle (sadece rakamlar)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$cleanNumber');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arama yapılamadı: $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Arama hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Örnek Ürün Detayı"),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Örnek Ürün Detayı",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Bu bir farazi örnek ürün detayıdır. Kendi ürünlerinizin detaylarını görmek ve yönetmek için giriş yapmalısınız.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Giriş Yap",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

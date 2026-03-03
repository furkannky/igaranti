import 'package:flutter/material.dart';
import 'package:igaranti/services/pdf_service.dart';
import 'package:igaranti/services/calendar_service.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
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
              // Ürün düzenleme sayfasına gidebilir
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Takvim hatırlatıcısı eklendi!')),
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
    onPressed: () => PdfService.generateProductReport(product),
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
            const Text("Fatura ve Belgeler",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildInvoiceSection(),
            const SizedBox(height: 25),

            // 3. Yaşam Döngüsü (Servis Kayıtları) Bölümü
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Yaşam Döngüsü",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                // Yeni Kayıt Ekleme Butonu
                TextButton.icon(
                  onPressed: () {
                    // Not: Bu sayfa henüz oluşturulmadıysa hata verebilir, 
                    // ismini projenize göre güncelleyin.
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddServiceRecordScreen(product: product)));
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
            const Text("Destek",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {}, // Marka destek hattı araması için
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blueGrey[50],
                  foregroundColor: Colors.blueGrey[800],
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

  // Fatura Görseli Widget'ı
  Widget _buildInvoiceSection() {
    return GestureDetector(
      onTap: () {
        // Görseli tam ekran açma işlevi buraya
      },
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
          image: product.invoiceImageUrl != null
              ? DecorationImage(
                  image: NetworkImage(product.invoiceImageUrl!),
                  fit: BoxFit.cover)
              : null,
        ),
        child: product.invoiceImageUrl == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Fatura Görseli Eklenmemiş",
                      style: TextStyle(color: Colors.grey)),
                ],
              )
            : null,
      ),
    );
  }

  // Servis Geçmişi Listesi Widget'ı
  Widget _buildServiceHistoryList() {
    if (product.serviceHistory == null || product.serviceHistory!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            "Henüz bir servis veya bakım kaydı bulunmuyor.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:BorderSide(color: Colors.grey[200]!)
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: const Icon(Icons.build_circle_outlined, color: Colors.blue),
            ),
            title: Text(record.description,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('dd MMMM yyyy').format(record.date)),
            trailing: Text(
              "${record.price.toStringAsFixed(2)} TL",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        );
      },
    );
  }

  // Üst Bilgi Kartı
  Widget _buildInfoCard(Color statusColor) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    Text(product.brand,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.blueGrey)),
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.remainingDays > 0 ? "GARANTİ VAR" : "SÜRESİ DOLDU",
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _infoRow("Satın Alma:", DateFormat('dd/MM/yyyy').format(product.purchaseDate)),
            const SizedBox(height: 8),
            _infoRow("Garanti Bitiş:", DateFormat('dd/MM/yyyy').format(product.expiryDate)),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}
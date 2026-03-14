import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bildirim Merkezi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Bildirim Ayarları",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductController>(
        builder: (context, controller, child) {
          return StreamBuilder<List<ProductModel>>(
            stream: controller.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Bir hata oluştu: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final products = snapshot.data ?? [];

              // Sadece garantisi bitmiş veya 30 günden az kalmış ürünleri filtrele
              final expiringProducts = products.where((p) {
                return p.remainingDays <= 30;
              }).toList();

              // Kalan güne göre sırala (En az gün en üstte, yani en acil olanlar)
              expiringProducts.sort(
                (a, b) => a.remainingDays.compareTo(b.remainingDays),
              );

              if (expiringProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 80,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Şu an için acil bir garanti bildirimi yok.",
                        style: TextStyle(fontSize: 16, color: Colors.white60),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: expiringProducts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = expiringProducts[index];

                  final isExpired = product.remainingDays <= 0;
                  final isCritical = product.remainingDays <= 7 && !isExpired;

                  Color iconColor = Colors.orange;
                  IconData iconData = Icons.warning_amber_rounded;
                  String statusText = "Garantisi Yaklaşıyor";

                  if (isExpired) {
                    iconColor = Colors.red;
                    iconData = Icons.error_outline;
                    statusText = "Garantisi Bitti!";
                  } else if (isCritical) {
                    iconColor = Colors.deepOrange;
                    iconData = Icons.notification_important;
                    statusText = "Kritik! Garantisi Bitmek Üzere";
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
                    ),
                    color: iconColor.withValues(alpha: 0.05),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withValues(alpha: 0.1),
                        radius: 25,
                        child: Icon(iconData, color: iconColor, size: 28),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isExpired
                                ? "Bitiş: ${DateFormat('dd.MM.yyyy').format(product.expiryDate)}"
                                : "Kalan Süre: ${product.remainingDays} gün",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(productId: product.id!),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

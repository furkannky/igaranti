import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/product_model.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import 'package:intl/intl.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  int _daysBeforeExpiry = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bildirim Ayarları",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Bildirimleri Aktif Et",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(value 
                              ? "Bildirimler aktif edildi" 
                              : "Bildirimler devre dışı bırakıldı"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hatırlatma Süresi",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Garanti bitişinden $_daysBeforeExpiry gün önce hatırlat",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _daysBeforeExpiry.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: "$_daysBeforeExpiry gün",
                      onChanged: (value) {
                        setState(() {
                          _daysBeforeExpiry = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _scheduleTestNotification();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Test Bildirim Gönder",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _scheduleAllNotifications();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Tüm Ürünler İçin Bildirim Planla",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleTestNotification() async {
    await _notificationService.scheduleWarrantyNotification(
      id: 999999,
      title: "Test Bildirimi",
      body: "Bu bir test bildirimidir. iGaranti uygulaması çalışıyor!",
      scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Test bildirimi 5 saniye içinde gönderilecek"),
      ),
    );
  }

  void _scheduleAllNotifications() async {
    if (!_notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Önce bildirimleri aktif edin"),
        ),
      );
      return;
    }

    final productController = Provider.of<ProductController>(context, listen: false);
    final products = await productController.getProducts().first;
    
    int scheduledCount = 0;
    
    for (final product in products) {
      if (product.remainingDays > 0) {
        final notificationDate = product.expiryDate.subtract(Duration(days: _daysBeforeExpiry));
        
        await _notificationService.scheduleWarrantyNotification(
          id: product.id.hashCode,
          title: "Garanti Bitişi Yaklaşıyor",
          body: "${product.name} ürününün garantisi $_daysBeforeExpiry gün içinde bitecek",
          scheduledDate: notificationDate,
        );
        scheduledCount++;
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$scheduledCount ürün için bildirim planlandı"),
      ),
    );
  }
}

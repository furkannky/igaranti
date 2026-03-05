import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();
  bool _notificationsEnabled = true;
  int _daysBeforeExpiry = 7;
  bool _vibrationEnabled = true;
  String _notificationSound = 'default';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _notificationsEnabled = await _settingsService.getNotificationsEnabled();
    _daysBeforeExpiry = await _settingsService.getDaysBeforeExpiry();
    _vibrationEnabled = await _settingsService.getVibrationEnabled();
    _notificationSound = await _settingsService.getNotificationSound();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bildirim Ayarları",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) async {
                        if (value) {
                          final hasPermission =
                              await _checkAndRequestPermissions();
                          if (!hasPermission) {
                            _showPermissionDialog();
                            return;
                          }
                        }

                        setState(() {
                          _notificationsEnabled = value;
                        });
                        await _settingsService.setNotificationsEnabled(value);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? "Bildirimler aktif edildi"
                                  : "Bildirimler devre dışı bırakıldı",
                            ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Garanti bitişinden $_daysBeforeExpiry gün önce hatırlat",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _daysBeforeExpiry.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: "$_daysBeforeExpiry gün",
                      onChanged: (value) async {
                        setState(() {
                          _daysBeforeExpiry = value.round();
                        });
                        await _settingsService.setDaysBeforeExpiry(
                          _daysBeforeExpiry,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Titreşim",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _vibrationEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _vibrationEnabled = value;
                        });
                        await _settingsService.setVibrationEnabled(value);
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Bildirim Sesi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _notificationSound,
                      items: const [
                        DropdownMenuItem(
                          value: 'default',
                          child: Text("Varsayılan"),
                        ),
                        DropdownMenuItem(
                          value: 'chime',
                          child: Text("Zil Sesi (Chime)"),
                        ),
                        DropdownMenuItem(
                          value: 'alert',
                          child: Text("Uyarı Sesi (Alert)"),
                        ),
                      ],
                      onChanged: (String? newValue) async {
                        if (newValue != null) {
                          setState(() {
                            _notificationSound = newValue;
                          });
                          await _settingsService.setNotificationSound(newValue);
                        }
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
                      "Bildirim Geçmişi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showNotificationHistory(),
                            icon: const Icon(Icons.history),
                            label: const Text("Geçmişi Gör"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _clearAllNotifications(),
                            icon: const Icon(Icons.clear_all),
                            label: const Text("Temizle"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
    await _notificationService.showInstantNotification(
      id: 999999,
      title: "Test Bildirimi",
      body: "Bu bir test bildirimidir. iGaranti uygulaması çalışıyor!",
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Test bildirimi gönderildi")));
  }

  void _scheduleAllNotifications() async {
    if (!_notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bildirimleri aktif edin")),
      );
      return;
    }

    final hasPermission = await _notificationService.arePermissionsGranted();
    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }

    try {
      final productController = Provider.of<ProductController>(
        context,
        listen: false,
      );
      final products = await productController.getProducts().first;

      int scheduledCount = 0;
      int criticalCount = 0;

      // Önce mevcut bildirimleri temizle
      await _notificationService.cancelAllNotifications();

      for (final product in products) {
        if (product.remainingDays > 0) {
          // Normal hatırlatma
          final normalNotificationDate = product.expiryDate.subtract(
            Duration(days: _daysBeforeExpiry),
          );

          await _notificationService.scheduleWarrantyNotification(
            id: product.id.hashCode,
            title: "Garanti Bitişi Yaklaşıyor",
            body:
                "${product.name} ürününün garantisi $_daysBeforeExpiry gün içinde bitecek",
            scheduledDate: normalNotificationDate,
            payload: product.id,
          );
          scheduledCount++;

          // Kritik hatırlatma (7 gün kala)
          if (product.remainingDays > 7) {
            final criticalNotificationDate = product.expiryDate.subtract(
              const Duration(days: 7),
            );

            await _notificationService.scheduleCriticalNotification(
              id: product.id.hashCode + 100000,
              title: "Kritik Garanti Uyarısı",
              body: "${product.name} ürününün garantisi 7 gün içinde bitecek!",
              scheduledDate: criticalNotificationDate,
              payload: product.id,
            );
            criticalCount++;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$scheduledCount normal ve $criticalCount kritik bildirim planlandı",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    final hasPermission = await _notificationService.arePermissionsGranted();
    if (!hasPermission) {
      return await _notificationService.requestPermissions();
    }
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bildirim İzni Gerekli"),
        content: const Text(
          "Bildirimleri kullanabilmek için lütfen ayarlardan bildirim iznini verin.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openAppSettings();
            },
            child: const Text("Ayarları Aç"),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  void _showNotificationHistory() async {
    final pendingNotifications = await _notificationService
        .getPendingNotifications();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bekleyen Bildirimler"),
        content: SizedBox(
          width: double.maxFinite,
          child: pendingNotifications.isEmpty
              ? const Center(child: Text("Bekleyen bildirim yok"))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: pendingNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = pendingNotifications[index];
                    return ListTile(
                      title: Text(notification.title ?? "Başlıksız"),
                      subtitle: Text(notification.body ?? "İçerik yok"),
                      trailing: Text("ID: ${notification.id}"),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tüm bildirimler iptal edildi")),
    );
  }
}

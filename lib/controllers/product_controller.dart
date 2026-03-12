import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/error_handler_service.dart';

class ProductController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Yeni Ürün Ekleme (Kullanıcıya Bağlı)
  Future<bool> addProduct(
    ProductModel product,
    List<File>? imageFiles,
    BuildContext context,
  ) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      ErrorHandlerService.handleError(context, 'Kullanıcı girişi yapılmamış!');
      return false;
    }

    debugPrint("🔥 Ürün ekleniyor - Kullanıcı ID: $uid");
    debugPrint("🔥 Ürün bilgisi: ${product.name} - ${product.brand}");

    _isLoading = true;
    notifyListeners();

    try {
      List<String>? imageUrls;
      if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint("🔥 Fotoğraflar yükleniyor...");
        imageUrls = await _storageService.uploadMultipleImages(imageFiles);
        debugPrint("🔥 Fotoğraflar yüklendi: $imageUrls");
      }

      Map<String, dynamic> data = product.toMap();
      data['userId'] = uid;

      // Geriye dönük uyumluluk: Eski invoiceImageUrl property'si için ilk görsel atanır
      if (imageUrls != null && imageUrls.isNotEmpty) {
        data['invoiceImageUrl'] = imageUrls.first;
        data['imageUrls'] = imageUrls;
      } else {
        data['invoiceImageUrl'] = null;
        data['imageUrls'] = <String>[];
      }

      // Servis geçmişi başlangıçta boş bir liste olarak eklenebilir
      data['serviceHistory'] = [];

      debugPrint("🔥 Firestore'a kaydediliyor: ${data.keys}");
      final docRef = await _firestore.collection('products').add(data);
      debugPrint("🔥 Ürün başarıyla kaydedildi - Document ID: ${docRef.id}");

      try {
        // Bildirim Kurulumu
        int notificationId = docRef.id.hashCode;
        await _notificationService.scheduleWarrantyNotification(
          id: notificationId,
          title: "Garanti Hatırlatıcısı ⏳",
          body: "${product.name} ürününün garantisi 1 ay sonra bitiyor!",
          scheduledDate: product.expiryDate.subtract(const Duration(days: 30)),
        );

        await _notificationService.scheduleWarrantyNotification(
          id: notificationId + 1,
          title: "DİKKAT: Garanti Bitiyor! ⚠️",
          body: "${product.name} ürününün garantisi önümüzdeki hafta doluyor.",
          scheduledDate: product.expiryDate.subtract(const Duration(days: 7)),
        );
      } catch (e) {
        debugPrint("Bildirim ekleme hatası (önemsiz): $e");
      }
    } catch (e) {
      debugPrint("❌ Ürün ekleme hatası: $e");
      if (context.mounted) {
        ErrorHandlerService.handleError(context, e);
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return true;
  }

  // YENİ EKLENDİ: Servis Kaydı Ekleme Fonksiyonu
  Future<void> addServiceHistory(String productId, ServiceRecord record) async {
    try {
      // FieldValue.arrayUnion kullanarak listenin sonuna yeni kaydı ekliyoruz
      await _firestore.collection('products').doc(productId).update({
        'serviceHistory': FieldValue.arrayUnion([record.toMap()]),
      });

      debugPrint("Servis kaydı başarıyla eklendi.");
      notifyListeners(); // UI'ın güncellenmesi için
    } catch (e) {
      debugPrint("Servis kaydı hatası: $e");
    }
  }

  // Kullanıcıya Özel Ürünleri Listeleme
  Stream<List<ProductModel>> getProducts() {
    final String? uid = _auth.currentUser?.uid;

    debugPrint("🔥 getProducts çağrıldı - Kullanıcı ID: $uid");

    if (uid == null) {
      debugPrint("❌ Kullanıcı ID null, boş liste dönüyor");
      return Stream.value([]);
    }

    debugPrint("🔥 Firestore sorgusu yapılıyor - userId: $uid");

    // Güvenlik kuralları gereği (Firebase Rules) tüm koleksiyonu okumaya iznimiz yok.
    // Bu nedenle mutlaka .where() ile filtrelemeliyiz, yoksa "Permission Denied" hatası alırız.
    return _firestore
        .collection('products')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            "🔥 Firestore'dan toplam ${snapshot.docs.length} ürün geldi",
          );

          final userProducts = snapshot.docs
              .map((doc) {
                final data = doc.data();
                debugPrint("🔥 Ürün verisi: $data");
                debugPrint(
                  "🔥 Ürün adı: ${data['name']} - userId: ${data['userId']}",
                );

                try {
                  final product = ProductModel.fromMap(data, doc.id);
                  debugPrint("🔥 ProductModel oluşturuldu: ${product.name}");
                  return product;
                } catch (e) {
                  debugPrint("❌ ProductModel oluşturma hatası: $e");
                  debugPrint("❌ Hatalı veri: $data");
                  return null;
                }
              })
              .where((product) => product != null)
              .cast<ProductModel>()
              .toList();

          // Bileşik dizin hatası olmaması için cihaz (client) tarafında sıralıyoruz
          userProducts.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

          debugPrint(
            "🔥 Kullanıcının sıralı ürün sayısı: ${userProducts.length}",
          );
          return userProducts;
        });
  }

  // Ürün Güncelleme (Düzenleme özelliği için yeni eklendi)
  Future<void> updateProduct(
    ProductModel product, {
    List<File>? newImageFiles,
    List<String>? remainingImageUrls,
  }) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint("Hata: Kullanıcı girişi yapılmamış!");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      List<String> finalImageUrls = remainingImageUrls ?? [];

      // Eğer yeni görseller seçildiyse yükle ve finale ekle
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        debugPrint("🔥 Yeni fotoğraflar yükleniyor...");
        List<String> newUrls = await _storageService.uploadMultipleImages(
          newImageFiles,
        );
        finalImageUrls.addAll(newUrls);
        debugPrint("🔥 Yeni fotoğraflar yüklendi: $newUrls");
      }

      product.imageUrls = finalImageUrls;

      String? updatedInvoiceUrl;
      if (finalImageUrls.isNotEmpty) {
        updatedInvoiceUrl = finalImageUrls.first;
      }

      Map<String, dynamic> data = product.toMap();
      data['userId'] = uid;
      data['invoiceImageUrl'] = updatedInvoiceUrl;
      data['imageUrls'] = finalImageUrls;

      if (product.id == null || product.id!.isEmpty) {
        debugPrint("❌ Hata: Güncellenecek ürünün ID'si null veya boş!");
        throw Exception("Güncellenecek ürünün ID'si bulunamadı.");
      }

      debugPrint("🔥 Firestore'da güncelleniyor: ${product.id}");
      await _firestore.collection('products').doc(product.id).update(data);
      debugPrint("🔥 Ürün başarıyla güncellendi");

      // Bildirimleri de güncellemek için eskileri silip yenileri ekleyebiliriz
      int notificationId = product.id!.hashCode;
      try {
        await _notificationService.cancelNotification(notificationId);
        await _notificationService.cancelNotification(notificationId + 1);
      } catch (e) {
        debugPrint("Bildirim silme hatası (önemsiz): $e");
      }

      try {
        final DateTime thirtyDaysBefore = product.expiryDate.subtract(
          const Duration(days: 30),
        );
        if (thirtyDaysBefore.isAfter(DateTime.now())) {
          await _notificationService.scheduleWarrantyNotification(
            id: notificationId,
            title: "Garanti Hatırlatıcısı ⏳",
            body: "${product.name} ürününün garantisi 1 ay sonra bitiyor!",
            scheduledDate: thirtyDaysBefore,
          );
        }

        final DateTime sevenDaysBefore = product.expiryDate.subtract(
          const Duration(days: 7),
        );
        if (sevenDaysBefore.isAfter(DateTime.now())) {
          await _notificationService.scheduleWarrantyNotification(
            id: notificationId + 1,
            title: "DİKKAT: Garanti Bitiyor! ⚠️",
            body:
                "${product.name} ürününün garantisi önümüzdeki hafta doluyor.",
            scheduledDate: sevenDaysBefore,
          );
        }
      } catch (e) {
        debugPrint("Bildirim zamanlama hatası (önemsiz): $e");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Ürün güncelleme hatası: $e\n$stackTrace");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ürün Silme
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }

  // --- Yeni: Yaşam Döngüsü (Servis Kaydı) Ekleme ---
  Future<void> addServiceRecord(
    String productId,
    ServiceRecord record, {
    File? documentFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Eğer kullanıcı servis için bir belge (fatura/fiş) eklediyse onu da Storage'a yükle
      if (documentFile != null) {
        String? docUrl = await _storageService.uploadInvoiceImage(documentFile);
        record.documentUrl = docUrl;
      }

      // 'serviceHistory' dizisine yeni elemanı atomic olarak ekle
      await _firestore.collection('products').doc(productId).update({
        'serviceHistory': FieldValue.arrayUnion([record.toMap()]),
      });

      debugPrint("✅ Servis kaydı başarıyla eklendi: $productId");
    } catch (e, stackTrace) {
      debugPrint("❌ Servis kaydı ekleme hatası: $e\n$stackTrace");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

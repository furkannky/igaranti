import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class ProductController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Yeni Ürün Ekleme (Kullanıcıya Bağlı)
  Future<void> addProduct(ProductModel product, File? imageFile) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint("Hata: Kullanıcı girişi yapılmamış!");
      return; 
    }

    _isLoading = true;
    notifyListeners();

    try {
      String? invoiceImageUrl;
      if (imageFile != null) {
        invoiceImageUrl = await _storageService.uploadInvoiceImage(imageFile);
      }

      Map<String, dynamic> data = product.toMap();
      data['userId'] = uid;
      data['invoiceImageUrl'] = invoiceImageUrl;
      // Servis geçmişi başlangıçta boş bir liste olarak eklenebilir
      data['serviceHistory'] = []; 

      final docRef = await _firestore.collection('products').add(data);

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
      debugPrint("Ürün ekleme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // YENİ EKLENDİ: Servis Kaydı Ekleme Fonksiyonu
  Future<void> addServiceHistory(String productId, ServiceRecord record) async {
    try {
      // FieldValue.arrayUnion kullanarak listenin sonuna yeni kaydı ekliyoruz
      await _firestore.collection('products').doc(productId).update({
        'serviceHistory': FieldValue.arrayUnion([record.toMap()])
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

    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection('products')
        .where('userId', isEqualTo: uid)
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Ürün Silme
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }
}
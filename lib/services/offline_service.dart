import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineService {
  static const String _productsCacheKey = 'cached_products';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _offlineQueueKey = 'offline_operations_queue';
  
  static OfflineService? _instance;
  static OfflineService get instance => _instance ??= OfflineService._();
  
  OfflineService._();
  
  // Ürünleri cache'e kaydet
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = products.map((p) => _productToJson(p)).toList();
      
      await prefs.setString(_productsCacheKey, jsonEncode(productsJson));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      debugPrint('✅ ${products.length} ürün cache\'lendi');
    } catch (e) {
      debugPrint('❌ Ürünler cache\'lenirken hata: $e');
    }
  }
  
  // Cache'den ürünleri oku
  Future<List<ProductModel>> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJsonString = prefs.getString(_productsCacheKey);
      
      if (productsJsonString == null) {
        debugPrint('📱 Cache\'de ürün bulunamadı');
        return [];
      }
      
      final productsJson = jsonDecode(productsJsonString) as List;
      final products = productsJson.map((json) => _productFromJson(json)).toList();
      
      debugPrint('📱 Cache\'den ${products.length} ürün okundu');
      return products;
    } catch (e) {
      debugPrint('❌ Cache\'den ürünler okunurken hata: $e');
      return [];
    }
  }
  
  // Son senkronizasyon zamanını al
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimeString = prefs.getString(_lastSyncKey);
      
      if (lastSyncTimeString == null) return null;
      
      return DateTime.parse(lastSyncTimeString);
    } catch (e) {
      debugPrint('❌ Son senkronizasyon zamanı okunurken hata: $e');
      return null;
    }
  }
  
  // Offline işlemi kuyruğa ekle
  Future<void> addToOfflineQueue(Map<String, dynamic> operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_offlineQueueKey) ?? '[]';
      
      final queue = jsonDecode(queueString) as List;
      operation['timestamp'] = DateTime.now().toIso8601String();
      queue.add(operation);
      
      await prefs.setString(_offlineQueueKey, jsonEncode(queue));
      debugPrint('📤 Offline işlem kuyruğa eklendi: ${operation['type']}');
    } catch (e) {
      debugPrint('❌ Offline kuyruğa ekleme hatası: $e');
    }
  }
  
  // Offline kuyruğu al
  Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_offlineQueueKey) ?? '[]';
      
      final queue = jsonDecode(queueString) as List;
      return queue.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Offline kuyruk okunurken hata: $e');
      return [];
    }
  }
  
  // Offline kuyruğu temizle
  Future<void> clearOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineQueueKey);
      debugPrint('🗑️ Offline kuyruk temizlendi');
    } catch (e) {
      debugPrint('❌ Offline kuyruk temizlenirken hata: $e');
    }
  }
  
  // Kuyruktaki işlemleri senkronize et
  Future<void> syncOfflineOperations() async {
    try {
      final queue = await getOfflineQueue();
      if (queue.isEmpty) {
        debugPrint('📤 Senkronize edilecek offline işlem yok');
        return;
      }
      
      final firestore = FirebaseFirestore.instance;
      int successCount = 0;
      int failCount = 0;
      
      for (final operation in queue) {
        try {
          switch (operation['type']) {
            case 'add':
              await _syncAddOperation(firestore, operation);
              successCount++;
              break;
            case 'update':
              await _syncUpdateOperation(firestore, operation);
              successCount++;
              break;
            case 'delete':
              await _syncDeleteOperation(firestore, operation);
              successCount++;
              break;
            default:
              debugPrint('⚠️ Bilinmeyen işlem türü: ${operation['type']}');
              failCount++;
          }
        } catch (e) {
          debugPrint('❌ İşlem senkronizasyon hatası: $e');
          failCount++;
        }
      }
      
      if (successCount > 0) {
        await clearOfflineQueue();
        debugPrint('✅ $successCount işlem başarıyla senkronize edildi');
      }
      
      if (failCount > 0) {
        debugPrint('⚠️ $failCount işlem senkronize edilemedi');
      }
    } catch (e) {
      debugPrint('❌ Senkronizasyon sırasında genel hata: $e');
    }
  }
  
  // Cache'i temizle
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_productsCacheKey);
      await prefs.remove(_lastSyncKey);
      debugPrint('🗑️ Cache temizlendi');
    } catch (e) {
      debugPrint('❌ Cache temizlenirken hata: $e');
    }
  }
  
  // İnternet bağlantısı kontrolü
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Ürün ekleme işlemini senkronize et
  Future<void> _syncAddOperation(FirebaseFirestore firestore, Map<String, dynamic> operation) async {
    final productData = operation['data'] as Map<String, dynamic>;
    await firestore.collection('products').add(productData);
  }
  
  // Ürün güncelleme işlemini senkronize et
  Future<void> _syncUpdateOperation(FirebaseFirestore firestore, Map<String, dynamic> operation) async {
    final productId = operation['productId'] as String;
    final productData = operation['data'] as Map<String, dynamic>;
    await firestore.collection('products').doc(productId).update(productData);
  }
  
  // Ürün silme işlemini senkronize et
  Future<void> _syncDeleteOperation(FirebaseFirestore firestore, Map<String, dynamic> operation) async {
    final productId = operation['productId'] as String;
    await firestore.collection('products').doc(productId).delete();
  }
  
  // ProductModel'i JSON'a dönüştür
  Map<String, dynamic> _productToJson(ProductModel product) {
    return {
      'id': product.id,
      'name': product.name,
      'brand': product.brand,
      'model': product.model,
      'purchaseDate': product.purchaseDate.toIso8601String(),
      'warrantyMonths': product.warrantyMonths,
      'category': product.category,
      'invoiceImageUrl': product.invoiceImageUrl,
      'imageUrls': product.imageUrls,
      'note': product.note,
      'isOnlineStore': product.isOnlineStore,
      'serviceHistory': product.serviceHistory?.map((s) => s.toMap()).toList(),
    };
  }
  
  // JSON'dan ProductModel oluştur
  ProductModel _productFromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      model: json['model'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      warrantyMonths: json['warrantyMonths'],
      category: json['category'],
      invoiceImageUrl: json['invoiceImageUrl'],
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      note: json['note'],
      isOnlineStore: json['isOnlineStore'] ?? false,
      serviceHistory: json['serviceHistory'] != null 
          ? (json['serviceHistory'] as List).map((s) => ServiceRecord.fromMap(s)).toList()
          : null,
    );
  }
  
  // Cache durumunu kontrol et
  Future<bool> isCacheFresh() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    // Cache 1 saat içinde taze kabul edilir
    return difference.inHours < 1;
  }
  
  // Cache istatistikleri
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJsonString = prefs.getString(_productsCacheKey);
      final lastSync = await getLastSyncTime();
      final queue = await getOfflineQueue();
      
      int productCount = 0;
      if (productsJsonString != null) {
        final productsJson = jsonDecode(productsJsonString) as List;
        productCount = productsJson.length;
      }
      
      return {
        'productCount': productCount,
        'lastSync': lastSync?.toIso8601String(),
        'isFresh': await isCacheFresh(),
        'offlineQueueSize': queue.length,
      };
    } catch (e) {
      debugPrint('❌ Cache istatistikleri alınamadı: $e');
      return {};
    }
  }
}

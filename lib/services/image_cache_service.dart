import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImageCacheService {
  static ImageCacheService? _instance;
  static ImageCacheService get instance => _instance ??= ImageCacheService._();
  
  ImageCacheService._();
  
  late Directory _cacheDir;
  final int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  final int _maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7 gün
  
  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, 'image_cache'));
      
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }
      
      // Cache temizleme kontrolü
      await _cleanupCache();
      
      debugPrint('🖼️ Image cache initialized: ${_cacheDir.path}');
    } catch (e) {
      debugPrint('❌ Image cache initialization failed: $e');
    }
  }
  
  // Resmi cache'den al veya indir
  Future<File?> getImage(String imageUrl) async {
    try {
      final fileName = _getFileName(imageUrl);
      final cachedFile = File(path.join(_cacheDir.path, fileName));
      
      // Cache'de varsa ve tazeyse return et
      if (await cachedFile.exists() && _isCacheValid(cachedFile)) {
        debugPrint('🖼️ Image hit from cache: $fileName');
        return cachedFile;
      }
      
      // İnternetten indir
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        await cachedFile.writeAsBytes(response.bodyBytes);
        debugPrint('🖼️ Image downloaded and cached: $fileName');
        return cachedFile;
      } else {
        debugPrint('❌ Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting image: $e');
      return null;
    }
  }
  
  // Resmi ön belleğe al (base64 veya bytes)
  Future<void> cacheImageFromBytes(String imageUrl, Uint8List imageBytes) async {
    try {
      final fileName = _getFileName(imageUrl);
      final cachedFile = File(path.join(_cacheDir.path, fileName));
      
      await cachedFile.writeAsBytes(imageBytes);
      debugPrint('🖼️ Image cached from bytes: $fileName');
    } catch (e) {
      debugPrint('❌ Error caching image from bytes: $e');
    }
  }
  
  // Cache'deki resmi sil
  Future<void> removeImage(String imageUrl) async {
    try {
      final fileName = _getFileName(imageUrl);
      final cachedFile = File(path.join(_cacheDir.path, fileName));
      
      if (await cachedFile.exists()) {
        await cachedFile.delete();
        debugPrint('🗑️ Image removed from cache: $fileName');
      }
    } catch (e) {
      debugPrint('❌ Error removing image from cache: $e');
    }
  }
  
  // Tüm cache'i temizle
  Future<void> clearCache() async {
    try {
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
        debugPrint('🗑️ Image cache cleared');
      }
    } catch (e) {
      debugPrint('❌ Error clearing image cache: $e');
    }
  }
  
  // Cache boyutunu al
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;
      
      if (await _cacheDir.exists()) {
        await for (final entity in _cacheDir.list()) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      return 0;
    }
  }
  
  // Cache'deki dosya sayısını al
  Future<int> getCacheFileCount() async {
    try {
      int fileCount = 0;
      
      if (await _cacheDir.exists()) {
        await for (final entity in _cacheDir.list()) {
          if (entity is File) {
            fileCount++;
          }
        }
      }
      
      return fileCount;
    } catch (e) {
      debugPrint('❌ Error getting cache file count: $e');
      return 0;
    }
  }
  
  // Cache istatistikleri
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final size = await getCacheSize();
      final count = await getCacheFileCount();
      
      return {
        'size': size,
        'sizeFormatted': _formatBytes(size),
        'fileCount': count,
        'maxSize': _maxCacheSize,
        'maxSizeFormatted': _formatBytes(_maxCacheSize),
        'usagePercentage': (size / _maxCacheSize * 100).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {};
    }
  }
  
  // Eski veya büyük cache'i temizle
  Future<void> _cleanupCache() async {
    try {
      final now = DateTime.now();
      final files = <FileSystemEntity>[];
      
      if (await _cacheDir.exists()) {
        await for (final entity in _cacheDir.list()) {
          files.add(entity);
        }
      }
      
      // Eski dosyaları sil
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          if (age.inMilliseconds > _maxCacheAge) {
            await file.delete();
            debugPrint('🗑️ Old image removed from cache: ${file.path}');
          }
        }
      }
      
      // Cache boyutunu kontrol et ve gerekirse temizle
      final currentSize = await getCacheSize();
      if (currentSize > _maxCacheSize) {
        await _cleanupBySize();
      }
    } catch (e) {
      debugPrint('❌ Error during cache cleanup: $e');
    }
  }
  
  // Boyuta göre temizleme (en eski dosyaları sil)
  Future<void> _cleanupBySize() async {
    try {
      final files = <File>[];
      
      if (await _cacheDir.exists()) {
        await for (final entity in _cacheDir.list()) {
          if (entity is File) {
            files.add(entity);
          }
        }
      }
      
      // Dosyaları son erişim zamanına göre sırala
      files.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statA.modified.compareTo(statB.modified);
      });
      
      // En eski dosyaları silerek cache boyutunu düşür
      int currentSize = await getCacheSize();
      final targetSize = (_maxCacheSize * 0.8).round(); // %80'e düşür
      
      for (final file in files) {
        if (currentSize <= targetSize) break;
        
        final fileSize = await file.length();
        await file.delete();
        currentSize -= fileSize;
        
        debugPrint('🗑️ Image removed for size cleanup: ${file.path}');
      }
    } catch (e) {
      debugPrint('❌ Error during size-based cleanup: $e');
    }
  }
  
  // Cache'deki resmin geçerli olup olmadığını kontrol et
  bool _isCacheValid(File file) {
    try {
      final now = DateTime.now();
      final stat = file.statSync();
      final age = now.difference(stat.modified);
      
      return age.inMilliseconds < _maxCacheAge;
    } catch (e) {
      return false;
    }
  }
  
  // URL'den dosya adı oluştur
  String _getFileName(String imageUrl) {
    // URL'den dosya adını çıkar veya hash oluştur
    final uri = Uri.parse(imageUrl);
    String fileName = path.basename(uri.path);
    
    // Eğer dosya adı yoksa veya çok kısaysa hash kullan
    if (fileName.isEmpty || fileName.length < 3) {
      fileName = imageUrl.hashCode.toString();
    }
    
    // Uzantıyı kontrol et
    if (!fileName.contains('.')) {
      fileName += '.jpg'; // Varsayılan uzantı
    }
    
    // Güvenli dosya adı oluştur (special characters temizle)
    fileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    
    return fileName;
  }
  
  // Byte'ları okunabilir formata dönüştür
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  // Ön bellek durumu kontrolü
  Future<bool> isImageCached(String imageUrl) async {
    try {
      final fileName = _getFileName(imageUrl);
      final cachedFile = File(path.join(_cacheDir.path, fileName));
      
      return await cachedFile.exists() && _isCacheValid(cachedFile);
    } catch (e) {
      return false;
    }
  }
  
  // Cache'deki resimlerin URL'lerini al
  Future<List<String>> getCachedImageUrls() async {
    try {
      final urls = <String>[];
      
      if (await _cacheDir.exists()) {
        await for (final entity in _cacheDir.list()) {
          if (entity is File) {
            // Dosya adından orijinal URL'i oluştur (ters işlem)
            final fileName = path.basename(entity.path);
            // Bu basit bir yaklaşım, gerçek uygulamada URL mapping gerekli
            urls.add('cached://$fileName');
          }
        }
      }
      
      return urls;
    } catch (e) {
      debugPrint('❌ Error getting cached image URLs: $e');
      return [];
    }
  }
}

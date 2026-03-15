import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Tek bir fotoğrafı Firebase Storage'a yükler ve URL'sini döndürür
  Future<String?> uploadImage(
    File imageFile, {
    String folderName = 'invoices',
  }) async {
    try {
      // Benzersiz bir dosya adı oluştur (Örn: invoices/unique_id.jpg)
      String extension = imageFile.path.toLowerCase().endsWith('.pdf')
          ? '.pdf'
          : '.jpg';
      String fileName = '$folderName/${_uuid.v4()}$extension';

      // Storage referansı oluştur
      Reference ref = _storage.ref().child(fileName);

      // Dosyayı yükle
      SettableMetadata? metadata;
      if (extension == '.pdf') {
        metadata = SettableMetadata(contentType: 'application/pdf');
      }

      UploadTask uploadTask = ref.putFile(imageFile, metadata);

      // Yükleme tamamlandığında indirme URL'sini al
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint("Dosya yükleme hatası: $e");
      return null;
    }
  }

  // Birden fazla fotoğraf yükler ve URL listesini döndürür
  Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, {
    String folderName = 'invoices',
  }) async {
    List<String> downloadUrls = [];

    for (File file in imageFiles) {
      String? url = await uploadImage(file, folderName: folderName);
      if (url != null) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }
}

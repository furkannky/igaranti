import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Fotoğrafı Firebase Storage'a yükler ve URL'sini döndürür
  Future<String?> uploadInvoiceImage(File imageFile) async {
    try {
      // Benzersiz bir dosya adı oluştur (Örn: invoices/unique_id.jpg)
      String fileName = 'invoices/${_uuid.v4()}.jpg';

      // Storage referansı oluştur
      Reference ref = _storage.ref().child(fileName);

      // Dosyayı yükle
      UploadTask uploadTask = ref.putFile(imageFile);

      // Yükleme tamamlandığında indirme URL'sini al
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Fotoğraf yükleme hatası: $e");
      return null;
    }
  }

  // Birden fazla fotoğraf yükler ve URL listesini döndürür
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> downloadUrls = [];

    for (File file in imageFiles) {
      String? url = await uploadInvoiceImage(file);
      if (url != null) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }
}

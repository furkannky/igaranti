import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String? id;
  String name;
  String brand;
  String model;
  DateTime purchaseDate;
  int warrantyMonths;
  String category;
  String? invoiceImageUrl;
  List<String>? imageUrls; // Eklenti: Birden fazla resim için
  String? note;
  bool isOnlineStore;
  List<ServiceRecord>? serviceHistory; // Kriter 6 için eklendi
  String? supportNumber; // Destek numarası eklendi

  ProductModel({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.purchaseDate,
    required this.warrantyMonths,
    required this.category,
    this.invoiceImageUrl,
    this.imageUrls,
    this.note,
    this.isOnlineStore = false,
    this.serviceHistory,
    this.supportNumber, // Destek numarası eklendi
  });

  // Garanti Bitiş Tarihini Hesapla
  DateTime get expiryDate {
    return DateTime(
      purchaseDate.year + (purchaseDate.month + warrantyMonths) ~/ 12,
      (purchaseDate.month + warrantyMonths) % 12,
      purchaseDate.day,
    );
  }

  // Kalan Günü Hesapla
  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Bugünün başı
    final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day); // Bitiş gününün başı
    final difference = expiryDay.difference(today).inDays;
    return difference;
  }

  // URL'nin PDF olup olmadığını kontrol et
  static bool isPdfUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      return path.endsWith('.pdf');
    } catch (_) {
      return url.toLowerCase().contains('.pdf');
    }
  }

  // Firebase'den Veri Okuma (Model Oluşturma)
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Geriye dönük uyumluluk: Hem eski `invoiceImageUrl` hem de yeni `imageUrls` yönetimi
    List<String> images = [];
    if (map['imageUrls'] != null) {
      images = List<String>.from(map['imageUrls']);
    } else if (map['invoiceImageUrl'] != null) {
      images.add(map['invoiceImageUrl']);
    }

    return ProductModel(
      id: documentId,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      warrantyMonths: map['warrantyMonths'] ?? 24,
      category: map['category'] ?? 'Diğer',
      invoiceImageUrl: map['invoiceImageUrl'],
      imageUrls: images,
      note: map['note'],
      isOnlineStore: map['isOnlineStore'] ?? false,
      supportNumber: map['supportNumber'], // Destek numarası eklendi
      // Servis geçmişi varsa listeye çeviriyoruz
      serviceHistory: map['serviceHistory'] != null
          ? (map['serviceHistory'] as List)
                .map((item) => ServiceRecord.fromMap(item))
                .toList()
          : [],
    );
  }

  // Firebase'e Veri Gönderme (Map'e Çevirme)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'model': model,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'warrantyMonths': warrantyMonths,
      'category': category,
      'invoiceImageUrl': invoiceImageUrl,
      'imageUrls': imageUrls,
      'note': note,
      'isOnlineStore': isOnlineStore,
      'supportNumber': supportNumber, // Destek numarası eklendi
      'expiryDate': Timestamp.fromDate(expiryDate), // Sorgular için önemli
      'serviceHistory': serviceHistory?.map((x) => x.toMap()).toList(),
    };
  }
}

// Kriter 6: Teknik Servis Günlüğü için yardımcı model
class ServiceRecord {
  DateTime date;
  String description;
  double price;
  String? documentUrl; // Fiş/Fatura belgesi eklenebilmesi için

  ServiceRecord({
    required this.date,
    required this.description,
    required this.price,
    this.documentUrl,
  });

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      documentUrl: map['documentUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
      'price': price,
      'documentUrl': documentUrl,
    };
  }
}

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
  String? note;
  bool isOnlineStore;
  List<ServiceRecord>? serviceHistory; // Kriter 6 için eklendi

  ProductModel({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.purchaseDate,
    required this.warrantyMonths,
    required this.category,
    this.invoiceImageUrl,
    this.note,
    this.isOnlineStore = false,
    this.serviceHistory,
  });

  // Garanti Bitiş Tarihini Hesapla
  DateTime get expiryDate {
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + warrantyMonths,
      purchaseDate.day,
    );
  }

  // Kalan Günü Hesapla
  int get remainingDays {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference;
  }

  // Firebase'den Veri Okuma (Model Oluşturma)
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      warrantyMonths: map['warrantyMonths'] ?? 24,
      category: map['category'] ?? 'Diğer',
      invoiceImageUrl: map['invoiceImageUrl'],
      note: map['note'],
      isOnlineStore: map['isOnlineStore'] ?? false,
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
      'note': note,
      'isOnlineStore': isOnlineStore,
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

  ServiceRecord({
    required this.date,
    required this.description,
    required this.price,
  });

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
      'price': price,
    };
  }
}
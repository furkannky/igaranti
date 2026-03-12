import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:igaranti/models/product_model.dart';

void main() {
  group('ProductModel Tests', () {
    late ProductModel product;
    late DateTime purchaseDate;

    setUp(() {
      purchaseDate = DateTime(2023, 1, 15);
      product = ProductModel(
        id: 'test-id',
        name: 'iPhone 13',
        brand: 'Apple',
        model: 'Pro Max',
        purchaseDate: purchaseDate,
        warrantyMonths: 24,
        category: 'Elektronik',
        note: 'Test note',
        isOnlineStore: false,
      );
    });

    test('ProductModel should create with valid data', () {
      expect(product.id, 'test-id');
      expect(product.name, 'iPhone 13');
      expect(product.brand, 'Apple');
      expect(product.model, 'Pro Max');
      expect(product.purchaseDate, purchaseDate);
      expect(product.warrantyMonths, 24);
      expect(product.category, 'Elektronik');
      expect(product.note, 'Test note');
      expect(product.isOnlineStore, false);
    });

    test('expiryDate should calculate correctly', () {
      final expectedExpiryDate = DateTime(2025, 1, 15);
      expect(product.expiryDate, expectedExpiryDate);
    });

    test('expiryDate should handle year overflow correctly', () {
      final decemberProduct = ProductModel(
        name: 'Test Product',
        brand: 'Test Brand',
        model: 'Test Model',
        purchaseDate: DateTime(2023, 12, 15),
        warrantyMonths: 3,
        category: 'Test',
      );
      
      expect(decemberProduct.expiryDate.year, 2024);
      expect(decemberProduct.expiryDate.month, 3);
      expect(decemberProduct.expiryDate.day, 15);
    });

    test('remainingDays should calculate correctly for future date', () {
      final now = DateTime.now();
      final futureProduct = ProductModel(
        name: 'Future Product',
        brand: 'Test Brand',
        model: 'Test Model',
        purchaseDate: now,
        warrantyMonths: 2,
        category: 'Test',
      );
      
      expect(futureProduct.remainingDays, greaterThan(0));
    });

    test('remainingDays should be negative for expired product', () {
      final expiredProduct = ProductModel(
        name: 'Expired Product',
        brand: 'Test Brand',
        model: 'Test Model',
        purchaseDate: DateTime(2020, 1, 1),
        warrantyMonths: 12,
        category: 'Test',
      );
      
      expect(expiredProduct.remainingDays, lessThan(0));
    });

    test('remainingDays should be zero for product expiring today', () {
      final today = DateTime.now();
      final expiringProduct = ProductModel(
        name: 'Expiring Product',
        brand: 'Test Brand',
        model: 'Test Model',
        purchaseDate: today.subtract(const Duration(days: 365)),
        warrantyMonths: 12,
        category: 'Test',
      );
      
      // Allow for small time differences (within 1 day)
      expect(expiringProduct.remainingDays.abs(), lessThanOrEqualTo(1));
    });

    test('toMap should convert product to map correctly', () {
      final map = product.toMap();
      
      expect(map['id'], 'test-id');
      expect(map['name'], 'iPhone 13');
      expect(map['brand'], 'Apple');
      expect(map['model'], 'Pro Max');
      expect(map['purchaseDate'], isA<Timestamp>());
      expect(map['warrantyMonths'], 24);
      expect(map['category'], 'Elektronik');
      expect(map['note'], 'Test note');
      expect(map['isOnlineStore'], false);
    });

    test('fromMap should create product from map correctly', () {
      final timestamp = Timestamp.fromDate(purchaseDate);
      final map = {
        'id': 'test-id',
        'name': 'iPhone 13',
        'brand': 'Apple',
        'model': 'Pro Max',
        'purchaseDate': timestamp,
        'warrantyMonths': 24,
        'category': 'Elektronik',
        'note': 'Test note',
        'isOnlineStore': false,
        'invoiceImageUrl': 'test-image-url',
        'imageUrls': ['url1', 'url2'],
        'serviceHistory': [],
      };
      
      final createdProduct = ProductModel.fromMap(map, 'test-id');
      
      expect(createdProduct.id, 'test-id');
      expect(createdProduct.name, 'iPhone 13');
      expect(createdProduct.brand, 'Apple');
      expect(createdProduct.model, 'Pro Max');
      expect(createdProduct.purchaseDate, purchaseDate);
      expect(createdProduct.warrantyMonths, 24);
      expect(createdProduct.category, 'Elektronik');
      expect(createdProduct.note, 'Test note');
      expect(createdProduct.isOnlineStore, false);
      expect(createdProduct.invoiceImageUrl, 'test-image-url');
      expect(createdProduct.imageUrls, ['url1', 'url2']);
      expect(createdProduct.serviceHistory, []);
    });

    test('fromMap should handle missing optional fields', () {
      final timestamp = Timestamp.fromDate(purchaseDate);
      final map = {
        'name': 'iPhone 13',
        'brand': 'Apple',
        'model': 'Pro Max',
        'purchaseDate': timestamp,
        'warrantyMonths': 24,
        'category': 'Elektronik',
        'isOnlineStore': false,
      };
      
      final createdProduct = ProductModel.fromMap(map, 'test-id');
      
      expect(createdProduct.id, 'test-id');
      expect(createdProduct.name, 'iPhone 13');
      expect(createdProduct.note, null);
      expect(createdProduct.invoiceImageUrl, null);
      expect(createdProduct.imageUrls, null);
      expect(createdProduct.serviceHistory, null);
    });

    test('fromMap should handle legacy invoiceImageUrl field', () {
      final timestamp = Timestamp.fromDate(purchaseDate);
      final map = {
        'name': 'iPhone 13',
        'brand': 'Apple',
        'model': 'Pro Max',
        'purchaseDate': timestamp,
        'warrantyMonths': 24,
        'category': 'Elektronik',
        'isOnlineStore': false,
        'invoiceImageUrl': 'legacy-image-url',
        // imageUrls field is missing (legacy data)
      };
      
      final createdProduct = ProductModel.fromMap(map, 'test-id');
      
      expect(createdProduct.invoiceImageUrl, 'legacy-image-url');
      expect(createdProduct.imageUrls, ['legacy-image-url']); // Should convert to array
    });

    test('fromMap should prefer imageUrls over invoiceImageUrl when both exist', () {
      final timestamp = Timestamp.fromDate(purchaseDate);
      final map = {
        'name': 'iPhone 13',
        'brand': 'Apple',
        'model': 'Pro Max',
        'purchaseDate': timestamp,
        'warrantyMonths': 24,
        'category': 'Elektronik',
        'isOnlineStore': false,
        'invoiceImageUrl': 'legacy-image-url',
        'imageUrls': ['new-url-1', 'new-url-2'],
      };
      
      final createdProduct = ProductModel.fromMap(map, 'test-id');
      
      expect(createdProduct.invoiceImageUrl, 'new-url-1'); // Should use first from imageUrls
      expect(createdProduct.imageUrls, ['new-url-1', 'new-url-2']);
    });

    test('products with same data should be equal', () {
      final product2 = ProductModel(
        id: 'test-id',
        name: 'iPhone 13',
        brand: 'Apple',
        model: 'Pro Max',
        purchaseDate: purchaseDate,
        warrantyMonths: 24,
        category: 'Elektronik',
        note: 'Test note',
        isOnlineStore: false,
      );
      
      expect(product, equals(product2));
    });

    test('products with different data should not be equal', () {
      final differentProduct = ProductModel(
        name: 'Samsung Galaxy',
        brand: 'Samsung',
        model: 'S21',
        purchaseDate: purchaseDate,
        warrantyMonths: 12,
        category: 'Elektronik',
      );
      
      expect(product, isNot(equals(differentProduct)));
    });

    test('toString should return meaningful representation', () {
      final stringRepresentation = product.toString();
      expect(stringRepresentation, contains('iPhone 13'));
      expect(stringRepresentation, contains('Apple'));
      expect(stringRepresentation, contains('Pro Max'));
    });
  });
}

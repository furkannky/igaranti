import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/product_model.dart';

class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final int exportedCount;
  final String format;

  ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    required this.exportedCount,
    required this.format,
  });
}

class ExportService {
  static ExportService? _instance;
  static ExportService get instance => _instance ??= ExportService._();
  
  ExportService._();
  
  // Ürünleri JSON formatında dışa aktar
  Future<ExportResult> exportToJson(List<ProductModel> products, {String? fileName}) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final defaultFileName = fileName ?? 'igaranti_backup_$timestamp.json';
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$defaultFileName');
      
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalProducts': products.length,
        'products': products.map((p) => _productToJson(p)).toList(),
      };
      
      await file.writeAsString(jsonEncode(exportData));
      
      debugPrint('✅ JSON export successful: ${file.path}');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        exportedCount: products.length,
        format: 'JSON',
      );
    } catch (e) {
      debugPrint('❌ JSON export failed: $e');
      return ExportResult(
        success: false,
        errorMessage: e.toString(),
        exportedCount: 0,
        format: 'JSON',
      );
    }
  }
  
  // Ürünleri CSV formatında dışa aktar
  Future<ExportResult> exportToCsv(List<ProductModel> products, {String? fileName}) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final defaultFileName = fileName ?? 'igaranti_backup_$timestamp.csv';
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$defaultFileName');
      
      final csvData = _generateCsvData(products);
      await file.writeAsString(csvData);
      
      debugPrint('✅ CSV export successful: ${file.path}');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        exportedCount: products.length,
        format: 'CSV',
      );
    } catch (e) {
      debugPrint('❌ CSV export failed: $e');
      return ExportResult(
        success: false,
        errorMessage: e.toString(),
        exportedCount: 0,
        format: 'CSV',
      );
    }
  }
  
  // Ürünleri PDF formatında dışa aktar
  Future<ExportResult> exportToPdf(List<ProductModel> products, {String? fileName}) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final defaultFileName = fileName ?? 'igaranti_backup_$timestamp.pdf';
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$defaultFileName');
      
      final pdf = pw.Document();
      
      // Başlık sayfası
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('iGaranti Ürün Listesi', style: pw.TextStyle(fontSize: 24)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Dışa Aktarma Tarihi: ${_formatDate(DateTime.now())}'),
                pw.Text('Toplam Ürün: ${products.length}'),
                pw.SizedBox(height: 30),
                pw.Text('Açıklama:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Bu dosya iGaranti uygulamasından dışa aktarılmış ürün listesini içerir.'),
              ],
            );
          },
        ),
      );
      
      // Ürün detayları sayfaları
      for (int i = 0; i < products.length; i += 5) {
        final chunk = products.skip(i).take(5).toList();
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 1,
                    child: pw.Text('Ürünler ${i + 1}-${(i + chunk.length).clamp(0, products.length)}'),
                  ),
                  pw.SizedBox(height: 20),
                  ...chunk.map((product) => _buildProductPdfWidget(product)),
                ],
              );
            },
          ),
        );
      }
      
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('✅ PDF export successful: ${file.path}');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        exportedCount: products.length,
        format: 'PDF',
      );
    } catch (e) {
      debugPrint('❌ PDF export failed: $e');
      return ExportResult(
        success: false,
        errorMessage: e.toString(),
        exportedCount: 0,
        format: 'PDF',
      );
    }
  }
  
  // JSON'dan ürünleri içe aktar
  Future<ExportResult> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return ExportResult(
          success: false,
          errorMessage: 'Dosya bulunamadı',
          exportedCount: 0,
          format: 'JSON',
        );
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      // Versiyon kontrolü
      if (data['version'] != '1.0') {
        return ExportResult(
          success: false,
          errorMessage: 'Desteklenmeyen dosya versiyonu',
          exportedCount: 0,
          format: 'JSON',
        );
      }
      
      final productsJson = data['products'] as List;
      final products = productsJson.map((json) => _productFromJson(json)).toList();
      
      debugPrint('✅ JSON import successful: ${products.length} products');
      
      return ExportResult(
        success: true,
        filePath: filePath,
        exportedCount: products.length,
        format: 'JSON',
      );
    } catch (e) {
      debugPrint('❌ JSON import failed: $e');
      return ExportResult(
        success: false,
        errorMessage: e.toString(),
        exportedCount: 0,
        format: 'JSON',
      );
    }
  }
  
  // CSV'den ürünleri içe aktar
  Future<ExportResult> importFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return ExportResult(
          success: false,
          errorMessage: 'Dosya bulunamadı',
          exportedCount: 0,
          format: 'CSV',
        );
      }
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.length < 2) {
        return ExportResult(
          success: false,
          errorMessage: 'CSV dosyası geçersiz',
          exportedCount: 0,
          format: 'CSV',
        );
      }
      
      final headers = lines[0].split(',');
      final products = <ProductModel>[];
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final values = line.split(',');
        if (values.length != headers.length) continue;
        
        final product = _productFromCsv(headers, values);
        if (product != null) {
          products.add(product);
        }
      }
      
      debugPrint('✅ CSV import successful: ${products.length} products');
      
      return ExportResult(
        success: true,
        filePath: filePath,
        exportedCount: products.length,
        format: 'CSV',
      );
    } catch (e) {
      debugPrint('❌ CSV import failed: $e');
      return ExportResult(
        success: false,
        errorMessage: e.toString(),
        exportedCount: 0,
        format: 'CSV',
      );
    }
  }
  
  // Dosyayı paylaş
  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Dosya bulunamadı');
      }
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'iGaranti Ürün Listesi',
      );
      
      debugPrint('✅ File shared successfully');
    } catch (e) {
      debugPrint('❌ File sharing failed: $e');
      rethrow;
    }
  }
  
  // Tüm dışa aktarma formatlarını test et
  Future<Map<String, ExportResult>> testAllFormats(List<ProductModel> products) async {
    final results = <String, ExportResult>{};
    
    // JSON test
    results['json'] = await exportToJson(products, fileName: 'test_export.json');
    
    // CSV test
    results['csv'] = await exportToCsv(products, fileName: 'test_export.csv');
    
    // PDF test
    results['pdf'] = await exportToPdf(products, fileName: 'test_export.pdf');
    
    return results;
  }
  
  // Dışa aktarma istatistikleri
  Map<String, dynamic> getExportStats(List<ProductModel> products) {
    final categories = <String, int>{};
    final brands = <String, int>{};
    final warrantyStats = <String, int>{};
    
    int expiredCount = 0;
    int expiringSoonCount = 0;
    int activeCount = 0;
    
    for (final product in products) {
      // Kategori istatistikleri
      categories[product.category] = (categories[product.category] ?? 0) + 1;
      
      // Marka istatistikleri
      brands[product.brand] = (brands[product.brand] ?? 0) + 1;
      
      // Garanti istatistikleri
      final warrantyKey = '${product.warrantyMonths} ay';
      warrantyStats[warrantyKey] = (warrantyStats[warrantyKey] ?? 0) + 1;
      
      // Durum istatistikleri
      if (product.remainingDays <= 0) {
        expiredCount++;
      } else if (product.remainingDays <= 30) {
        expiringSoonCount++;
      } else {
        activeCount++;
      }
    }
    
    return {
      'totalProducts': products.length,
      'categories': categories,
      'brands': brands,
      'warrantyStats': warrantyStats,
      'statusStats': {
        'expired': expiredCount,
        'expiringSoon': expiringSoonCount,
        'active': activeCount,
      },
      'exportDate': DateTime.now().toIso8601String(),
    };
  }
  
  // CSV verisi oluştur
  String _generateCsvData(List<ProductModel> products) {
    final headers = [
      'ID',
      'Ürün Adı',
      'Marka',
      'Model',
      'Kategori',
      'Satın Alma Tarihi',
      'Garanti Süresi (Ay)',
      'Garanti Bitiş Tarihi',
      'Kalan Gün',
      'Not',
      'Online Mağaza',
    ];
    
    final rows = <List<String>>[];
    rows.add(headers);
    
    for (final product in products) {
      rows.add([
        product.id ?? '',
        product.name,
        product.brand,
        product.model,
        product.category,
        _formatDate(product.purchaseDate),
        product.warrantyMonths.toString(),
        _formatDate(product.expiryDate),
        product.remainingDays.toString(),
        product.note ?? '',
        product.isOnlineStore.toString(),
      ]);
    }
    
    return rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
  }
  
  // PDF widget oluştur
  pw.Widget _buildProductPdfWidget(ProductModel product) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(product.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 5),
          pw.Text('Marka: ${product.brand} | Model: ${product.model}'),
          pw.Text('Kategori: ${product.category}'),
          pw.Text('Satın Alma: ${_formatDate(product.purchaseDate)}'),
          pw.Text('Garanti: ${product.warrantyMonths} ay'),
          pw.Text('Durum: ${_getWarrantyStatus(product.remainingDays)}'),
          if (product.note != null && product.note!.isNotEmpty)
            pw.Text('Not: ${product.note}'),
        ],
      ),
    );
  }
  
  // ProductModel'i JSON'a dönüştür
  Map<String, dynamic> _productToJson(ProductModel product) {
    return {
      'id': product.id,
      'name': product.name,
      'brand': product.brand,
      'model': product.model,
      'category': product.category,
      'purchaseDate': product.purchaseDate.toIso8601String(),
      'warrantyMonths': product.warrantyMonths,
      'expiryDate': product.expiryDate.toIso8601String(),
      'remainingDays': product.remainingDays,
      'note': product.note,
      'isOnlineStore': product.isOnlineStore,
      'imageUrls': product.imageUrls,
      'invoiceImageUrl': product.invoiceImageUrl,
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
      category: json['category'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      warrantyMonths: json['warrantyMonths'],
      note: json['note'],
      isOnlineStore: json['isOnlineStore'] ?? false,
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      invoiceImageUrl: json['invoiceImageUrl'],
    );
  }
  
  // CSV'den ProductModel oluştur
  ProductModel? _productFromCsv(List<String> headers, List<String> values) {
    try {
      final Map<String, String> data = {};
      for (int i = 0; i < headers.length && i < values.length; i++) {
        data[headers[i]] = values[i].replaceAll('"', '');
      }
      
      return ProductModel(
        name: data['Ürün Adı'] ?? '',
        brand: data['Marka'] ?? '',
        model: data['Model'] ?? '',
        category: data['Kategori'] ?? '',
        purchaseDate: DateTime.parse(data['Satın Alma Tarihi'] ?? DateTime.now().toIso8601String()),
        warrantyMonths: int.tryParse(data['Garanti Süresi (Ay)'] ?? '24') ?? 24,
        note: data['Not']?.isEmpty == true ? null : data['Not'],
        isOnlineStore: data['Online Mağaza']?.toLowerCase() == 'true',
      );
    } catch (e) {
      debugPrint('❌ Error parsing CSV row: $e');
      return null;
    }
  }
  
  // Tarih formatla
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  // Garanti durumunu al
  String _getWarrantyStatus(int remainingDays) {
    if (remainingDays <= 0) return 'Süresi Doldu';
    if (remainingDays <= 30) return 'Yakında Bitecek (${remainingDays} gün)';
    return 'Devam Ediyor';
  }
}

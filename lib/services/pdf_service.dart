import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateProductReport(ProductModel product) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  "iGaranti - Ürün Bilgi Kartı",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Ürün:", product.name),
                    _buildInfoRow(
                      "Marka/Model:",
                      "${product.brand} / ${product.model}",
                    ),
                    _buildInfoRow(
                      "Satın Alma:",
                      dateFmt.format(product.purchaseDate),
                    ),
                    _buildInfoRow(
                      "Garanti Bitiş:",
                      dateFmt.format(product.expiryDate),
                    ),
                    _buildInfoRow("Kategori:", product.category),
                    if (product.note != null && product.note!.isNotEmpty)
                      _buildInfoRow("Not:", product.note!),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "SERVİS GEÇMİŞİ",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (product.serviceHistory != null &&
                  product.serviceHistory!.isNotEmpty)
                pw.TableHelper.fromTextArray(
                  headers: ['Tarih', 'İşlem', 'Ücret'],
                  data: product.serviceHistory!
                      .map(
                        (e) => [
                          dateFmt.format(e.date),
                          e.description,
                          "${e.price.toStringAsFixed(2)} TL",
                        ],
                      )
                      .toList(),
                  border: pw.TableBorder.all(width: 1),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                  },
                )
              else
                pw.Text("Servis kaydı bulunmamaktadır."),
            ],
          );
        },
      ),
    );

    // PDF'i önizle ve yazdır/kaydet seçeneği sun
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${product.name}_bilgi_karti.pdf',
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localFilePath;
  bool isDownloading = true;
  String errorMessage = '';
  int? currentPage = 0;
  int? totalPages = 0;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  /// PDF'i goruntuleyiciye hazirlar. 
  /// flutter_pdfview network URL desteklemedigi icin dosyayi gecici bir buffer'a alir.
  Future<void> _preparePdf() async {
    try {
      final fileName = "temp_view_${widget.pdfUrl.hashCode}.pdf";
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      // Eger cache'de varsa direkt ac
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            localFilePath = file.path;
            isDownloading = false;
          });
        }
        return;
      }

      // Dosyayi network'ten oku
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            localFilePath = file.path;
            isDownloading = false;
          });
        }
      } else {
        throw Exception('Dosya sunucudan alinamadi (Hata: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: "Orijinal Linki Ac",
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Gosterici
          if (localFilePath != null && !isDownloading)
            PDFView(
              filePath: localFilePath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: currentPage ?? 0,
              fitPolicy: FitPolicy.BOTH,
              onRender: (pages) => setState(() {
                totalPages = pages;
                isReady = true;
              }),
              onError: (error) => setState(() => errorMessage = error.toString()),
              onPageError: (page, error) => setState(() => errorMessage = error.toString()),
              onPageChanged: (page, total) => setState(() {
                currentPage = page;
                totalPages = total;
              }),
            ),

          // Yukleme Durumu
          if (isDownloading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   CircularProgressIndicator(color: Colors.white),
                   SizedBox(height: 16),
                   Text("Belge Hazirlaniyor...", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          // Hata Durumu
          if (errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      "Belge Acilamadi",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text("Tarayicida Goruntule"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isReady && totalPages != null
          ? Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "${(currentPage ?? 0) + 1} / $totalPages",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

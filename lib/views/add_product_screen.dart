import 'dart:io'; // Dosya işlemleri için
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:igaranti/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Kamera erişimi
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../data/popular_brands.dart';
import '../services/notification_settings_service.dart';
import '../widgets/guest_login_overlay.dart';

// Dosya tipleri için enum
enum DocumentType { image, pdf }

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onSaveCompleted;

  const AddProductScreen({super.key, this.onSaveCompleted});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  // Seçilen belgeler
  List<File> _selectedProductImages = [];
  File? _selectedInvoiceFile;
  final ImagePicker _picker = ImagePicker();
  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  // Form Kontrolleri
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _noteController = TextEditingController(); // Not alanı eklendi
  final _customWarrantyMonthsController =
      TextEditingController(); // Manuel garanti süresi (Ay)
  final _customWarrantyYearsController =
      TextEditingController(); // Manuel garanti süresi (Yıl)

  DateTime _selectedDate = DateTime.now();
  int _warrantyMonths = 24;
  String _selectedCategory = 'Elektronik';
  bool _isOnline = false;
  bool _isWarrantyExpanded = false;
  bool _isCategoryExpanded = false;
  bool _isBrandExpanded = false;

  final List<String> _categories = [
    'Elektronik',
    'Mutfak',
    'Ev Gereçleri',
    'Mobilya',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _customWarrantyMonthsController.addListener(_updateCustomWarranty);
    _customWarrantyYearsController.addListener(_updateCustomWarranty);
  }

  void _updateCustomWarranty() {
    int years = int.tryParse(_customWarrantyYearsController.text) ?? 0;
    int months = int.tryParse(_customWarrantyMonthsController.text) ?? 0;

    int totalMonths = (years * 12) + months;

    if (totalMonths >= 0) {
      if (mounted) {
        setState(() {
          _warrantyMonths = totalMonths;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _noteController.dispose();
    _customWarrantyMonthsController.dispose();
    _customWarrantyYearsController.dispose();
    super.dispose();
  }

  // Ürün Fotoğrafı Seçim Fonksiyonları
  Future<void> _pickProductImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 70,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedProductImages.addAll(images.map((img) => File(img.path)));
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 70,
        );
        if (image != null) {
          setState(() {
            _selectedProductImages.add(File(image.path));
          });
        }
      }
    } catch (e) {
      debugPrint("Ürün fotoğrafı seçme hatası: $e");
    }
  }

  // Garanti Belgesi / Fatura Seçim Fonksiyonları
  Future<void> _pickInvoiceImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedInvoiceFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Fatura fotoğrafı seçme hatası: $e");
    }
  }

  Future<void> _pickInvoicePDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedInvoiceFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint("Fatura PDF seçme hatası: $e");
    }
  }

  void _showInvoicePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Fatura / Garanti Belgesi Seç"),
        content: const Text("Eklemek istediğiniz belge türünü seçin:"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickInvoiceImage(ImageSource.camera);
            },
            child: Row(
              children: const [
                Icon(Icons.camera_alt),
                SizedBox(width: 8),
                Text("Kamera ile Çek"),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickInvoiceImage(ImageSource.gallery);
            },
            child: Row(
              children: const [
                Icon(Icons.photo_library),
                SizedBox(width: 8),
                Text("Galeriden Seç"),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickInvoicePDF();
            },
            child: Row(
              children: const [
                Icon(Icons.picture_as_pdf),
                SizedBox(width: 8),
                Text("PDF Olarak Seç"),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
        ],
      ),
    );
  }

  // Garanti metni yardımcı metod
  String _getWarrantyText(int months) {
    if (months == 6) return '6 Ay';
    if (months == 12) return '1 Yıl';
    if (months == 24) return '2 Yıl';
    if (months == 36) return '3 Yıl';
    if (months == 48) return '4 Yıl';
    if (months == 60) return '5 Yıl';

    // Manuel değerler için yıl/ay hesabı
    if (months >= 12 && months % 12 == 0) {
      final years = months ~/ 12;
      return '$years Yıl';
    }
    return '$months Ay';
  }

  // Kategori seçeneği widget'ı
  Widget _buildCategoryOption(String category) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _isCategoryExpanded = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: isSelected ? Colors.blueAccent : Colors.white60,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.white38,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // Kategori ikonu yardımcı metod
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Elektronik':
        return Icons.smartphone;
      case 'Mutfak':
        return Icons.kitchen;
      case 'Ev Gereçleri':
        return Icons.home;
      case 'Mobilya':
        return Icons.chair;
      case 'Diğer':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  // Garanti seçeneği widget'ı
  Widget _buildWarrantyOption(int months) {
    final isSelected = _warrantyMonths == months;

    return GestureDetector(
      onTap: () {
        setState(() {
          _warrantyMonths = months;
          _isWarrantyExpanded = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getWarrantyText(months),
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.white38,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Ürün Ekle")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürün Adı - Kart Görünümü (Açılır Değil)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_bag,
                            color: Colors.blueAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: "Ürün adını girin",
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? "Lütfen ürün adını girin" : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Kategori Seçimi - Açılır Kart
                  GestureDetector(
                    onTap: () => setState(
                      () => _isCategoryExpanded = !_isCategoryExpanded,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Kart Başlığı
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      color: Colors.blueAccent,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Kategori",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _selectedCategory,
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isCategoryExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white60,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),

                          // Açılır Seçenekler
                          if (_isCategoryExpanded)
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),

                                  // Kaydırılabilir kategori seçenekleri
                                  SizedBox(
                                    height: 200,
                                    child: ListView(
                                      children: [
                                        ..._categories.map(
                                          (category) =>
                                              _buildCategoryOption(category),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Marka ve Model - Birleşik Kart
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isBrandExpanded = !_isBrandExpanded),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Kart Başlığı
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.branding_watermark,
                                      color: Colors.blueAccent,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Marka & Model",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "${_brandController.text.isEmpty ? "Marka" : _brandController.text} • ${_modelController.text.isEmpty ? "Model" : _modelController.text}",
                                          style: TextStyle(
                                            color:
                                                (_brandController
                                                        .text
                                                        .isEmpty &&
                                                    _modelController
                                                        .text
                                                        .isEmpty)
                                                ? Colors.white38
                                                : Colors.blueAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isBrandExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white60,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),

                          // Açılır İçerik
                          if (_isBrandExpanded)
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),

                                  // Marka alanı
                                  Autocomplete<String>(
                                    initialValue: TextEditingValue(
                                      text: _brandController.text,
                                    ),
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                          if (textEditingValue.text.isEmpty) {
                                            return const Iterable<
                                              String
                                            >.empty();
                                          }
                                          final brands =
                                              PopularBrands.getBrandsForCategory(
                                                _selectedCategory,
                                              );
                                          return brands.where((brand) {
                                            return brand.toLowerCase().contains(
                                              textEditingValue.text
                                                  .toLowerCase(),
                                            );
                                          });
                                        },
                                    onSelected: (String selection) {
                                      _brandController.text = selection;
                                      setState(() {});
                                    },
                                    fieldViewBuilder:
                                        (
                                          context,
                                          textEditingController,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          return TextFormField(
                                            controller: textEditingController,
                                            focusNode: focusNode,
                                            decoration: const InputDecoration(
                                              labelText: "Marka *",
                                              labelStyle: TextStyle(
                                                color: Colors.white70,
                                              ),
                                              hintText:
                                                  "Marka girin veya seçin",
                                              hintStyle: TextStyle(
                                                color: Colors.white38,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                                borderSide: BorderSide(
                                                  color: Colors.white38,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                                borderSide: BorderSide(
                                                  color: Colors.white38,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                                borderSide: BorderSide(
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            validator: (value) {
                                              // Marka zorunlu değil, sadece boş bırakılabilir
                                              return null;
                                            },
                                            onChanged: (value) {
                                              _brandController.text = value;
                                              setState(() {});
                                            },
                                            onFieldSubmitted: (value) =>
                                                onFieldSubmitted(),
                                          );
                                        },
                                  ),

                                  const SizedBox(height: 12),

                                  // Model alanı
                                  TextFormField(
                                    controller: _modelController,
                                    decoration: const InputDecoration(
                                      labelText: "Model",
                                      labelStyle: TextStyle(
                                        color: Colors.white70,
                                      ),
                                      hintText: "Model girin",
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white38,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white38,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    onChanged: (value) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: Colors.blueAccent,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Satın Alma Tarihi",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'dd.MM.yyyy',
                                    ).format(_selectedDate),
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                locale: const Locale('tr', 'TR'),
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Tarih Seç",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Garanti Süresi Seçimi - Açılır Kart
                  GestureDetector(
                    onTap: () => setState(
                      () => _isWarrantyExpanded = !_isWarrantyExpanded,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Kart Başlığı
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.blueAccent,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Garanti Süresi",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _getWarrantyText(_warrantyMonths),
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isWarrantyExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white60,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),

                          // Açılır Seçenekler
                          if (_isWarrantyExpanded)
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),

                                  // Kaydırılabilir seçenekler
                                  SizedBox(
                                    height: 200,
                                    child: ListView(
                                      children: [
                                        // Hazır seçenekler
                                        ...[6, 12, 24, 36, 48, 60].map(
                                          (months) =>
                                              _buildWarrantyOption(months),
                                        ),

                                        // Manuel giriş alanı
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Manuel Giriş",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _customWarrantyYearsController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration: const InputDecoration(
                                                        hintText: "Yıl",
                                                        hintStyle: TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 14,
                                                        ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  8,
                                                                ),
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .white38,
                                                              ),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.all(
                                                                    Radius.circular(
                                                                      8,
                                                                    ),
                                                                  ),
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Colors
                                                                        .white38,
                                                                  ),
                                                            ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  8,
                                                                ),
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .blueAccent,
                                                              ),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _customWarrantyMonthsController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration: const InputDecoration(
                                                        hintText: "Ay",
                                                        hintStyle: TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 14,
                                                        ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  8,
                                                                ),
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .white38,
                                                              ),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.all(
                                                                    Radius.circular(
                                                                      8,
                                                                    ),
                                                                  ),
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Colors
                                                                        .white38,
                                                                  ),
                                                            ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  8,
                                                                ),
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .blueAccent,
                                                              ),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (_warrantyMonths > 0)
                                                Text(
                                                  "Toplam: $_warrantyMonths Ay",
                                                  style: const TextStyle(
                                                    color: Colors.blueAccent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SwitchListTile(
                    title: const Text("Online Mağaza"),
                    value: _isOnline,
                    onChanged: (val) => setState(() => _isOnline = val),
                  ),

                  const Divider(),

                  // Ürün Fotoğrafları Alanı
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Ürün Fotoğrafları Ekle",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Ürünün fiziksel durumunu gösteren fotoğraflar",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickProductImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text("Kamera"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: const BorderSide(
                                      color: Colors.blueAccent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickProductImage(ImageSource.gallery),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: const Text("Galeri"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: const BorderSide(
                                      color: Colors.blueAccent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Seçilen Ürün Fotoğrafları Listesi
                  if (_selectedProductImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedProductImages.length,
                          itemBuilder: (context, index) {
                            final file = _selectedProductImages[index];
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      file,
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 15,
                                  top: 5,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    radius: 15,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedProductImages.removeAt(
                                            index,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Garanti Belgesi / Fatura Alanı
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Colors.orangeAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Garanti Belgesi / Fatura Ekle",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Fatura, garanti belgesi veya fiş fotoğrafı/PDF",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Fatura seçilmişse onu göster, seçilmemişse ekleme butonunu göster
                          _selectedInvoiceFile != null
                              ? Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.orangeAccent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            _selectedInvoiceFile!.path
                                                .toLowerCase()
                                                .endsWith('.pdf')
                                            ? Container(
                                                color: Colors.red.withValues(
                                                  alpha: 0.1,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: const [
                                                    Icon(
                                                      Icons.picture_as_pdf,
                                                      color: Colors.redAccent,
                                                      size: 50,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      "Fatura/Belge (PDF)",
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Image.file(
                                                _selectedInvoiceFile!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.red,
                                        radius: 18,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(
                                            () => _selectedInvoiceFile = null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _showInvoicePickerDialog,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text(
                                      "Belge Seç (Galeri, Kamera veya PDF)",
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orangeAccent,
                                      side: const BorderSide(
                                        color: Colors.orangeAccent,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: productController.isLoading
                          ? null
                          : _saveProduct,
                      child: productController.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "GARANTİYİ KAYDET",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isGuest)
            Positioned.fill(
              child: const GuestLoginOverlay(
                title: "Ürün Eklemek İçin Giriş Yapmalısınız",
                description:
                    "Ürün ekleyebilmek, garantilerinizi kaydedip yönetebilmek için lütfen oturum açın.",
              ),
            ),
        ],
      ),
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Loading state'i başlat
      setState(() {});

      final product = ProductModel(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? "Belirtilmemiş"
            : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? "Belirtilmemiş"
            : _modelController.text.trim(),
        purchaseDate: _selectedDate,
        warrantyMonths: _warrantyMonths,
        category: _selectedCategory,
        isOnlineStore: _isOnline,
        note: _noteController.text.trim(),
      );

      try {
        final success =
            await Provider.of<ProductController>(
              context,
              listen: false,
            ).addProduct(
              product,
              _selectedProductImages,
              _selectedInvoiceFile,
              context,
            );

        // Başarılı mesajını göster ve navigation'ı yap
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ürün başarıyla eklendi!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Bildirimleri arka planda planla, navigation'ı bekleme
          _scheduleProductNotifications(product).catchError((e) {
            debugPrint("Bildirim planlama hatası: $e");
          });

          // Navigation'ı geciktir
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            // Eğer callback verilmişse çalıştır (MainScreen'de sekmeyi değiştirmek için)
            if (widget.onSaveCompleted != null) {
              widget.onSaveCompleted!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        }
      } catch (e) {
        debugPrint("Ürün ekleme hatası: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hata: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Loading state'i sonlandır
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _scheduleProductNotifications(ProductModel product) async {
    // Bildirimlerin açık olup olmadığını kontrol et
    final notificationsEnabled = await _settingsService
        .getNotificationsEnabled();
    if (!notificationsEnabled) return;

    // İzinleri kontrol et
    final hasPermission = await _notificationService.arePermissionsGranted();
    if (!hasPermission) return;

    final daysBeforeExpiry = await _settingsService.getDaysBeforeExpiry();

    // Normal hatırlatma
    if (product.remainingDays > daysBeforeExpiry) {
      final normalNotificationDate = product.expiryDate.subtract(
        Duration(days: daysBeforeExpiry),
      );

      await _notificationService.scheduleWarrantyNotification(
        id: product.id.hashCode,
        title: "Garanti Bitişi Yaklaşıyor",
        body:
            "${product.name} ürününün garantisi $daysBeforeExpiry gün içinde bitecek",
        scheduledDate: normalNotificationDate,
        payload: product.id,
      );
    }

    // Kritik hatırlatma (7 gün kala)
    if (product.remainingDays > 7) {
      final criticalNotificationDate = product.expiryDate.subtract(
        const Duration(days: 7),
      );

      await _notificationService.scheduleCriticalNotification(
        id: product.id.hashCode + 100000,
        title: "Kritik Garanti Uyarısı",
        body: "${product.name} ürününün garantisi 7 gün içinde bitecek!",
        scheduledDate: criticalNotificationDate,
        payload: product.id,
      );
    }
  }
}

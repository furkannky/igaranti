import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../data/popular_brands.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _noteController;
  late TextEditingController _customWarrantyMonthsController;
  late TextEditingController _customWarrantyYearsController;

  DateTime? _selectedDate;
  String _selectedCategory = 'Elektronik';

  final List<File> _newProductImages = []; // Yeni eklenen ürün fotoğrafları
  List<String> _existingProductImages = []; // Firebase'den gelen eski ürün fotoğrafları

  File? _newInvoiceFile; // Yeni eklenen fatura
  String? _existingInvoiceUrl; // Firebase'den gelen fatura URL'si

  bool _isOnlineStore = false;
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

  int _warrantyMonths = 24;

  @override
  void initState() {
    super.initState();
    // Mevcut değerleri doldur
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand);
    _modelController = TextEditingController(text: widget.product.model);
    _noteController = TextEditingController(text: widget.product.note ?? '');

    _warrantyMonths = widget.product.warrantyMonths;
    int years = _warrantyMonths ~/ 12;
    int months = _warrantyMonths % 12;

    _customWarrantyYearsController = TextEditingController(
      text: years > 0 ? years.toString() : '',
    );
    _customWarrantyMonthsController = TextEditingController(
      text: months > 0 ? months.toString() : '',
    );

    _customWarrantyMonthsController.addListener(_updateCustomWarranty);
    _customWarrantyYearsController.addListener(_updateCustomWarranty);

    _selectedDate = widget.product.purchaseDate;
    _selectedCategory = widget.product.category;
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }
    _isOnlineStore = widget.product.isOnlineStore;

    if (widget.product.imageUrls != null && widget.product.imageUrls!.isNotEmpty) {
      _existingProductImages = List.from(widget.product.imageUrls!);
    }
    if (widget.product.invoiceImageUrl != null) {
      _existingInvoiceUrl = widget.product.invoiceImageUrl!;
    }
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
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await picker.pickMultiImage(
          imageQuality: 70,
        );
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _newProductImages.addAll(
              pickedFiles.map((file) => File(file.path)),
            );
          });
        }
      } else {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          imageQuality: 70,
        );
        if (pickedFile != null) {
          setState(() {
            _newProductImages.add(File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      debugPrint("Görsel seçme hatası: $e");
    }
  }

  Future<void> _pickInvoiceImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _newInvoiceFile = File(image.path);
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
          _newInvoiceFile = File(result.files.single.path!);
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
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Elektronik': return Icons.smartphone;
      case 'Mutfak': return Icons.kitchen;
      case 'Ev Gereçleri': return Icons.home;
      case 'Mobilya': return Icons.chair;
      case 'Diğer': return Icons.more_horiz;
      default: return Icons.category;
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
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
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
              const Icon(Icons.radio_button_unchecked, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen satın alma tarihini seçin')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final updatedProduct = ProductModel(
          id: widget.product.id,
          name: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          purchaseDate: _selectedDate!,
          warrantyMonths: _warrantyMonths,
          category: _selectedCategory,
          note: _noteController.text.trim(),
          isOnlineStore: _isOnlineStore,
          serviceHistory: widget.product.serviceHistory,
        );

        final productController = Provider.of<ProductController>(
          context,
          listen: false,
        );

        await productController.updateProduct(
          updatedProduct,
          newProductImages: _newProductImages,
          remainingProductImages: _existingProductImages,
          newInvoiceFile: _newInvoiceFile,
          remainingInvoiceUrl: _existingInvoiceUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla güncellendi!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata oluştu: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ürünü Düzenle')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ürün Adı
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
                          const Icon(Icons.shopping_bag, color: Colors.blueAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: "Ürün adını girin",
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              validator: (v) => v!.isEmpty ? "Lütfen ürün adını girin" : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Kategori Seçimi
                  GestureDetector(
                    onTap: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.category, color: Colors.blueAccent, size: 24),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icon(
                                  _isCategoryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.white60,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
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
                                  SizedBox(
                                    height: 200,
                                    child: ListView(
                                      children: _categories.map((c) => _buildCategoryOption(c)).toList(),
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

                  // Marka & Model
                  GestureDetector(
                    onTap: () => setState(() => _isBrandExpanded = !_isBrandExpanded),
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.branding_watermark, color: Colors.blueAccent, size: 24),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: (_brandController.text.isEmpty && _modelController.text.isEmpty)
                                                ? Colors.white38 : Colors.blueAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isBrandExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.white60,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
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
                                  Autocomplete<String>(
                                    initialValue: TextEditingValue(text: _brandController.text),
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                                      final brands = PopularBrands.getBrandsForCategory(_selectedCategory);
                                      return brands.where((brand) => brand.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (String selection) {
                                      _brandController.text = selection;
                                      setState(() {});
                                    },
                                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                      return TextFormField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          labelText: "Marka *",
                                          labelStyle: TextStyle(color: Colors.white70),
                                          hintText: "Marka girin veya seçin",
                                          hintStyle: TextStyle(color: Colors.white38),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                        ),
                                        style: const TextStyle(color: Colors.white),
                                        onChanged: (value) {
                                          _brandController.text = value;
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _modelController,
                                    decoration: const InputDecoration(
                                      labelText: "Model",
                                      labelStyle: TextStyle(color: Colors.white70),
                                      hintText: "Model girin",
                                      hintStyle: TextStyle(color: Colors.white38),
                                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
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

                  // Satın Alma Tarihi
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
                              const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 24),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Satın Alma Tarihi",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd.MM.yyyy').format(_selectedDate!),
                                    style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500),
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
                                initialDate: _selectedDate!,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _selectedDate = picked);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Tarih Seç", style: TextStyle(color: Colors.blueAccent)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Garanti Süresi
                  GestureDetector(
                    onTap: () => setState(() => _isWarrantyExpanded = !_isWarrantyExpanded),
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified, color: Colors.blueAccent, size: 24),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Garanti Süresi",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                        ),
                                        Text(
                                          _getWarrantyText(_warrantyMonths),
                                          style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isWarrantyExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.white60,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
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
                                  SizedBox(
                                    height: 200,
                                    child: ListView(
                                      children: [
                                        ...[6, 12, 24, 36, 48, 60].map((m) => _buildWarrantyOption(m)),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Manuel Giriş", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller: _customWarrantyYearsController,
                                                      keyboardType: TextInputType.number,
                                                      decoration: const InputDecoration(
                                                        hintText: "Yıl",
                                                        hintStyle: TextStyle(color: Colors.white38),
                                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                                      ),
                                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller: _customWarrantyMonthsController,
                                                      keyboardType: TextInputType.number,
                                                      decoration: const InputDecoration(
                                                        hintText: "Ay",
                                                        hintStyle: TextStyle(color: Colors.white38),
                                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                                      ),
                                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                                    ),
                                                  ),
                                                ],
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
                    title: const Text("Online Mağaza", style: TextStyle(color: Colors.white)),
                    activeThumbColor: Colors.blueAccent,
                    value: _isOnlineStore,
                    onChanged: (val) => setState(() => _isOnlineStore = val),
                  ),

                  const Divider(color: Colors.white24, height: 32),

                  // Ürün Fotoğrafları Alanı
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.add_photo_alternate, color: Colors.blueAccent, size: 20),
                              SizedBox(width: 8),
                              Text("Ürün Fotoğrafları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickProductImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text("Kamera"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: const BorderSide(color: Colors.blueAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickProductImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text("Galeri"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: const BorderSide(color: Colors.blueAccent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fotoğraflar Listesi
                  if (_existingProductImages.isNotEmpty || _newProductImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._existingProductImages.map((url) => Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(url, height: 120, width: 120, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  right: 15, top: 5,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red, radius: 15,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                                      onPressed: () => setState(() => _existingProductImages.remove(url)),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                            ..._newProductImages.asMap().entries.map((entry) => Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(entry.value, height: 120, width: 120, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  right: 15, top: 5,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red, radius: 15,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                      onPressed: () => setState(() => _newProductImages.removeAt(entry.key)),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Garanti Belgesi / Fatura
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.receipt_long, color: Colors.orangeAccent, size: 20),
                              SizedBox(width: 8),
                              Text("Garanti Belgesi / Fatura", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_newInvoiceFile != null || _existingInvoiceUrl != null)
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity, height: 150,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orangeAccent, width: 2)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _newInvoiceFile != null
                                        ? (_newInvoiceFile!.path.toLowerCase().endsWith('.pdf')
                                          ? Container(
                                              color: Colors.red.withValues(alpha: 0.1),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 50),
                                                  SizedBox(height: 8),
                                                  Text("Yeni PDF Seçildi", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            )
                                          : Image.file(_newInvoiceFile!, fit: BoxFit.cover))
                                        : Image.network(_existingInvoiceUrl!, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  right: 8, top: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red, radius: 18,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                      onPressed: () => setState(() { _newInvoiceFile = null; _existingInvoiceUrl = null; }),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showInvoicePickerDialog,
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Belge Seç"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orangeAccent,
                                  side: const BorderSide(color: Colors.orangeAccent),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Notlar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Notlar (Opsiyonel)",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _updateProduct,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("GÜNCELLE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

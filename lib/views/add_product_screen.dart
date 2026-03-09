import 'dart:io'; // Dosya işlemleri için
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Kamera erişimi
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../data/popular_brands.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onSaveCompleted;

  const AddProductScreen({super.key, this.onSaveCompleted});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  // Resim Seçimi Değişkenleri
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  // Form Kontrolleri
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _noteController = TextEditingController(); // Not alanı eklendi
  final _customWarrantyController = TextEditingController(); // Manuel garanti süresi

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

  // Kamera/Galeri seçim fonksiyonu
  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } else {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    }
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
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.blueAccent.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
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
              const Icon(
                Icons.check_circle,
                color: Colors.blueAccent,
                size: 18,
              )
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
          color: isSelected 
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.blueAccent.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
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
              const Icon(
                Icons.check_circle,
                color: Colors.blueAccent,
                size: 18,
              )
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

    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Ürün Ekle")),
      body: SingleChildScrollView(
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
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
                          validator: (v) => v!.isEmpty ? "Lütfen ürün adını girin" : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 15),

              // Marka ve Model - Birleşik Kart
              GestureDetector(
                onTap: () => setState(() => _isBrandExpanded = !_isBrandExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
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
                            color: Colors.black.withOpacity(0.2),
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
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<String>.empty();
                                  }
                                  final brands = PopularBrands.getBrandsForCategory(
                                    _selectedCategory,
                                  );
                                  return brands.where((brand) {
                                    return brand.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase(),
                                    );
                                  });
                                },
                                onSelected: (String selection) {
                                  _brandController.text = selection;
                                  setState(() {});
                                },
                                fieldViewBuilder: (
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
                                      labelStyle: TextStyle(color: Colors.white70),
                                      hintText: "Marka girin veya seçin",
                                      hintStyle: TextStyle(color: Colors.white38),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                        borderSide: BorderSide(color: Colors.white38),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                        borderSide: BorderSide(color: Colors.white38),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                        borderSide: BorderSide(color: Colors.blueAccent),
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Marka gerekli';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => setState(() {}),
                                    onFieldSubmitted: (value) => onFieldSubmitted(),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Model alanı
                              TextFormField(
                                controller: _modelController,
                                decoration: const InputDecoration(
                                  labelText: "Model",
                                  labelStyle: TextStyle(color: Colors.white70),
                                  hintText: "Model girin",
                                  hintStyle: TextStyle(color: Colors.white38),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    borderSide: BorderSide(color: Colors.white38),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    borderSide: BorderSide(color: Colors.white38),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    borderSide: BorderSide(color: Colors.blueAccent),
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

              // Satın Alma Tarihi
              const Text(
                "Satın Alma Tarihi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                trailing: const Icon(
                  Icons.calendar_month,
                  color: Colors.blueAccent,
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),

              const SizedBox(height: 10),

              // Garanti Süresi Seçimi - Açılır Kart
              GestureDetector(
                onTap: () => setState(() => _isWarrantyExpanded = !_isWarrantyExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: Colors.black.withOpacity(0.2),
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
                                    ...[6, 12, 24, 36, 48, 60].map((months) => 
                                      _buildWarrantyOption(months)
                                    ),
                                    
                                    // Manuel giriş alanı
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  controller: _customWarrantyController,
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    hintText: "Ay sayısı",
                                                    hintStyle: TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                                      borderSide: BorderSide(color: Colors.white38),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                                      borderSide: BorderSide(color: Colors.white38),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                                      borderSide: BorderSide(color: Colors.blueAccent),
                                                    ),
                                                    contentPadding: EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                  onChanged: (value) {
                                                    final customValue = int.tryParse(value);
                                                    if (customValue != null && customValue > 0) {
                                                      setState(() {
                                                        _warrantyMonths = customValue;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                "ay",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
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

              const SizedBox(height: 20),

              // Kategori Seçimi - Açılır Kart
              GestureDetector(
                onTap: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
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
                            color: Colors.black.withOpacity(0.2),
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
                                    ..._categories.map((category) => 
                                      _buildCategoryOption(category)
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

              // Fatura Fotoğrafı Yükleme Alanı (Kriter 2)
              const Text(
                "Fatura Fotoğrafı",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Kamera"),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Galeri"),
                  ),
                ],
              ),

              // Seçilen Fotoğraflar Listesi
              if (_selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _selectedImages[index],
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
                                      _selectedImages.removeAt(index);
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
                  onPressed: productController.isLoading ? null : _saveProduct,
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
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Brand ve model kontrollerini de validate et
      if (_brandController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen marka bilgisini girin"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Loading state'i başlat
      setState(() {});

      final product = ProductModel(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        purchaseDate: _selectedDate,
        warrantyMonths: _warrantyMonths,
        category: _selectedCategory,
        isOnlineStore: _isOnline,
        note: _noteController.text.trim(),
      );

      try {
        // Controller'a resimleri list olarak gönderiyoruz
        await Provider.of<ProductController>(
          context,
          listen: false,
        ).addProduct(product, _selectedImages);

        // Başarılı mesajını göster ve navigation'ı yap
        if (mounted) {
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

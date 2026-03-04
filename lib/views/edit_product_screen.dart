import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

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
  late TextEditingController _warrantyMonthsController;
  late TextEditingController _noteController;

  DateTime? _selectedDate;
  String _selectedCategory = 'Elektronik';
  List<File> _newImageFiles = []; // Yeni eklenen fotoğraflar
  List<String> _existingImageUrls =
      []; // Firebase'den gelen ve hala silinmeyen eski URL'ler
  bool _isOnlineStore = false;

  final List<String> _categories = [
    'Elektronik',
    'Beyaz Eşya',
    'Mobilya',
    'Otomotiv',
    'Giyim',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    // Mevcut değerleri doldur
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand);
    _modelController = TextEditingController(text: widget.product.model);
    _warrantyMonthsController = TextEditingController(
      text: widget.product.warrantyMonths.toString(),
    );
    _noteController = TextEditingController(text: widget.product.note ?? '');

    _selectedDate = widget.product.purchaseDate;
    _selectedCategory = widget.product.category;
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }
    _isOnlineStore = widget.product.isOnlineStore;

    if (widget.product.imageUrls != null &&
        widget.product.imageUrls!.isNotEmpty) {
      _existingImageUrls = List.from(widget.product.imageUrls!);
    } else if (widget.product.invoiceImageUrl != null) {
      _existingImageUrls = [widget.product.invoiceImageUrl!];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _warrantyMonthsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();

      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await picker.pickMultiImage(
          imageQuality: 70,
        );

        if (pickedFiles.isNotEmpty) {
          setState(() {
            _newImageFiles.addAll(pickedFiles.map((file) => File(file.path)));
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
            _newImageFiles.add(File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      debugPrint("Görsel seçme hatası: $e");
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera ile Çek'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç (Çoklu Seçim)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
          warrantyMonths: int.parse(_warrantyMonthsController.text.trim()),
          category: _selectedCategory,
          note: _noteController.text.trim(),
          isOnlineStore: _isOnlineStore,
          invoiceImageUrl: widget.product.invoiceImageUrl, // Eski görseli koru
          serviceHistory:
              widget.product.serviceHistory, // Servis geçmişini koru
        );

        final productController = Provider.of<ProductController>(
          context,
          listen: false,
        );

        await productController.updateProduct(
          updatedProduct,
          newImageFiles: _newImageFiles,
          remainingImageUrls: _existingImageUrls,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla güncellendi!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ürünü Düzenle')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Görseller Bölümü Başlığı ve Seçici
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Ürün / Fatura Görselleri",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showImagePickerOptions,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text("Ekle"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tüm Görselleri Gösteren Yatay Liste
                    if (_existingImageUrls.isNotEmpty ||
                        _newImageFiles.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Mevcut (Eski) Resimler
                            ..._existingImageUrls.map((url) {
                              return Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        url,
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
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _existingImageUrls.remove(url);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),

                            // Yeni Eklenen Resimler
                            ..._newImageFiles.asMap().entries.map((entry) {
                              int index = entry.key;
                              File file = entry.value;
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
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _newImageFiles.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              size: 30,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              'Görsel Ekle',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Temel Bilgiler
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ürün Adı',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(
                              labelText: 'Marka',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Gerekli' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Gerekli' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Kategori ve Garanti
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _warrantyMonthsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Ay (Garanti)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Gerekli' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarih Seçimi
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: Text(
                        _selectedDate == null
                            ? 'Satın Alma Tarihi Seçin'
                            : 'Satın Alma: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),

                    // Notlar ve Online Seçeneği
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notlar (Opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Online Mağazadan Alındı'),
                      value: _isOnlineStore,
                      onChanged: (bool value) {
                        setState(() {
                          _isOnlineStore = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Kaydet Butonu
                    ElevatedButton(
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Değişiklikleri Kaydet',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

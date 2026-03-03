import 'dart:io'; // Dosya işlemleri için
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Kamera erişimi
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../data/popular_brands.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Resim Seçimi Değişkenleri
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Form Kontrolleri
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _noteController = TextEditingController(); // Not alanı eklendi
  
  DateTime _selectedDate = DateTime.now();
  int _warrantyMonths = 24; 
  String _selectedCategory = 'Elektronik';
  bool _isOnline = false;

  final List<String> _categories = ['Elektronik', 'Mutfak', 'Ev Gereçleri', 'Mobilya', 'Diğer'];

  // Kamera/Galeri seçim fonksiyonu
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70); // Kaliteyi biraz düşürerek hızlı yükleme sağlarız
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
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
              // Ürün Adı
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Ürün Adı", border: OutlineInputBorder(), prefixIcon: Icon(Icons.shopping_bag)),
                validator: (v) => v!.isEmpty ? "Lütfen ürün adını girin" : null,
              ),
              const SizedBox(height: 15),
              
              // Marka ve Model yanyana
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final brands = PopularBrands.getBrandsForCategory(_selectedCategory);
                        return brands.where((brand) {
                          return brand.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _brandController.text = selection;
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: "Marka", border: OutlineInputBorder()),
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: "Model", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Satın Alma Tarihi
              const Text("Satın Alma Tarihi", style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_month, color: Colors.blueAccent),
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

              // Garanti Süresi Seçimi
              const Text("Garanti Süresi (Ay)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [12, 24, 36, 60].map((month) {
                  return ChoiceChip(
                    label: Text("$month Ay"),
                    selected: _warrantyMonths == month,
                    selectedColor: Colors.blueAccent.withOpacity(0.3),
                    onSelected: (val) => setState(() => _warrantyMonths = month),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Kategori ve Mağaza Türü
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
              ),
              
              SwitchListTile(
                title: const Text("Online Mağaza"),
                value: _isOnline,
                onChanged: (val) => setState(() => _isOnline = val),
              ),

              const Divider(),

              // Fatura Fotoğrafı Yükleme Alanı (Kriter 2)
              const Text("Fatura Fotoğrafı", style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 5, top: 5,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _selectedImage = null),
                          ),
                        ),
                      )
                    ],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: productController.isLoading ? null : _saveProduct,
                  child: productController.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("GARANTİYİ KAYDET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      final product = ProductModel(
        name: _nameController.text,
        brand: _brandController.text,
        model: _modelController.text,
        purchaseDate: _selectedDate,
        warrantyMonths: _warrantyMonths,
        category: _selectedCategory,
        isOnlineStore: _isOnline,
        note: _noteController.text,
      );

      // Controller'a resmi de gönderiyoruz
      await Provider.of<ProductController>(context, listen: false).addProduct(product, _selectedImage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ürün başarıyla eklendi!")));
        Navigator.pop(context);
      }
    }
  }
}
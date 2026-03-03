import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../controllers/product_controller.dart';
import 'package:provider/provider.dart';

class AddServiceRecordScreen extends StatefulWidget {
  final ProductModel product;
  const AddServiceRecordScreen({super.key, required this.product});

  @override
  State<AddServiceRecordScreen> createState() => _AddServiceRecordScreenState();
}

class _AddServiceRecordScreenState extends State<AddServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Servis Kaydı Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ListTile(
                title: Text("İşlem Tarihi: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
                trailing: const Icon(Icons.calendar_month),
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
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Yapılan İşlem (Örn: Ekran değişimi)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Lütfen açıklama girin" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Ücret (Opsiyonel)", border: OutlineInputBorder(), suffixText: "TL"),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  child: const Text("KAYDI EKLE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final newRecord = ServiceRecord(
        date: _selectedDate,
        description: _descController.text,
        price: double.tryParse(_priceController.text) ?? 0,
      );

      // Controller'daki güncelleme fonksiyonunu çağıracağız
      await Provider.of<ProductController>(context, listen: false)
          .addServiceHistory(widget.product.id!, newRecord);
      
      if (mounted) Navigator.pop(context);
    }
  }
}
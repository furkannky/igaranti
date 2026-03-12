class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});

  static const ValidationResult valid = ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message) => ValidationResult(isValid: false, errorMessage: message);
}

class ValidationService {
  // Email validasyonu
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.invalid('Email adresi gerekli');
    }

    email = email.trim();

    // Email format kontrolü
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.invalid('Geçerli bir email adresi girin');
    }

    // Uzunluk kontrolü
    if (email.length > 254) {
      return ValidationResult.invalid('Email adresi çok uzun');
    }

    // Local ve domain kısmı kontrolü
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return ValidationResult.invalid('Geçerli bir email adresi girin');
    }

    return ValidationResult.valid;
  }

  // Şifre validasyonu
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.invalid('Şifre gerekli');
    }

    if (password.length < 6) {
      return ValidationResult.invalid('Şifre en az 6 karakter olmalıdır');
    }

    if (password.length > 128) {
      return ValidationResult.invalid('Şifre çok uzun');
    }

    // Güçlü şifre kontrolü (isteğe bağlı)
    if (!containsUppercase(password)) {
      return ValidationResult.invalid('Şifrede en az bir büyük harf olmalı');
    }

    if (!containsLowercase(password)) {
      return ValidationResult.invalid('Şifrede en az bir küçük harf olmalı');
    }

    if (!containsDigit(password)) {
      return ValidationResult.invalid('Şifrede en az bir rakam olmalı');
    }

    return ValidationResult.valid;
  }

  // Ürün adı validasyonu
  static ValidationResult validateProductName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.invalid('Ürün adı gerekli');
    }

    name = name.trim();

    if (name.length < 2) {
      return ValidationResult.invalid('Ürün adı en az 2 karakter olmalı');
    }

    if (name.length > 100) {
      return ValidationResult.invalid('Ürün adı çok uzun (max 100 karakter)');
    }

    // Özel karakter kontrolü
    if (containsInvalidChars(name)) {
      return ValidationResult.invalid('Ürün adı geçersiz karakterler içeriyor');
    }

    return ValidationResult.valid;
  }

  // Marka validasyonu
  static ValidationResult validateBrand(String? brand) {
    if (brand == null || brand.trim().isEmpty) {
      return ValidationResult.invalid('Marka gerekli');
    }

    brand = brand.trim();

    if (brand.length < 2) {
      return ValidationResult.invalid('Marka en az 2 karakter olmalı');
    }

    if (brand.length > 50) {
      return ValidationResult.invalid('Marka çok uzun (max 50 karakter)');
    }

    if (containsInvalidChars(brand)) {
      return ValidationResult.invalid('Marka geçersiz karakterler içeriyor');
    }

    return ValidationResult.valid;
  }

  // Model validasyonu
  static ValidationResult validateModel(String? model) {
    if (model == null || model.trim().isEmpty) {
      return ValidationResult.valid; // Model zorunlu değil
    }

    model = model.trim();

    if (model.length > 50) {
      return ValidationResult.invalid('Model çok uzun (max 50 karakter)');
    }

    if (containsInvalidChars(model)) {
      return ValidationResult.invalid('Model geçersiz karakterler içeriyor');
    }

    return ValidationResult.valid;
  }

  // Not validasyonu
  static ValidationResult validateNote(String? note) {
    if (note == null || note.trim().isEmpty) {
      return ValidationResult.valid; // Not zorunlu değil
    }

    note = note.trim();

    if (note.length > 500) {
      return ValidationResult.invalid('Not çok uzun (max 500 karakter)');
    }

    return ValidationResult.valid;
  }

  // Garanti süresi validasyonu
  static ValidationResult validateWarrantyMonths(int? months) {
    if (months == null) {
      return ValidationResult.invalid('Garanti süresi gerekli');
    }

    if (months < 1) {
      return ValidationResult.invalid('Garanti süresi en az 1 ay olmalı');
    }

    if (months > 120) {
      // 10 yıl
      return ValidationResult.invalid('Garanti süresi çok uzun (max 120 ay)');
    }

    return ValidationResult.valid;
  }

  // Tarih validasyonu
  static ValidationResult validatePurchaseDate(DateTime? date) {
    if (date == null) {
      return ValidationResult.invalid('Satın alma tarihi gerekli');
    }

    final now = DateTime.now();
    final minDate = DateTime(2000); // 2000 yılından eski olamaz
    final maxDate = now; // Gelecekte olamaz

    if (date.isBefore(minDate)) {
      return ValidationResult.invalid('Tarih çok eski');
    }

    if (date.isAfter(maxDate)) {
      return ValidationResult.invalid('Tarih gelecekte olamaz');
    }

    return ValidationResult.valid;
  }

  // Dosya validasyonu
  static ValidationResult validateFile(String? filePath, {int maxSizeMB = 10}) {
    if (filePath == null || filePath.isEmpty) {
      return ValidationResult.invalid('Dosya seçilmedi');
    }

    // Dosya uzantısı kontrolü
    final extension = filePath.toLowerCase().split('.').last;
    final allowedExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'pdf',
    ];

    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.invalid('Desteklenmeyen dosya formatı');
    }

    return ValidationResult.valid;
  }

  // Yardımcı metodlar
  static bool containsUppercase(String text) {
    return text.contains(RegExp(r'[A-Z]'));
  }

  static bool containsLowercase(String text) {
    return text.contains(RegExp(r'[a-z]'));
  }

  static bool containsDigit(String text) {
    return text.contains(RegExp(r'[0-9]'));
  }

  static bool containsInvalidChars(String text) {
    // HTML, script injection gibi tehlikeli karakterleri kontrol et
    final dangerousChars = RegExp('[<>"\'&]');
    return dangerousChars.hasMatch(text);
  }

  // Form validasyonu için genel metod
  static Map<String, ValidationResult> validateProductForm({
    String? name,
    String? brand,
    String? model,
    String? note,
    int? warrantyMonths,
    DateTime? purchaseDate,
  }) {
    final results = <String, ValidationResult>{};

    results['name'] = validateProductName(name);
    results['brand'] = validateBrand(brand);
    results['model'] = validateModel(model);
    results['note'] = validateNote(note);
    results['warrantyMonths'] = validateWarrantyMonths(warrantyMonths);
    results['purchaseDate'] = validatePurchaseDate(purchaseDate);

    return results;
  }

  // Login form validasyonu
  static Map<String, ValidationResult> validateLoginForm({
    String? email,
    String? password,
  }) {
    final results = <String, ValidationResult>{};

    results['email'] = validateEmail(email);
    results['password'] = validatePassword(password);

    return results;
  }

  // Register form validasyonu
  static Map<String, ValidationResult> validateRegisterForm({
    String? email,
    String? password,
    String? confirmPassword,
  }) {
    final results = validateLoginForm(email: email, password: password);

    if (confirmPassword == null || confirmPassword.isEmpty) {
      results['confirmPassword'] = ValidationResult.invalid(
        'Şifre tekrarı gerekli',
      );
    } else if (password != confirmPassword) {
      results['confirmPassword'] = ValidationResult.invalid(
        'Şifreler eşleşmiyor',
      );
    } else {
      results['confirmPassword'] = ValidationResult.valid;
    }

    return results;
  }
}

import 'dart:core';
import '../models/product_model.dart';

class SearchFilters {
  final String? query;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? brands;
  final int? minWarrantyMonths;
  final int? maxWarrantyMonths;
  final bool? onlyExpired;
  final bool? onlyExpiringSoon;
  final bool? onlyActive;

  const SearchFilters({
    this.query,
    this.category,
    this.startDate,
    this.endDate,
    this.brands,
    this.minWarrantyMonths,
    this.maxWarrantyMonths,
    this.onlyExpired,
    this.onlyExpiringSoon,
    this.onlyActive,
  });

  SearchFilters copyWith({
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? brands,
    int? minWarrantyMonths,
    int? maxWarrantyMonths,
    bool? onlyExpired,
    bool? onlyExpiringSoon,
    bool? onlyActive,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      brands: brands ?? this.brands,
      minWarrantyMonths: minWarrantyMonths ?? this.minWarrantyMonths,
      maxWarrantyMonths: maxWarrantyMonths ?? this.maxWarrantyMonths,
      onlyExpired: onlyExpired ?? this.onlyExpired,
      onlyExpiringSoon: onlyExpiringSoon ?? this.onlyExpiringSoon,
      onlyActive: onlyActive ?? this.onlyActive,
    );
  }

  bool get hasAnyFilter =>
      query != null ||
      category != null ||
      startDate != null ||
      endDate != null ||
      (brands != null && brands!.isNotEmpty) ||
      minWarrantyMonths != null ||
      maxWarrantyMonths != null ||
      onlyExpired == true ||
      onlyExpiringSoon == true ||
      onlyActive == true;

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'category': category,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'brands': brands,
      'minWarrantyMonths': minWarrantyMonths,
      'maxWarrantyMonths': maxWarrantyMonths,
      'onlyExpired': onlyExpired,
      'onlyExpiringSoon': onlyExpiringSoon,
      'onlyActive': onlyActive,
    };
  }

  factory SearchFilters.fromMap(Map<String, dynamic> map) {
    return SearchFilters(
      query: map['query'],
      category: map['category'],
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      brands: map['brands'] != null ? List<String>.from(map['brands']) : null,
      minWarrantyMonths: map['minWarrantyMonths'],
      maxWarrantyMonths: map['maxWarrantyMonths'],
      onlyExpired: map['onlyExpired'],
      onlyExpiringSoon: map['onlyExpiringSoon'],
      onlyActive: map['onlyActive'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilters &&
        other.query == query &&
        other.category == category &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.brands == brands &&
        other.minWarrantyMonths == minWarrantyMonths &&
        other.maxWarrantyMonths == maxWarrantyMonths &&
        other.onlyExpired == onlyExpired &&
        other.onlyExpiringSoon == onlyExpiringSoon &&
        other.onlyActive == onlyActive;
  }

  @override
  int get hashCode {
    return query.hashCode ^
        category.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        brands.hashCode ^
        minWarrantyMonths.hashCode ^
        maxWarrantyMonths.hashCode ^
        onlyExpired.hashCode ^
        onlyExpiringSoon.hashCode ^
        onlyActive.hashCode;
  }
}

class SearchResult {
  final List<ProductModel> products;
  final int totalCount;
  final SearchFilters appliedFilters;
  final Duration searchDuration;

  SearchResult({
    required this.products,
    required this.totalCount,
    required this.appliedFilters,
    required this.searchDuration,
  });
}

class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._();
  
  SearchService._();

  // Ürünleri filtrele
  SearchResult searchProducts(List<ProductModel> products, SearchFilters filters) {
    final stopwatch = Stopwatch()..start();
    
    List<ProductModel> filteredProducts = List.from(products);
    
    // Metin araması
    if (filters.query != null && filters.query!.isNotEmpty) {
      final query = filters.query!.toLowerCase();
      filteredProducts = filteredProducts.where((product) {
        return _matchesQuery(product, query);
      }).toList();
    }
    
    // Kategori filtresi
    if (filters.category != null && filters.category!.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.category.toLowerCase() == filters.category!.toLowerCase();
      }).toList();
    }
    
    // Tarih aralığı filtresi
    if (filters.startDate != null || filters.endDate != null) {
      filteredProducts = filteredProducts.where((product) {
        return _isInDateRange(product.purchaseDate, filters.startDate, filters.endDate);
      }).toList();
    }
    
    // Marka filtresi
    if (filters.brands != null && filters.brands!.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return filters.brands!.any((brand) => 
          product.brand.toLowerCase() == brand.toLowerCase()
        );
      }).toList();
    }
    
    // Garanti süresi filtresi
    if (filters.minWarrantyMonths != null || filters.maxWarrantyMonths != null) {
      filteredProducts = filteredProducts.where((product) {
        return _isInWarrantyRange(product.warrantyMonths, filters.minWarrantyMonths, filters.maxWarrantyMonths);
      }).toList();
    }
    
    // Durum filtreleri
    if (filters.onlyExpired == true) {
      filteredProducts = filteredProducts.where((product) => product.remainingDays <= 0).toList();
    }
    
    if (filters.onlyExpiringSoon == true) {
      filteredProducts = filteredProducts.where((product) => 
        product.remainingDays > 0 && product.remainingDays <= 30
      ).toList();
    }
    
    if (filters.onlyActive == true) {
      filteredProducts = filteredProducts.where((product) => product.remainingDays > 30).toList();
    }
    
    stopwatch.stop();
    
    return SearchResult(
      products: filteredProducts,
      totalCount: filteredProducts.length,
      appliedFilters: filters,
      searchDuration: stopwatch.elapsed,
    );
  }
  
  // Metin araması
  bool _matchesQuery(ProductModel product, String query) {
    final searchableText = [
      product.name,
      product.brand,
      product.model,
      product.category,
      if (product.note != null) product.note!,
    ].join(' ').toLowerCase();
    
    // Kelime bazında arama
    final queryWords = query.split(' ').where((word) => word.isNotEmpty);
    
    for (final word in queryWords) {
      if (!searchableText.contains(word)) {
        return false;
      }
    }
    
    return true;
  }
  
  // Tarih aralığı kontrolü
  bool _isInDateRange(DateTime purchaseDate, DateTime? startDate, DateTime? endDate) {
    if (startDate != null && purchaseDate.isBefore(startDate)) {
      return false;
    }
    
    if (endDate != null && purchaseDate.isAfter(endDate)) {
      return false;
    }
    
    return true;
  }
  
  // Garanti süresi aralığı kontrolü
  bool _isInWarrantyRange(int warrantyMonths, int? minMonths, int? maxMonths) {
    if (minMonths != null && warrantyMonths < minMonths) {
      return false;
    }
    
    if (maxMonths != null && warrantyMonths > maxMonths) {
      return false;
    }
    
    return true;
  }
  
  // Öneriler oluştur
  List<String> getSuggestions(List<ProductModel> products, String query) {
    if (query.isEmpty) return [];
    
    final suggestions = <String>{};
    final lowerQuery = query.toLowerCase();
    
    for (final product in products) {
      // Ürün adı önerileri
      if (product.name.toLowerCase().contains(lowerQuery)) {
        suggestions.add(product.name);
      }
      
      // Marka önerileri
      if (product.brand.toLowerCase().contains(lowerQuery)) {
        suggestions.add(product.brand);
      }
      
      // Model önerileri
      if (product.model.toLowerCase().contains(lowerQuery)) {
        suggestions.add(product.model);
      }
      
      // Kategori önerileri
      if (product.category.toLowerCase().contains(lowerQuery)) {
        suggestions.add(product.category);
      }
    }
    
    final suggestionList = suggestions.toList();
    suggestionList.sort((a, b) => a.length.compareTo(b.length));
    
    return suggestionList.take(10).toList();
  }
  
  // Popüler markaları al
  List<String> getPopularBrands(List<ProductModel> products, {int limit = 10}) {
    final brandCounts = <String, int>{};
    
    for (final product in products) {
      brandCounts[product.brand] = (brandCounts[product.brand] ?? 0) + 1;
    }
    
    final sortedBrands = brandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedBrands
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
  
  // Popüler kategorileri al
  List<String> getPopularCategories(List<ProductModel> products, {int limit = 10}) {
    final categoryCounts = <String, int>{};
    
    for (final product in products) {
      categoryCounts[product.category] = (categoryCounts[product.category] ?? 0) + 1;
    }
    
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
  
  // Arama istatistikleri
  Map<String, dynamic> getSearchStats(List<ProductModel> products) {
    final totalProducts = products.length;
    final expiredCount = products.where((p) => p.remainingDays <= 0).length;
    final expiringSoonCount = products.where((p) => p.remainingDays > 0 && p.remainingDays <= 30).length;
    final activeCount = products.where((p) => p.remainingDays > 30).length;
    
    final categories = getPopularCategories(products);
    final brands = getPopularBrands(products);
    
    return {
      'totalProducts': totalProducts,
      'expiredCount': expiredCount,
      'expiringSoonCount': expiringSoonCount,
      'activeCount': activeCount,
      'categories': categories,
      'brands': brands,
      'averageWarranty': totalProducts > 0 
          ? products.map((p) => p.warrantyMonths).reduce((a, b) => a + b) / totalProducts 
          : 0,
    };
  }
  
  // Gelişmiş arama (fuzzy search)
  SearchResult fuzzySearch(List<ProductModel> products, String query, {double threshold = 0.6}) {
    final stopwatch = Stopwatch()..start();
    
    if (query.isEmpty) {
      return SearchResult(
        products: products,
        totalCount: products.length,
        appliedFilters: const SearchFilters(),
        searchDuration: stopwatch.elapsed,
      );
    }
    
    final lowerQuery = query.toLowerCase();
    final scoredProducts = <ProductModel, double>{};
    
    for (final product in products) {
      final score = _calculateFuzzyScore(product, lowerQuery);
      if (score >= threshold) {
        scoredProducts[product] = score;
      }
    }
    
    // Skora göre sırala
    final sortedProducts = scoredProducts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    stopwatch.stop();
    
    return SearchResult(
      products: sortedProducts.map((e) => e.key).toList(),
      totalCount: sortedProducts.length,
      appliedFilters: SearchFilters(query: query),
      searchDuration: stopwatch.elapsed,
    );
  }
  
  // Fuzzy search skoru hesapla
  double _calculateFuzzyScore(ProductModel product, String query) {
    final searchableText = [
      product.name,
      product.brand,
      product.model,
      product.category,
      if (product.note != null) product.note!,
    ].join(' ').toLowerCase();
    
    double score = 0.0;
    final queryWords = query.split(' ').where((word) => word.isNotEmpty);
    
    for (final word in queryWords) {
      // Tam eşleşme
      if (searchableText.contains(word)) {
        score += 1.0;
      }
      
      // Kısmi eşleşme (Levenshtein distance)
      final partialScore = _calculatePartialMatch(searchableText, word);
      score += partialScore;
    }
    
    // Normalize et
    return score / queryWords.length;
  }
  
  // Kısmi eşleşme skoru
  double _calculatePartialMatch(String text, String query) {
    if (query.isEmpty) return 0.0;
    
    int maxScore = 0;
    final textLength = text.length;
    final queryLength = query.length;
    
    for (int i = 0; i <= textLength - queryLength; i++) {
      final substring = text.substring(i, i + queryLength);
      int score = 0;
      
      for (int j = 0; j < queryLength; j++) {
        if (substring[j] == query[j]) {
          score++;
        }
      }
      
      maxScore = maxScore > score ? maxScore : score;
    }
    
    return maxScore / queryLength;
  }
}

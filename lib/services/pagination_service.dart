import 'dart:core';
import '../models/product_model.dart';

class PaginationConfig {
  final int pageSize;
  final int currentPage;
  final String? sortBy;
  final bool sortAscending;
  final String? lastDocumentId;
  
  const PaginationConfig({
    this.pageSize = 20,
    this.currentPage = 0,
    this.sortBy,
    this.sortAscending = true,
    this.lastDocumentId,
  });
  
  PaginationConfig copyWith({
    int? pageSize,
    int? currentPage,
    String? sortBy,
    bool? sortAscending,
    String? lastDocumentId,
  }) {
    return PaginationConfig(
      pageSize: pageSize ?? this.pageSize,
      currentPage: currentPage ?? this.currentPage,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
    );
  }
  
  int get offset => currentPage * pageSize;
  bool get hasNextPage => lastDocumentId != null;
}

class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? nextCursor;
  final String? previousCursor;
  
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.nextCursor,
    this.previousCursor,
  });
  
  int get totalPages => (totalCount / pageSize).ceil();
  
  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'totalCount': totalCount,
      'currentPage': currentPage,
      'pageSize': pageSize,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
      'nextCursor': nextCursor,
      'previousCursor': previousCursor,
      'totalPages': totalPages,
    };
  }
}

class PaginationService {
  static PaginationService? _instance;
  static PaginationService get instance => _instance ??= PaginationService._();
  
  PaginationService._();
  
  // Ürünleri sayfala
  PaginatedResult<ProductModel> paginateProducts(
    List<ProductModel> products,
    PaginationConfig config,
  ) {
    // Sıralama
    final sortedProducts = _sortProducts(products, config.sortBy, config.sortAscending);
    
    // Sayfalama
    final startIndex = config.offset;
    final endIndex = (startIndex + config.pageSize).clamp(0, sortedProducts.length);
    
    final paginatedItems = startIndex < sortedProducts.length
        ? sortedProducts.sublist(startIndex, endIndex)
        : <ProductModel>[];
    
    // Cursor'ları hesapla
    String? nextCursor;
    String? previousCursor;
    
    if (config.hasNextPage && endIndex < sortedProducts.length) {
      nextCursor = sortedProducts[endIndex].id;
    }
    
    if (config.currentPage > 0 && startIndex > 0) {
      previousCursor = sortedProducts[startIndex - 1].id;
    }
    
    return PaginatedResult<ProductModel>(
      items: paginatedItems,
      totalCount: sortedProducts.length,
      currentPage: config.currentPage,
      pageSize: config.pageSize,
      hasNextPage: endIndex < sortedProducts.length,
      hasPreviousPage: config.currentPage > 0,
      nextCursor: nextCursor,
      previousCursor: previousCursor,
    );
  }
  
  // Ürünleri sırala
  List<ProductModel> _sortProducts(
    List<ProductModel> products,
    String? sortBy,
    bool ascending,
  ) {
    if (sortBy == null || sortBy.isEmpty) {
      return List.from(products);
    }
    
    final sortedProducts = List<ProductModel>.from(products);
    
    sortedProducts.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy.toLowerCase()) {
        case 'name':
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'brand':
          comparison = a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
          break;
        case 'category':
          comparison = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          break;
        case 'purchaseDate':
          comparison = a.purchaseDate.compareTo(b.purchaseDate);
          break;
        case 'expiryDate':
          comparison = a.expiryDate.compareTo(b.expiryDate);
          break;
        case 'remainingDays':
          comparison = a.remainingDays.compareTo(b.remainingDays);
          break;
        case 'warrantyMonths':
          comparison = a.warrantyMonths.compareTo(b.warrantyMonths);
          break;
        default:
          comparison = 0;
      }
      
      return ascending ? comparison : -comparison;
    });
    
    return sortedProducts;
  }
  
  // Sonraki sayfa konfigürasyonu
  PaginationConfig getNextPageConfig(PaginationConfig currentConfig, String? nextCursor) {
    if (nextCursor == null) {
      return currentConfig;
    }
    
    return currentConfig.copyWith(
      currentPage: currentConfig.currentPage + 1,
      lastDocumentId: nextCursor,
    );
  }
  
  // Önceki sayfa konfigürasyonu
  PaginationConfig getPreviousPageConfig(PaginationConfig currentConfig, String? previousCursor) {
    if (currentConfig.currentPage <= 0) {
      return currentConfig;
    }
    
    return currentConfig.copyWith(
      currentPage: currentConfig.currentPage - 1,
      lastDocumentId: previousCursor,
    );
  }
  
  // Belirli bir sayfaya git
  PaginationConfig goToPage(PaginationConfig currentConfig, int pageNumber) {
    if (pageNumber < 0) {
      return currentConfig.copyWith(currentPage: 0);
    }
    
    return currentConfig.copyWith(
      currentPage: pageNumber,
      lastDocumentId: null, // Reset cursor when jumping to specific page
    );
  }
  
  // Sayfa boyutunu değiştir
  PaginationConfig changePageSize(PaginationConfig currentConfig, int newPageSize) {
    if (newPageSize <= 0) {
      return currentConfig;
    }
    
    // Sayfa boyutu değiştiğinde sayfa numarasını sıfırla
    return currentConfig.copyWith(
      pageSize: newPageSize,
      currentPage: 0,
      lastDocumentId: null,
    );
  }
  
  // Sıralamayı değiştir
  PaginationConfig changeSorting(
    PaginationConfig currentConfig,
    String? sortBy,
    bool? ascending,
  ) {
    return currentConfig.copyWith(
      sortBy: sortBy,
      sortAscending: ascending ?? true,
      currentPage: 0, // Sıralama değiştiğinde başa dön
      lastDocumentId: null,
    );
  }
  
  // Sayfa bilgileri
  Map<String, dynamic> getPageInfo(PaginationConfig config, int totalCount) {
    final totalPages = (totalCount / config.pageSize).ceil();
    final startItem = totalCount > 0 ? config.offset + 1 : 0;
    final endItem = (config.offset + config.pageSize).clamp(0, totalCount);
    
    return {
      'currentPage': config.currentPage,
      'totalPages': totalPages,
      'totalCount': totalCount,
      'pageSize': config.pageSize,
      'startItem': startItem,
      'endItem': endItem,
      'hasNextPage': config.currentPage < totalPages - 1,
      'hasPreviousPage': config.currentPage > 0,
      'isFirstPage': config.currentPage == 0,
      'isLastPage': config.currentPage >= totalPages - 1,
    };
  }
  
  // Sayfa numaraları listesi (pagination controls için)
  List<int> getPageNumbers(int currentPage, int totalPages, {int maxVisible = 5}) {
    if (totalPages <= maxVisible) {
      return List.generate(totalPages, (index) => index);
    }
    
    final List<int> pageNumbers = [];
    final halfVisible = maxVisible ~/ 2;
    
    int startPage = (currentPage - halfVisible).clamp(0, totalPages - 1);
    int endPage = startPage + maxVisible - 1;
    
    if (endPage >= totalPages) {
      endPage = totalPages - 1;
      startPage = (endPage - maxVisible + 1).clamp(0, totalPages - 1);
    }
    
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(i);
    }
    
    return pageNumbers;
  }
  
  // Arama sonucunu sayfala
  PaginatedResult<ProductModel> paginateSearchResult(
    List<ProductModel> allProducts,
    List<ProductModel> filteredProducts,
    PaginationConfig config,
  ) {
    // Filtrelenmiş ürünleri sayfala
    final result = paginateProducts(filteredProducts, config);
    
    // Toplam sayıyı filtrelenmiş sonuç olarak güncelle
    return PaginatedResult<ProductModel>(
      items: result.items,
      totalCount: result.totalCount,
      currentPage: result.currentPage,
      pageSize: result.pageSize,
      hasNextPage: result.hasNextPage,
      hasPreviousPage: result.hasPreviousPage,
      nextCursor: result.nextCursor,
      previousCursor: result.previousCursor,
    );
  }
  
  // Performans optimizasyonu - büyük veri setleri için
  PaginatedResult<ProductModel> paginateLargeDataset(
    List<ProductModel> products,
    PaginationConfig config, {
    int chunkSize = 1000,
  }) {
    if (products.length <= chunkSize) {
      return paginateProducts(products, config);
    }
    
    // Büyük veri setleri için chunk'lar halinde işle
    final startIndex = config.offset;
    final endIndex = (startIndex + config.pageSize).clamp(0, products.length);
    
    // Sadece gerekli chunk'ı işle
    final chunkStart = (startIndex ~/ chunkSize) * chunkSize;
    final chunkEnd = ((endIndex ~/ chunkSize) + 1) * chunkSize;
    final actualChunkEnd = chunkEnd.clamp(0, products.length);
    
    final relevantChunk = products.sublist(chunkStart, actualChunkEnd);
    final sortedChunk = _sortProducts(relevantChunk, config.sortBy, config.sortAscending);
    
    // Chunk içindeki gerçek offset'i hesapla
    final chunkOffset = startIndex - chunkStart;
    final chunkEndIndex = (chunkOffset + config.pageSize).clamp(0, sortedChunk.length);
    
    final paginatedItems = chunkOffset < sortedChunk.length
        ? sortedChunk.sublist(chunkOffset, chunkEndIndex)
        : <ProductModel>[];
    
    return PaginatedResult<ProductModel>(
      items: paginatedItems,
      totalCount: products.length,
      currentPage: config.currentPage,
      pageSize: config.pageSize,
      hasNextPage: endIndex < products.length,
      hasPreviousPage: config.currentPage > 0,
    );
  }
  
  // Önbellek için anahtar oluştur
  String generateCacheKey(PaginationConfig config, String? additionalFilter) {
    final parts = [
      'page_${config.currentPage}',
      'size_${config.pageSize}',
      if (config.sortBy != null) 'sort_${config.sortBy}_${config.sortAscending}',
      if (additionalFilter != null) additionalFilter,
    ];
    
    return parts.join('_');
  }
  
  // Sayfa geçişleri için geçerlilik kontrolü
  bool isValidPageTransition(PaginationConfig fromConfig, PaginationConfig toConfig, int totalCount) {
    final totalPages = (totalCount / fromConfig.pageSize).ceil();
    
    // Sayfa numarası geçerli mi?
    if (toConfig.currentPage < 0 || toConfig.currentPage >= totalPages) {
      return false;
    }
    
    // Sayfa boyutu geçerli mi?
    if (toConfig.pageSize <= 0 || toConfig.pageSize > 100) {
      return false;
    }
    
    return true;
  }
}

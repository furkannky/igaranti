import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  
  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  
  AnalyticsService._();
  
  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Debug modunda crashlytics'i devre dışı bırak
      if (kDebugMode) {
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
        debugPrint('🔧 Crashlytics disabled in debug mode');
      } else {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
        debugPrint('✅ Analytics and Crashlytics initialized');
      }
      
      // Analytics'i etkinleştir
      await _analytics.setAnalyticsCollectionEnabled(true);
      
    } catch (e) {
      debugPrint('❌ Analytics initialization failed: $e');
    }
  }
  
  // Screen view tracking
  Future<void> trackScreenView(String screenName, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        parameters: parameters,
      );
      debugPrint('📊 Screen view tracked: $screenName');
    } catch (e) {
      debugPrint('❌ Screen view tracking failed: $e');
    }
  }
  
  // Custom event tracking
  Future<void> trackEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('📊 Event tracked: $name');
    } catch (e) {
      debugPrint('❌ Event tracking failed: $e');
    }
  }
  
  // Product specific events
  Future<void> trackProductAdded(String category, String brand, {bool isOnline = false}) async {
    await trackEvent('product_added', parameters: {
      'category': category,
      'brand': brand,
      'is_online': isOnline,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackProductUpdated(String productId, {String? category, String? brand}) async {
    final params = <String, Object>{
      'product_id': productId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (category != null) params['category'] = category;
    if (brand != null) params['brand'] = brand;
    
    await trackEvent('product_updated', parameters: params);
  }
  
  Future<void> trackProductDeleted(String productId, {String? category, String? brand}) async {
    final params = <String, Object>{
      'product_id': productId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (category != null) params['category'] = category;
    if (brand != null) params['brand'] = brand;
    
    await trackEvent('product_deleted', parameters: params);
  }
  
  // Search events
  Future<void> trackSearch(String query, int resultCount, {String? category, String? brand}) async {
    final params = <String, Object>{
      'query': query,
      'result_count': resultCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (category != null) params['category'] = category;
    if (brand != null) params['brand'] = brand;
    
    await trackEvent('search_performed', parameters: params);
  }
  
  // Filter events
  Future<void> trackFilter(String filterType, String filterValue, int resultCount) async {
    await trackEvent('filter_applied', parameters: {
      'filter_type': filterType,
      'filter_value': filterValue,
      'result_count': resultCount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Export events
  Future<void> trackExport(String format, int productCount, {bool success = true}) async {
    await trackEvent('data_exported', parameters: {
      'format': format,
      'product_count': productCount,
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Import events
  Future<void> trackImport(String format, int productCount, {bool success = true}) async {
    await trackEvent('data_imported', parameters: {
      'format': format,
      'product_count': productCount,
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // User engagement events
  Future<void> trackUserLogin(String method) async {
    await trackEvent('user_login', parameters: {
      'login_method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackUserLogout() async {
    await trackEvent('user_logout', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackUserRegistration(String method) async {
    await trackEvent('user_registration', parameters: {
      'registration_method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // App performance events
  Future<void> trackAppStart() async {
    await trackEvent('app_start', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackAppBackground() async {
    await trackEvent('app_background', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackAppForeground() async {
    await trackEvent('app_foreground', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Feature usage events
  Future<void> trackFeatureUsed(String featureName, {Map<String, Object>? additionalData}) async {
    final params = <String, Object>{
      'feature_name': featureName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (additionalData != null) {
      params.addAll(additionalData);
    }
    
    await trackEvent('feature_used', parameters: params);
  }
  
  // Error tracking
  Future<void> trackError(dynamic error, StackTrace? stackTrace, {String? context}) async {
    try {
      // Crashlytics'e gönder
      await _crashlytics.recordError(error, stackTrace, fatal: false, information: [
        if (context != null) DiagnosticsProperty('context', context),
      ]);
      
      // Analytics'e gönder
      await trackEvent('error_occurred', parameters: {
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        'context': context ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint('📊 Error tracked: $error');
    } catch (e) {
      debugPrint('❌ Error tracking failed: $e');
    }
  }
  
  // Custom user properties
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('📊 User property set: $name = $value');
    } catch (e) {
      debugPrint('❌ User property setting failed: $e');
    }
  }
  
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (userId != null) {
        await _crashlytics.setUserIdentifier(userId);
      }
      debugPrint('📊 User ID set: $userId');
    } catch (e) {
      debugPrint('❌ User ID setting failed: $e');
    }
  }
  
  // Engagement tracking
  Future<void> trackEngagement(String engagementType, {Map<String, Object>? parameters}) async {
    await trackEvent('user_engagement', parameters: {
      'engagement_type': engagementType,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    });
  }
  
  // Notification events
  Future<void> trackNotificationReceived(String type, String title) async {
    await trackEvent('notification_received', parameters: {
      'notification_type': type,
      'notification_title': title,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackNotificationTapped(String type, String title) async {
    await trackEvent('notification_tapped', parameters: {
      'notification_type': type,
      'notification_title': title,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Performance metrics
  Future<void> trackPerformanceMetric(String metricName, double value, {String? unit}) async {
    await trackEvent('performance_metric', parameters: {
      'metric_name': metricName,
      'metric_value': value,
      'metric_unit': unit ?? 'ms',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Session tracking
  Future<void> trackSessionStart() async {
    await trackEvent('session_start', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackSessionEnd(Duration sessionDuration) async {
    await trackEvent('session_end', parameters: {
      'session_duration_ms': sessionDuration.inMilliseconds,
      'session_duration_seconds': sessionDuration.inSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Business metrics
  Future<void> trackWarrantyExpiryCheck(int totalProducts, int expiringSoon, int expired) async {
    await trackEvent('warranty_expiry_check', parameters: {
      'total_products': totalProducts,
      'expiring_soon': expiringSoon,
      'expired': expired,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> trackImageUpload(int imageCount, double totalSizeMB) async {
    await trackEvent('image_upload', parameters: {
      'image_count': imageCount,
      'total_size_mb': totalSizeMB,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // A/B testing events
  Future<void> trackExperiment(String experimentName, String variant, {Map<String, Object>? parameters}) async {
    await trackEvent('ab_test', parameters: {
      'experiment_name': experimentName,
      'variant': variant,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    });
  }
  
  // Social sharing events
  Future<void> trackShare(String contentType, String method) async {
    await trackEvent('content_shared', parameters: {
      'content_type': contentType,
      'share_method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Settings events
  Future<void> trackSettingChanged(String settingName, String oldValue, String newValue) async {
    await trackEvent('setting_changed', parameters: {
      'setting_name': settingName,
      'old_value': oldValue,
      'new_value': newValue,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Cleanup
  Future<void> dispose() async {
    try {
      // Analytics ve Crashlytics dispose gerekmiyor (Firebase manages lifecycle)
      debugPrint('📊 Analytics service disposed');
    } catch (e) {
      debugPrint('❌ Analytics service disposal failed: $e');
    }
  }
}

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarService {
  static Future<bool> addToGoogleCalendar({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Google Calendar URL format
      final String dateFormat = 'yyyyMMdd\'T\'HHmmss\'Z\'';
      final String start = DateFormat(dateFormat).format(startDate.toUtc());
      final String end = DateFormat(dateFormat).format(endDate.toUtc());
      
      final Uri uri = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent(title)}'
        '&details=${Uri.encodeComponent(description)}'
        '&dates=$start/$end'
      );
      
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Takvim ekleme hatası: $e');
      return false;
    }
  }

  static Future<bool> addWarrantyExpiryReminder({
    required String productName,
    required String brand,
    required DateTime expiryDate,
  }) async {
    final String title = 'Garanti Bitişi: $productName';
    final String description = '''
$productName ($brand) ürününün garantisi bitiyor.

Ürün: $productName
Marka: $brand
Garanti Bitiş Tarihi: ${DateFormat('dd.MM.yyyy').format(expiryDate)}

iGaranti uygulamasından oluşturuldu.
    ''';
    
    // Bitiş günü için tüm gün etkinliği
    final DateTime start = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final DateTime end = start.add(const Duration(days: 1));
    
    return await addToGoogleCalendar(
      title: title,
      description: description,
      startDate: start,
      endDate: end,
    );
  }

  static Future<bool> addServiceReminder({
    required String productName,
    required String serviceName,
    required DateTime serviceDate,
  }) async {
    final String title = 'Servis Hatırlatıcısı: $productName';
    final String description = '''
$productName için servis randevunuz var.

Ürün: $productName
Servis: $serviceName
Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(serviceDate)}

iGaranti uygulamasından oluşturuldu.
    ''';
    
    // Servis tarihi için 1 saatlik etkinlik
    final DateTime start = serviceDate;
    final DateTime end = serviceDate.add(const Duration(hours: 1));
    
    return await addToGoogleCalendar(
      title: title,
      description: description,
      startDate: start,
      endDate: end,
    );
  }
}

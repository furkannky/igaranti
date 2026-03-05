import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static final NotificationSettingsService _instance = NotificationSettingsService._();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._();

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _daysBeforeExpiryKey = 'days_before_expiry';
  static const String _notificationSoundKey = 'notification_sound';
  static const String _vibrationEnabledKey = 'vibration_enabled';

  Future<SharedPreferences> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      // Platform exception handling - return default values if SharedPreferences fails
      debugPrint('SharedPreferences error: $e');
      rethrow;
    }
  }

  Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_notificationsEnabledKey) ?? true;
    } catch (e) {
      debugPrint('Error getting notifications enabled: $e');
      return true; // Default value
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_notificationsEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error setting notifications enabled: $e');
    }
  }

  Future<int> getDaysBeforeExpiry() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getInt(_daysBeforeExpiryKey) ?? 7;
    } catch (e) {
      debugPrint('Error getting days before expiry: $e');
      return 7; // Default value
    }
  }

  Future<void> setDaysBeforeExpiry(int days) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_daysBeforeExpiryKey, days);
    } catch (e) {
      debugPrint('Error setting days before expiry: $e');
    }
  }

  Future<String> getNotificationSound() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_notificationSoundKey) ?? 'default';
    } catch (e) {
      debugPrint('Error getting notification sound: $e');
      return 'default'; // Default value
    }
  }

  Future<void> setNotificationSound(String sound) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_notificationSoundKey, sound);
    } catch (e) {
      debugPrint('Error setting notification sound: $e');
    }
  }

  Future<bool> getVibrationEnabled() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_vibrationEnabledKey) ?? true;
    } catch (e) {
      debugPrint('Error getting vibration enabled: $e');
      return true; // Default value
    }
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_vibrationEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error setting vibration enabled: $e');
    }
  }

  Future<void> clearAllSettings() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_notificationsEnabledKey);
      await prefs.remove(_daysBeforeExpiryKey);
      await prefs.remove(_notificationSoundKey);
      await prefs.remove(_vibrationEnabledKey);
    } catch (e) {
      debugPrint('Error clearing settings: $e');
    }
  }
}

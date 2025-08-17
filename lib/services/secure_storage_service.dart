// secure_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static Future<void> setPasscode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_passcode', code);
  }

  static Future<String?> getPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_passcode');
  }

  static Future<void> clearPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_passcode');
  }
}

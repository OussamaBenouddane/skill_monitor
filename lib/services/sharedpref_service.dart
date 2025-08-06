import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService extends GetxService {
  late SharedPreferences _prefs;

  SharedPreferences get prefs => _prefs;

  /// Initialize SharedPreferences
  Future<SharedPrefsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  /// Convenience methods for common operations
  
  // String operations
  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  
  // Bool operations
  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  
  // Int operations
  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  
  // Remove operations
  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
  
  // Get all keys
  Set<String> getKeys() => _prefs.getKeys();
  
  // Check if key exists
  bool containsKey(String key) => _prefs.containsKey(key);
}
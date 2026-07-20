import 'dart:convert';
import '../models/global_setting.dart';
import 'api_service.dart';

class SettingsService {
  static Future<List<GlobalSetting>> getGlobalSettings() async {
    try {
      final response = await ApiService.get('/global-settings');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => GlobalSetting.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load settings');
      }
    } catch (e) {
      print('Error fetching settings: $e');
      return [];
    }
  }

  static Future<dynamic> getSettingValue(String key) async {
    try {
      final settings = await getGlobalSettings();
      final setting = settings.firstWhere((s) => s.key == key);
      return setting.value;
    } catch (e) {
      return null;
    }
  }
}

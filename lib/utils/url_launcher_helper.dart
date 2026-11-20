import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'url_launcher_stub.dart' if (dart.library.js_interop) 'url_launcher_web.dart' as web_launcher;

class UrlLauncherHelper {
  static Future<bool> openUrl(String urlString) async {
    if (kIsWeb) {
      try {
        final webResult = web_launcher.openUrlInWeb(urlString);
        if (webResult) return true;
      } catch (e) {
        debugPrint('Web openUrl direct error: $e');
      }
    }

    try {
      final Uri uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return launched;
    } catch (e) {
      debugPrint('LaunchUrl error: $e');
      if (kIsWeb) {
        try {
          return web_launcher.openUrlInWeb(urlString);
        } catch (_) {}
      }
      return false;
    }
  }
}

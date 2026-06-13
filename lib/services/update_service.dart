import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;
  UpdateService._();

  final ApiService _api = ApiService();

  Future<void> checkForUpdate(BuildContext context) async {
    if (kIsWeb) return; // Updates don't apply to web
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      final res = await _api.get('/version/latest');
      final data = res.data;
      final latestVersion = data['version'] as String;

      final isWindows = defaultTargetPlatform == TargetPlatform.windows;
      final downloadUrl = (isWindows
              ? data['downloadUrlWindows']
              : data['downloadUrl']) as String? ??
          '';

      if (downloadUrl.isEmpty) return;

      if (_compareVersions(latestVersion, currentVersion) > 0) {
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Update Available'),
              content: Text(
                  'Version $latestVersion is available.\nYou have $currentVersion.\n\n${data['releaseNotes'] ?? ''}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchUrl(downloadUrl);
                  },
                  child: const Text('Download'),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {}
  }

  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

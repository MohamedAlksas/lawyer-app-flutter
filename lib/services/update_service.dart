import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'api_service.dart';
import '../app.dart'; // To access navigatorKey

class UpdateService {
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;
  UpdateService._();

  final ApiService _api = ApiService();

  Future<void> checkForUpdate(BuildContext context, {bool manual = false}) async {
    if (kIsWeb) {
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Web version is always up to date.')),
        );
      }
      return;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      final res = await _api.get('/version/latest');
      final data = res.data;
      final latestVersion = data['version'] as String;

      final downloadUrl = (defaultTargetPlatform == TargetPlatform.windows
              ? data['downloadUrlWindows']
              : data['downloadUrl']) as String? ??
          '';

      if (downloadUrl.isEmpty) {
        if (manual && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid update URL found.')),
          );
        }
        return;
      }

      if (_compareVersions(latestVersion, currentVersion) > 0) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _UpdateFlowDialog(
              latestVersion: latestVersion,
              currentVersion: currentVersion,
              releaseNotes: data['releaseNotes'] ?? '',
              downloadUrl: downloadUrl,
            ),
          );
        }
      } else if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are on the latest version ($currentVersion).')),
        );
      }
    } catch (e) {
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check for updates: $e')),
        );
      }
    }
  }

  int _compareVersions(String a, String b) {
    try {
      final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (var i = 0; i < 3; i++) {
        final va = i < partsA.length ? partsA[i] : 0;
        final vb = i < partsB.length ? partsB[i] : 0;
        if (va != vb) return va - vb;
      }
    } catch (_) {}
    return 0;
  }
}

class _UpdateFlowDialog extends StatefulWidget {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String downloadUrl;

  const _UpdateFlowDialog({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  @override
  State<_UpdateFlowDialog> createState() => _UpdateFlowDialogState();
}

class _UpdateFlowDialogState extends State<_UpdateFlowDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _status = '';
  bool _isError = false;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _status = 'Preparing download...';
    });

    try {
      final dio = Dio();
      final fileName = widget.downloadUrl.split('/').last;
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';

      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _progress = count / total;
              _status = 'Downloading: ${(_progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      setState(() {
        _status = 'Download complete. Launching installer...';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await OpenFilex.open(savePath);
      
      if (mounted) {
        if (result.type != ResultType.done) {
          setState(() {
            _isError = true;
            _status = 'Could not launch installer: ${result.message}\nPlease install manually from your temp folder.';
          });
        } else {
          // Success! Installer is running, app will close/update
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _status = 'Download failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return AlertDialog(
        title: Text(_isError ? 'Update Failed' : 'Installing Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isError) LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          if (_isError)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Update Available'),
      content: Text(
          'Version ${widget.latestVersion} is available.\nYou have ${widget.currentVersion}.\n\n${widget.releaseNotes}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: _startDownload,
          child: const Text('Update Now'),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'api_service.dart';

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

      final isWindows = defaultTargetPlatform == TargetPlatform.windows;
      final downloadUrl = (isWindows
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
                    _downloadAndInstall(context, downloadUrl, latestVersion);
                  },
                  child: const Text('Update Now'),
                ),
              ],
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

  Future<void> _downloadAndInstall(BuildContext context, String url, String version) async {
    final fileName = url.split('/').last;
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/$fileName';

    if (!context.mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DownloadDialog(
        url: url,
        savePath: savePath,
        version: version,
      ),
    );
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
}

class _DownloadDialog extends StatefulWidget {
  final String url;
  final String savePath;
  final String version;

  const _DownloadDialog({
    required this.url,
    required this.savePath,
    required this.version,
  });

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0;
  String _status = 'Starting download...';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await Dio().download(
        widget.url,
        widget.savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _progress = count / total;
              _status = 'Downloading update: ${(_progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      setState(() {
        _status = 'Download complete. Launching installer...';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await OpenFilex.open(widget.savePath);
      
      if (mounted) {
        if (result.type != ResultType.done) {
          setState(() {
            _isError = true;
            _status = 'Could not launch installer: ${result.message}\nPlease try downloading manually.';
          });
        } else {
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
    return AlertDialog(
      title: Text(_isError ? 'Update Failed' : 'Updating to ${widget.version}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isError) LinearProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text(_status),
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
}

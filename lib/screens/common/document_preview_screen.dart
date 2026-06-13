import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final String url;
  final String title;

  const DocumentPreviewScreen({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isPdf = url.toLowerCase().endsWith('.pdf') || url.contains('pdf');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share logic could be added here
            },
          ),
        ],
      ),
      body: Center(
        child: isPdf
            ? SfPdfViewer.network(url)
            : InteractiveViewer(
                child: Image.network(
                  url,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(s.noData),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

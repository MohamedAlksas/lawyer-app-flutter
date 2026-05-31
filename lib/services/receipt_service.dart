import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateReceiptPdf({
  required String clientName,
  required String amount,
  required String caseNum,
  required String date,
  String? note,
}) async {
  final pdf = pw.Document();

  final arabicFont = await PdfGoogleFonts.cairoRegular();
  final arabicBold = await PdfGoogleFonts.cairoBold();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'مكتب المحاماة - سند قبض',
                    style: pw.TextStyle(font: arabicBold, fontSize: 18),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey),
                pw.SizedBox(height: 12),
                pw.Text('تاريخ السند: $date', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                pw.SizedBox(height: 12),
                pw.Text('استلمنا من السيد/ة: $clientName', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                pw.SizedBox(height: 8),
                pw.Text('مبلغ وقدره: $amount جنيه مصري', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                pw.SizedBox(height: 8),
                pw.Text('وذلك عن قضية رقم: $caseNum', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                if (note != null && note.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text('ملاحظات: $note', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                ],
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.bottomLeft,
                  child: pw.Text(
                    'توقيع المستلم: ______________',
                    style: pw.TextStyle(font: arabicFont, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/reports_service.dart';

class ExportReportPage extends StatefulWidget {
  const ExportReportPage({super.key});

  @override
  State<ExportReportPage> createState() => _ExportReportPageState();
}

class _ExportReportPageState extends State<ExportReportPage> {
  final _service = ReportsService();
  bool _loadingPdf = false;
  bool _loadingExcel = false;
  bool _pdfDone = false;
  bool _excelDone = false;

  /// Opens an authenticated URL in the browser — this triggers a native Chrome download
  /// because the backend responds with Content-Disposition: attachment.
  void _triggerDownload(String url, String filename) {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
  }

  Future<void> _exportPdf() async {
    setState(() => _loadingPdf = true);
    try {
      final url = await _service.getExportUrl('/reports/export/pdf');
      _triggerDownload(url, 'equb_financial_report.txt');
      if (mounted) setState(() { _pdfDone = true; _loadingPdf = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPdf = false);
        ErrorSnackbar.show(context, 'Report export failed');
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _loadingExcel = true);
    try {
      final url = await _service.getExportUrl('/reports/export/excel');
      _triggerDownload(url, 'financial_report.csv');
      if (mounted) setState(() { _excelDone = true; _loadingExcel = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingExcel = false);
        ErrorSnackbar.show(context, 'Export failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Export Report', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Report',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                        Text('Tap to download — file saves to your Downloads folder',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Text('Export Format',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 15)),
            const SizedBox(height: 16),

            // PDF / TXT card
            _ExportCard(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Financial Report (.txt)',
              subtitle: 'Full formatted transaction report — downloads instantly',
              color: AppTheme.error,
              loading: _loadingPdf,
              done: _pdfDone,
              doneLabel: 'Downloaded ✓',
              onTap: _loadingPdf ? null : _exportPdf,
            ),

            const SizedBox(height: 12),

            // CSV card
            _ExportCard(
              icon: Icons.table_chart_rounded,
              title: 'CSV Spreadsheet (.csv)',
              subtitle: 'All transactions — open in Excel or Google Sheets',
              color: AppTheme.secondary,
              loading: _loadingExcel,
              done: _excelDone,
              doneLabel: 'Downloaded ✓',
              onTap: _loadingExcel ? null : _exportExcel,
            ),

            if (_pdfDone || _excelDone) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'File downloaded to your Downloads folder.',
                        style: TextStyle(fontFamily: 'Poppins', color: AppTheme.success, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool loading;
  final bool done;
  final String doneLabel;
  final VoidCallback? onTap;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.loading,
    required this.done,
    required this.doneLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: done ? Border.all(color: AppTheme.success, width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (done ? AppTheme.success : color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, color: AppTheme.success, size: 24)
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 14)),
                  Text(done ? doneLabel : subtitle,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: done ? AppTheme.success : AppTheme.grayText,
                          fontSize: 12)),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary))
            else
              Icon(
                done ? Icons.check_circle_rounded : Icons.download_rounded,
                color: done ? AppTheme.success : color,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

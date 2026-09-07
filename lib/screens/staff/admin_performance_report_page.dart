import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/tourflow_widgets.dart';

class AdminPerformanceReportPage extends StatefulWidget {
  const AdminPerformanceReportPage({super.key});

  static const routeName = '/admin-performance-report';

  @override
  State<AdminPerformanceReportPage> createState() => _AdminPerformanceReportPageState();
}

class _AdminPerformanceReportPageState extends State<AdminPerformanceReportPage> {
  final _client = Supabase.instance.client;
  late Future<_PerformanceReportData> _report;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _report = _loadReport();
  }

  Future<_PerformanceReportData> _loadReport() async {
    final feedbackRows = await _client.from('feedback').select('overall_rating');

    final bookingRows = await _client
        .from('bookings')
        .select(
      'visitor_count, completed_at, '
          'slot:attraction_slots('
          'attraction:attractions(entrance_price_myr)'
          ')',
    )
        .eq('status', 'completed');

    double averageRating = 0.0;

    if (feedbackRows.isNotEmpty) {
      final validRatings = feedbackRows
          .map((row) => (row['overall_rating'] as num?)?.toDouble())
          .whereType<double>()
          .toList();

      if (validRatings.isNotEmpty) {
        averageRating = validRatings.reduce((a, b) => a + b) / validRatings.length;
      }
    }

    final double visitorSatisfaction =
    averageRating == 0 ? 0.0 : (averageRating / 5) * 100;

    double totalRevenue = 0.0;
    int totalVisitors = 0;

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month, now.day + 1);

    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthDays =
        DateTime(previousMonthStart.year, previousMonthStart.month + 1, 0).day;

    final comparisonDay =
    now.day > previousMonthDays ? previousMonthDays : now.day;

    final previousMonthEnd = DateTime(
      previousMonthStart.year,
      previousMonthStart.month,
      comparisonDay + 1,
    );

    double currentRevenue = 0.0;
    double previousRevenue = 0.0;

    for (final row in bookingRows) {
      final visitors = (row['visitor_count'] as num?)?.toInt() ?? 0;
      final slot = (row['slot'] as Map?)?.cast<String, dynamic>();
      final attraction = (slot?['attraction'] as Map?)?.cast<String, dynamic>();

      final entrancePrice =
          (attraction?['entrance_price_myr'] as num?)?.toDouble() ?? 0.0;

      final revenue = visitors * entrancePrice;

      totalVisitors += visitors;
      totalRevenue += revenue;

      final completedAtValue = row['completed_at'];
      if (completedAtValue == null) continue;

      final completedAt =
      DateTime.parse(completedAtValue.toString()).toLocal();

      if (!completedAt.isBefore(currentMonthStart) &&
          completedAt.isBefore(currentMonthEnd)) {
        currentRevenue += revenue;
      }

      if (!completedAt.isBefore(previousMonthStart) &&
          completedAt.isBefore(previousMonthEnd)) {
        previousRevenue += revenue;
      }
    }

    final double revenuePerVisitor =
    totalVisitors == 0 ? 0.0 : totalRevenue / totalVisitors;

    String revenueGrowth;

    if (previousRevenue == 0) {
      revenueGrowth = currentRevenue > 0 ? 'New' : '0%';
    } else {
      final growth =
          ((currentRevenue - previousRevenue) / previousRevenue) * 100;

      revenueGrowth =
      '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%';
    }

    return _PerformanceReportData(
      visitorSatisfaction: visitorSatisfaction,
      averageRating: averageRating,
      revenuePerVisitor: revenuePerVisitor,
      revenueGrowth: revenueGrowth,
      totalVisitors: totalVisitors,
      totalRevenue: totalRevenue,
      totalFeedback: feedbackRows.length,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  Future<Uint8List> _buildPdf(_PerformanceReportData data) async {
    final pdf = pw.Document();
    final generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 1,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TourFlow',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'ADMINISTRATOR',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 1,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TourFlow Performance Report',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Text(
            'Performance Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Visitor, rating and revenue performance',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated: ${_formatDate(generatedAt)}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'Performance Metrics',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.8,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              _pdfTableHeader('Metric', 'Value'),
              _pdfTableRow(
                'Visitor Satisfaction',
                '${data.visitorSatisfaction.toStringAsFixed(0)}%',
              ),
              _pdfTableRow(
                'Average Rating',
                data.averageRating == 0
                    ? 'No rating data'
                    : '${data.averageRating.toStringAsFixed(1)} / 5',
              ),
              _pdfTableRow(
                'Revenue Per Visitor',
                'RM ${data.revenuePerVisitor.toStringAsFixed(2)}',
              ),
              _pdfTableRow(
                'Revenue Growth',
                data.revenueGrowth,
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Key Metrics',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.8,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              _pdfTableHeader('Item', 'Value'),
              _pdfTableRow(
                'Total Visitors',
                _formatNumber(data.totalVisitors),
              ),
              _pdfTableRow(
                'Total Revenue',
                'RM ${data.totalRevenue.toStringAsFixed(2)}',
              ),
              _pdfTableRow(
                'Feedback Records',
                '${data.totalFeedback}',
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Calculation Notes',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Revenue is derived from completed bookings using visitor count multiplied by attraction entrance price.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Revenue growth compares the current month-to-date with the same period of the previous month.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.TableRow _pdfTableHeader(String left, String right) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            left,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            right,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf(_PerformanceReportData data) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final bytes = await _buildPdf(data);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'tourflow_performance_report.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to export PDF: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Performance Report',
      role: 'TOURFLOW · ADMINISTRATOR',
      navigationRole: TourFlowNavigationRole.administrator,
      selectedNavigationIndex: 0,
      child: FutureBuilder<_PerformanceReportData>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return ModuleCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Unable to generate performance report.',
                    style: TextStyle(
                      color: TourFlowColors.heading,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _report = _loadReport();
                      });
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7357C8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Overview',
                          style: TextStyle(
                            color: TourFlowColors.heading,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Visitor, rating and revenue performance summary',
                          style: TextStyle(
                            color: TourFlowColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.sentiment_satisfied_alt_outlined,
                      label: 'Visitor Satisfaction',
                      value:
                      '${data.visitorSatisfaction.toStringAsFixed(0)}%',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.star_outline_rounded,
                      label: 'Average Rating',
                      value: data.averageRating == 0
                          ? '-'
                          : '${data.averageRating.toStringAsFixed(1)} / 5',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.payments_outlined,
                      label: 'Revenue / Visitor',
                      value:
                      'RM ${data.revenuePerVisitor.toStringAsFixed(2)}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Revenue Growth',
                      value: data.revenueGrowth,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE1E5EA),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFF1EDFA),
                              borderRadius: BorderRadius.all(
                                Radius.circular(9),
                              ),
                            ),
                            child: Icon(
                              Icons.analytics_outlined,
                              color: Color(0xFF7357C8),
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Key Metrics',
                          style: TextStyle(
                            color: TourFlowColors.heading,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _SummaryRow(
                      icon: Icons.groups_outlined,
                      label: 'Total Visitors',
                      value: _formatNumber(data.totalVisitors),
                    ),

                    const Divider(
                      height: 24,
                      color: Color(0xFFEDF0F3),
                    ),

                    _SummaryRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Total Revenue',
                      value:
                      'RM ${data.totalRevenue.toStringAsFixed(2)}',
                    ),

                    const Divider(
                      height: 24,
                      color: Color(0xFFEDF0F3),
                    ),

                    _SummaryRow(
                      icon: Icons.rate_review_outlined,
                      label: 'Feedback Records',
                      value: '${data.totalFeedback}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8FC),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFFE6DDF2),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF7357C8),
                      size: 17,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Revenue is derived from completed bookings using visitor count × attraction entrance price. Revenue growth compares the current month-to-date with the same period of the previous month.',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 8.8,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed:
                  _isExporting ? null : () => _exportPdf(data),
                  icon: _isExporting
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 20,
                  ),
                  label: Text(
                    _isExporting
                        ? 'Generating PDF...'
                        : 'Export PDF',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1EDFA),
                    foregroundColor: const Color(0xFF6546B2),
                    disabledBackgroundColor:
                    const Color(0xFFF3F1F6),
                    disabledForegroundColor:
                    const Color(0xFF9E97AA),
                    elevation: 0,
                    side: const BorderSide(
                      color: Color(0xFFD8CCEB),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EDFA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7357C8),
              size: 17,
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF796E91),
            size: 16,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.body,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: TourFlowColors.heading,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PerformanceReportData {
  const _PerformanceReportData({
    required this.visitorSatisfaction,
    required this.averageRating,
    required this.revenuePerVisitor,
    required this.revenueGrowth,
    required this.totalVisitors,
    required this.totalRevenue,
    required this.totalFeedback,
  });

  final double visitorSatisfaction;
  final double averageRating;
  final double revenuePerVisitor;
  final String revenueGrowth;
  final int totalVisitors;
  final double totalRevenue;
  final int totalFeedback;
}
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/tourflow_widgets.dart';

class AdminSustainabilityReportPage extends StatefulWidget {
  const AdminSustainabilityReportPage({super.key});

  static const routeName = '/admin-sustainability-report';

  @override
  State<AdminSustainabilityReportPage> createState() =>
      _AdminSustainabilityReportPageState();
}

class _AdminSustainabilityReportPageState
    extends State<AdminSustainabilityReportPage> {
  final _client = Supabase.instance.client;

  Future<_SustainabilityReportData>? _report;

  DateTime? _startDate;
  DateTime? _endDate;

  bool _argumentsLoaded = false;
  bool _isExporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_argumentsLoaded) return;
    _argumentsLoaded = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map) {
      final startDate = arguments['startDate'];
      final endDate = arguments['endDate'];

      if (startDate is DateTime) {
        _startDate = DateTime(startDate.year, startDate.month, startDate.day);
      }

      if (endDate is DateTime) {
        _endDate = DateTime(endDate.year, endDate.month, endDate.day);
      }
    }

    _report = _loadReport();
  }

  String _dateForQuery(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<_SustainabilityReportData> _loadReport() async {
    var query = _client
        .from('sustainability_metrics')
        .select(
          'record_date, carbon_offset_kg, water_saved_l, energy_saved_kwh, '
          'recycling_rate, attraction:attractions(id, name)',
        );

    if (_startDate != null) {
      query = query.gte('record_date', _dateForQuery(_startDate!));
    }

    if (_endDate != null) {
      query = query.lte('record_date', _dateForQuery(_endDate!));
    }

    final rows = await query.order('record_date', ascending: true);

    double carbonOffset = 0.0;
    double waterSaved = 0.0;
    double energySaved = 0.0;

    double recyclingTotal = 0.0;
    int recyclingRecords = 0;

    final attractionIds = <String>{};

    for (final row in rows) {
      carbonOffset += (row['carbon_offset_kg'] as num?)?.toDouble() ?? 0.0;

      waterSaved += (row['water_saved_l'] as num?)?.toDouble() ?? 0.0;

      energySaved += (row['energy_saved_kwh'] as num?)?.toDouble() ?? 0.0;

      final recycling = (row['recycling_rate'] as num?)?.toDouble();

      if (recycling != null) {
        recyclingTotal += recycling;
        recyclingRecords++;
      }

      final attraction = (row['attraction'] as Map?)?.cast<String, dynamic>();

      final attractionId = attraction?['id']?.toString();

      if (attractionId != null && attractionId.isNotEmpty) {
        attractionIds.add(attractionId);
      }
    }

    final recyclingRate = recyclingRecords == 0
        ? 0.0
        : recyclingTotal / recyclingRecords;

    return _SustainabilityReportData(
      carbonOffsetKg: carbonOffset,
      waterSavedL: waterSaved,
      energySavedKwh: energySaved,
      recyclingRate: recyclingRate,
      recordCount: rows.length,
      attractionCount: attractionIds.length,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _reportPeriod(_SustainabilityReportData data) {
    if (data.startDate == null || data.endDate == null) {
      return 'All Available Data';
    }

    if (data.startDate!.year == data.endDate!.year &&
        data.startDate!.month == data.endDate!.month &&
        data.startDate!.day == data.endDate!.day) {
      return _formatDate(data.startDate!);
    }

    return '${_formatDate(data.startDate!)} - '
        '${_formatDate(data.endDate!)}';
  }

  Future<Uint8List> _buildPdf(_SustainabilityReportData data) async {
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
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
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
                top: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TourFlow Sustainability Report',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of '
                  '${context.pagesCount}',
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
            'Sustainability Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            'Environmental sustainability performance',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 6),

          pw.Text(
            'Reporting Period: ${_reportPeriod(data)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 3),

          pw.Text(
            'Generated: ${_formatDate(generatedAt)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Sustainability Metrics',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              _pdfTableHeader('Metric', 'Value'),
              _pdfTableRow(
                'Carbon Offset',
                '${_formatNumber(data.carbonOffsetKg)} kg',
              ),
              _pdfTableRow(
                'Water Saved',
                '${_formatNumber(data.waterSavedL)} L',
              ),
              _pdfTableRow(
                'Energy Saved',
                '${_formatNumber(data.energySavedKwh)} kWh',
              ),
              _pdfTableRow(
                'Recycling Rate',
                '${data.recyclingRate.toStringAsFixed(1)}%',
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Report Summary',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              _pdfTableHeader('Item', 'Value'),
              _pdfTableRow('Reporting Period', _reportPeriod(data)),
              _pdfTableRow('Attractions', '${data.attractionCount}'),
              _pdfTableRow('Data Records', '${data.recordCount}'),
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
                  'Carbon offset, water saved and energy saved '
                  'are calculated by summing all recorded values '
                  'within the selected reporting period.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  'Recycling rate is calculated using the '
                  'average recycling rate of all records within '
                  'the selected reporting period.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  'Attractions represents the number of unique '
                  'attractions with sustainability records, while '
                  'Data Records represents the total number of '
                  'sustainability records in the selected period.',
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
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            left,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            right,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
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
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf(_SustainabilityReportData data) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final bytes = await _buildPdf(data);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'tourflow_sustainability_report.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to export PDF: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _report = _loadReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return TourFlowPage(
      title: 'Sustainability Report',
      role: 'TOURFLOW · ADMINISTRATOR',
      navigationRole: TourFlowNavigationRole.administrator,
      selectedNavigationIndex: 0,

      child: report == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          : FutureBuilder<_SustainabilityReportData>(
              future: report,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
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
                          'Unable to generate sustainability report.',
                          style: TextStyle(
                            color: TourFlowColors.heading,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _retry,
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
                            color: const Color(0xFF2B9465),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(width: 9),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sustainability Overview',
                                style: TextStyle(
                                  color: TourFlowColors.heading,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Environmental performance summary',
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
                            icon: Icons.cloud_outlined,
                            label: 'Carbon Offset',
                            value: '${_formatNumber(data.carbonOffsetKg)} kg',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.water_drop_outlined,
                            label: 'Water Saved',
                            value: '${_formatNumber(data.waterSavedL)} L',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.bolt_outlined,
                            label: 'Energy Saved',
                            value: '${_formatNumber(data.energySavedKwh)} kWh',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.recycling_rounded,
                            label: 'Recycling Rate',
                            value: '${data.recyclingRate.toStringAsFixed(1)}%',
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
                        border: Border.all(color: const Color(0xFFE1E5EA)),
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
                                    color: Color(0xFFEAF7F0),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(9),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFF2B9465),
                                    size: 18,
                                  ),
                                ),
                              ),

                              SizedBox(width: 10),

                              Text(
                                'Report Summary',
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
                            icon: Icons.date_range_outlined,
                            label: 'Reporting Period',
                            value: _reportPeriod(data),
                          ),

                          const Divider(height: 24, color: Color(0xFFEDF0F3)),

                          _SummaryRow(
                            icon: Icons.location_on_outlined,
                            label: 'Attractions',
                            value: '${data.attractionCount}',
                          ),

                          const Divider(height: 24, color: Color(0xFFEDF0F3)),

                          _SummaryRow(
                            icon: Icons.storage_outlined,
                            label: 'Data Records',
                            value: '${data.recordCount}',
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
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFDDE8E2)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF2B9465),
                            size: 17,
                          ),

                          SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              'Carbon offset, water saved and energy saved use total recorded values within the selected reporting period. Recycling rate uses the average recorded rate.',
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
                        onPressed: _isExporting ? null : () => _exportPdf(data),
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
                                size: 18,
                              ),
                        label: Text(
                          _isExporting ? 'Generating PDF...' : 'Export PDF',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAF7F0),
                          foregroundColor: const Color(0xFF247E57),
                          disabledBackgroundColor: const Color(0xFFF0F4F2),
                          disabledForegroundColor: const Color(0xFF8FA49A),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFC8E3D5)),
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
        border: Border.all(color: const Color(0xFFE1E5EA)),
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
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF2B9465), size: 17),
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
            color: const Color(0xFFF2F6F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6B8176), size: 16),
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

class _SustainabilityReportData {
  const _SustainabilityReportData({
    required this.carbonOffsetKg,
    required this.waterSavedL,
    required this.energySavedKwh,
    required this.recyclingRate,
    required this.recordCount,
    required this.attractionCount,
    required this.startDate,
    required this.endDate,
  });

  final double carbonOffsetKg;
  final double waterSavedL;
  final double energySavedKwh;
  final double recyclingRate;

  final int recordCount;
  final int attractionCount;

  final DateTime? startDate;
  final DateTime? endDate;
}

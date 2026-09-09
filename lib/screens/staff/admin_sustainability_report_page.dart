import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/tourflow_widgets.dart';

class AdminSustainabilityReportPage extends StatefulWidget {
  const AdminSustainabilityReportPage({
    super.key,
  });

  static const routeName =
      '/admin-sustainability-report';

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

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map) {
      final startDate = arguments['startDate'];
      final endDate = arguments['endDate'];

      if (startDate is DateTime) {
        _startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
      }

      if (endDate is DateTime) {
        _endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
        );
      }
    }

    _report = _loadReport();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatInteger(int value) {
    final text = value.toString();
    final result = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;

      result.write(text[i]);

      if (remaining > 1 &&
          remaining % 3 == 1) {
        result.write(',');
      }
    }

    return result.toString();
  }

  String _reportPeriod(
      _SustainabilityReportData data,
      ) {
    if (data.startDate == null ||
        data.endDate == null) {
      return 'All Available Data';
    }

    if (data.startDate!.year ==
        data.endDate!.year &&
        data.startDate!.month ==
            data.endDate!.month &&
        data.startDate!.day ==
            data.endDate!.day) {
      return _formatDate(data.startDate!);
    }

    return '${_formatDate(data.startDate!)} - '
        '${_formatDate(data.endDate!)}';
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  DateTime _endExclusive(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day + 1,
    );
  }

  Future<_SustainabilityReportData>
  _loadReport() async {
    if (_startDate == null ||
        _endDate == null) {
      return _SustainabilityReportData.empty(
        startDate: _startDate,
        endDate: _endDate,
      );
    }

    final start =
    _startOfDay(_startDate!).toUtc();

    final endExclusive =
    _endExclusive(_endDate!).toUtc();

    /*
     * VISITOR DATA
     *
     * attraction_check_ins tells us:
     * - which booking actually visited
     * - which attraction was visited
     * - when the visitor checked in
     *
     * bookings gives:
     * - visitor_count
     * - slot_id
     */
    final checkInRows = await _client
        .from('attraction_check_ins')
        .select(
      'booking_id, attraction_id, checked_in_at, '
          'attraction:attractions(id, name), '
          'booking:bookings(visitor_count, slot_id)',
    )
        .gte(
      'checked_in_at',
      start.toIso8601String(),
    )
        .lt(
      'checked_in_at',
      endExclusive.toIso8601String(),
    )
        .order(
      'checked_in_at',
      ascending: true,
    );

    final visitorsByAttraction =
    <String, int>{};

    final attractionNames =
    <String, String>{};

    final visitorsBySlot =
    <String, int>{};

    final seenBookings = <String>{};

    var checkInRecordCount = 0;

    for (final row in checkInRows) {
      final bookingId =
          row['booking_id']?.toString() ?? '';

      if (bookingId.isNotEmpty &&
          seenBookings.contains(bookingId)) {
        continue;
      }

      if (bookingId.isNotEmpty) {
        seenBookings.add(bookingId);
      }

      final attraction =
      (row['attraction'] as Map?)
          ?.cast<String, dynamic>();

      final booking =
      (row['booking'] as Map?)
          ?.cast<String, dynamic>();

      final attractionId =
          row['attraction_id']?.toString() ??
              attraction?['id']?.toString() ??
              '';

      if (attractionId.isEmpty) {
        continue;
      }

      final attractionName =
          attraction?['name']?.toString() ??
              'Unknown Attraction';

      final visitorCount =
          (booking?['visitor_count'] as num?)
              ?.toInt() ??
              1;

      final slotId =
          booking?['slot_id']?.toString() ?? '';

      attractionNames[attractionId] =
          attractionName;

      visitorsByAttraction[attractionId] =
          (visitorsByAttraction[
          attractionId] ??
              0) +
              visitorCount;

      if (slotId.isNotEmpty) {
        visitorsBySlot[slotId] =
            (visitorsBySlot[slotId] ?? 0) +
                visitorCount;
      }

      checkInRecordCount++;
    }

    final totalVisitors =
    visitorsByAttraction.values.fold<int>(
      0,
          (sum, visitors) => sum + visitors,
    );

    final attractionCount =
        visitorsByAttraction.length;

    final distribution =
    <_AttractionDistribution>[];

    visitorsByAttraction.forEach(
          (attractionId, visitors) {
        final percentage =
        totalVisitors == 0
            ? 0.0
            : visitors /
            totalVisitors *
            100;

        distribution.add(
          _AttractionDistribution(
            attractionId: attractionId,
            attractionName:
            attractionNames[attractionId] ??
                'Unknown Attraction',
            visitors: visitors,
            percentage: percentage,
          ),
        );
      },
    );

    distribution.sort(
          (a, b) =>
          b.visitors.compareTo(a.visitors),
    );

    final mostVisitedAttraction =
    distribution.isEmpty
        ? null
        : distribution.first;

    final averageVisitorsPerAttraction =
    attractionCount == 0
        ? 0.0
        : totalVisitors /
        attractionCount;

    /*
     * ATTRACTION USAGE
     *
     * We use slot capacity because it gives a proper
     * denominator for attraction usage.
     *
     * Usage =
     * checked-in visitors for slots
     * --------------------------------
     * total available capacity of slots
     *
     * Closed slots are excluded.
     */
    final slotRows = await _client
        .from('attraction_slots')
        .select(
      'id, attraction_id, starts_at, '
          'maximum_capacity, status, '
          'attraction:attractions(id, name)',
    )
        .gte(
      'starts_at',
      start.toIso8601String(),
    )
        .lt(
      'starts_at',
      endExclusive.toIso8601String(),
    )
        .order(
      'starts_at',
      ascending: true,
    );

    final usageMap =
    <String, _UsageAccumulator>{};

    /*
     * First include attractions that had visitors.
     */
    visitorsByAttraction.forEach(
          (attractionId, visitors) {
        usageMap[attractionId] =
            _UsageAccumulator(
              attractionId: attractionId,
              attractionName:
              attractionNames[attractionId] ??
                  'Unknown Attraction',
              visitors: visitors,
            );
      },
    );

    var scheduledSlotCount = 0;

    for (final row in slotRows) {
      final status =
          row['status']?.toString() ?? '';

      /*
       * Closed slots were not available to visitors,
       * so they should not contribute to usable
       * capacity.
       */
      if (status == 'closed') {
        continue;
      }

      final attraction =
      (row['attraction'] as Map?)
          ?.cast<String, dynamic>();

      final attractionId =
          row['attraction_id']?.toString() ??
              attraction?['id']?.toString() ??
              '';

      final slotId =
          row['id']?.toString() ?? '';

      if (attractionId.isEmpty ||
          slotId.isEmpty) {
        continue;
      }

      final attractionName =
          attraction?['name']?.toString() ??
              attractionNames[attractionId] ??
              'Unknown Attraction';

      final maximumCapacity =
          (row['maximum_capacity'] as num?)
              ?.toInt() ??
              0;

      if (maximumCapacity <= 0) {
        continue;
      }

      final accumulator =
      usageMap.putIfAbsent(
        attractionId,
            () => _UsageAccumulator(
          attractionId: attractionId,
          attractionName: attractionName,
          visitors:
          visitorsByAttraction[
          attractionId] ??
              0,
        ),
      );

      accumulator.totalCapacity +=
          maximumCapacity;

      accumulator.slotCount++;

      scheduledSlotCount++;
    }

    final attractionUsage =
    usageMap.values
        .map(
          (item) => _AttractionUsage(
        attractionId:
        item.attractionId,
        attractionName:
        item.attractionName,
        visitors: item.visitors,
        totalCapacity:
        item.totalCapacity,
        slotCount:
        item.slotCount,
        utilisation:
        item.totalCapacity == 0
            ? 0.0
            : item.visitors /
            item.totalCapacity *
            100,
      ),
    )
        .toList();

    attractionUsage.sort(
          (a, b) => b.utilisation.compareTo(
        a.utilisation,
      ),
    );

    final validUsage =
    attractionUsage
        .where(
          (item) =>
      item.totalCapacity > 0,
    )
        .toList();

    final averageUtilisation =
    validUsage.isEmpty
        ? 0.0
        : validUsage.fold<double>(
      0,
          (sum, item) =>
      sum +
          item.utilisation,
    ) /
        validUsage.length;

    return _SustainabilityReportData(
      totalVisitors: totalVisitors,
      attractionCount: attractionCount,
      mostVisitedAttractionName:
      mostVisitedAttraction
          ?.attractionName ??
          '-',
      mostVisitedVisitors:
      mostVisitedAttraction
          ?.visitors ??
          0,
      averageVisitorsPerAttraction:
      averageVisitorsPerAttraction,
      averageUtilisation:
      averageUtilisation,
      checkInRecordCount:
      checkInRecordCount,
      scheduledSlotCount:
      scheduledSlotCount,
      distribution: distribution,
      attractionUsage:
      attractionUsage,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<Uint8List> _buildPdf(
      _SustainabilityReportData data,
      ) async {
    final pdf = pw.Document();
    final generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:
        const pw.EdgeInsets.all(36),

        header: (context) {
          return pw.Container(
            padding:
            const pw.EdgeInsets.only(
              bottom: 12,
            ),
            decoration:
            const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 1,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment
                  .spaceBetween,
              children: [
                pw.Text(
                  'TourFlow',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight:
                    pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'ADMINISTRATOR',
                  style:
                  const pw.TextStyle(
                    fontSize: 9,
                    color:
                    PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },

        footer: (context) {
          return pw.Container(
            padding:
            const pw.EdgeInsets.only(
              top: 10,
            ),
            decoration:
            const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 1,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment
                  .spaceBetween,
              children: [
                pw.Text(
                  'TourFlow Sustainability Report',
                  style:
                  const pw.TextStyle(
                    fontSize: 8,
                    color:
                    PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of '
                      '${context.pagesCount}',
                  style:
                  const pw.TextStyle(
                    fontSize: 8,
                    color:
                    PdfColors.grey600,
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
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            'Visitor distribution and attraction usage for better crowd management',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),

          pw.SizedBox(height: 6),

          pw.Text(
            'Reporting Period: ${_reportPeriod(data)}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),

          pw.SizedBox(height: 3),

          pw.Text(
            'Generated: ${_formatDate(generatedAt)}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Sustainability Overview',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight:
              pw.FontWeight.bold,
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
              1: pw.FlexColumnWidth(1.5),
            },
            children: [
              _pdfTableHeader(
                'Metric',
                'Value',
              ),
              _pdfTableRow(
                'Total Visitors',
                '${data.totalVisitors}',
              ),
              _pdfTableRow(
                'Attractions Visited',
                '${data.attractionCount}',
              ),
              _pdfTableRow(
                'Most Visited Attraction',
                data.mostVisitedVisitors == 0
                    ? '-'
                    : '${data.mostVisitedAttractionName} '
                    '(${data.mostVisitedVisitors} visitors)',
              ),
              _pdfTableRow(
                'Average Visitors / Attraction',
                data.averageVisitorsPerAttraction
                    .toStringAsFixed(1),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Visitor Distribution',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          if (data.distribution.isEmpty)
            pw.Text(
              'No visitor check-in data was recorded during this period.',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.8,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
              },
              children: [
                _pdfThreeHeader(
                  'Attraction',
                  'Visitors',
                  'Distribution',
                ),
                ...data.distribution.map(
                      (item) =>
                      _pdfThreeRow(
                        item.attractionName,
                        '${item.visitors}',
                        '${item.percentage.toStringAsFixed(1)}%',
                      ),
                ),
              ],
            ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Attraction Usage',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            'Usage compares checked-in visitors with total available slot capacity during the reporting period.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),

          pw.SizedBox(height: 10),

          if (data.attractionUsage.isEmpty)
            pw.Text(
              'No attraction usage data was available for this period.',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.8,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(0.8),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                _pdfFourHeader(
                  'Attraction',
                  'Visitors',
                  'Capacity',
                  'Usage',
                ),
                ...data.attractionUsage.map(
                      (item) =>
                      _pdfFourRow(
                        item.attractionName,
                        '${item.visitors}',
                        item.totalCapacity == 0
                            ? '-'
                            : '${item.totalCapacity}',
                        item.totalCapacity == 0
                            ? '-'
                            : '${item.utilisation.toStringAsFixed(1)}%',
                      ),
                ),
              ],
            ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Report Summary',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight:
              pw.FontWeight.bold,
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
              1: pw.FlexColumnWidth(1.5),
            },
            children: [
              _pdfTableHeader(
                'Item',
                'Value',
              ),
              _pdfTableRow(
                'Reporting Period',
                _reportPeriod(data),
              ),
              _pdfTableRow(
                'Check-in Records',
                '${data.checkInRecordCount}',
              ),
              _pdfTableRow(
                'Scheduled Slots',
                '${data.scheduledSlotCount}',
              ),
              _pdfTableRow(
                'Average Attraction Usage',
                '${data.averageUtilisation.toStringAsFixed(1)}%',
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Container(
            width: double.infinity,
            padding:
            const pw.EdgeInsets.all(12),
            decoration:
            pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius:
              pw.BorderRadius.circular(
                6,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Calculation Notes',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight:
                    pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 6),

                pw.Text(
                  'Total visitors is calculated by summing the visitor count of bookings that successfully checked in during the selected reporting period.',
                  style:
                  const pw.TextStyle(
                    fontSize: 9,
                    color:
                    PdfColors.grey700,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  'Visitor distribution is calculated as attraction visitors divided by total visitors, multiplied by 100.',
                  style:
                  const pw.TextStyle(
                    fontSize: 9,
                    color:
                    PdfColors.grey700,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  'Attraction usage compares checked-in visitors with total available slot capacity. Closed slots are excluded from available capacity.',
                  style:
                  const pw.TextStyle(
                    fontSize: 9,
                    color:
                    PdfColors.grey700,
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

  pw.TableRow _pdfTableHeader(
      String left,
      String right,
      ) {
    return pw.TableRow(
      decoration:
      const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      children: [
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(8),
          child: pw.Text(
            left,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(8),
          child: pw.Text(
            right,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.TableRow _pdfTableRow(
      String label,
      String value,
      ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style:
            const pw.TextStyle(
              fontSize: 9,
            ),
          ),
        ),
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.TableRow _pdfThreeHeader(
      String first,
      String second,
      String third,
      ) {
    return pw.TableRow(
      decoration:
      const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      children: [
        _pdfCell(
          first,
          bold: true,
        ),
        _pdfCell(
          second,
          bold: true,
          right: true,
        ),
        _pdfCell(
          third,
          bold: true,
          right: true,
        ),
      ],
    );
  }

  pw.TableRow _pdfThreeRow(
      String first,
      String second,
      String third,
      ) {
    return pw.TableRow(
      children: [
        _pdfCell(first),
        _pdfCell(
          second,
          right: true,
        ),
        _pdfCell(
          third,
          right: true,
        ),
      ],
    );
  }

  pw.TableRow _pdfFourHeader(
      String first,
      String second,
      String third,
      String fourth,
      ) {
    return pw.TableRow(
      decoration:
      const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      children: [
        _pdfCell(
          first,
          bold: true,
        ),
        _pdfCell(
          second,
          bold: true,
          right: true,
        ),
        _pdfCell(
          third,
          bold: true,
          right: true,
        ),
        _pdfCell(
          fourth,
          bold: true,
          right: true,
        ),
      ],
    );
  }

  pw.TableRow _pdfFourRow(
      String first,
      String second,
      String third,
      String fourth,
      ) {
    return pw.TableRow(
      children: [
        _pdfCell(first),
        _pdfCell(
          second,
          right: true,
        ),
        _pdfCell(
          third,
          right: true,
        ),
        _pdfCell(
          fourth,
          right: true,
        ),
      ],
    );
  }

  pw.Widget _pdfCell(
      String value, {
        bool bold = false,
        bool right = false,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: right
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _exportPdf(
      _SustainabilityReportData data,
      ) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final bytes =
      await _buildPdf(data);

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        'tourflow_sustainability_report.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
      navigationRole:
      TourFlowNavigationRole
          .administrator,
      selectedNavigationIndex: 0,
      child: report == null
          ? const Padding(
        padding:
        EdgeInsets.symmetric(
          vertical: 60,
        ),
        child: Center(
          child:
          CircularProgressIndicator(),
        ),
      )
          : FutureBuilder<
          _SustainabilityReportData>(
        future: report,
        builder:
            (context, snapshot) {
          if (snapshot
              .connectionState !=
              ConnectionState.done) {
            return const Padding(
              padding:
              EdgeInsets.symmetric(
                vertical: 60,
              ),
              child: Center(
                child:
                CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return ModuleCard(
              child: Column(
                children: [
                  const Icon(
                    Icons
                        .error_outline_rounded,
                    color:
                    Colors.redAccent,
                    size: 30,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Unable to generate sustainability report.',
                    style: TextStyle(
                      color:
                      TourFlowColors
                          .heading,
                      fontSize: 12,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  Text(
                    snapshot.error
                        .toString(),
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      color:
                      TourFlowColors
                          .muted,
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  OutlinedButton(
                    onPressed: _retry,
                    child: const Text(
                      'Try Again',
                    ),
                  ),
                ],
              ),
            );
          }

          final data =
          snapshot.data!;

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFF2B9465,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'Sustainability Overview',
                          style:
                          TextStyle(
                            color:
                            TourFlowColors
                                .heading,
                            fontSize:
                            15,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Visitor distribution and attraction usage summary',
                          style:
                          TextStyle(
                            color:
                            TourFlowColors
                                .muted,
                            fontSize:
                            9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                    _MetricCard(
                      icon: Icons
                          .groups_outlined,
                      label:
                      'Total Visitors',
                      value:
                      _formatInteger(
                        data.totalVisitors,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                    _MetricCard(
                      icon: Icons
                          .location_on_outlined,
                      label:
                      'Attractions Visited',
                      value:
                      '${data.attractionCount}',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                    _MetricCard(
                      icon: Icons
                          .emoji_events_outlined,
                      label: data
                          .mostVisitedVisitors ==
                          0
                          ? 'Most Visited Attraction'
                          : 'Most Visited · ${data.mostVisitedVisitors} visitors',
                      value: data
                          .mostVisitedAttractionName,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                    _MetricCard(
                      icon: Icons
                          .balance_outlined,
                      label:
                      'Avg. Visitors / Attraction',
                      value: data
                          .averageVisitorsPerAttraction
                          .toStringAsFixed(
                        1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              _SectionCard(
                title:
                'Visitor Distribution',
                subtitle:
                'Share of visitors across attractions',
                icon: Icons
                    .pie_chart_outline_rounded,
                child: data
                    .distribution
                    .isEmpty
                    ? const _EmptyMessage(
                  message:
                  'No visitor check-ins were recorded during this period.',
                )
                    : Column(
                  children: List
                      .generate(
                    data.distribution
                        .length,
                        (index) {
                      final item =
                      data.distribution[
                      index];

                      return _DistributionRow(
                        item:
                        item,
                        isLast:
                        index ==
                            data.distribution.length -
                                1,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              _SectionCard(
                title:
                'Attraction Usage',
                subtitle:
                'Checked-in visitors compared with available slot capacity',
                icon: Icons
                    .donut_large_rounded,
                child: data
                    .attractionUsage
                    .isEmpty
                    ? const _EmptyMessage(
                  message:
                  'No attraction usage data was available during this period.',
                )
                    : Column(
                  children: List
                      .generate(
                    data.attractionUsage
                        .length,
                        (index) {
                      final item =
                      data.attractionUsage[
                      index];

                      return _UsageRow(
                        item:
                        item,
                        isLast:
                        index ==
                            data.attractionUsage.length -
                                1,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .all(
                  15,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius
                      .circular(
                    14,
                  ),
                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFE1E5EA,
                    ),
                  ),
                  boxShadow:
                  const [
                    BoxShadow(
                      color: Color(
                        0x08000000,
                      ),
                      blurRadius:
                      8,
                      offset:
                      Offset(
                        0,
                        3,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Row(
                      children: [
                        SizedBox(
                          width: 34,
                          height:
                          34,
                          child:
                          DecoratedBox(
                            decoration:
                            BoxDecoration(
                              color:
                              Color(
                                0xFFEAF7F0,
                              ),
                              borderRadius:
                              BorderRadius
                                  .all(
                                Radius.circular(
                                  9,
                                ),
                              ),
                            ),
                            child:
                            Icon(
                              Icons
                                  .description_outlined,
                              color:
                              Color(
                                0xFF2B9465,
                              ),
                              size:
                              18,
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 10,
                        ),

                        Text(
                          'Report Summary',
                          style:
                          TextStyle(
                            color:
                            TourFlowColors
                                .heading,
                            fontSize:
                            15,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _SummaryRow(
                      icon: Icons
                          .date_range_outlined,
                      label:
                      'Reporting Period',
                      value:
                      _reportPeriod(
                        data,
                      ),
                    ),

                    const Divider(
                      height: 24,
                      color: Color(
                        0xFFEDF0F3,
                      ),
                    ),

                    _SummaryRow(
                      icon: Icons
                          .qr_code_scanner_rounded,
                      label:
                      'Check-in Records',
                      value:
                      '${data.checkInRecordCount}',
                    ),

                    const Divider(
                      height: 24,
                      color: Color(
                        0xFFEDF0F3,
                      ),
                    ),

                    _SummaryRow(
                      icon: Icons
                          .calendar_view_day_outlined,
                      label:
                      'Scheduled Slots',
                      value:
                      '${data.scheduledSlotCount}',
                    ),

                    const Divider(
                      height: 24,
                      color: Color(
                        0xFFEDF0F3,
                      ),
                    ),

                    _SummaryRow(
                      icon: Icons
                          .donut_large_rounded,
                      label:
                      'Avg. Attraction Usage',
                      value:
                      '${data.averageUtilisation.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF8FAF9,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    11,
                  ),
                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFDDE8E2,
                    ),
                  ),
                ),
                child:
                const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Icon(
                      Icons
                          .info_outline_rounded,
                      color:
                      Color(
                        0xFF2B9465,
                      ),
                      size: 17,
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        'Visitor distribution is calculated from successful check-ins. Attraction usage compares checked-in visitors with available slot capacity during the selected reporting period.',
                        style:
                        TextStyle(
                          color:
                          TourFlowColors
                              .body,
                          fontSize:
                          8.8,
                          height:
                          1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width:
                double.infinity,
                height: 46,
                child:
                ElevatedButton.icon(
                  onPressed:
                  _isExporting
                      ? null
                      : () =>
                      _exportPdf(
                        data,
                      ),
                  icon: _isExporting
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                    ),
                  )
                      : const Icon(
                    Icons
                        .picture_as_pdf_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _isExporting
                        ? 'Generating PDF...'
                        : 'Export PDF',
                    style:
                    const TextStyle(
                      fontSize:
                      13,
                      fontWeight:
                      FontWeight
                          .w800,
                    ),
                  ),
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    const Color(
                      0xFFEAF7F0,
                    ),
                    foregroundColor:
                    const Color(
                      0xFF247E57,
                    ),
                    disabledBackgroundColor:
                    const Color(
                      0xFFF0F4F2,
                    ),
                    disabledForegroundColor:
                    const Color(
                      0xFF8FA49A,
                    ),
                    elevation: 0,
                    side:
                    const BorderSide(
                      color:
                      Color(
                        0xFFC8E3D5,
                      ),
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),
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
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(13),
        border: Border.all(
          color:
          const Color(0xFFE1E5EA),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEAF7F0,
              ),
              borderRadius:
              BorderRadius.circular(
                9,
              ),
            ),
            child: Icon(
              icon,
              color:
              const Color(
                0xFF2B9465,
              ),
              size: 17,
            ),
          ),

          const Spacer(),

          SizedBox(
            width:
            double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
              Alignment.centerLeft,
              child: Text(
                value,
                style:
                const TextStyle(
                  color:
                  TourFlowColors
                      .heading,
                  fontSize: 17,
                  fontWeight:
                  FontWeight
                      .w800,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            label,
            maxLines: 2,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color:
              TourFlowColors.muted,
              fontSize: 8.5,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFE1E5EA),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFEAF7F0,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                  const Color(
                    0xFF2B9465,
                  ),
                  size: 18,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        color:
                        TourFlowColors
                            .heading,
                        fontSize: 14,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        color:
                        TourFlowColors
                            .muted,
                        fontSize: 8.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          child,
        ],
      ),
    );
  }
}

class _DistributionRow
    extends StatelessWidget {
  const _DistributionRow({
    required this.item,
    required this.isLast,
  });

  final _AttractionDistribution item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(
            color:
            Color(
              0xFFEDF0F3,
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.attractionName,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    color:
                    TourFlowColors
                        .heading,
                    fontSize: 10,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                '${item.visitors} visitors',
                style:
                const TextStyle(
                  color:
                  TourFlowColors.body,
                  fontSize: 9,
                  fontWeight:
                  FontWeight
                      .w600,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              SizedBox(
                width: 45,
                child: Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  textAlign:
                  TextAlign.right,
                  style:
                  const TextStyle(
                    color:
                    Color(
                      0xFF247E57,
                    ),
                    fontSize: 9.5,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(
              10,
            ),
            child:
            LinearProgressIndicator(
              value:
              (item.percentage /
                  100)
                  .clamp(
                0.0,
                1.0,
              ),
              minHeight: 6,
              backgroundColor:
              const Color(
                0xFFEEF4F1,
              ),
              valueColor:
              const AlwaysStoppedAnimation<
                  Color>(
                Color(
                  0xFF2B9465,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.item,
    required this.isLast,
  });

  final _AttractionUsage item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final hasCapacity =
        item.totalCapacity > 0;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(
            color:
            Color(
              0xFFEDF0F3,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.attractionName,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    color:
                    TourFlowColors
                        .heading,
                    fontSize: 10,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                hasCapacity
                    ? '${item.utilisation.toStringAsFixed(1)}%'
                    : '-',
                style:
                const TextStyle(
                  color:
                  Color(
                    0xFF247E57,
                  ),
                  fontSize: 10,
                  fontWeight:
                  FontWeight
                      .w800,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            hasCapacity
                ? '${item.visitors} visitors / ${item.totalCapacity} total slot capacity · ${item.slotCount} slots'
                : '${item.visitors} visitors · no slot capacity available',
            style:
            const TextStyle(
              color:
              TourFlowColors.muted,
              fontSize: 8.3,
            ),
          ),

          if (hasCapacity) ...[
            const SizedBox(
              height: 7,
            ),
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                10,
              ),
              child:
              LinearProgressIndicator(
                value:
                (item.utilisation /
                    100)
                    .clamp(
                  0.0,
                  1.0,
                ),
                minHeight: 6,
                backgroundColor:
                const Color(
                  0xFFEEF4F1,
                ),
                valueColor:
                const AlwaysStoppedAnimation<
                    Color>(
                  Color(
                    0xFF2B9465,
                  ),
                ),
              ),
            ),
          ],
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
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFF2F6F4,
            ),
            borderRadius:
            BorderRadius.circular(
              8,
            ),
          ),
          child: Icon(
            icon,
            color:
            const Color(
              0xFF6B8176,
            ),
            size: 16,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Text(
            label,
            style:
            const TextStyle(
              color:
              TourFlowColors.body,
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
            TextAlign.right,
            style:
            const TextStyle(
              color:
              TourFlowColors
                  .heading,
              fontSize: 11,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 18,
      ),
      child: Center(
        child: Text(
          message,
          textAlign:
          TextAlign.center,
          style:
          const TextStyle(
            color:
            TourFlowColors.muted,
            fontSize: 9.5,
          ),
        ),
      ),
    );
  }
}

class _UsageAccumulator {
  _UsageAccumulator({
    required this.attractionId,
    required this.attractionName,
    required this.visitors,
  });

  final String attractionId;
  final String attractionName;
  final int visitors;

  int totalCapacity = 0;
  int slotCount = 0;
}

class _AttractionDistribution {
  const _AttractionDistribution({
    required this.attractionId,
    required this.attractionName,
    required this.visitors,
    required this.percentage,
  });

  final String attractionId;
  final String attractionName;
  final int visitors;
  final double percentage;
}

class _AttractionUsage {
  const _AttractionUsage({
    required this.attractionId,
    required this.attractionName,
    required this.visitors,
    required this.totalCapacity,
    required this.slotCount,
    required this.utilisation,
  });

  final String attractionId;
  final String attractionName;
  final int visitors;
  final int totalCapacity;
  final int slotCount;
  final double utilisation;
}

class _SustainabilityReportData {
  const _SustainabilityReportData({
    required this.totalVisitors,
    required this.attractionCount,
    required this.mostVisitedAttractionName,
    required this.mostVisitedVisitors,
    required this.averageVisitorsPerAttraction,
    required this.averageUtilisation,
    required this.checkInRecordCount,
    required this.scheduledSlotCount,
    required this.distribution,
    required this.attractionUsage,
    required this.startDate,
    required this.endDate,
  });

  factory _SustainabilityReportData.empty({
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    return _SustainabilityReportData(
      totalVisitors: 0,
      attractionCount: 0,
      mostVisitedAttractionName: '-',
      mostVisitedVisitors: 0,
      averageVisitorsPerAttraction: 0,
      averageUtilisation: 0,
      checkInRecordCount: 0,
      scheduledSlotCount: 0,
      distribution: const [],
      attractionUsage: const [],
      startDate: startDate,
      endDate: endDate,
    );
  }

  final int totalVisitors;
  final int attractionCount;

  final String mostVisitedAttractionName;
  final int mostVisitedVisitors;

  final double averageVisitorsPerAttraction;
  final double averageUtilisation;

  final int checkInRecordCount;
  final int scheduledSlotCount;

  final List<_AttractionDistribution>
  distribution;

  final List<_AttractionUsage>
  attractionUsage;

  final DateTime? startDate;
  final DateTime? endDate;
}
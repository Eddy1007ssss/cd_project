import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'admin_performance_report_page.dart';
import 'admin_sustainability_report_page.dart';

class AdminGenerateReportPage extends StatefulWidget {
  const AdminGenerateReportPage({super.key});

  static const routeName = '/admin-generate-report';

  @override
  State<AdminGenerateReportPage> createState() =>
      _AdminGenerateReportPageState();
}

class _AdminGenerateReportPageState extends State<AdminGenerateReportPage> {
  DateTime? _sustainabilityStartDate;
  DateTime? _sustainabilityEndDate;

  DateTime? _performanceStartDate;
  DateTime? _performanceEndDate;

  Future<DateTime?> _pickDate({
    required DateTime? initialDate,
    required DateTime? firstDate,
    required DateTime? lastDate,
  }) {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? now,
    );
  }

  Future<void> _pickSustainabilityStartDate() async {
    final date = await _pickDate(
      initialDate: _sustainabilityStartDate,
      firstDate: null,
      lastDate: _sustainabilityEndDate ?? DateTime.now(),
    );

    if (date == null || !mounted) return;

    setState(() {
      _sustainabilityStartDate = date;

      if (_sustainabilityEndDate != null &&
          _sustainabilityEndDate!.isBefore(date)) {
        _sustainabilityEndDate = null;
      }
    });
  }

  Future<void> _pickSustainabilityEndDate() async {
    final date = await _pickDate(
      initialDate: _sustainabilityEndDate ?? _sustainabilityStartDate,
      firstDate: _sustainabilityStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    setState(() {
      _sustainabilityEndDate = date;
    });
  }

  Future<void> _pickPerformanceStartDate() async {
    final date = await _pickDate(
      initialDate: _performanceStartDate,
      firstDate: null,
      lastDate: _performanceEndDate ?? DateTime.now(),
    );

    if (date == null || !mounted) return;

    setState(() {
      _performanceStartDate = date;

      if (_performanceEndDate != null &&
          _performanceEndDate!.isBefore(date)) {
        _performanceEndDate = null;
      }
    });
  }

  Future<void> _pickPerformanceEndDate() async {
    final date = await _pickDate(
      initialDate: _performanceEndDate ?? _performanceStartDate,
      firstDate: _performanceStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    setState(() {
      _performanceEndDate = date;
    });
  }

  void _generateSustainabilityReport() {
    if (_sustainabilityStartDate == null ||
        _sustainabilityEndDate == null) {
      _showDateMessage();
      return;
    }

    Navigator.pushNamed(
      context,
      AdminSustainabilityReportPage.routeName,
      arguments: {
        'startDate': _sustainabilityStartDate,
        'endDate': _sustainabilityEndDate,
      },
    );
  }

  void _generatePerformanceReport() {
    if (_performanceStartDate == null ||
        _performanceEndDate == null) {
      _showDateMessage();
      return;
    }

    Navigator.pushNamed(
      context,
      AdminPerformanceReportPage.routeName,
      arguments: {
        'startDate': _performanceStartDate,
        'endDate': _performanceEndDate,
      },
    );
  }

  void _showDateMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a start date and end date.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Generate Report',
      role: 'TOURFLOW · ADMINISTRATOR',
      navigationRole: TourFlowNavigationRole.administrator,
      selectedNavigationIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Reports',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Choose a report and reporting period',
            style: TextStyle(
              color: TourFlowColors.muted,
              fontSize: 9.5,
            ),
          ),

          const SizedBox(height: 17),

          _ReportCard(
            accentColor: const Color(0xFF2B9465),
            accentBackground: const Color(0xFFEAF7F0),
            icon: Icons.eco_rounded,
            title: 'Sustainability Report',
            subtitle:
            'Visitor distribution and attraction usage for better crowd management',
            metrics: const [
              _MetricItem(
                icon: Icons.groups_outlined,
                label: 'Total Visitors',
              ),
              _MetricItem(
                icon: Icons.location_on_outlined,
                label: 'Attractions Visited',
              ),
              _MetricItem(
                icon: Icons.emoji_events_outlined,
                label: 'Most Visited Attraction',
              ),
              _MetricItem(
                icon: Icons.balance_outlined,
                label: 'Average Visitors / Attraction',
              ),
            ],
            startDate: _sustainabilityStartDate,
            endDate: _sustainabilityEndDate,
            onStartDate: _pickSustainabilityStartDate,
            onEndDate: _pickSustainabilityEndDate,
            onGenerate: _generateSustainabilityReport,
          ),

          const SizedBox(height: 16),

          _ReportCard(
            accentColor: const Color(0xFF7154C4),
            accentBackground: const Color(0xFFF1EDFA),
            icon: Icons.analytics_outlined,
            title: 'Performance Report',
            subtitle:
            'Visitor satisfaction, rating and booking value analytics',
            metrics: const [
              _MetricItem(
                icon: Icons.sentiment_satisfied_alt_outlined,
                label: 'Visitor Satisfaction',
              ),
              _MetricItem(
                icon: Icons.star_outline_rounded,
                label: 'Average Rating',
              ),
              _MetricItem(
                icon: Icons.payments_outlined,
                label: 'Estimated Value / Visitor',
              ),
              _MetricItem(
                icon: Icons.trending_up_rounded,
                label: 'Booking Value Growth',
              ),
            ],
            startDate: _performanceStartDate,
            endDate: _performanceEndDate,
            onStartDate: _pickPerformanceStartDate,
            onEndDate: _pickPerformanceEndDate,
            onGenerate: _generatePerformanceReport,
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFE4E7EB),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF7A8492),
                  size: 17,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reports use system data within the selected reporting period and can be exported as PDF after generation.',
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

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.accentColor,
    required this.accentBackground,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.startDate,
    required this.endDate,
    required this.onStartDate,
    required this.onEndDate,
    required this.onGenerate,
  });

  final Color accentColor;
  final Color accentBackground;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_MetricItem> metrics;

  final DateTime? startDate;
  final DateTime? endDate;

  final VoidCallback onStartDate;
  final VoidCallback onEndDate;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              color: accentColor,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              15,
              15,
              15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentBackground,
                        borderRadius:
                        BorderRadius.circular(11),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color:
                              TourFlowColors.heading,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color:
                              TourFlowColors.muted,
                              fontSize: 8.7,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        item: metrics[0],
                        accentColor: accentColor,
                        accentBackground:
                        accentBackground,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricTile(
                        item: metrics[1],
                        accentColor: accentColor,
                        accentBackground:
                        accentBackground,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        item: metrics[2],
                        accentColor: accentColor,
                        accentBackground:
                        accentBackground,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricTile(
                        item: metrics[3],
                        accentColor: accentColor,
                        accentBackground:
                        accentBackground,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                const Text(
                  'Report Period',
                  style: TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Start Date',
                        date: startDate,
                        onTap: onStartDate,
                        accentColor: accentColor,
                      ),
                    ),

                    const Padding(
                      padding:
                      EdgeInsets.symmetric(
                        horizontal: 7,
                      ),
                      child: Text(
                        '—',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                        ),
                      ),
                    ),

                    Expanded(
                      child: _DateField(
                        label: 'End Date',
                        date: endDate,
                        onTap: onEndDate,
                        accentColor: accentColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      accentBackground,
                      foregroundColor: accentColor,
                      elevation: 0,
                      side: BorderSide(
                        color: accentColor.withValues(
                          alpha: 0.25,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 17,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Generate Report',
                          style: TextStyle(
                            fontSize: 10.8,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.accentColor,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final Color accentColor;

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFBFC),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFFE1E5EA),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 15,
                color: date == null
                    ? const Color(0xFF98A2B3)
                    : accentColor,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  date == null
                      ? label
                      : _formatDate(date!),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: date == null
                        ? const Color(0xFF98A2B3)
                        : TourFlowColors.body,
                    fontSize: 8.8,
                    fontWeight: date == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.item,
    required this.accentColor,
    required this.accentBackground,
  });

  final _MetricItem item;
  final Color accentColor;
  final Color accentBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE6E9ED),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: accentBackground,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              item.icon,
              color: accentColor,
              size: 14,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TourFlowColors.body,
                fontSize: 8.2,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
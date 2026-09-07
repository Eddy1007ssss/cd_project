import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'admin_performance_report_page.dart';
import 'admin_sustainability_report_page.dart';

class AdminGenerateReportPage extends StatelessWidget {
  const AdminGenerateReportPage({super.key});

  static const routeName = '/admin-generate-report';

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
            'Choose a report to view the latest analytics',
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
            subtitle: 'Environmental performance and resource savings',
            metrics: const [
              _MetricItem(icon: Icons.cloud_outlined, label: 'Carbon Offset'),
              _MetricItem(icon: Icons.water_drop_outlined, label: 'Water Saved'),
              _MetricItem(icon: Icons.bolt_outlined, label: 'Energy Saved'),
              _MetricItem(icon: Icons.recycling_rounded, label: 'Recycling Rate'),
            ],
            onGenerate: () {
              Navigator.pushNamed(
                context,
                AdminSustainabilityReportPage.routeName,
              );
            },
          ),

          const SizedBox(height: 16),

          _ReportCard(
            accentColor: const Color(0xFF7154C4),
            accentBackground: const Color(0xFFF1EDFA),
            icon: Icons.analytics_outlined,
            title: 'Performance Report',
            subtitle: 'Visitor satisfaction, rating and revenue analytics',
            metrics: const [
              _MetricItem(
                icon: Icons.sentiment_satisfied_alt_outlined,
                label: 'Visitor Satisfaction',
              ),
              _MetricItem(icon: Icons.star_outline_rounded, label: 'Attraction Rating'),
              _MetricItem(icon: Icons.payments_outlined, label: 'Revenue / Visitor'),
              _MetricItem(icon: Icons.trending_up_rounded, label: 'Revenue Growth'),
            ],
            onGenerate: () {
              Navigator.pushNamed(
                context,
                AdminPerformanceReportPage.routeName,
              );
            },
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFE4E7EB)),
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
                    'Reports use the latest system data and can be exported as PDF after generation.',
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
    required this.onGenerate,
  });

  final Color accentColor;
  final Color accentBackground;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_MetricItem> metrics;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E5EA)),
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
            padding: const EdgeInsets.fromLTRB(18, 15, 15, 15),
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
                        borderRadius: BorderRadius.circular(11),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: TourFlowColors.heading,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: TourFlowColors.muted,
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
                        accentBackground: accentBackground,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricTile(
                        item: metrics[1],
                        accentColor: accentColor,
                        accentBackground: accentBackground,
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
                        accentBackground: accentBackground,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MetricTile(
                        item: metrics[3],
                        accentColor: accentColor,
                        accentBackground: accentBackground,
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
                      backgroundColor: accentBackground,
                      foregroundColor: accentColor,
                      elevation: 0,
                      side: BorderSide(
                        color: accentColor.withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE6E9ED)),
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
import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class LiveCrowdPage extends StatelessWidget {
  const LiveCrowdPage({super.key});

  static const String routeName = '/live-crowd';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Live Crowd',
      role: 'TOURFLOW · OPERATOR',
      isStaff: true,

      // Live Crowd 是从 Operator Dashboard 进入，
      // 所以暂时保持 Dashboard selected。
      selectedNavigationIndex: 0,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =====================================================
          // CROWD STATUS
          // =====================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Moderate crowd · 68 / 120',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Updated live from tourist check-ins and staff scans.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC44D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '57% OCCUPANCY',
                    style: TextStyle(
                      color: Color(0xFF5C4200),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // =====================================================
          // LIVE METRICS
          // =====================================================
          const Row(
            children: [
              Expanded(
                child: _CrowdMetricCard(
                  value: '+12',
                  label: 'Last 15 min',
                ),
              ),

              SizedBox(width: 8),

              Expanded(
                child: _CrowdMetricCard(
                  value: '23',
                  label: 'Expected',
                ),
              ),

              SizedBox(width: 8),

              Expanded(
                child: _CrowdMetricCard(
                  value: '18m',
                  label: 'Avg visit',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =====================================================
          // VISITOR CHART
          // =====================================================
          Container(
            padding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE4E7EC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visitors by 15-minute interval',
                  style: TextStyle(
                    color: Color(0xFF131B2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 22),

                const SizedBox(
                  height: 125,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _VisitorBar(
                          height: 34,
                          label: '3:00',
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: _VisitorBar(
                          height: 42,
                          label: '3:15',
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: _VisitorBar(
                          height: 50,
                          label: '3:30',
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: _VisitorBar(
                          height: 59,
                          label: '3:45',
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: _VisitorBar(
                          height: 65,
                          label: '4:00',
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: _VisitorBar(
                          height: 78,
                          label: '4:15',
                          highlighted: true,
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: _VisitorBar(
                          height: 70,
                          label: '4:30',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // =====================================================
          // ALERT THRESHOLD
          // =====================================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFF59E0B),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                      size: 19,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Approaching alert threshold',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 7),

                Text(
                  'Notify staff when occupancy reaches 80% or the arrival rate increases sharply.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =====================================================
          // CAPACITY INFORMATION
          // =====================================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE4E7EC),
              ),
            ),
            child: const Column(
              children: [
                _InformationRow(
                  label: 'Current Visitors',
                  value: '68',
                ),

                Divider(
                  height: 22,
                  color: Color(0xFFE4E7EC),
                ),

                _InformationRow(
                  label: 'Maximum Capacity',
                  value: '120',
                ),

                Divider(
                  height: 22,
                  color: Color(0xFFE4E7EC),
                ),

                _InformationRow(
                  label: 'Available Capacity',
                  value: '52',
                ),

                Divider(
                  height: 22,
                  color: Color(0xFFE4E7EC),
                ),

                _InformationRow(
                  label: 'Crowd Level',
                  value: 'MODERATE',
                  valueColor: Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// METRIC CARD
// ===========================================================

class _CrowdMetricCard extends StatelessWidget {
  const _CrowdMetricCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF79571E),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// VISITOR BAR
// ===========================================================

class _VisitorBar extends StatelessWidget {
  const _VisitorBar({
    required this.height,
    required this.label,
    this.highlighted = false,
  });

  final double height;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFFFCB7A)
                : const Color(0xFFFFF1DD),
            borderRadius: BorderRadius.circular(7),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// INFORMATION ROW
// ===========================================================

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
            ),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF131B2E),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
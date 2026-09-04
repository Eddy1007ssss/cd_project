import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class RevenuePromotionPage extends StatefulWidget {
  const RevenuePromotionPage({super.key});

  static const routeName = '/revenue-promotion';

  @override
  State<RevenuePromotionPage> createState() => _RevenuePromotionPageState();
}

class _RevenuePromotionPageState extends State<RevenuePromotionPage> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Revenue & Promotion',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,

      // Keep Dashboard/Home selected
      selectedNavigationIndex: 0,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // SUMMARY
          // =========================
          const Row(
            children: [
              Expanded(
                child: _RevenueSummaryCard(
                  value: 'RM8.4k',
                  label: 'This month',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _RevenueSummaryCard(value: '+12%', label: 'Growth'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _RevenueSummaryCard(value: '1,684', label: 'Visitors'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =========================
          // SELECT DATE
          // =========================
          OutlinedButton(
            onPressed: _selectDate,
            style: OutlinedButton.styleFrom(
              foregroundColor: TourFlowColors.heading,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: const BorderSide(color: Color(0xFFE2E6EC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              _selectedDate == null
                  ? 'Select a Date'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 12),

          // =========================
          // REVENUE CHART
          // =========================
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenue and visitors by day',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _Bar(height: 44),
                      _Bar(height: 52),
                      _Bar(height: 66),
                      _Bar(height: 64),
                      _Bar(height: 78),
                      _Bar(height: 98, highlighted: true),
                      _Bar(height: 83),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // =========================
          // PROMOTION OPPORTUNITY
          // =========================
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Promotion opportunity',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F9EC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 7, color: Color(0xFF22C875)),
                          SizedBox(width: 5),
                          Text(
                            'Off-peak',
                            style: TextStyle(
                              color: Color(0xFF20A75A),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  'Tuesday 3:00 – 5:00 PM has low attendance and available capacity.',
                  style: TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Suggested offer: 15% off off-peak slots',
                  style: TextStyle(color: TourFlowColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // =========================
          // CREATE PROMOTION
          // =========================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/promotion-suggestion');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC80),
                foregroundColor: const Color(0xFF7A5200),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'View Suggested Promotion',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: TourFlowColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, this.highlighted = false});

  final double height;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFC46B) : const Color(0xFFFFF2DF),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

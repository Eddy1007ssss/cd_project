import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class PromotionSuggestionPage extends StatefulWidget {
  const PromotionSuggestionPage({super.key});

  static const routeName = '/promotion-suggestion';

  @override
  State<PromotionSuggestionPage> createState() =>
      _PromotionSuggestionPageState();
}

class _PromotionSuggestionPageState extends State<PromotionSuggestionPage> {
  final _repository = EngagementRepository();

  late Future<List<VisitorTrendEntry>> _visitorTrends;
  String? _selectedAttractionKey;

  @override
  void initState() {
    super.initState();
    _visitorTrends = _repository.fetchOperatorVisitorTrends();
  }

  String _attractionKey(String name) => name.trim().toLowerCase();

  List<_AttractionOption> _buildAttractions(List<VisitorTrendEntry> entries) {
    final attractions = <String, _AttractionOption>{};

    for (final entry in entries) {
      final name = entry.attractionName.trim();
      if (name.isEmpty) continue;

      final key = _attractionKey(name);

      attractions.putIfAbsent(
        key,
        () => _AttractionOption(key: key, name: name),
      );
    }

    final result = attractions.values.toList();
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return result;
  }

  _PromotionSuggestionData? _buildSuggestion(
    List<VisitorTrendEntry> entries,
    String attractionKey,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 29));
    final endDate = today.add(const Duration(days: 1));

    final recentEntries = entries.where((entry) {
      return _attractionKey(entry.attractionName) == attractionKey &&
          !entry.checkedInAt.isBefore(startDate) &&
          entry.checkedInAt.isBefore(endDate);
    }).toList();

    if (recentEntries.isEmpty) return null;

    final dailyPeriodTotals = <String, _DailyPeriodTotal>{};

    for (final entry in recentEntries) {
      final date = DateTime(
        entry.checkedInAt.year,
        entry.checkedInAt.month,
        entry.checkedInAt.day,
      );

      final startHour = (entry.checkedInAt.hour ~/ 2) * 2;

      final key =
          '${date.year}-${date.month}-${date.day}-${date.weekday}-$startHour';

      final existing = dailyPeriodTotals[key];

      if (existing == null) {
        dailyPeriodTotals[key] = _DailyPeriodTotal(
          weekday: date.weekday,
          startHour: startHour,
          visitors: entry.visitorCount,
        );
      } else {
        dailyPeriodTotals[key] = _DailyPeriodTotal(
          weekday: existing.weekday,
          startHour: existing.startHour,
          visitors: existing.visitors + entry.visitorCount,
        );
      }
    }

    if (dailyPeriodTotals.isEmpty) return null;

    final groupedPeriods = <String, List<int>>{};

    for (final total in dailyPeriodTotals.values) {
      final key = '${total.weekday}-${total.startHour}';

      groupedPeriods.putIfAbsent(key, () => []);
      groupedPeriods[key]!.add(total.visitors);
    }

    final buckets = <_PeriodBucket>[];

    groupedPeriods.forEach((key, visitorTotals) {
      final parts = key.split('-');
      final weekday = int.parse(parts[0]);
      final startHour = int.parse(parts[1]);

      final average =
          visitorTotals.fold<int>(0, (sum, value) => sum + value) /
          visitorTotals.length;

      buckets.add(
        _PeriodBucket(
          weekday: weekday,
          startHour: startHour,
          averageVisitors: average,
          observations: visitorTotals.length,
        ),
      );
    });

    if (buckets.isEmpty) return null;

    final repeatedBuckets = buckets
        .where((bucket) => bucket.observations >= 2)
        .toList();

    final candidates = repeatedBuckets.isNotEmpty ? repeatedBuckets : buckets;

    candidates.sort((a, b) => a.averageVisitors.compareTo(b.averageVisitors));

    final lowest = candidates.first;

    final overallAverage =
        dailyPeriodTotals.values.fold<int>(
          0,
          (sum, item) => sum + item.visitors,
        ) /
        dailyPeriodTotals.length;

    var discount = 10;

    if (overallAverage > 0) {
      final ratio = lowest.averageVisitors / overallAverage;

      if (ratio <= 0.4) {
        discount = 20;
      } else if (ratio <= 0.7) {
        discount = 15;
      }
    }

    return _PromotionSuggestionData(
      attractionName: recentEntries.first.attractionName.trim(),
      weekday: lowest.weekday,
      startHour: lowest.startHour,
      averageVisitors: lowest.averageVisitors,
      observations: lowest.observations,
      overallAverage: overallAverage,
      discount: discount,
    );
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _formatHour(int hour) {
    final safeHour = hour % 24;

    if (safeHour == 0) return '12:00 AM';
    if (safeHour < 12) return '$safeHour:00 AM';
    if (safeHour == 12) return '12:00 PM';

    return '${safeHour - 12}:00 PM';
  }

  String _suggestedTime(_PromotionSuggestionData suggestion) {
    return '${_weekdayName(suggestion.weekday)}, '
        '${_formatHour(suggestion.startHour)} – '
        '${_formatHour(suggestion.startHour + 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Suggested Promotion',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 0,
      child: FutureBuilder<List<VisitorTrendEntry>>(
        future: _visitorTrends,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 300,
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
                    'Unable to load visitor trend data.',
                    textAlign: TextAlign.center,
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
                        _visitorTrends = _repository
                            .fetchOperatorVisitorTrends();
                      });
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final entries = snapshot.data ?? const <VisitorTrendEntry>[];

          final attractions = _buildAttractions(entries);

          if (attractions.isEmpty) {
            return const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: TourFlowColors.muted,
                        size: 30,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No visitor trend data available.',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Promotion suggestions will appear after visitor check-in data is recorded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final selectedAttractionKey =
              _selectedAttractionKey ?? attractions.first.key;

          final suggestion = _buildSuggestion(entries, selectedAttractionKey);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE1B2)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFD68A00),
                      size: 22,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Off-Peak Promotion',
                            style: TextStyle(
                              color: Color(0xFF805300),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Based on visitor check-ins from the last 30 days',
                            style: TextStyle(
                              color: TourFlowColors.body,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Select Attraction',
                style: TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 7),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3E7EC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      color: Color(0xFF956000),
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAttractionKey,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: TourFlowColors.muted,
                          ),
                          items: attractions.map((attraction) {
                            return DropdownMenuItem<String>(
                              value: attraction.key,
                              child: Text(
                                attraction.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: TourFlowColors.heading,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedAttractionKey = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (suggestion == null)
                const ModuleCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.insights_outlined,
                            color: TourFlowColors.muted,
                            size: 30,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Not enough recent visitor data',
                            style: TextStyle(
                              color: TourFlowColors.heading,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'There are no recorded visitor check-ins for this attraction within the last 30 days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                _RecommendationCard(
                  time: _suggestedTime(suggestion),
                  discount: suggestion.discount,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.groups_outlined,
                        value: suggestion.averageVisitors.toStringAsFixed(1),
                        label: 'Avg. Visitors',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.calendar_month_outlined,
                        value: '${suggestion.observations}',
                        label: 'Observed Days',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _InfoCard(
                  icon: Icons.analytics_outlined,
                  title: 'Why this period?',
                  text:
                      'This was one of the lowest observed attendance periods for ${suggestion.attractionName} during the last 30 days, averaging ${suggestion.averageVisitors.toStringAsFixed(1)} visitors.',
                ),

                const SizedBox(height: 10),

                _InfoCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Expected Benefit',
                  text:
                      'Encourage more bookings during lower-attendance periods and improve visitor distribution across different times of the week.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.time, required this.discount});

  final String time;
  final int discount;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Promotion',
            style: TextStyle(
              color: TourFlowColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DC),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF956000),
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggested Time',
                      style: TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(height: 1, color: const Color(0xFFEDF0F3)),

          const SizedBox(height: 14),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF9EE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFF229A54),
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggested Offer',
                      style: TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$discount% Off Off-Peak Bookings',
                      style: const TextStyle(
                        color: Color(0xFF188847),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF9EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '-$discount%',
                  style: const TextStyle(
                    color: Color(0xFF188847),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8ED)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF956000), size: 17),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 8,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF956000), size: 18),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 10,
                    height: 1.45,
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

class _AttractionOption {
  const _AttractionOption({required this.key, required this.name});

  final String key;
  final String name;
}

class _DailyPeriodTotal {
  const _DailyPeriodTotal({
    required this.weekday,
    required this.startHour,
    required this.visitors,
  });

  final int weekday;
  final int startHour;
  final int visitors;
}

class _PeriodBucket {
  const _PeriodBucket({
    required this.weekday,
    required this.startHour,
    required this.averageVisitors,
    required this.observations,
  });

  final int weekday;
  final int startHour;
  final double averageVisitors;
  final int observations;
}

class _PromotionSuggestionData {
  const _PromotionSuggestionData({
    required this.attractionName,
    required this.weekday,
    required this.startHour,
    required this.averageVisitors,
    required this.observations,
    required this.overallAverage,
    required this.discount,
  });

  final String attractionName;
  final int weekday;
  final int startHour;
  final double averageVisitors;
  final int observations;
  final double overallAverage;
  final int discount;
}

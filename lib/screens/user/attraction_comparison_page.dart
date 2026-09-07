import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import 'attraction_details_page.dart';

class AttractionComparisonPage extends StatelessWidget {
  const AttractionComparisonPage({super.key});

  static const routeName = '/attraction-comparison';

  static const double _labelWidth = 130;
  static const double _attractionWidth = 220;

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    final attractions = arguments is List
        ? arguments.whereType<Attraction>().take(3).toList()
        : <Attraction>[];

    // ============================================================
    // NOT ENOUGH ATTRACTIONS
    // ============================================================

    if (attractions.length < 2) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compare Attractions'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(height: 14),
                Text(
                  'Select two or three attractions from Discover to compare them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ============================================================
    // CALCULATE COMPARISON HIGHLIGHTS
    // ============================================================

    final cheapestPrice = attractions
        .map((item) => item.entrancePriceMyr)
        .reduce(
          (a, b) => a < b ? a : b,
    );

    final distances = attractions
        .where((item) => item.distanceKm != null)
        .map((item) => item.distanceKm!)
        .toList();

    final nearestDistance = distances.isEmpty
        ? null
        : distances.reduce(
          (a, b) => a < b ? a : b,
    );

    final mostAvailableSlots = attractions
        .map((item) => item.availableSlots.length)
        .reduce(
          (a, b) => a > b ? a : b,
    );

    final totalWidth =
        _labelWidth + (_attractionWidth * attractions.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Attractions'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ======================================================
          // INFORMATION CARD
          // ======================================================

          Card(
            color: const Color(0xFFF2F3FF),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.compare_arrows,
                    color: Color(0xFF79571E),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Comparing ${attractions.length} attractions. '
                          'Swipe horizontally to view all information.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // HORIZONTAL COMPARISON TABLE
          // ======================================================

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                columnWidths: {
                  0: const FixedColumnWidth(_labelWidth),
                  for (int i = 0; i < attractions.length; i++)
                    i + 1: const FixedColumnWidth(_attractionWidth),
                },
                defaultVerticalAlignment:
                TableCellVerticalAlignment.middle,
                children: [
                  // ==================================================
                  // ATTRACTION NAME
                  // ==================================================

                  _buildRow(
                    label: 'Attraction',
                    values: attractions
                        .map((item) => item.name)
                        .toList(),
                    isHeader: true,
                  ),

                  // ==================================================
                  // CATEGORY
                  // ==================================================

                  _buildRow(
                    label: 'Category',
                    values: attractions
                        .map((item) => item.category)
                        .toList(),
                  ),

                  // ==================================================
                  // TYPE
                  // ==================================================

                  _buildRow(
                    label: 'Type',
                    values: attractions.map(
                          (item) {
                        if (item.attractionType.trim().isEmpty) {
                          return 'Not specified';
                        }

                        return _capitalize(
                          item.attractionType,
                        );
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // LOCATION
                  // ==================================================

                  _buildRow(
                    label: 'Location',
                    values: attractions
                        .map((item) => item.locationName)
                        .toList(),
                  ),

                  // ==================================================
                  // PRICE
                  // ==================================================

                  _buildRow(
                    label: 'Price',
                    values: attractions.map(
                          (item) {
                        final price = item.entrancePriceMyr;

                        final text = price == 0
                            ? 'Free'
                            : 'RM ${price.toStringAsFixed(2)}';

                        if (price == cheapestPrice) {
                          return '$text\n✓ Lowest price';
                        }

                        return text;
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // DISTANCE
                  // ==================================================

                  _buildRow(
                    label: 'Distance',
                    values: attractions.map(
                          (item) {
                        final distance = item.distanceKm;

                        if (distance == null) {
                          return 'Unavailable';
                        }

                        final text =
                            '${distance.toStringAsFixed(1)} km';

                        if (nearestDistance != null &&
                            distance == nearestDistance) {
                          return '$text\n✓ Nearest';
                        }

                        return text;
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // CROWD
                  // ==================================================

                  _buildRow(
                    label: 'Crowd',
                    values: attractions.map(
                          (item) {
                        return '${item.estimatedCrowdLevel}\nestimate';
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // AVAILABLE SLOTS
                  // ==================================================

                  _buildRow(
                    label: 'Available Slots',
                    values: attractions.map(
                          (item) {
                        final count =
                            item.availableSlots.length;

                        if (count == 0) {
                          return '0\nNo available slots';
                        }

                        if (count == mostAvailableSlots) {
                          return '$count\n✓ Most availability';
                        }

                        return '$count';
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // NEXT SLOT
                  // ==================================================

                  _buildRow(
                    label: 'Next Slot',
                    values: attractions.map(
                          (item) {
                        final slot =
                            item.nextAvailableSlot;

                        if (slot == null) {
                          return 'No available slot';
                        }

                        return '${_date(slot.startsAt)}\n'
                            '${_time(slot.startsAt)} – '
                            '${_time(slot.endsAt)}';
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // OPEN NOW
                  // ==================================================

                  _buildRow(
                    label: 'Open Now',
                    values: attractions.map(
                          (item) {
                        if (item.operatingHours.isEmpty) {
                          return 'Hours unavailable';
                        }

                        return item.isOpenAt(
                          DateTime.now(),
                        )
                            ? '✓ Open now'
                            : 'Closed now';
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // ACCESSIBILITY
                  // ==================================================

                  _buildRow(
                    label: 'Accessibility',
                    values: attractions.map(
                          (item) {
                        return item.isAccessible
                            ? '✓ Accessible'
                            : 'Not specified';
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // CAPACITY
                  // ==================================================

                  _buildRow(
                    label: 'Capacity',
                    values: attractions.map(
                          (item) {
                        return '${item.maximumCapacity} visitors';
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // FACILITIES
                  // ==================================================

                  _buildRow(
                    label: 'Facilities',
                    values: attractions.map(
                          (item) {
                        if (item.facilities.isEmpty) {
                          return 'None listed';
                        }

                        return item.facilities
                            .map((facility) => '• $facility')
                            .join('\n');
                      },
                    ).toList(),
                  ),

                  // ==================================================
                  // ACTION
                  // ==================================================

                  TableRow(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    children: [
                      const _LabelCell(
                        text: 'Action',
                      ),

                      ...attractions.map(
                            (attraction) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AttractionDetailsPage.routeName,
                                  arguments: attraction.id,
                                );
                              },
                              icon: const Icon(
                                Icons.info_outline,
                                size: 18,
                              ),
                              label: const Text(
                                'View Details',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF79571E),
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // COMPARISON HELP
          // ======================================================

          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF79571E),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Compare price, distance, crowd level, '
                          'available slots, accessibility and facilities '
                          'before selecting an attraction.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CREATE NORMAL TABLE ROW
  // ============================================================

  TableRow _buildRow({
    required String label,
    required List<String> values,
    bool isHeader = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader
            ? const Color(0xFFFFF5E6)
            : Colors.white,
      ),
      children: [
        _LabelCell(
          text: label,
          isHeader: isHeader,
        ),

        ...values.map(
              (value) => _ValueCell(
            text: value,
            isHeader: isHeader,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// LABEL CELL
// ================================================================

class _LabelCell extends StatelessWidget {
  const _LabelCell({
    required this.text,
    this.isHeader = false,
  });

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 54,
      ),
      padding: const EdgeInsets.all(12),
      color: isHeader
          ? const Color(0xFFFFE6BF)
          : const Color(0xFFF7F7F7),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 13 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ================================================================
// VALUE CELL
// ================================================================

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.text,
    this.isHeader = false,
  });

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 54,
      ),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 14 : 12,
          fontWeight:
          isHeader ? FontWeight.w800 : FontWeight.w600,
          height: 1.4,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// ================================================================
// HELPERS
// ================================================================

String _capitalize(String value) {
  final cleaned = value.trim();

  if (cleaned.isEmpty) {
    return cleaned;
  }

  return '${cleaned[0].toUpperCase()}'
      '${cleaned.substring(1).toLowerCase()}';
}

String _date(DateTime value) {
  return '${value.day}/${value.month}/${value.year}';
}

String _time(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
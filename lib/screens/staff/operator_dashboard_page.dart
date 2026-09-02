import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'attraction_details_page.dart';
import 'slot_manager_page.dart';

class OperatorDashboardPage extends StatelessWidget {
  const OperatorDashboardPage({super.key});

  static const routeName = '/operator-dashboard';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Operator Dashboard',
      role: 'TOURFLOW · OPERATOR',
      showBackButton: false,
      isStaff: true,
      selectedNavigationIndex: 0,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleCard(
            color: TourFlowColors.lavender,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, Alex',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Manage attractions, visitor capacity and daily operations.',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: TourFlowColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: TourFlowColors.primaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Register New Attraction',
            icon: Icons.add_location_alt_outlined,
            onPressed: () {
              Navigator.pushNamed(
                context,
                AttractionDetailsPage.routeName,
              );
            },
          ),

          const SizedBox(height: 16),

          // =========================
          // ROW 1
          // Revenue + Visitors
          // =========================
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/revenue-promotion',
                    );
                  },
                  child: const MetricCard(
                    label: 'Total Revenue',
                    value: 'RM 42,850',
                    icon: Icons.payments_outlined,
                    note: '+12% this month',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/visitor-statistics',
                    );
                  },
                  child: const MetricCard(
                    label: 'Total Visitors',
                    value: '1,248',
                    icon: Icons.groups_outlined,
                    note: '+8% this month',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =========================
          // ROW 2
          // Average Rating + Live Crowd
          // =========================
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/operator-feedback',
                    );
                  },
                  child: const MetricCard(
                    label: 'Average Rating',
                    value: '4.9 / 5.0',
                    icon: Icons.star_outline_rounded,
                    note: '+0.2 this month',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/live-crowd',
                    );
                  },
                  child: const MetricCard(
                    label: 'Live Crowd',
                    value: '68 / 120',
                    icon: Icons.groups_outlined,
                    note: 'MODERATE · 57%',
                  ),
                ),
              ),
            ],
          ),

          // =========================
          // VIEW REPORT BUTTON
          // =========================
          const SizedBox(height: 16),

          PrimaryButton(
            label: 'View Report',
            icon: Icons.assignment_outlined,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/operator-report-queue',
              );
            },
          ),

          const SizedBox(height: 22),

          // =========================
          // YOUR ATTRACTIONS
          // =========================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Your Attractions'),
              TextButton(
                onPressed: () {},
                child: const Text('View all'),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Wrap(
            spacing: 8,
            children: [
              StatusChip(
                label: 'All (12)',
                color: TourFlowColors.primaryText,
              ),
              StatusChip(
                label: 'Draft (2)',
                color: TourFlowColors.muted,
              ),
              StatusChip(
                label: 'Pending (3)',
                color: TourFlowColors.warning,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _AttractionSummaryCard(
            name: 'Old Town Square',
            location: 'Kuala Lumpur City Centre',
            visitors: '642 visitors today',
            rating: '4.9',
            status: 'ACTIVE',
            statusColor: TourFlowColors.success,
            icon: Icons.account_balance_rounded,
            onTap: () {
              Navigator.pushNamed(
                context,
                AttractionDetailsPage.routeName,
              );
            },
          ),

          const SizedBox(height: 12),

          _AttractionSummaryCard(
            name: 'Heritage Walking Tour',
            location: 'Merdeka Square',
            visitors: '124 visitors today',
            rating: '4.8',
            status: 'PENDING',
            statusColor: TourFlowColors.warning,
            icon: Icons.directions_walk_rounded,
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _AttractionSummaryCard(
            name: 'Lumina Botanical Gardens',
            location: 'Perdana Botanical Gardens',
            visitors: 'Not yet published',
            rating: '—',
            status: 'DRAFT',
            statusColor: TourFlowColors.muted,
            icon: Icons.local_florist_rounded,
            onTap: () {},
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlineActionButton(
              label: 'Open Slot Manager',
              icon: Icons.schedule_rounded,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  SlotManagerPage.routeName,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttractionSummaryCard extends StatelessWidget {
  const _AttractionSummaryCard({
    required this.name,
    required this.location,
    required this.visitors,
    required this.rating,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String location;
  final String visitors;
  final String rating;
  final String status;
  final Color statusColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: TourFlowColors.lavenderStrong,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: TourFlowColors.primaryText,
                  size: 32,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: TourFlowColors.heading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: status,
                          color: statusColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      location,
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visitors,
                            style: const TextStyle(
                              color: TourFlowColors.body,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: TourFlowColors.warning,
                          size: 15,
                        ),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: TourFlowColors.heading,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
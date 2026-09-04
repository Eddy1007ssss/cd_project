import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import '../../widgets/navigation/navigation_routes.dart';

class SlotManagerPage extends StatefulWidget {
  const SlotManagerPage({super.key});

  static const routeName = TourFlowRoutes.slotManager;

  @override
  State<SlotManagerPage> createState() => _SlotManagerPageState();
}

class _SlotManagerPageState extends State<SlotManagerPage> {
  bool _showCreateForm = true;

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Slot Manager',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      pageLevel: TourFlowPageLevel.topLevel,
      selectedNavigationIndex: 2,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Manage Visit Slots',
            subtitle:
                'Create time slots, control capacity and block maintenance dates.',
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Active Slots',
                  value: '124',
                  icon: Icons.event_available_outlined,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'Maintenance',
                  value: '03',
                  icon: Icons.build_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const MetricCard(
            label: 'Critical Capacity Alerts',
            value: '01',
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _showCreateForm ? 'Hide New Slot Form' : 'Create New Slot',
            icon: _showCreateForm
                ? Icons.keyboard_arrow_up_rounded
                : Icons.add_rounded,
            onPressed: () {
              setState(() => _showCreateForm = !_showCreateForm);
            },
          ),
          if (_showCreateForm) ...[
            const SizedBox(height: 14),
            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    'Create New Slot',
                    subtitle: 'Old Town Square · Standard Visit',
                  ),
                  const SizedBox(height: 16),
                  const StaticField(
                    label: 'Tour Type',
                    value: 'Standard Self-Guided Visit',
                    icon: Icons.tour_outlined,
                    trailing: Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  const SizedBox(height: 13),
                  const StaticField(
                    label: 'Date',
                    value: '12 September 2026',
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 13),
                  const Row(
                    children: [
                      Expanded(
                        child: StaticField(
                          label: 'Start Time',
                          value: '10:00',
                          icon: Icons.schedule_outlined,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: StaticField(
                          label: 'End Time',
                          value: '11:30',
                          icon: Icons.schedule_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  const StaticField(
                    label: 'Maximum Visitor Capacity',
                    value: '30 visitors',
                    icon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Create Slot',
                    icon: Icons.add_task_rounded,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New Open slot created.')),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Active & Upcoming Slots'),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 17),
                label: const Text('Filter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _SlotCard(
            date: 'SEP\n12',
            time: '10:00 – 11:30',
            title: 'Standard Self-Guided Visit',
            capacity: '18 / 30 registered',
            status: 'OPEN',
            statusColor: TourFlowColors.success,
          ),
          const SizedBox(height: 11),
          const _SlotCard(
            date: 'SEP\n12',
            time: '12:00 – 13:30',
            title: 'Heritage Guided Tour',
            capacity: '30 / 30 registered',
            status: 'FULL',
            statusColor: TourFlowColors.warning,
          ),
          const SizedBox(height: 11),
          const _SlotCard(
            date: 'SEP\n13',
            time: '15:00 – 16:30',
            title: 'Standard Self-Guided Visit',
            capacity: '0 / 30 registered',
            status: 'CLOSED',
            statusColor: TourFlowColors.danger,
          ),
          const SizedBox(height: 11),
          const _SlotCard(
            date: 'AUG\n27',
            time: '09:00 – 10:30',
            title: 'Morning Heritage Visit',
            capacity: '24 / 30 registered',
            status: 'EXPIRED',
            statusColor: TourFlowColors.muted,
          ),
          const SizedBox(height: 22),
          const SectionTitle(
            'Maintenance Blocks',
            subtitle: 'Tourists cannot book slots during these periods.',
          ),
          const SizedBox(height: 10),
          const _MaintenanceCard(
            date: '24 Sep 08:00 – 25 Sep 18:00',
            reason: 'Landscape and facility maintenance',
          ),
          const SizedBox(height: 10),
          const _MaintenanceCard(
            date: '18 October 2026',
            reason: 'Private event setup',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlineActionButton(
              label: 'Block Another Date',
              icon: Icons.event_busy_outlined,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maintenance period form opened for demo.'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.date,
    required this.time,
    required this.title,
    required this.capacity,
    required this.status,
    required this.statusColor,
  });

  final String date;
  final String time;
  final String title;
  final String capacity;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TourFlowColors.lavenderStrong,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TourFlowColors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
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
                        title,
                        style: const TextStyle(
                          color: TourFlowColors.heading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StatusChip(label: status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 15,
                      color: TourFlowColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        capacity,
                        style: const TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Manage slot',
                      onSelected: (action) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$action selected for $time.'),
                            ),
                          ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'Edit', child: Text('Edit slot')),
                        PopupMenuItem(
                          value: 'Close',
                          child: Text('Close slot'),
                        ),
                        PopupMenuItem(
                          value: 'Cancel',
                          child: Text('Cancel slot'),
                        ),
                      ],
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: TourFlowColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.date, required this.reason});

  final String date;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE8E7),
            foregroundColor: TourFlowColors.danger,
            child: Icon(Icons.build_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  reason,
                  style: const TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const StatusChip(label: 'BLOCKED', color: TourFlowColors.danger),
        ],
      ),
    );
  }
}

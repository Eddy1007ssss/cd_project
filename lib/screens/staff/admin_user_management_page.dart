import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'admin_attraction_review_page.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  static const routeName = '/admin-user-management';

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Admin',
      role: 'TOURFLOW · ADMINISTRATOR',
      showBackButton: false,
      isStaff: true,
      selectedNavigationIndex: 0,
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'User Management',
            subtitle:
                'Review operator applications and manage platform account access.',
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Pending Approval',
                  value: '14 Operators',
                  icon: Icons.hourglass_top_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'Active Platform Users',
                  value: '1,284',
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const MetricCard(
            label: 'Deactivated Accounts',
            value: '32',
            icon: Icons.person_off_outlined,
          ),
          const SizedBox(height: 20),
          ModuleCard(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                _TabButton(
                  label: 'Pending Operators',
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                _TabButton(
                  label: 'Active Users',
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                _TabButton(
                  label: 'Deactivated',
                  selected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Operator Verification Requests',
                style: TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 17),
                label: const Text('Filter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _OperatorRequestCard(
            initials: 'MS',
            name: 'Marco Santoro',
            business: 'Santoro Cultural Experiences',
            submitted: 'Submitted 2 hours ago',
            onReview: () {},
          ),
          const SizedBox(height: 12),
          _OperatorRequestCard(
            initials: 'AL',
            name: 'Alyssa Lim',
            business: 'KL Heritage Walks Sdn. Bhd.',
            submitted: 'Submitted yesterday',
            onReview: () {},
          ),
          const SizedBox(height: 12),
          _OperatorRequestCard(
            initials: 'RK',
            name: 'Raj Kumar',
            business: 'Eco Nature Adventures',
            submitted: 'Submitted 2 days ago',
            onReview: () {},
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Review Pending Attraction',
            icon: Icons.fact_check_outlined,
            onPressed: () {
              Navigator.pushNamed(
                context,
                AdminAttractionReviewPage.routeName,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? TourFlowColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? TourFlowColors.primaryText
                  : TourFlowColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OperatorRequestCard extends StatelessWidget {
  const _OperatorRequestCard({
    required this.initials,
    required this.name,
    required this.business,
    required this.submitted,
    required this.onReview,
  });

  final String initials;
  final String name;
  final String business;
  final String submitted;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: TourFlowColors.lavenderStrong,
                foregroundColor: TourFlowColors.primaryText,
                child: Text(initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      business,
                      style: const TextStyle(
                        color: TourFlowColors.body,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      submitted,
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusChip(
                label: 'PENDING',
                color: TourFlowColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlineActionButton(
                  label: 'Reject',
                  color: TourFlowColors.danger,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onReview,
                  style: FilledButton.styleFrom(
                    backgroundColor: TourFlowColors.primary,
                    foregroundColor: TourFlowColors.primaryText,
                  ),
                  child: const Text('Review'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

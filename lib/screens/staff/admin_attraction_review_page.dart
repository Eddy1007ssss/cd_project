import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class AdminAttractionReviewPage extends StatelessWidget {
  const AdminAttractionReviewPage({super.key});

  static const routeName = '/admin-attraction-review';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Attraction Review',
      role: 'TOURFLOW · ADMINISTRATOR',
      isStaff: true,
      selectedNavigationIndex: 3,
      child: Column(
        children: [
          const ModuleCard(
            color: TourFlowColors.lavender,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: TourFlowColors.primary,
                  foregroundColor: TourFlowColors.primaryText,
                  child: Icon(Icons.fact_check_outlined),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submission #8293',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Submitted 22 August 2026 · 10:42 AM',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: 'PENDING',
                  color: TourFlowColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('General Information'),
                SizedBox(height: 16),
                StaticField(
                  label: 'Attraction Name',
                  value: 'Lumina Botanical Gardens & Conservatory',
                  icon: Icons.local_florist_outlined,
                ),
                SizedBox(height: 13),
                StaticField(
                  label: 'Category',
                  value: 'Nature · Photography · Family',
                  icon: Icons.category_outlined,
                ),
                SizedBox(height: 13),
                StaticField(
                  label: 'Location',
                  value: 'Perdana Botanical Gardens, Kuala Lumpur',
                  icon: Icons.location_on_outlined,
                ),
                SizedBox(height: 13),
                StaticField(
                  label: 'Description',
                  value:
                      'A living collection of tropical plants, glasshouse exhibits and quiet nature trails designed for all ages.',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionTitle('Submitted Media'),
                    StatusChip(
                      label: '6 IMAGES',
                      color: TourFlowColors.primaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 155,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0E4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.park_rounded,
                      size: 78,
                      color: Color(0xFF729568),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(child: _MediaThumb(icon: Icons.eco_rounded)),
                    SizedBox(width: 8),
                    Expanded(child: _MediaThumb(icon: Icons.nature_rounded)),
                    SizedBox(width: 8),
                    Expanded(child: _MediaThumb(icon: Icons.photo_outlined)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Operating & Capacity'),
                SizedBox(height: 14),
                _ReviewRow(
                  label: 'Opening Days',
                  value: 'Monday – Sunday',
                ),
                Divider(height: 24),
                _ReviewRow(
                  label: 'Opening Hours',
                  value: '08:00 – 20:00',
                ),
                Divider(height: 24),
                _ReviewRow(label: 'Maximum Capacity', value: '120 visitors'),
                Divider(height: 24),
                _ReviewRow(label: 'Check-In', value: 'QR + Mobile Staff'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Operator Verification'),
                SizedBox(height: 14),
                _ReviewRow(
                  label: 'Business',
                  value: 'Lumina Eco Leisure Sdn. Bhd.',
                ),
                Divider(height: 24),
                _ReviewRow(label: 'Registration No.', value: '202501084231'),
                Divider(height: 24),
                _ReviewRow(label: 'Representative', value: 'Alyssa Lim'),
                Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: TourFlowColors.success,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Business documents verified',
                        style: TextStyle(
                          color: TourFlowColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: 'VERIFIED',
                      color: TourFlowColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Guidelines & Rules'),
                SizedBox(height: 14),
                StaticField(
                  label: 'Visitor Guidelines',
                  value:
                      'Arrive within the selected slot. Follow marked trails and use designated rest areas.',
                  maxLines: 4,
                ),
                SizedBox(height: 13),
                StaticField(
                  label: 'Attraction Rules',
                  value:
                      'No plant removal, smoking, outside catering or entry into staff-only areas.',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Review Notes',
                  subtitle:
                      'Add a clear reason if the submission must be rejected.',
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Admin Note',
                  value: 'All required information has been reviewed.',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlineActionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: TourFlowColors.danger,
                    onPressed: () {},
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: TourFlowColors.lavenderStrong,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: TourFlowColors.body, size: 30),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: TourFlowColors.heading,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

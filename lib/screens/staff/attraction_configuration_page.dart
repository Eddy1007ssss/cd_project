import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'operator_dashboard_page.dart';

class AttractionConfigurationPage extends StatefulWidget {
  const AttractionConfigurationPage({super.key});

  static const routeName = '/attraction-configuration';

  @override
  State<AttractionConfigurationPage> createState() =>
      _AttractionConfigurationPageState();
}

class _AttractionConfigurationPageState
    extends State<AttractionConfigurationPage> {
  bool _isOutdoor = false;

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Attraction Configuration',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 1,
      child: Column(
        children: [
          const ModuleCard(
            color: TourFlowColors.lavender,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: TourFlowColors.primary,
                  foregroundColor: TourFlowColors.primaryText,
                  child: Text('2'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SectionTitle(
                    'Operating Configuration',
                    subtitle:
                        'Set opening hours, check-in rules and safe visitor capacity.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Operating Hours'),
                SizedBox(height: 14),
                _HoursRow(day: 'Monday – Friday', hours: '08:00 – 20:00'),
                Divider(height: 24),
                _HoursRow(day: 'Saturday', hours: '09:00 – 22:00'),
                Divider(height: 24),
                _HoursRow(day: 'Sunday', hours: 'Closed', closed: true),
                SizedBox(height: 14),
                StaticField(
                  label: 'Special Notes',
                  value: 'Last entry is 30 minutes before closing time.',
                  icon: Icons.info_outline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Attraction Type & Check-In',
                  subtitle:
                      'The attraction type determines the required check-in method.',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.apartment_rounded),
                        label: Text('Indoor'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.park_outlined),
                        label: Text('Outdoor'),
                      ),
                    ],
                    selected: {_isOutdoor},
                    onSelectionChanged: (selection) =>
                        setState(() => _isOutdoor = selection.first),
                  ),
                ),
                const SizedBox(height: 9),
                _ChoiceTile(
                  icon: _isOutdoor
                      ? Icons.location_on_outlined
                      : Icons.qr_code_scanner_rounded,
                  title: _isOutdoor
                      ? 'GPS Geofence Self Check-In'
                      : 'Fixed Entrance QR Check-In',
                  subtitle: _isOutdoor
                      ? 'Tourists check in inside the configured attraction boundary.'
                      : 'Staff scan booking QR codes at the fixed entrance.',
                  selected: true,
                  onTap: () {},
                ),
                if (_isOutdoor) ...[
                  const SizedBox(height: 9),
                  _ChoiceTile(
                    icon: Icons.phone_android_rounded,
                    title: 'Roaming Staff QR Fallback',
                    subtitle:
                        'Required fallback when GPS self check-in is unavailable.',
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 13),
                  const StaticField(
                    label: 'Geofence Radius',
                    value: '150 metres',
                    icon: Icons.radar_rounded,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Capacity & Crowd Levels',
                  subtitle:
                      'These thresholds power the live crowd status shown to tourists.',
                ),
                SizedBox(height: 16),
                StaticField(
                  label: 'Maximum Attraction Capacity',
                  value: '120 visitors',
                  icon: Icons.groups_outlined,
                ),
                SizedBox(height: 16),
                _ThresholdRow(
                  color: TourFlowColors.success,
                  label: 'Low',
                  range: '0 – 40 visitors',
                ),
                SizedBox(height: 9),
                _ThresholdRow(
                  color: Color(0xFF65A30D),
                  label: 'Moderate',
                  range: '41 – 75 visitors',
                ),
                SizedBox(height: 9),
                _ThresholdRow(
                  color: TourFlowColors.warning,
                  label: 'High',
                  range: '76 – 105 visitors',
                ),
                SizedBox(height: 9),
                _ThresholdRow(
                  color: TourFlowColors.danger,
                  label: 'Critical',
                  range: '106 – 120 visitors',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Maintenance & Closure'),
                SizedBox(height: 14),
                StaticField(
                  label: 'Start Date',
                  value: '24 September 2026 · 08:00',
                  icon: Icons.event_busy_outlined,
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'End Date',
                  value: '25 September 2026 · 18:00',
                  icon: Icons.event_available_outlined,
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Reason',
                  value: 'Scheduled landscape and facility maintenance.',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Save & Submit for Approval',
            icon: Icons.send_outlined,
            onPressed: () async {
              if (await Navigator.maybePop(context) || !context.mounted) return;
              Navigator.pushReplacementNamed(
                context,
                OperatorDashboardPage.routeName,
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlineActionButton(
              label: 'Save as Draft',
              icon: Icons.save_outlined,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attraction draft saved.')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.day,
    required this.hours,
    this.closed = false,
  });

  final String day;
  final String hours;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            day,
            style: const TextStyle(
              color: TourFlowColors.heading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        StatusChip(
          label: hours,
          color: closed ? TourFlowColors.danger : TourFlowColors.success,
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? TourFlowColors.lavender : TourFlowColors.surface,
          border: Border.all(
            color: selected
                ? TourFlowColors.primaryText
                : TourFlowColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: TourFlowColors.primaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? TourFlowColors.primaryText
                  : TourFlowColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  const _ThresholdRow({
    required this.color,
    required this.label,
    required this.range,
  });

  final Color color;
  final String label;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TourFlowColors.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            range,
            style: const TextStyle(color: TourFlowColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

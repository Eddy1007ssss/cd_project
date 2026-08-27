import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'attraction_configuration_page.dart';

class AttractionDetailsPage extends StatelessWidget {
  const AttractionDetailsPage({super.key});

  static const routeName = '/attraction-details';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Attraction Details',
      role: 'TOURFLOW · OPERATOR',
      isStaff: true,
      selectedNavigationIndex: 0,
      child: Column(
        children: [
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Core Details',
                  subtitle:
                      'Provide clear public information for tourists discovering this attraction.',
                ),
                SizedBox(height: 18),
                StaticField(
                  label: 'Attraction Name',
                  value: 'Old Town Square',
                  icon: Icons.place_outlined,
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Category',
                  value: 'Historical Landmark',
                  icon: Icons.category_outlined,
                  trailing: Icon(Icons.keyboard_arrow_down_rounded),
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Description',
                  value:
                      'A historic square in the Old Town quarter of Kuala Lumpur. Visitors can explore heritage buildings, local culture and guided walking routes.',
                  maxLines: 5,
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Location Tag',
                  value: 'Kuala Lumpur, Malaysia',
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Geographic Data'),
                const SizedBox(height: 14),
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EFE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 92,
                        color: Color(0xFF8BA17E),
                      ),
                      Icon(
                        Icons.location_pin,
                        size: 44,
                        color: TourFlowColors.danger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlineActionButton(
                    label: 'Set Coordinates',
                    icon: Icons.my_location_rounded,
                    onPressed: () {},
                  ),
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
                    SectionTitle('Media Gallery'),
                    StatusChip(
                      label: '4/10 SLOTS',
                      color: TourFlowColors.primaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.25,
                  children: const [
                    _GalleryTile(icon: Icons.account_balance_rounded),
                    _GalleryTile(icon: Icons.location_city_rounded),
                    _GalleryTile(icon: Icons.groups_rounded),
                    _GalleryTile(icon: Icons.add_photo_alternate_outlined, add: true),
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
                SectionTitle('Visitor Information'),
                SizedBox(height: 16),
                StaticField(
                  label: 'Visitor Guidelines',
                  value:
                      'Arrive 15 minutes before your registered slot. Keep walkways clear and follow staff instructions.',
                  maxLines: 4,
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Attraction Rules',
                  value:
                      'No smoking, restricted equipment or unattended children inside the attraction area.',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Continue to Configuration',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.pushNamed(
                context,
                AttractionConfigurationPage.routeName,
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlineActionButton(
              label: 'Save as Draft',
              icon: Icons.save_outlined,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.icon, this.add = false});

  final IconData icon;
  final bool add;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: add
            ? TourFlowColors.background
            : TourFlowColors.lavenderStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: add
              ? TourFlowColors.primaryText
              : TourFlowColors.border.withOpacity(0.4),
        ),
      ),
      child: Icon(
        icon,
        size: 38,
        color: add
            ? TourFlowColors.primaryText
            : TourFlowColors.body,
      ),
    );
  }
}

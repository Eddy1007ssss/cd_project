import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

typedef ManagementRow = Map<String, dynamic>;

/// Module 1 persistence. Authorization remains in Postgres/RLS, not in widgets.
class ManagementRepository {
  ManagementRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get client => _client ?? Supabase.instance.client;
  String get userId =>
      client.auth.currentUser?.id ??
      (throw const AuthException('Please sign in first.'));

  Future<List<ManagementRow>> applications() async => await client
      .from('operator_applications')
      .select()
      .order('created_at', ascending: false);

  Future<List<ManagementRow>> users() async =>
      await client.from('profiles').select().order('full_name');

  Future<List<ManagementRow>> organizations() async {
    final members = await client
        .from('organization_members')
        .select('organization_id')
        .eq('user_id', userId)
        .eq('member_role', 'operator')
        .eq('is_active', true);
    final ids = members.map((row) => row['organization_id'] as String).toList();
    if (ids.isEmpty) return [];
    return await client
        .from('operator_organizations')
        .select()
        .inFilter('id', ids)
        .eq('is_active', true)
        .order('name');
  }

  Future<List<ManagementRow>> attractions({bool administrator = false}) async {
    if (administrator) {
      return await client
          .from('attractions')
          .select()
          .order('updated_at', ascending: false);
    }
    final orgs = await organizations();
    if (orgs.isEmpty) return [];
    return await client
        .from('attractions')
        .select()
        .inFilter(
          'organization_id',
          orgs.map((row) => row['id'] as String).toList(),
        )
        .order('name');
  }

  Future<void> submitApplication(ManagementRow values) async {
    await client
        .from('operator_applications')
        .insert({...values, 'applicant_id': userId})
        .select('id')
        .single();
  }

  Future<void> reviewApplication(
    String id,
    String decision,
    String note,
  ) async {
    await client.rpc(
      'review_operator_application',
      params: {'application_id': id, 'decision': decision, 'note': note},
    );
  }

  Future<void> setAccountStatus(String id, String status) async {
    await client.rpc(
      'set_account_status',
      params: {'target_user_id': id, 'new_status': status},
    );
  }

  Future<void> reviewAttraction(String id, String decision, String note) async {
    await client.rpc(
      'review_attraction',
      params: {'target_attraction_id': id, 'decision': decision, 'note': note},
    );
  }

  Future<List<ManagementRow>> hours(String id) async => await client
      .from('operating_hours')
      .select()
      .eq('attraction_id', id)
      .order('day_of_week');

  Future<List<ManagementRow>> images(String id) async => await client
      .from('attraction_images')
      .select()
      .eq('attraction_id', id)
      .order('display_order');

  Future<String> saveAttraction(
    ManagementRow values,
    List<ManagementRow> hours,
  ) async {
    final result = await client.rpc(
      'save_managed_attraction',
      params: {'details': values, 'hours': hours},
    );
    return result as String;
  }

  Future<List<ManagementRow>> slots(String id) async => await client
      .from('attraction_slots')
      .select()
      .eq('attraction_id', id)
      .order('starts_at');

  Future<List<ManagementRow>> closures(String id) async => await client
      .from('closure_periods')
      .select()
      .eq('attraction_id', id)
      .order('starts_at');

  Future<void> saveSlot(ManagementRow values) async {
    await client.rpc('save_managed_slot', params: {'details': values});
  }

  Future<void> addClosure(ManagementRow values) async {
    await client.rpc('add_managed_closure', params: {'details': values});
  }

  Future<int> bulkCreateSlots({
    required String attractionId,
    required DateTime firstDay,
    required DateTime lastDay,
    required String openingTime,
    required String closingTime,
    required int durationMinutes,
    required int capacity,
  }) async {
    final result = await client.rpc('bulk_create_managed_slots', params: {
      'target_attraction_id': attractionId,
      'first_day': firstDay.toIso8601String().substring(0, 10),
      'last_day': lastDay.toIso8601String().substring(0, 10),
      'opening_time': openingTime,
      'closing_time': closingTime,
      'duration_minutes': durationMinutes,
      'capacity': capacity,
    });
    return (result as num).toInt();
  }

  Future<void> assignStaff({
    required String organizationId,
    required String staffUserId,
    required bool active,
  }) => client.rpc('set_organization_staff', params: {
        'target_organization_id': organizationId,
        'target_user_id': staffUserId,
        'active': active,
      });

  Future<String> submitAppeal({
    String? applicationId,
    String? attractionId,
    required String explanation,
  }) async => await client.rpc('create_operator_appeal', params: {
        'target_application_id': applicationId,
        'target_attraction_id': attractionId,
        'explanation_value': explanation,
      }) as String;

  Future<String> uploadImage({
    required String bucket,
    required String folder,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 10 MB.');
    }
    final path = '$folder/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return path;
  }

  Future<void> addAttractionImage(String id, String path, int position) async {
    await client
        .from('attraction_images')
        .insert({
          'attraction_id': id,
          'storage_path': path,
          'display_order': position,
        })
        .select('id')
        .single();
  }

  Future<String> documentUrl(String path) =>
      client.storage.from('operator-documents').createSignedUrl(path, 300);

  String imageUrl(String path) =>
      client.storage.from('attraction-images').getPublicUrl(path);
}

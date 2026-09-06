import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_crowd_models.dart';

class LiveCrowdRepository {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // OPERATOR LIVE CROWD LIST
  // ============================================================

  Future<List<OperatorLiveCrowdSummary>>
  fetchOperatorLiveCrowdList() async {
    final response = await _supabase.rpc(
      'get_operator_live_crowd_list',
    );

    final rows = response as List<dynamic>;

    return rows
        .map(
          (row) =>
          OperatorLiveCrowdSummary.fromJson(
            Map<String, dynamic>.from(
              row as Map,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // OPERATOR LIVE CROWD DETAILS
  // ============================================================

  Future<OperatorLiveCrowdDetails>
  fetchOperatorLiveCrowdDetails(
      String attractionId,
      ) async {
    final response = await _supabase.rpc(
      'get_operator_live_crowd_details',
      params: {
        'target_attraction_id': attractionId,
      },
    );

    return OperatorLiveCrowdDetails.fromJson(
      Map<String, dynamic>.from(
        response as Map,
      ),
    );
  }
}
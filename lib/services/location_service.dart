import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attraction.dart';

class AttractionService {
  final SupabaseClient _client = Supabase.instance.client;

  // UC-M2-01: Browse Approved Attractions
  Future<List<Attraction>> getApprovedAttractions() async {
    final response = await _client
        .from('attractions')
        .select()
        .eq('status', 'approved');

    return (response as List)
        .map((row) => Attraction.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // UC-M2-02: Search Attractions
  Future<List<Attraction>> searchAttractions(String keyword) async {
    final response = await _client
        .from('attractions')
        .select()
        .eq('status', 'approved')
        .or('name.ilike.%$keyword%,category.ilike.%$keyword%,'
        'description.ilike.%$keyword%,location.ilike.%$keyword%');

    return (response as List)
        .map((row) => Attraction.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // UC-M2-03: Filter and Sort Attractions
  Future<List<Attraction>> filterAndSortAttractions({
    double? maxPrice,
    double? minRating,
    String? crowdLevel,
    String? category,
    bool? accessibleOnly,
    String sortBy = 'rating', // 'rating', 'price', 'distance'
    bool ascending = false,
  }) async {
    var query = _client.from('attractions').select().eq('status', 'approved');

    if (maxPrice != null) query = query.lte('price', maxPrice);
    if (minRating != null) query = query.gte('rating', minRating);
    if (crowdLevel != null) query = query.eq('crowd_level', crowdLevel);
    if (category != null) query = query.eq('category', category);
    if (accessibleOnly == true) query = query.eq('is_accessible', true);

    final response = await query.order(sortBy, ascending: ascending);

    return (response as List)
        .map((row) => Attraction.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // UC-M2-13: View Attraction Details (single attraction with live data)
  Future<Attraction?> getAttractionById(String id) async {
    final response = await _client
        .from('attractions')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Attraction.fromMap(response);
  }

  // UC-M2-12: Compare Attractions (fetch multiple by ID)
  Future<List<Attraction>> getAttractionsByIds(List<String> ids) async {
    final response =
    await _client.from('attractions').select().inFilter('id', ids);

    return (response as List)
        .map((row) => Attraction.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
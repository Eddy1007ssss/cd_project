import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// RLS-filtered row changes invalidate existing aggregate queries. No visitor
/// rows are exposed to tourists. Polling in the screens remains a fallback.
class CrowdUpdates {
  CrowdUpdates(this.onChange, {SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  final void Function() onChange;
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  Timer? _debounce;
  bool _disposed = false;

  void start({String? attractionId}) {
    if (_channel != null || _disposed) return;
    final channel = _client.channel('crowd-${DateTime.now().microsecondsSinceEpoch}');
    void changed(PostgresChangePayload _) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), () {
        if (!_disposed) onChange();
      });
    }
    for (final table in ['attraction_check_ins', 'attraction_slots']) {
      channel.onPostgresChanges(event: PostgresChangeEvent.all,
        schema: 'public', table: table,
        filter: attractionId == null ? null : PostgresChangeFilter(
          type: PostgresChangeFilterType.eq, column: 'attraction_id', value: attractionId),
        callback: changed);
    }
    _channel = channel;
    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed && !_disposed) onChange();
    });
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(_client.removeChannel(channel).then<void>((_) {}));
    }
  }
}

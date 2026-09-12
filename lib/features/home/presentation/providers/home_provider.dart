import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../domain/dashboard_summary.dart';

part 'home_provider.g.dart';

/// Live-updating connectivity signal for the Home header's indicator.
/// The existing [ConnectivityService] already exposes a stream — this
/// just makes it watchable as a provider, reused as-is rather than
/// duplicated.
@riverpod
Stream<bool> connectivityStatus(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
}

/// Derives the dashboard's overall [DataFreshness] label honestly from
/// what's actually known — connectivity, and whether the centers and
/// alerts sections currently have data or an error. See
/// [DataFreshness]'s own doc comment for the reasoning behind each case.
DataFreshness deriveFreshness({
  required bool isConnected,
  required bool hasAnyData,
  required bool hasAnyError,
}) {
  if (isConnected) {
    return hasAnyError ? DataFreshness.unavailable : DataFreshness.live;
  }
  return hasAnyData ? DataFreshness.cached : DataFreshness.offline;
}

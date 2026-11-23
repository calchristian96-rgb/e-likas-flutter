import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/lock_note.dart';
import 'current_event.dart';

/// True while the selected event is being monitored: registration
/// (centers, private houses, returning families), relief rounds,
/// transfers and final counts wait for CSWD's "Start evacuation"
/// (docs/backend/apps-api-2026-11-22.md section 1, Locks).
final eventMonitoredProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(currentStaffEventProvider).value?.status == 'monitoring',
);

/// Shows [child] while the event allows field work, else the one lock
/// design ("Available when the event is Active").
class MonitoringLock extends ConsumerWidget {
  const MonitoringLock({super.key, required this.child, this.dense = false});

  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(eventMonitoredProvider) ? LockNote(dense: dense) : child;
}

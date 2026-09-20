import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/evacuation_center.dart';

/// Stable-sorts [centers] so every center in [ownBarangayName] comes
/// first, in their original relative order, followed by every other
/// center in its original relative order — mirrors the desktop app's
/// own barangay-pinning in its citywide center list. A plain name
/// comparison (not [EvacuationCenter.barangayId]): the public
/// `/evacuation-centers` list this screen and EC Board's own center
/// picker both read from never populates `barangayId` (only the
/// single-center authenticated detail fetch does — see
/// [EvacuationCenter.barangayId]'s doc comment), so the barangay
/// display name is the only field both a center and a [StaffSession]
/// reliably carry.
List<EvacuationCenter> pinOwnBarangayFirst(
  List<EvacuationCenter> centers,
  String? ownBarangayName,
) {
  if (ownBarangayName == null || ownBarangayName.isEmpty) return centers;
  final own = <EvacuationCenter>[];
  final others = <EvacuationCenter>[];
  for (final center in centers) {
    if (center.barangay == ownBarangayName) {
      own.add(center);
    } else {
      others.add(center);
    }
  }
  if (own.isEmpty) return centers;
  return [...own, ...others];
}

/// Builds a flat widget list from [centers] — split into "Your
/// barangay" / "Other barangays" labeled groups when the split is
/// actually meaningful (a real own-barangay match, and at least one
/// center left over from elsewhere), or just [tileBuilder] applied
/// straight down the list otherwise, so a session with no barangay
/// (or a result set that's entirely one barangay) doesn't show a
/// pointless single-group heading. Shared by every screen that lists
/// centers barangay-pinned — the staff center-management list and EC
/// Board's own center picker — so the grouping reads identically in
/// both places.
List<Widget> buildBarangayGroupedCenterTiles({
  required List<EvacuationCenter> centers,
  required String? ownBarangayName,
  required String ownGroupLabel,
  required String othersGroupLabel,
  required Widget Function(EvacuationCenter center) tileBuilder,
  required Widget spacer,
}) {
  final own = ownBarangayName == null
      ? const <EvacuationCenter>[]
      : centers.where((c) => c.barangay == ownBarangayName).toList();
  final others = ownBarangayName == null
      ? centers
      : centers.where((c) => c.barangay != ownBarangayName).toList();

  if (own.isEmpty || others.isEmpty) {
    return [
      for (final center in centers) ...[tileBuilder(center), spacer],
    ];
  }

  return [
    CenterGroupLabel(text: ownGroupLabel),
    for (final center in own) ...[tileBuilder(center), spacer],
    spacer,
    CenterGroupLabel(text: othersGroupLabel),
    for (final center in others) ...[tileBuilder(center), spacer],
  ];
}

class CenterGroupLabel extends StatelessWidget {
  const CenterGroupLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: semantic.navy,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

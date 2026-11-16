import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/data_freshness_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/barangay_status.dart';
import 'barangay_picker_sheet.dart';
import 'barangay_status_providers.dart';

/// The fill colours of the web map (backend map-api.md). Normal has no
/// fill on the map; on a card it is the success green.
Color barangayStatusColor(BuildContext context, String status) {
  return switch (status) {
    BarangayStatusKey.watch => const Color(0xFFFACC15),
    BarangayStatusKey.floodingReported => const Color(0xFFF97316),
    BarangayStatusKey.preemptiveEvacuation => const Color(0xFFDC2626),
    BarangayStatusKey.forcedEvacuation => const Color(0xFF7F1D1D),
    _ => const Color(0xFF15803D),
  };
}

/// Home's answer-first card: "Your barangay: Binatagan — Flooding
/// reported", the colour always with its word. Asks for the barangay
/// when none is chosen yet.
class BarangayStatusCard extends ConsumerWidget {
  const BarangayStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final own = ref.watch(residentBarangayProvider);
    final boardAsync = ref.watch(barangayStatusBoardProvider);

    if (own == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          minTileHeight: 64,
          leading: Icon(
            Icons.location_city_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(l10n.residentBarangayPickerTitle),
          subtitle: Text(l10n.residentBarangayWhy),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showBarangayPickerSheet(context),
        ),
      );
    }

    final board = boardAsync.value;
    final status = board?.byId(own.id);
    final color = barangayStatusColor(
      context,
      status?.status ?? BarangayStatusKey.normal,
    );
    final label = status?.label ?? (boardAsync.isLoading ? '…' : '—');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showBarangayPickerSheet(context),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.residentBarangayStatusOf(own.name),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (board != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          board.hasOpenEvent
                              ? board.eventName!
                              : l10n.residentNoOpenEvent,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (board.isFromCache)
                          Text(
                            l10n.residentStatusSavedCopy(
                              board.lastSyncedAt == null
                                  ? ''
                                  : formatElapsedSince(board.lastSyncedAt!),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

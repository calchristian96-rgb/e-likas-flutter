import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/sheet_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/barangay_status.dart';
import 'barangay_status_providers.dart';

/// What the live strip has to say, or null on a calm day.
class LiveStatusNews {
  const LiveStatusNews({
    required this.orderedBarangays,
    this.eventName,
    this.updatedAt,
  });

  /// Barangays under a preemptive or forced evacuation order.
  final int orderedBarangays;
  final String? eventName;

  /// When the saved copy was last synced (null when it is live).
  final DateTime? updatedAt;
}

/// The strip's news from the barangay board the app already loads: an
/// evacuation order in any barangay. (Mayon at Alert Level 1+ joins it
/// later, from its own cached read.)
final liveStatusNewsProvider = Provider<LiveStatusNews?>((ref) {
  final board = ref.watch(barangayStatusBoardProvider).value;
  if (board == null || !board.hasOpenEvent) return null;
  final ordered = board.barangays
      .where(
        (b) =>
            b.status == BarangayStatusKey.preemptiveEvacuation ||
            b.status == BarangayStatusKey.forcedEvacuation,
      )
      .length;
  if (ordered == 0) return null;
  return LiveStatusNews(
    orderedBarangays: ordered,
    eventName: board.eventName,
    updatedAt: board.isFromCache ? board.lastSyncedAt : null,
  );
});

/// The live status strip: bulletin navy across the top of the resident
/// app, only when there is news (The Band Is Live Rule). Calm days show
/// nothing at all. Taps through to the map.
class BulletinStrip extends ConsumerWidget {
  const BulletinStrip({super.key, this.news});

  /// For a test render; otherwise read from [liveStatusNewsProvider].
  final LiveStatusNews? news;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = news ?? ref.watch(liveStatusNewsProvider);
    if (n == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final title = l10n.situationEvacuationOrdered.toUpperCase();
    final event = n.eventName;
    final updated = n.updatedAt;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Material(
          color: Sheet.bulletin,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: () => context.go('/map'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    // The band's status dot (the web's #F87171).
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF87171),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event == null ? title : '$title · $event',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SheetText.label(Colors.white, size: 16)
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.situationEvacuatingBarangays(
                              n.orderedBarangays,
                            ),
                            style: const TextStyle(
                              fontFamily: Sheet.bodyFont,
                              fontSize: 14,
                              height: 1.35,
                              color: Sheet.bulletinText,
                            ),
                          ),
                          if (updated != null)
                            Text(
                              '${l10n.freshnessLastUpdatedVerb} '
                              '${DateFormat('MMM d, h:mm a').format(updated)}',
                              style: const TextStyle(
                                fontFamily: Sheet.bodyFont,
                                fontSize: 14,
                                height: 1.35,
                                color: Sheet.bulletinText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

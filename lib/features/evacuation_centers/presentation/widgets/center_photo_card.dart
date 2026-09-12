import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/home_provider.dart'
    show connectivityStatusProvider;
import '../providers/center_photo_provider.dart';

/// A wide, rounded-corner photo card for Evacuation Center Details —
/// shown beneath the header/status area, above the Overview section.
/// Always renders *something* (photo, loading spinner, or a clean
/// placeholder) — never a broken-image icon, a raw network error, or
/// a URL. See `center_photo_provider.dart` for the online/offline/
/// cache-fallback resolution this displays.
class CenterPhotoCard extends ConsumerWidget {
  const CenterPhotoCard({
    super.key,
    required this.centerId,
    required this.photoUrl,
  });

  final int centerId;
  final String? photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: photoUrl == null || photoUrl!.isEmpty
            ? const _CenterPhotoPlaceholder()
            : _NetworkOrCachedPhoto(centerId: centerId, photoUrl: photoUrl!),
      ),
    );
  }
}

class _NetworkOrCachedPhoto extends ConsumerWidget {
  const _NetworkOrCachedPhoto({required this.centerId, required this.photoUrl});

  final int centerId;
  final String photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileAsync = ref.watch(centerPhotoFileProvider(centerId, photoUrl));
    // Display-only: doesn't affect resolution (see
    // `center_photo_provider.dart`), just which placeholder copy to
    // show if resolution comes back with nothing — "unavailable
    // offline" only makes sense to say when there genuinely is no
    // connection right now.
    final isOffline = ref.watch(connectivityStatusProvider).value == false;
    return fileAsync.when(
      data: (file) => file == null
          ? _CenterPhotoPlaceholder(offline: isOffline)
          : Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // A cached file can still be corrupt/truncated (e.g. an
              // interrupted download that raced past the byte-count
              // check) — errorBuilder keeps that a placeholder instead
              // of a broken-image icon or a crash.
              errorBuilder: (context, error, stackTrace) =>
                  const _CenterPhotoPlaceholder(),
            ),
      loading: () => const _CenterPhotoLoading(),
      error: (error, stackTrace) => const _CenterPhotoPlaceholder(),
    );
  }
}

class _CenterPhotoLoading extends StatelessWidget {
  const _CenterPhotoLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Subtle navy-tinted surface + building icon + "No photo available" —
/// deliberately calm, never an error look, since "no photo" is a
/// normal, expected state for the vast majority of centers today (see
/// `EvacuationCenter.photoUrl`'s doc comment). Shows the more specific
/// "unavailable offline" copy only when [offline] is true *and* there
/// was an actual URL to try (see [_NetworkOrCachedPhoto]) — a center
/// with no photo at all always shows the plain message regardless of
/// connectivity.
class _CenterPhotoPlaceholder extends StatelessWidget {
  const _CenterPhotoPlaceholder({this.offline = false});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              offline
                  ? l10n.centerPhotoUnavailableOffline
                  : l10n.centerPhotoUnavailable,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

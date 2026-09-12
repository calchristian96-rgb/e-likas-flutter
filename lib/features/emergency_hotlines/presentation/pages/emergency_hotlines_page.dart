import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/emergency_hotlines_data.dart';
import '../../domain/hotline.dart';
import '../providers/hotline_favorites_provider.dart';
import '../widgets/hotline_card.dart';
import '../widgets/hotline_category_display.dart';
import '../widgets/priority_hotline_card.dart';

/// Emergency Hotlines — entirely static, local data (see
/// `emergency_hotlines_data.dart`'s own doc comment for why there's no
/// repository/loading state here at all): no spinner, no network
/// dependency, works identically online or fully offline.
///
/// No search control: with 7 real entries total, already grouped into
/// a handful of short category sections, a search box would add UI
/// surface without saving a resident real time over just scanning the
/// (short, on-screen-at-once) list — see the final report for this
/// reasoning spelled out.
class EmergencyHotlinesPage extends ConsumerWidget {
  const EmergencyHotlinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final favoritesAsync = ref.watch(hotlineFavoritesProvider);
    final favorites = favoritesAsync.value ?? const <String>{};

    // The single national-emergency entry gets its own priority
    // treatment below, not a category section — nothing else should
    // exist in this category today, but if it ever did, this still
    // only pulls out the *first* one rather than silently dropping the
    // rest.
    final priorityHotline = emergencyHotlines
        .where((h) => h.category == HotlineCategory.nationalEmergency)
        .firstOrNull;

    final favoriteHotlines = emergencyHotlines
        .where((h) => favorites.contains(h.name))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyHotlinesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OfficialServicesBanner(message: l10n.emergencyHotlinesSubtitle),
          const SizedBox(height: 10),
          _EmergencyInfoBanner(message: l10n.emergencyCallNowNote),
          const SizedBox(height: 10),
          _OfflineCapabilityBanner(message: l10n.hotlinesOfflineNote),
          const SizedBox(height: 16),
          if (priorityHotline != null) ...[
            PriorityHotlineCard(hotline: priorityHotline),
            const SizedBox(height: 20),
          ],
          if (favoriteHotlines.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.star_rounded,
              label: l10n.favoritesSectionTitle,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 8),
            for (final hotline in favoriteHotlines)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HotlineCard(hotline: hotline),
              ),
            const SizedBox(height: 8),
          ],
          for (final category in hotlineCategorySectionOrder)
            _buildCategorySection(context, theme, category),
        ],
      ),
    );
  }

  /// Returns an empty [SizedBox] rather than `null`/omitting the
  /// section when [category] has no real entries — a category present
  /// in the enum but genuinely absent from today's verified hotline
  /// list (there isn't one currently, but the guard costs nothing and
  /// means adding/removing hotlines later can never produce an empty
  /// "Fire" heading with nothing under it).
  Widget _buildCategorySection(
    BuildContext context,
    ThemeData theme,
    HotlineCategory category,
  ) {
    final hotlines = emergencyHotlines
        .where((h) => h.category == category)
        .toList();
    if (hotlines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: hotlineCategoryIcon(category),
            label: hotlineCategoryLabel(context, category),
            color: hotlineCategoryColor(category, theme),
          ),
          const SizedBox(height: 8),
          for (final hotline in hotlines)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HotlineCard(hotline: hotline),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The "these are the official emergency services of Ligao City" banner
/// — light blue/neutral surface with a shield icon, reusing the same
/// `secondaryContainer` + `Icons.shield_outlined` pairing already used
/// for E-LIKAS's own official/trust framing on the splash screen, Home,
/// and Staff sign-in, rather than inventing a new "official" visual
/// language just for this page.
class _OfficialServicesBanner extends StatelessWidget {
  const _OfficialServicesBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact, static (no icon/colour change over time) strip making
/// the "call now if this is life-threatening" message the very first
/// thing on screen — separate from [_OfflineCapabilityBanner] below it,
/// since one is about urgency and the other about connectivity, and
/// conflating them into one banner would blur both messages.
class _EmergencyInfoBanner extends StatelessWidget {
  const _EmergencyInfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineCapabilityBanner extends StatelessWidget {
  const _OfflineCapabilityBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.offline_bolt_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

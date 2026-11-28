import 'package:flutter/material.dart';

import '../../../../core/widgets/ui_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/staff_session.dart';

/// Who is signed in: the same card as everything else, with the light
/// staff highlight (thin brand-blue border and tint), never a heavy dark
/// card. Used in Settings and at the top of More.
class StaffIdentityCard extends StatelessWidget {
  const StaffIdentityCard({super.key, required this.session, this.onTap});

  final StaffSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // The role's display name, and the barangay only when there is one.
    final subtitle = session.barangayName != null
        ? l10n.staffIdentityWithBarangay(
            session.roleDisplayName,
            session.barangayName!,
          )
        : session.roleDisplayName;

    return AppCard(
      highlight: true,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.surface,
            child: Icon(
              Icons.badge_outlined,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

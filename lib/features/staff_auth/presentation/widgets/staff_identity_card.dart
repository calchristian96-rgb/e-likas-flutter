import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/staff_session.dart';

/// The dark-navy staff identity card shown both in Settings' STAFF
/// section and at the top of the Staff Dashboard — one widget so the
/// two places can never visually drift apart. Reuses the exact
/// `[navy, deepNavy]` gradient `_BrandedHeader` (Home's own header)
/// already established as this app's "official/branded" visual
/// language, rather than inventing a second dark treatment.
///
/// Purely informational — no chevron, not wrapped in an `InkWell` —
/// every real value comes straight from [session], never hardcoded.
class StaffIdentityCard extends StatelessWidget {
  const StaffIdentityCard({super.key, required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final l10n = AppLocalizations.of(context);

    // roleDisplayName ("Barangay Official"), never the raw backend
    // enum value session.role ("barangay_official") this card used to
    // show verbatim. CSWD/admin accounts have no barangay — shown as
    // just the role, never "Brgy. null" or a dangling "Brgy." with
    // nothing after it.
    final subtitle = session.barangayName != null
        ? l10n.staffIdentityWithBarangay(
            session.roleDisplayName,
            session.barangayName!,
          )
        : session.roleDisplayName;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [semantic.navy, semantic.deepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.badge_outlined, color: semantic.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

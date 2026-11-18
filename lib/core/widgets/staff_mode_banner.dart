import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../l10n/app_localizations.dart';

/// Amber, readable on any screen (dark text on amber passes contrast).
const staffModeAmber = Color(0xFFFBBF24);
const staffModeInk = Color(0xFF1F2937);

/// On top of the resident app while a staff account is signed in: says
/// so plainly and goes back to Staff Mode in one tap. Shown above every
/// tab, so the public view is never mistaken for Staff Mode.
class StaffModeBanner extends ConsumerWidget {
  const StaffModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(staffAuthProvider).value;
    if (session == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Material(
        color: staffModeAmber,
        child: SafeArea(
          bottom: false,
          child: InkWell(
            onTap: () => context.go('/staff'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.badge, color: staffModeInk, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.staffBannerSignedIn(session.name),
                        style: const TextStyle(
                          color: staffModeInk,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.staffBannerBack,
                      style: const TextStyle(
                        color: staffModeInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: staffModeInk),
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

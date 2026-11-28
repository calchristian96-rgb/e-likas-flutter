import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/sheet_tokens.dart';
import '../../features/staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../l10n/app_localizations.dart';

/// Staff Mode is overprinted in solid ink with paper text (14.6:1): no
/// state colour is borrowed for it (amber would read as a barangay on
/// Watch). The names are kept so existing callers keep compiling.
const staffModeAmber = Sheet.ink;
const staffModeInk = Sheet.paper;

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
      value: SystemUiOverlayStyle.light,
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
                          fontFamily: Sheet.bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.staffBannerBack.toUpperCase(),
                      semanticsLabel: l10n.staffBannerBack,
                      style: SheetText.label(Sheet.nightSiennaText, size: 16)
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Sheet.nightSiennaText,
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_state.dart';
import '../../domain/entities/staff_session.dart';
import '../pages/staff_login_page.dart';
import '../providers/staff_auth_provider.dart';

/// Gate for every staff screen beyond the login page itself
/// (Workspace, Register Family, Pending Registrations, ...).
///
/// This is a per-screen guard rather than a `GoRouter.redirect` — the
/// app's router (`app/router/app_router.dart`) is a plain top-level
/// `GoRouter` with no redirect logic and no Riverpod container
/// reference today, and restructuring it just for this would touch
/// working, unrelated navigation code. Wrapping each staff screen's
/// body in this instead is additive: no signed-in session → show the
/// login screen in its place; loading/error → a small inline state,
/// never a crash or a blank screen.
class StaffAuthGuard extends ConsumerWidget {
  const StaffAuthGuard({super.key, required this.builder});

  final Widget Function(BuildContext context, StaffSession session) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(staffAuthProvider);

    return authState.when(
      data: (session) {
        if (session == null) return const StaffLoginPage();
        return builder(context, session);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: 'Could not check your staff sign-in status.',
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../env/env.dart';

/// An unmissable "you are not talking to production" strip, shown
/// above every screen in the app — wired in once via
/// `MaterialApp.router`'s `builder`, not any individual page — whenever
/// the effective backend isn't [Env.compiledDefaultApiBaseUrl] (the
/// real production URL). Covers both ways this app can end up pointed
/// away from production the same way: a `--dart-define` at build time,
/// and the persistent runtime override (see
/// `BackendOverrideService`) — a tester asking "which backend am I
/// actually hitting?" needs the same answer either way.
///
/// Never rendered in a release build, full stop — checked here too,
/// independently of `Env.apiBaseUrl` already resolving to the
/// compiled default in that case: this is exactly the kind of thing
/// that must be structurally impossible to accidentally ship visible
/// to a resident, not just true in practice today.
class DevModeBanner extends StatelessWidget {
  const DevModeBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode || Env.apiBaseUrl == Env.compiledDefaultApiBaseUrl) {
      return child;
    }

    return Column(
      children: [
        Material(
          color: const Color(0xFFB3261E),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DEV MODE — not production — ${Env.apiBaseUrl}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

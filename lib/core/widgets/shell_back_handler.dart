import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Android back on a tab's first screen. A page opened inside a tab is
/// closed by its own navigator first (back returns to the previous
/// screen); only when a tab has nothing left to close does this decide:
/// on any tab but Home, back goes to Home; on Home, the first back says
/// "Press back again to exit" and a second one within 2 seconds closes
/// the app, so it is never closed by accident.
class ShellBackHandler extends StatefulWidget {
  const ShellBackHandler({
    super.key,
    required this.navigationShell,
    required this.homeBranch,
    required this.child,
  });

  final StatefulNavigationShell navigationShell;

  /// The branch index of the Home tab.
  final int homeBranch;
  final Widget child;

  @override
  State<ShellBackHandler> createState() => _ShellBackHandlerState();
}

class _ShellBackHandlerState extends State<ShellBackHandler> {
  static const _exitWindow = Duration(seconds: 2);
  DateTime? _lastBackOnHome;

  void _onBack() {
    final shell = widget.navigationShell;
    if (shell.currentIndex != widget.homeBranch) {
      shell.goBranch(widget.homeBranch);
      return;
    }
    final now = DateTime.now();
    final last = _lastBackOnHome;
    if (last != null && now.difference(last) < _exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBackOnHome = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pressBackAgainToExit),
          duration: _exitWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}

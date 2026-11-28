import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/result.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/staff_auth_provider.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/lock_note.dart';
import '../../../support/support_requests.dart';

/// Real Sanctum email/password login against `POST /auth/login` —
/// the only auth endpoint the backend exposes, so there is no
/// separate "username" flow to build.
class StaffLoginPage extends ConsumerStatefulWidget {
  const StaffLoginPage({super.key});

  @override
  ConsumerState<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends ConsumerState<StaffLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  /// The account is locked (423) or the server is in maintenance: the
  /// lock look, not the error look.
  bool _locked = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isOnline = await ref.read(connectivityServiceProvider).hasConnection;
    if (!isOnline) {
      setState(() => _errorMessage = l10n.staffLoginOfflineTitle);
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(staffAuthProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result case Failed(:final failure)) {
      setState(() {
        _errorMessage = failure.message;
        _locked =
            failure is AccountLockedFailure || failure is MaintenanceFailure;
      });
      return;
    }

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffLoginTitle)),
      // The one primary action, fixed at the bottom above the keyboard.
      bottomNavigationBar: BottomActionBar(
        children: [
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.staffLoginButton),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: ElikasLogo(size: 72)),
                const SizedBox(height: 16),
                Text(
                  l10n.staffLoginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                const MaintenanceNote(),
                if (_errorMessage != null) ...[
                  if (_locked)
                    LockNote(message: _errorMessage)
                  else
                    _LoginErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  // Email or username: never validated as an email.
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: l10n.staffLoginEmailLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.staffLoginEmailLabel;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: l10n.staffLoginPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.staffLoginPasswordLabel;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../../core/network/staff_api_error_mapper.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/staff_auth_provider.dart';

/// First sign-in with a temporary password: choose your own before
/// anything else (`must_change_password`, or a 403
/// `password_change_required`). `POST /auth/password` (at least 10
/// characters, different from the current one); the other sessions of
/// the account end, this one stays.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _currentError = null;
    });
    try {
      final response = await ref
          .read(staffApiClientProvider)
          .post(
            '/auth/password',
            data: {
              'current_password': _current.text,
              'password': _new.text,
              'password_confirmation': _confirm.text,
            },
          );
      final data = (response.data as Map<String, dynamic>)['data'];
      final user = data is Map<String, dynamic>
          ? (data['user'] as Map<String, dynamic>? ?? data)
          : null;
      await ref.read(staffAuthProvider.notifier).passwordChanged(user);
    } on DioException catch (e) {
      final failure = mapStaffDioError(e);
      setState(() {
        if (failure is ValidationFailure &&
            failure.fieldErrors['current_password'] != null) {
          _currentError = failure.fieldErrors['current_password']!.join(' ');
        } else if (failure is ValidationFailure &&
            failure.fieldErrors['password'] != null) {
          _error = failure.fieldErrors['password']!.join(' ');
        } else {
          _error = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    InputDecoration deco(String label, {String? error}) => InputDecoration(
      labelText: label,
      errorText: error,
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        tooltip: l10n.passwordShow,
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.passwordChangeTitle),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(staffAuthProvider.notifier).logout(),
            child: Text(l10n.staffWorkspaceLogout),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: pagePadding(context),
          children: [
            Icon(
              Icons.password,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(l10n.passwordChangeBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _current,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: deco(l10n.passwordCurrent, error: _currentError),
              validator: (v) => (v ?? '').isEmpty ? l10n.passwordCurrent : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _new,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: deco(l10n.passwordNew),
              validator: (v) {
                final value = v ?? '';
                if (value.length < 10) return l10n.passwordTooShort;
                if (value == _current.text) return l10n.passwordSameAsOld;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: deco(l10n.passwordConfirm),
              validator: (v) => v != _new.text ? l10n.passwordMismatch : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.passwordSave),
            ),
          ],
        ),
      ),
    );
  }
}

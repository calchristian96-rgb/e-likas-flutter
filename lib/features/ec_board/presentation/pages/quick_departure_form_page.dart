import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/departure_status.dart';
import '../../domain/entities/quick_departure_request.dart';
import '../providers/ec_board_provider.dart';
import 'add_evacuee_form_page.dart' show localizedAgeBracket;

/// Quick Departure — **online-only, never offline-queued**: see
/// `QuickDepartureRequest`'s doc comment for why (it selects specific
/// existing server records off the server's own current state, unlike
/// Add Evacuee or the sectoral/4Ps edit). `EcBoardPage` already keeps
/// this action itself off-screen (replaced by an explanatory card)
/// while offline, so reaching this page at all implies connectivity
/// was present a moment ago — this still re-checks right before
/// submitting in case it dropped in between.
class QuickDepartureFormPage extends ConsumerStatefulWidget {
  const QuickDepartureFormPage({
    super.key,
    required this.centerId,
    required this.evacuationEventId,
  });

  final int centerId;
  final int evacuationEventId;

  @override
  ConsumerState<QuickDepartureFormPage> createState() =>
      _QuickDepartureFormPageState();
}

class _QuickDepartureFormPageState
    extends ConsumerState<QuickDepartureFormPage> {
  AgeBracket? _ageBracket;
  String? _sex;
  DepartureStatus? _status;
  int _quantity = 1;
  bool _submitting = false;

  void _showSnack(String message, {required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  bool get _isSubmittable =>
      _ageBracket != null && _sex != null && _status != null && _quantity > 0;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_isSubmittable) {
      _showSnack(l10n.ecBoardQuickDepartureValidationBanner, isError: true);
      return;
    }

    setState(() => _submitting = true);
    final isOnline = await ref.read(connectivityServiceProvider).hasConnection;
    if (!isOnline) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(l10n.ecBoardQuickDepartureOfflineMessage, isError: true);
      return;
    }

    final result = await ref.read(ecBoardQuickDepartureProvider)(
      QuickDepartureRequest(
        evacuationCenterId: widget.centerId,
        evacuationEventId: widget.evacuationEventId,
        ageBracket: _ageBracket!,
        sex: _sex!,
        quantity: _quantity,
        status: _status!,
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Success(:final value):
        ref.invalidate(
          ecBoardQuickCountProvider(widget.centerId, widget.evacuationEventId),
        );
        _showSnack(
          value.isEmpty ? l10n.ecBoardQuickDepartureSuccessMessage : value,
          isError: false,
        );
        Navigator.of(context).maybePop();
      case Failed(:final failure):
        // The backend's own message already names the real available
        // count (e.g. "Only 2 matching evacuee(s) are currently here,
        // cannot mark 5 as departed.") — shown as-is rather than
        // replaced with a generic banner, since it's more actionable
        // than anything this form could say on its own.
        _showSnack(failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ecBoardQuickDepartureTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.ecBoardQuickDepartureSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.ecBoardFieldSex, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.staffRegSexMale),
                  selected: _sex == 'male',
                  onSelected: (_) => setState(() => _sex = 'male'),
                ),
                ChoiceChip(
                  label: Text(l10n.staffRegSexFemale),
                  selected: _sex == 'female',
                  onSelected: (_) => setState(() => _sex = 'female'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ecBoardFieldAgeBracket,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final bracket in ageBracketValues)
                  ChoiceChip(
                    label: Text(localizedAgeBracket(context, bracket)),
                    selected: _ageBracket == bracket,
                    onSelected: (_) => setState(() => _ageBracket = bracket),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ecBoardQuickDepartureQuantity,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: _quantity.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (value) =>
                  setState(() => _quantity = int.tryParse(value) ?? 0),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ecBoardQuickDepartureStatus,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.ecBoardQuickDepartureReturnedHome),
                  selected: _status == DepartureStatus.returnedHome,
                  onSelected: (_) =>
                      setState(() => _status = DepartureStatus.returnedHome),
                ),
                ChoiceChip(
                  label: Text(l10n.ecBoardQuickDepartureTransferred),
                  selected: _status == DepartureStatus.transferred,
                  onSelected: (_) =>
                      setState(() => _status = DepartureStatus.transferred),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.ecBoardQuickDepartureSubmitButton),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

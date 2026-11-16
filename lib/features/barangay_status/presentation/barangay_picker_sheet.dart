import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/search_field.dart';
import '../../../l10n/app_localizations.dart';
import 'barangay_status_providers.dart';

/// Pick "my barangay" once; it is kept on this device and used to show
/// the barangay's status and its centers. The list is the public
/// barangay-status list (id, name), so it works offline once fetched.
Future<void> showBarangayPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const FractionallySizedBox(
      heightFactor: 0.85,
      child: _BarangayPicker(),
    ),
  );
}

class _BarangayPicker extends ConsumerStatefulWidget {
  const _BarangayPicker();

  @override
  ConsumerState<_BarangayPicker> createState() => _BarangayPickerState();
}

class _BarangayPickerState extends ConsumerState<_BarangayPicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final board = ref.watch(barangayStatusBoardProvider);
    final chosen = ref.watch(residentBarangayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.residentBarangayPickerTitle,
            style: theme.textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SearchField(
            controller: _search,
            hintText: l10n.residentBarangaySearchHint,
            clearTooltip: l10n.clearSearch,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: board.when(
            data: (board) {
              final q = _query.trim().toLowerCase();
              final items = [
                for (final b in board.barangays)
                  if (q.isEmpty || b.name.toLowerCase().contains(q)) b,
              ]..sort((a, b) => a.name.compareTo(b.name));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final b = items[i];
                  final selected = b.id == chosen?.id;
                  return ListTile(
                    minTileHeight: 48,
                    title: Text(b.name),
                    selected: selected,
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () async {
                      await ref
                          .read(residentBarangayProvider.notifier)
                          .choose(b);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: ErrorState(
                message: l10n.residentBarangayListUnavailable,
                onRetry: () => ref.invalidate(barangayStatusBoardProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

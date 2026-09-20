import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../../../../core/env/backend_override_service.dart';
import '../../../../core/env/env.dart';

/// Hidden developer-only screen for the persistent local/staging
/// backend override (see `BackendOverrideService`) — reached only via
/// the tap sequence on Settings' "E-LIKAS" about row, never linked from
/// anywhere a resident would naturally navigate. Not localized: this is
/// developer tooling, not resident-facing UI, matching how this app's
/// existing debug-log utilities are English-only too.
///
/// Guards `kReleaseMode` itself, redundantly with the tap trigger that
/// reaches it (see `SettingsPage`) — this is exactly the kind of screen
/// that must stay unreachable in a release build through more than one
/// independent check.
class DevSettingsPage extends StatefulWidget {
  const DevSettingsPage({super.key});

  @override
  State<DevSettingsPage> createState() => _DevSettingsPageState();
}

class _DevSettingsPageState extends State<DevSettingsPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: BackendOverrideService.overrideUrl ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showRestartReminder(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      await _clear();
      return;
    }
    await BackendOverrideService.setOverride(value);
    if (!mounted) return;
    setState(() {});
    _showRestartReminder(
      'Override saved. Fully close and reopen the app (not just hot '
      'reload/restart) for this to take effect.',
    );
  }

  Future<void> _clear() async {
    await BackendOverrideService.clearOverride();
    _controller.clear();
    if (!mounted) return;
    setState(() {});
    _showRestartReminder(
      'Override cleared — will use the compiled default next launch. '
      'Fully close and reopen the app for this to take effect.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      // Unreachable in practice — the tap trigger that leads here is
      // itself gated on kReleaseMode — kept as a second, independent
      // stop rather than trusting that alone.
      return const Scaffold(body: Center(child: Text('Not available.')));
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Developer: Backend URL')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Overrides which backend this app talks to, persisted on '
              'this device across app restarts — for local/staging '
              'testing only. Never active in a release build, '
              'regardless of what\'s saved here.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _InfoRow(
              label: 'Compiled default (production unless built with '
                  '--dart-define)',
              value: Env.compiledDefaultApiBaseUrl,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Currently effective',
              value: Env.apiBaseUrl,
            ),
            const Divider(height: 32),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Override base URL',
                hintText: 'http://192.168.1.7:8000/api/v1/',
                border: OutlineInputBorder(),
                helperText:
                    'Include the trailing slash and /api/v1/ path — '
                    'leave blank and save to clear the override.',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save override'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: const Text('Clear override'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A red banner appears at the top of every screen whenever '
              'the effective backend isn\'t production, whether that\'s '
              'from this override or a --dart-define build.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/lock_note.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';

/// One of the user's own problem reports (`GET /support-requests/mine`).
class SupportRequest {
  const SupportRequest({
    required this.id,
    required this.whatHappened,
    required this.status,
    this.statusLabel,
    this.reply,
    this.repliedBy,
    this.createdAt,
    this.hasScreenshot = false,
  });

  factory SupportRequest.fromJson(Map<String, dynamic> j) => SupportRequest(
    id: (j['id'] as num).toInt(),
    whatHappened: j['what_happened'] as String? ?? '',
    status: j['status'] as String? ?? 'new',
    statusLabel: j['status_label'] as String?,
    reply: j['reply'] as String?,
    repliedBy: j['replied_by'] is Map
        ? (j['replied_by'] as Map)['name'] as String?
        : j['replied_by'] as String?,
    createdAt: parseServerTime(j['created_at']),
    hasScreenshot: j['has_screenshot'] == true,
  );

  final int id;
  final String whatHappened;

  /// new | in_progress | resolved
  final String status;
  final String? statusLabel;
  final String? reply;
  final String? repliedBy;
  final DateTime? createdAt;
  final bool hasScreenshot;
}

final mySupportRequestsProvider =
    FutureProvider.autoDispose<List<SupportRequest>>((ref) async {
      final response = await ref
          .watch(staffApiClientProvider)
          .get('/support-requests/mine');
      final data = (response.data as Map<String, dynamic>)['data'];
      final rows = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? const [];
      return [
        for (final r in rows)
          SupportRequest.fromJson(r as Map<String, dynamic>),
      ];
    });

/// Picks a photo; a seam so tests never open the camera.
typedef PhotoPicker = Future<XFile?> Function(ImageSource source);

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) =>
      (source) => ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      ),
);

/// The screens a report can be about (`page`).
const supportPages = [
  'Home',
  'EC Board',
  'Register family',
  'Families to evacuate',
  'Relief boxes',
  'Facility requests',
  'Final count',
  'Transfers',
  'Sync',
  'Sign in',
  'Other',
];

/// "Report a problem" (CSWD and officials, `support.report`): what
/// happened, the screen, and an optional photo from the camera or the
/// gallery. Online only. The administrator answers; the reply shows
/// under "Your reports".
class ReportProblemPage extends ConsumerStatefulWidget {
  const ReportProblemPage({super.key});

  @override
  ConsumerState<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends ConsumerState<ReportProblemPage> {
  final _what = TextEditingController();
  String _page = supportPages.first;
  XFile? _photo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _what.dispose();
    super.dispose();
  }

  bool get _valid {
    final n = _what.text.trim().length;
    return n >= 10 && n <= 2000;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final photo = await ref.read(photoPickerProvider)(source);
      if (photo != null && mounted) setState(() => _photo = photo);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).reportPhotoFailed);
      }
    }
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      setState(() => _error = l10n.reportNeedsConnection);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final form = FormData.fromMap({
        'what_happened': _what.text.trim(),
        'page': _page,
        'source': 'mobile',
        if (_photo != null)
          'screenshot': await MultipartFile.fromFile(
            _photo!.path,
            filename: _photo!.name,
          ),
      });
      await ref
          .read(staffApiClientProvider)
          .post(
            '/support-requests',
            data: form,
            timeout: const Duration(seconds: 60),
          );
      ref.invalidate(mySupportRequestsProvider);
      if (!mounted) return;
      setState(() {
        _what.clear();
        _photo = null;
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.reportSent)));
    } on DioException catch (e) {
      setState(() => _error = mapStaffDioError(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mine = ref.watch(mySupportRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportTitle)),
      body: ListView(
        padding: pagePadding(context),
        children: [
          Text(l10n.reportIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _what,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: l10n.reportWhatHappened,
              helperText: l10n.reportWhatHappenedHint,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _page,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.reportScreen,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final p in supportPages)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) => setState(() => _page = v ?? _page),
          ),
          const SizedBox(height: 16),
          Text(l10n.reportPhoto, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(l10n.reportPhotoPrivacy, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          if (_photo != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined),
              title: Text(_photo!.name),
              trailing: IconButton(
                tooltip: l10n.reportPhotoRemove,
                onPressed: () => setState(() => _photo = null),
                icon: const Icon(Icons.close),
              ),
            )
          else
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.reportPhotoCamera),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.reportPhotoGallery),
                ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _valid && !_busy ? _send : null,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.reportSend),
          ),
          SectionTitle(l10n.reportYours),
          ...mine.when(
            loading: () => [const LinearProgressIndicator()],
            error: (_, _) => [
              Text(
                l10n.reportNeedsConnection,
                style: theme.textTheme.bodySmall,
              ),
            ],
            data: (list) => list.isEmpty
                ? [Text(l10n.reportNone, style: theme.textTheme.bodySmall)]
                : [
                    for (final r in list)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            r.whatHappened,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              r.statusLabel ?? r.status,
                              if (r.createdAt != null)
                                formatShortDateTime(r.createdAt!),
                              if ((r.reply ?? '').isNotEmpty)
                                l10n.reportReply(r.repliedBy ?? '', r.reply!),
                            ].join('\n'),
                          ),
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}

/// A technical notice from the administrator (`GET /system-notices`).
class SystemNotice {
  const SystemNotice({
    required this.id,
    required this.title,
    required this.message,
  });

  final int id;
  final String title;
  final String message;
}

/// The notices showing now; empty when they cannot be read.
final systemNoticesProvider = FutureProvider.autoDispose<List<SystemNotice>>((
  ref,
) async {
  try {
    final response = await ref
        .watch(staffApiClientProvider)
        .get('/system-notices');
    final data = (response.data as Map<String, dynamic>)['data'];
    final rows = data is List
        ? data
        : (data as Map<String, dynamic>?)?['notices'] as List? ?? const [];
    return [
      for (final n in rows)
        SystemNotice(
          id: ((n as Map<String, dynamic>)['id'] as num).toInt(),
          title: n['title'] as String? ?? '',
          message: n['message'] as String? ?? '',
        ),
    ];
  } catch (_) {
    return const [];
  }
});

/// Notices closed on this phone for this run (there is nothing to mark
/// as read on the server).
class _ClosedNotices extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void close(int id) => state = {...state, id};
}

final _closedNoticesProvider = NotifierProvider<_ClosedNotices, Set<int>>(
  _ClosedNotices.new,
);

/// The administrator's notices as a banner above Staff Mode.
class SystemNoticesBanner extends ConsumerWidget {
  const SystemNoticesBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final closed = ref.watch(_closedNoticesProvider);
    final notices = [
      for (final n in ref.watch(systemNoticesProvider).value ?? const [])
        if (!closed.contains(n.id)) n,
    ];
    if (notices.isEmpty) return const SizedBox.shrink();
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            for (final n in notices)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          if (n.message.isNotEmpty)
                            Text(
                              n.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.dismiss,
                      onPressed: () =>
                          ref.read(_closedNoticesProvider.notifier).close(n.id),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The server's maintenance message before signing in
/// (`GET /public/system-status`), or null.
final maintenanceMessageProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  try {
    final response = await ref
        .watch(staffApiClientProvider)
        .get('/public/system-status');
    final data =
        (response.data as Map<String, dynamic>)['data'] ?? response.data;
    final m = (data as Map<String, dynamic>)['maintenance'] as Map?;
    if (m?['enabled'] != true) return null;
    return (m?['message'] as String?) ?? '';
  } catch (_) {
    return null;
  }
});

/// The maintenance message on the sign-in screen, with the lock look.
class MaintenanceNote extends ConsumerWidget {
  const MaintenanceNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final message = ref.watch(maintenanceMessageProvider).value;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LockNote(
        message: message.isEmpty ? l10n.maintenanceDefault : message,
      ),
    );
  }
}

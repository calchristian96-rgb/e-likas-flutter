import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/debug/center_photo_debug_log.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/entities/evacuation_center_draft.dart';
import '../providers/staff_evacuation_centers_provider.dart';
import 'center_location_picker_page.dart';

/// One reusable form for both Add and Edit Evacuation Center —
/// [editingCenter] null means create mode. Online-only throughout (see
/// this feature's top-level doc comment): there is no offline draft,
/// no pending queue, nothing persisted until the server confirms it.
class EvacuationCenterFormPage extends StatelessWidget {
  const EvacuationCenterFormPage({super.key, this.editingCenter});

  final EvacuationCenter? editingCenter;

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) => _EvacuationCenterFormBody(
        session: session,
        editingCenter: editingCenter,
      ),
    );
  }
}

class _EvacuationCenterFormBody extends ConsumerStatefulWidget {
  const _EvacuationCenterFormBody({required this.session, this.editingCenter});

  final StaffSession session;
  final EvacuationCenter? editingCenter;

  @override
  ConsumerState<_EvacuationCenterFormBody> createState() =>
      _EvacuationCenterFormBodyState();
}

class _EvacuationCenterFormBodyState
    extends ConsumerState<_EvacuationCenterFormBody> {
  late EvacuationCenterDraft _draft;
  late final bool _initialHadLocation;
  Map<String, List<String>> _fieldErrors = {};
  bool _submitting = false;
  bool _dirty = false;
  File? _newPhotoFile;

  bool get _isEditing => widget.editingCenter != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingCenter;
    _draft = editing != null
        ? EvacuationCenterDraft.fromEntity(editing)
        : const EvacuationCenterDraft();
    _initialHadLocation = _draft.hasLocation;

    // A barangay official's own barangay is server-locked on both
    // create and update — the client-submitted `barangay_id` is
    // silently overridden either way (confirmed against
    // `EvacuationCenterController::store()`/`update()`). Pre-filling
    // it here is a convenience, not a real choice, which is exactly
    // why the barangay field renders read-only for this role below.
    if (widget.session.isBarangayOfficial &&
        widget.session.barangayId != null) {
      _draft = _draft.copyWith(barangayId: widget.session.barangayId);
    }
  }

  void _updateDraft(
    EvacuationCenterDraft Function(EvacuationCenterDraft) update,
  ) {
    setState(() {
      _draft = update(_draft);
      _dirty = true;
    });
  }

  Future<void> _chooseLocation() async {
    final result = await Navigator.of(context).push<CenterLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => CenterLocationPickerPage(
          initialLatitude: _draft.latitude,
          initialLongitude: _draft.longitude,
        ),
      ),
    );
    if (result == null) return; // back/cancel — no change
    if (result.cleared) {
      _updateDraft((d) => d.copyWith(clearLocation: true));
    } else {
      _updateDraft(
        (d) =>
            d.copyWith(latitude: result.latitude, longitude: result.longitude),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.centerTakePhoto),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.centerChooseFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    // Downscaled client-side rather than relying on the backend's
    // 5MB cap alone — a modern phone camera photo can comfortably
    // exceed that before any compression, so this avoids a
    // predictable 422 on a perfectly reasonable photo.
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return; // cancelled — safe no-op

    final file = File(picked.path);
    centerPhotoDebugLog(
      'picked photo file exists=${await file.exists()} '
      'filename=${picked.name} file size=${await file.length()}',
    );
    setState(() {
      _newPhotoFile = file;
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.centerDiscardDialogTitle),
        content: Text(l10n.centerDiscardDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.centerDiscardDialogConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message, {required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _fieldErrors = {});

    if (!_draft.isSubmittable) {
      _showSnack(l10n.centerValidationBanner, isError: true);
      return;
    }

    setState(() => _submitting = true);
    final locationWasCleared = _initialHadLocation && !_draft.hasLocation;
    centerPhotoDebugLog(
      'mode=${_isEditing ? 'edit' : 'create'} '
      'photo selected=${_newPhotoFile != null}',
    );

    final result = _isEditing
        ? await ref.read(updateEvacuationCenterProvider)(
            id: widget.editingCenter!.id,
            draft: _draft,
            photo: _newPhotoFile,
            locationWasCleared: locationWasCleared,
          )
        : await ref.read(createEvacuationCenterProvider)(
            draft: _draft,
            photo: _newPhotoFile,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Success(:final value):
        centerPhotoDebugLog('submit result entity.photoUrl=${value.photoUrl}');
        _dirty = false;
        // Every provider a resident/staff screen could be showing
        // stale center data from — refreshed rather than left to
        // silently disagree with what the server just confirmed.
        ref.invalidate(allEvacuationCentersProvider);
        if (_isEditing) {
          ref.invalidate(staffCenterDetailProvider(widget.editingCenter!.id));
        }
        _showSnack(
          _isEditing
              ? l10n.centerUpdateSuccessMessage
              : l10n.centerCreateSuccessMessage,
          isError: false,
        );
        Navigator.of(context).pop();
      case Failed(:final failure):
        if (failure is ValidationFailure) {
          setState(() => _fieldErrors = failure.fieldErrors);
          _showSnack(l10n.centerValidationBanner, isError: true);
        } else if (failure is NetworkFailure) {
          // Covers both "genuinely offline" (the repository's own
          // connectivity guard) and "online but the request itself
          // failed" (DNS/timeout/connection error) — `Failure.message`
          // is set English-only in the data layer (no BuildContext
          // there to localize from, same convention every other
          // repository in this app follows), so the localized
          // equivalent is substituted here instead of shown raw.
          _showSnack(l10n.centerOfflineRequired, isError: true);
        } else {
          _showSnack(failure.message, isError: true);
        }
    }
  }

  List<String>? _errorsFor(String field) => _fieldErrors[field];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final barangaysAsync = ref.watch(barangaysProvider);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? l10n.centerEditEvacuationCenter
                : l10n.staffAddEvacuationCenter,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.centerSectionInformation,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _draft.name,
                decoration: InputDecoration(
                  labelText: l10n.centerFieldName,
                  border: const OutlineInputBorder(),
                  errorText: _errorsFor('name')?.join(' '),
                ),
                onChanged: (value) =>
                    _updateDraft((d) => d.copyWith(name: value)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _draft.type,
                decoration: InputDecoration(
                  labelText: l10n.centerFieldType,
                  border: const OutlineInputBorder(),
                  errorText: _errorsFor('type')?.join(' '),
                ),
                items: [
                  for (final type in evacuationCenterTypeValues)
                    DropdownMenuItem(
                      value: type,
                      child: Text(localizedCenterType(context, type)),
                    ),
                ],
                onChanged: (value) =>
                    _updateDraft((d) => d.copyWith(type: value)),
              ),
              const SizedBox(height: 12),
              _BarangayField(
                session: widget.session,
                barangaysAsync: barangaysAsync,
                value: _draft.barangayId,
                errors: _errorsFor('barangay_id'),
                onChanged: (id) =>
                    _updateDraft((d) => d.copyWith(barangayId: id)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _draft.address,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.centerFieldAddress,
                  border: const OutlineInputBorder(),
                  errorText: _errorsFor('address')?.join(' '),
                ),
                onChanged: (value) =>
                    _updateDraft((d) => d.copyWith(address: value)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _draft.status,
                decoration: InputDecoration(
                  labelText: l10n.centerFieldStatus,
                  border: const OutlineInputBorder(),
                  errorText: _errorsFor('status')?.join(' '),
                ),
                items: [
                  for (final status in const [
                    'active',
                    'on_standby',
                    'full',
                    'closed',
                  ])
                    DropdownMenuItem(
                      value: status,
                      child: Text(localizedCenterStatus(context, status)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateDraft((d) => d.copyWith(status: value));
                  }
                },
              ),
              const Divider(height: 32),
              Text(
                l10n.centerSectionLocation,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _LocationSummaryCard(
                draft: _draft,
                errors: _errorsFor('latitude') ?? _errorsFor('longitude'),
                onChoose: _chooseLocation,
              ),
              const Divider(height: 32),
              Text(
                l10n.centerSectionCapacity,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _draft.capacityFamilies?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.centerFieldCapacityFamilies,
                        border: const OutlineInputBorder(),
                        errorText: _errorsFor('capacity_families')?.join(' '),
                      ),
                      onChanged: (value) => _updateDraft(
                        (d) => d.copyWith(
                          capacityFamilies: int.tryParse(value),
                          clearCapacityFamilies: value.trim().isEmpty,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: _draft.capacityPersons?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.overviewCapacity,
                        border: const OutlineInputBorder(),
                        errorText: _errorsFor('capacity_persons')?.join(' '),
                      ),
                      onChanged: (value) => _updateDraft(
                        (d) => d.copyWith(
                          capacityPersons: int.tryParse(value),
                          clearCapacityPersons: value.trim().isEmpty,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                l10n.centerFieldCampManager,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _draft.campManagerName,
                decoration: InputDecoration(
                  labelText: l10n.centerFieldCampManagerName,
                  border: const OutlineInputBorder(),
                  errorText: _errorsFor('camp_manager_name')?.join(' '),
                ),
                onChanged: (value) => _updateDraft(
                  (d) => d.copyWith(
                    campManagerName: value,
                    clearCampManagerName: value.trim().isEmpty,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _draft.campManagerContact,
                // Plain phone-friendly keyboard only — no PH mobile
                // regex enforced here, since the backend's own rule
                // for this field is just `string|max:20`, not the
                // stricter pattern the family-registration contact
                // number field uses. Applying that stricter rule here
                // would be a Flutter-invented restriction the backend
                // doesn't actually have.
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.centerFieldCampManagerContact,
                  border: const OutlineInputBorder(),
                  errorText: _errorsFor('camp_manager_contact')?.join(' '),
                ),
                onChanged: (value) => _updateDraft(
                  (d) => d.copyWith(
                    campManagerContact: value,
                    clearCampManagerContact: value.trim().isEmpty,
                  ),
                ),
              ),
              const Divider(height: 32),
              Text(
                l10n.centerFieldPhoto,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _PhotoPickerField(
                newPhotoFile: _newPhotoFile,
                existingPhotoUrl: widget.editingCenter?.photoUrl,
                onChoose: _pickPhoto,
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
                    : Text(
                        _isEditing
                            ? l10n.centerSaveChanges
                            : l10n.centerCreateEvacuationCenter,
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only for a barangay official (server-locked to their own
/// barangay either way, per `EvacuationCenterController`) — a live
/// editable dropdown for that role would be misleading, not just
/// redundant. Administrator/CSWD personnel get the real cached/live
/// barangay list, reused from the staff family-registration feature
/// (`barangaysProvider`) rather than a second lookup for the same
/// data, and never a hardcoded Ligao barangay list.
class _BarangayField extends StatelessWidget {
  const _BarangayField({
    required this.session,
    required this.barangaysAsync,
    required this.value,
    required this.errors,
    required this.onChanged,
  });

  final StaffSession session;
  final AsyncValue<List<dynamic>> barangaysAsync;
  final int? value;
  final List<String>? errors;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (session.isBarangayOfficial) {
      return TextFormField(
        initialValue: session.barangayName ?? l10n.centerFieldBarangay,
        enabled: false,
        decoration: InputDecoration(
          labelText: l10n.centerFieldBarangay,
          border: const OutlineInputBorder(),
          helperText: l10n.centerBarangayLockedHelper,
        ),
      );
    }
    return barangaysAsync.when(
      data: (barangays) => DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: l10n.centerFieldBarangay,
          border: const OutlineInputBorder(),
          errorText: errors?.join(' '),
        ),
        items: [
          for (final barangay in barangays)
            DropdownMenuItem(
              value: barangay.id as int,
              child: Text(barangay.name as String),
            ),
        ],
        onChanged: onChanged,
      ),
      loading: () => const LinearProgressIndicator(),
      error: (error, stackTrace) => Text(
        l10n.staffRegLookupUnavailable,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _LocationSummaryCard extends StatelessWidget {
  const _LocationSummaryCard({
    required this.draft,
    required this.errors,
    required this.onChoose,
  });

  final EvacuationCenterDraft draft;
  final List<String>? errors;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasLocation = draft.hasLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation
                    ? Icons.place_outlined
                    : Icons.location_off_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLocation
                      ? '${draft.latitude}, ${draft.longitude}'
                      : l10n.centerNoLocationSet,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: onChoose,
                child: Text(
                  hasLocation
                      ? l10n.centerChangeLocation
                      : l10n.centerChooseLocation,
                ),
              ),
            ],
          ),
        ),
        if (errors != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errors!.join(' '),
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _PhotoPickerField extends ConsumerWidget {
  const _PhotoPickerField({
    required this.newPhotoFile,
    required this.existingPhotoUrl,
    required this.onChoose,
  });

  final File? newPhotoFile;
  final String? existingPhotoUrl;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: newPhotoFile != null
                ? Image.file(
                    newPhotoFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _photoPlaceholder(context, l10n),
                  )
                : (existingPhotoUrl == null || existingPhotoUrl!.isEmpty)
                ? _photoPlaceholder(context, l10n)
                : Image.network(
                    existingPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _photoPlaceholder(context, l10n),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onChoose,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(
            newPhotoFile != null ||
                    (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty)
                ? l10n.centerChangePhoto
                : l10n.centerChoosePhoto,
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.centerPhotoUnavailable,
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

import 'age_bracket.dart';
import 'departure_status.dart';

/// One `POST /evacuation-centers/{id}/quick-departure` request —
/// **online-only, never queued offline** (see
/// `EcBoardRepository.quickDeparture`'s doc comment for why): unlike
/// Add Evacuee or the sectoral/4Ps edit, this selects SPECIFIC existing
/// records off the server's own current state (oldest-arrival-first
/// among whoever matches), so a stale local view could depart the
/// wrong people or double-process a departure the server already saw
/// from another device.
class QuickDepartureRequest {
  const QuickDepartureRequest({
    required this.evacuationCenterId,
    required this.evacuationEventId,
    required this.ageBracket,
    required this.sex,
    required this.quantity,
    required this.status,
  });

  final int evacuationCenterId;
  final int evacuationEventId;
  final AgeBracket ageBracket;

  /// 'male' | 'female'.
  final String sex;
  final int quantity;
  final DepartureStatus status;

  Map<String, dynamic> toJson() => {
    'evacuation_event_id': evacuationEventId,
    'age_bracket': ageBracket.wireValue,
    'sex': sex,
    'quantity': quantity,
    'status': status.wireValue,
  };
}

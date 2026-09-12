/// A single emergency contact number, shown on the Emergency Hotlines
/// page.
///
/// Pure Dart, no Flutter dependency — [category] is used by the
/// presentation layer to choose an icon and color (see
/// `hotline_card.dart`), the same pattern the Map feature already uses
/// for hazard-type colors, rather than baking a Flutter `IconData`
/// into the domain layer itself.
class Hotline {
  const Hotline({
    required this.name,
    required this.number,
    required this.description,
    required this.category,
  });

  final String name;
  final String number;
  final String description;
  final HotlineCategory category;

  /// [number] with every non-dialable display character stripped —
  /// spaces and hyphens (`0998 598 5928` / `0998-598-5928` both become
  /// `09985985928`) — safe to hand straight to a `tel:` URI regardless
  /// of which display format a given entry happens to use. A leading
  /// `+` is preserved so a `+63` number still dials correctly.
  String get dialableNumber => number.replaceAll(RegExp(r'[\s-]'), '');
}

enum HotlineCategory {
  nationalEmergency,
  disasterResponse,
  fire,
  police,
  medical,
  rescue,
  socialWelfare,
  utility,
}

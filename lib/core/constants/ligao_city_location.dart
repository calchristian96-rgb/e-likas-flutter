/// Ligao City, Albay's approximate town-center coordinates — the one
/// shared source of truth for every feature that needs a Ligao City
/// location and doesn't have anything more specific to use (the GIS
/// map's fallback center when no real center data has loaded yet, and
/// the staff evacuation-center location picker's fallback center for
/// a brand-new center with no location set yet).
///
/// Deliberately not derived from the resident's live GPS position —
/// this is a fixed reference point, not something that should shift
/// depending on exactly where within the city a resident is standing.
class LigaoCityLocation {
  LigaoCityLocation._();

  static const double latitude = 13.1391;
  static const double longitude = 123.5333;
}

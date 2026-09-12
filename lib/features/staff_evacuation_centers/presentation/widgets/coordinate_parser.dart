/// A successfully-parsed `latitude, longitude` pair — values are
/// exactly what `double.tryParse` produced from the input text, never
/// rounded or reformatted, so what staff pasted is exactly what gets
/// submitted (subject only to Dart `double` representation).
class ParsedCoordinates {
  const ParsedCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Parses a Google-Maps-style "latitude, longitude" paste — e.g.
/// `13.139123, 123.532145` — into [ParsedCoordinates], or `null` if
/// [input] isn't a valid pair. Deliberately permissive about
/// whitespace and decimal-place count, strict about everything else:
///
/// - must split into exactly two comma-separated parts
/// - both parts must parse as numbers (`double.tryParse`)
/// - latitude must be in `[-90, 90]`, longitude in `[-180, 180]`
///
/// Rejects (never throws, never partially updates a caller's state):
/// a single number, space-separated numbers with no comma, non-numeric
/// text, a third comma-separated value, an out-of-range value, and
/// blank input.
ParsedCoordinates? parseCoordinates(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split(',');
  if (parts.length != 2) return null;

  final latitude = double.tryParse(parts[0].trim());
  final longitude = double.tryParse(parts[1].trim());
  if (latitude == null || longitude == null) return null;

  if (latitude < -90 || latitude > 90) return null;
  if (longitude < -180 || longitude > 180) return null;

  return ParsedCoordinates(latitude: latitude, longitude: longitude);
}

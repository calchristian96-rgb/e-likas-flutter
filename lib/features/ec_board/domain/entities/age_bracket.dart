/// The 7 age brackets the backend's EC Information Board endpoints use
/// (`POST /evacuation-centers/{id}/evacuees`'s `age_bracket` field,
/// `GET .../quick-count`'s breakdown) — the same vocabulary already
/// confirmed server-side for `Evacuee::getAgeBracketAttribute()`.
enum AgeBracket {
  infant,
  toddler,
  preschooler,
  schoolAge,
  teenage,
  adult,
  seniorCitizen;

  String get wireValue => switch (this) {
    AgeBracket.infant => 'infant',
    AgeBracket.toddler => 'toddler',
    AgeBracket.preschooler => 'preschooler',
    AgeBracket.schoolAge => 'school_age',
    AgeBracket.teenage => 'teenage',
    AgeBracket.adult => 'adult',
    AgeBracket.seniorCitizen => 'senior_citizen',
  };

  static AgeBracket? fromWire(String? value) => switch (value) {
    'infant' => AgeBracket.infant,
    'toddler' => AgeBracket.toddler,
    'preschooler' => AgeBracket.preschooler,
    'school_age' => AgeBracket.schoolAge,
    'teenage' => AgeBracket.teenage,
    'adult' => AgeBracket.adult,
    'senior_citizen' => AgeBracket.seniorCitizen,
    _ => null,
  };
}

/// Fixed display order for every bracket-driven UI (Add Evacuee's
/// picker, the quick-count breakdown table) — youngest to oldest,
/// matching the DROMIC/EC Information Board template's own ordering.
const ageBracketValues = AgeBracket.values;

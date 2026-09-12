import 'hotline.dart';

/// Ligao City's official emergency contact numbers, as static
/// application data — no network request, no local database. This is
/// deliberately the entire "data layer" for this feature: there's
/// nothing to fetch, cache, or synchronize, so a repository/datasource
/// pair would be an abstraction with nothing to abstract.
///
/// Numbers verified against a real, current hotline reference photo
/// supplied directly by the user — PNP, BFP Ligao, CDRRMO, JBDAPH
/// Tuburan, CSWDO, and LCWD all reflect that photo exactly (display
/// formatting normalized to this list's existing space-separated style
/// for visual consistency; the digits themselves are unchanged from the
/// photo). National Emergency (911) and both Special Rescue Unit lines
/// were not in that photo and are preserved unchanged, per the explicit
/// instruction to keep existing contacts that a new reference photo
/// simply doesn't happen to repeat.
const List<Hotline> emergencyHotlines = [
  Hotline(
    name: 'National Emergency',
    number: '911',
    description: 'For any life-threatening emergency, nationwide.',
    category: HotlineCategory.nationalEmergency,
  ),
  Hotline(
    name: 'CDRRMO Operations Center',
    number: '0956 635 2627',
    description: "Ligao City's disaster response and coordination center.",
    category: HotlineCategory.disasterResponse,
  ),
  Hotline(
    name: 'CDRRMO EQRT',
    number: '0962 289 9037',
    description:
        'Emergency Quick Response Team for immediate disaster response.',
    category: HotlineCategory.disasterResponse,
  ),
  Hotline(
    name: 'Bureau of Fire Protection – Ligao',
    number: '0963 702 6628',
    description: 'Fire emergencies and fire-related rescue.',
    category: HotlineCategory.fire,
  ),
  Hotline(
    name: 'Bureau of Fire Protection – Ligao (Alternate)',
    number: '0928 507 1914',
    description: 'Alternate line for Bureau of Fire Protection – Ligao.',
    category: HotlineCategory.fire,
  ),
  Hotline(
    name: 'Philippine National Police – Ligao',
    number: '0998 598 5928',
    description: 'Police assistance and law enforcement.',
    category: HotlineCategory.police,
  ),
  Hotline(
    name: 'JBDAPH Tuburan',
    number: '0945 296 2595',
    description: 'Medical emergency line serving Barangay Tuburan.',
    category: HotlineCategory.medical,
  ),
  Hotline(
    name: 'Special Rescue Unit',
    number: '0929 775 9604',
    description: 'Search, rescue, and emergency response.',
    category: HotlineCategory.rescue,
  ),
  Hotline(
    name: 'Special Rescue Unit (Alternate)',
    number: '0935 699 2804',
    description: 'Alternate line for the Special Rescue Unit.',
    category: HotlineCategory.rescue,
  ),
  Hotline(
    name: 'CSWDO',
    number: '0954 346 3393',
    description: 'City Social Welfare and Development Office of Ligao City.',
    category: HotlineCategory.socialWelfare,
  ),
  Hotline(
    name: 'CSWDO (Alternate)',
    number: '0930 643 1778',
    description: 'Alternate line for CSWDO.',
    category: HotlineCategory.socialWelfare,
  ),
  Hotline(
    name: 'LCWD',
    number: '0998 598 5928',
    description: 'Ligao City Water District.',
    category: HotlineCategory.utility,
  ),
];

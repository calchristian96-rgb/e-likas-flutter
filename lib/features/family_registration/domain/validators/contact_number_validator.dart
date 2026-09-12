/// Philippine mobile number format this app requires for every family
/// member's contact number.
///
/// Matches the backend contract exactly — confirmed directly against
/// the newest `RegisterFamilyRequest::rules()`:
/// `'members.*.contact_number' => ['required', 'string',
/// 'regex:/^(09|\+639)\d{9}$/']`. That Laravel pattern and this one
/// are the same regular language, just factored differently (the
/// backend factors out the shared `\d{9}` suffix; this one spells out
/// each full alternative) — same strings accepted, same strings
/// rejected. Enforcing it here client-side exists so an offline
/// registration with a missing/malformed number is caught before it
/// ever reaches the pending queue, rather than surfacing as a 422
/// hours later during sync — see `FamilyRegistrationFormPage`.
///
/// Accepts exactly two shapes: `09XXXXXXXXX` (11 digits, local) and
/// `+639XXXXXXXXX` (country code + 9 digits). Nothing is normalized or
/// reformatted before matching — a value with spaces/hyphens/wrong
/// digit count is rejected outright rather than silently corrected.
final RegExp phMobileNumberPattern = RegExp(r'^(09\d{9}|\+639\d{9})$');

bool isValidPhMobileNumber(String value) =>
    phMobileNumberPattern.hasMatch(value);

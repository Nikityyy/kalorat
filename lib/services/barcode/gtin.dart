/// Retail barcode numbers (GTIN): EAN-13, EAN-8, UPC-A and UPC-E.
library;

final _digits = RegExp(r'^\d+$');

/// True for an 8, 12 or 13 digit code whose check digit is right.
bool isValidGtin(String code) {
  if (!_digits.hasMatch(code)) return false;
  if (code.length != 8 && code.length != 12 && code.length != 13) {
    return false;
  }
  var sum = 0;
  for (var i = 0; i < code.length - 1; i++) {
    final digit = code.codeUnitAt(code.length - 2 - i) - 48;
    sum += i.isEven ? digit * 3 : digit;
  }
  return (10 - sum % 10) % 10 == code.codeUnitAt(code.length - 1) - 48;
}

/// The 12 digit UPC-A form of an 8 digit UPC-E code, or null.
String? expandUpcE(String code) {
  if (code.length != 8 || !_digits.hasMatch(code)) return null;
  final system = code[0];
  if (system != '0' && system != '1') return null;
  final d = code.substring(1, 7);
  final check = code[7];
  final String body;
  switch (d[5]) {
    case '0':
    case '1':
    case '2':
      body = '${d.substring(0, 2)}${d[5]}0000${d.substring(2, 5)}';
    case '3':
      body = '${d.substring(0, 3)}00000${d.substring(3, 5)}';
    case '4':
      body = '${d.substring(0, 4)}00000${d[4]}';
    default:
      body = '${d.substring(0, 5)}0000${d[5]}';
  }
  final upcA = '$system$body$check';
  return isValidGtin(upcA) ? upcA : null;
}

/// The codes to look a scanned [code] up under, best first. A UPC-A code is
/// also tried as the EAN-13 it equals (leading 0), and the reverse.
List<String> lookupCandidates(String code, {String? format}) {
  final upcE = format?.toUpperCase().replaceAll('-', '') == 'UPCE'
      ? expandUpcE(code)
      : null;
  final primary = upcE ?? code;
  return [
    primary,
    if (primary.length == 12) '0$primary',
    if (primary.length == 13 && primary.startsWith('0')) primary.substring(1),
  ];
}

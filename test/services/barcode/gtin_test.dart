import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/services/barcode/gtin.dart';

void main() {
  test('valid check digits are accepted', () {
    expect(isValidGtin('5000112674453'), isTrue); // Sprite can, EAN-13
    expect(isValidGtin('4006381333931'), isTrue); // EAN-13
    expect(isValidGtin('96385074'), isTrue); // EAN-8
    expect(isValidGtin('036000291452'), isTrue); // UPC-A
  });

  test('wrong check digits, lengths and characters are rejected', () {
    expect(isValidGtin('5000112674454'), isFalse);
    expect(isValidGtin('500011267445'), isFalse);
    expect(isValidGtin('50001126744531'), isFalse);
    expect(isValidGtin('5000112a74453'), isFalse);
    expect(isValidGtin(''), isFalse);
  });

  test('UPC-E expands to UPC-A', () {
    expect(expandUpcE('04252614'), '042100005264');
    expect(expandUpcE('01234565'), '012345000065');
    expect(expandUpcE('04252615'), isNull); // wrong check digit
    expect(expandUpcE('24252614'), isNull); // number system 2
  });

  test('lookup candidates cover the EAN-13 and UPC-A spellings', () {
    expect(lookupCandidates('5000112674453'), ['5000112674453']);
    expect(lookupCandidates('036000291452'), ['036000291452', '0036000291452']);
    expect(lookupCandidates('0036000291452'), [
      '0036000291452',
      '036000291452',
    ]);
    expect(lookupCandidates('04252614', format: 'UPCE'), [
      '042100005264',
      '0042100005264',
    ]);
    expect(lookupCandidates('96385074', format: 'EAN8'), ['96385074']);
  });
}

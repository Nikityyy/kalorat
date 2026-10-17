import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/utils/app_version.dart';

void main() {
  test('formats version with build number', () {
    expect(formatAppVersion('0.2.0', '82'), '0.2.0 (82)');
    expect(formatAppVersion('dev', ''), 'dev');
  });

  test('shortens a full commit hash to 7 characters', () {
    expect(
      shortenCommit('ca51b2ee6c7fdfce33f44c2a664f5d6697d6e68d'),
      'ca51b2e',
    );
    expect(shortenCommit('abc'), 'abc');
    expect(shortenCommit(''), '');
  });

  test('local builds without CI defines report dev', () {
    expect(AppVersion.label, 'dev');
    expect(AppVersion.shortCommit, '');
  });
}

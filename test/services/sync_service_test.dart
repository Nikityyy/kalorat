import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/services/sync_service.dart';

void main() {
  test('conflicts use strict last-write-wins semantics', () {
    final current = DateTime.utc(2026, 7, 10, 10);

    expect(
      shouldReplaceVersion(current.add(const Duration(seconds: 1)), current),
      isTrue,
    );
    expect(shouldReplaceVersion(current, current), isFalse);
    expect(
      shouldReplaceVersion(
        current.subtract(const Duration(seconds: 1)),
        current,
      ),
      isFalse,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/services/sync_service.dart';

void main() {
  group('activity level conflict resolution', () {
    final lastSync = DateTime.utc(2026, 7, 10, 10);

    test('keeps a guest user\'s local selection during account linking', () {
      expect(
        shouldUseCloudActivityLevel(
          localUserIsGuest: true,
          localLastSyncTimestamp: null,
          cloudProfileUpdatedAt: DateTime.utc(2026, 7, 11),
        ),
        isFalse,
      );
    });

    test('keeps local selection when the cloud profile predates last sync', () {
      expect(
        shouldUseCloudActivityLevel(
          localUserIsGuest: false,
          localLastSyncTimestamp: lastSync,
          cloudProfileUpdatedAt: lastSync.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('uses cloud selection when profile changed after last sync', () {
      expect(
        shouldUseCloudActivityLevel(
          localUserIsGuest: false,
          localLastSyncTimestamp: lastSync,
          cloudProfileUpdatedAt: lastSync.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('uses cloud value for established local accounts without sync time', () {
      expect(
        shouldUseCloudActivityLevel(
          localUserIsGuest: false,
          localLastSyncTimestamp: null,
          cloudProfileUpdatedAt: lastSync,
        ),
        isTrue,
      );
    });
  });

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

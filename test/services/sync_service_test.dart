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

  group('idsNeedingDownload', () {
    final local = {
      'same': DateTime.utc(2026, 7, 10, 10),
      'older': DateTime.utc(2026, 7, 10, 9),
      'newer': DateTime.utc(2026, 7, 10, 11),
    };
    Map<String, dynamic> row(String id, DateTime? updatedAt) => {
      'id': id,
      'updated_at': updatedAt?.toIso8601String(),
    };

    test('downloads only rows that are new or changed in the cloud', () {
      final ids = idsNeedingDownload([
        row('same', DateTime.utc(2026, 7, 10, 10)),
        row('older', DateTime.utc(2026, 7, 10, 10)),
        row('newer', DateTime.utc(2026, 7, 10, 10)),
        row('missing', DateTime.utc(2026, 7, 1)),
      ], (r) => local[r['id']]);
      expect(ids, ['older', 'missing']);
    });

    test('downloads a row whose cloud timestamp is unreadable', () {
      final ids = idsNeedingDownload([row('same', null)], (r) => local[r['id']]);
      expect(ids, ['same']);
    });

    test('downloads nothing when everything is up to date', () {
      final ids = idsNeedingDownload([
        row('same', DateTime.utc(2026, 7, 10, 10)),
      ], (r) => local[r['id']]);
      expect(ids, isEmpty);
    });
  });
}

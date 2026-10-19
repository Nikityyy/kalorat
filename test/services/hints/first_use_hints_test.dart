import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kalorat/services/hints/first_use_hints.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hints_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('a hint is unseen until it is dismissed, then stays seen', () async {
    await Hive.openBox('settings_box');
    expect(FirstUseHints.seen(FirstUseHint.camera), isFalse);
    await FirstUseHints.markSeen(FirstUseHint.camera);
    expect(FirstUseHints.seen(FirstUseHint.camera), isTrue);
  });

  test('hints are remembered one by one', () async {
    await Hive.openBox('settings_box');
    await FirstUseHints.markSeen(FirstUseHint.camera);
    expect(FirstUseHints.seen(FirstUseHint.backup), isFalse);
  });

  test('a hint is remembered after the box is reopened', () async {
    await Hive.openBox('settings_box');
    await FirstUseHints.markSeen(FirstUseHint.backup);
    await Hive.close();
    await Hive.openBox('settings_box');
    expect(FirstUseHints.seen(FirstUseHint.backup), isTrue);
  });

  test('without storage no hint is shown', () {
    expect(FirstUseHints.seen(FirstUseHint.camera), isTrue);
    expect(FirstUseHints.seen(FirstUseHint.backup), isTrue);
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kalorat/models/models.dart';
import 'package:kalorat/services/database_service.dart';
import 'package:kalorat/services/photo_store.dart';

import '../helpers/test_data.dart';

void main() {
  late Directory directory;
  late DatabaseService database;
  late Box<MealModel> mealsBox;
  late PhotoStore photos;

  // Distinct, base64-inline photos like older web versions stored them.
  // Older web versions stored photos inline; real JPEG base64 starts with
  // `/9j/`, which looks like an absolute path.
  String inlinePhoto(int seed) => base64Encode(
    Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      ...List.generate(400, (i) => (i + seed) % 256),
    ]),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kalorat_photo_test_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MealModelAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WeightModelAdapter());
    }
    await Hive.openBox<dynamic>('settings_box');
    mealsBox = await Hive.openBox<MealModel>('test_meals');
    photos = await PhotoStore.open();
    database = DatabaseService();
    await database.initForTest(
      userBox: await Hive.openBox<UserModel>(DatabaseService.userBoxName),
      mealsBox: mealsBox,
      weightsBox: await Hive.openBox<WeightModel>('test_weights'),
      photoStore: photos,
    );
  });

  tearDown(() async {
    PhotoStore.instance = PhotoStore(null);
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('migrates inline photos of existing meals into the store', () async {
    final updatedAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
    final photo = inlinePhoto(1);
    final meal = TestData.sampleMeal(
      id: 'm1',
      photoPaths: [photo, '/native/file.jpg'],
    ).copyWith(updatedAt: updatedAt);
    await mealsBox.put(meal.id, meal);
    await mealsBox.put('m2', TestData.sampleMeal(id: 'm2', photoPaths: []));

    expect(await database.migrateInlinePhotos(), isTrue);

    final migrated = database.getMealById('m1')!;
    expect(PhotoStore.isRef(migrated.photoPaths.first), isTrue);
    expect(migrated.photoPaths.last, '/native/file.jpg');
    expect(await photos.read(migrated.photoPaths.first), base64Decode(photo));
    expect(migrated.updatedAt, updatedAt, reason: 'must not look like an edit');
    expect(
      database
          .getMealsByDate(migrated.timestamp)
          .firstWhere((m) => m.id == 'm1')
          .photoPaths,
      migrated.photoPaths,
      reason: 'indices see the migrated meal',
    );

    expect(await database.migrateInlinePhotos(), isFalse, reason: 'idempotent');
  });

  test('recognizes JPEG base64 as inline, not as a file path', () {
    expect(inlinePhoto(0), startsWith('/9j/'));
    expect(PhotoStore.isInlineBase64(inlinePhoto(0)), isTrue);
    expect(PhotoStore.isInlineBase64('/data/user/0/app/meal_1.jpg'), isFalse);
    expect(
      PhotoStore.isInlineBase64('blob:http://localhost/${'a' * 300}'),
      isFalse,
    );
    expect(PhotoStore.isInlineBase64('kphoto:${'1' * 300}'), isFalse);
  });

  test('legacy inline photos stay readable before migration', () async {
    final photo = inlinePhoto(2);
    expect(await photos.read(photo), base64Decode(photo));
  });

  test('deleting a meal deletes its stored photos', () async {
    final ref = await photos.save(Uint8List.fromList([1, 2, 3]));
    await database.saveMeal(TestData.sampleMeal(id: 'm1', photoPaths: [ref]));

    await database.deleteMeal('m1');

    expect(await photos.read(ref), isNull);
  });

  test('deleting a meal keeps photos still used elsewhere', () async {
    final shared = await photos.save(Uint8List.fromList([1]));
    final pendingCapture = await photos.save(Uint8List.fromList([2]));
    await database.saveMeal(
      TestData.sampleMeal(id: 'm1', photoPaths: [shared, pendingCapture]),
    );
    await database.saveMeal(
      TestData.sampleMeal(id: 'm2', photoPaths: [shared]),
    );
    final pending = await Hive.openBox<dynamic>(
      DatabaseService.pendingPhotosBoxName,
    );
    await pending.put(DatabaseService.pendingPhotosKey, [pendingCapture]);

    await database.deleteMeal('m1');

    expect(await photos.read(shared), [1], reason: 'meal m2 still shows it');
    expect(await photos.read(pendingCapture), [2], reason: 'still in review');
  });

  test('import stores inline photos and export inlines them again', () async {
    final photo = inlinePhoto(3);
    await database.importAll({
      'version': '1.0',
      'meals': [
        TestData.sampleMeal(id: 'm1', photoPaths: [photo]).toJson(),
      ],
    });

    final stored = database.getMealById('m1')!.photoPaths.single;
    expect(PhotoStore.isRef(stored), isTrue);
    expect(jsonEncode(database.exportAll()), isNot(contains(photo)));

    final exported = await database.exportAllWithPhotos();
    expect((exported['meals'] as List).single['photoPaths'], [photo]);
  });

  test(
    'photos kept by the import backup survive deletes and restore',
    () async {
      final ref = await photos.save(Uint8List.fromList([4, 5, 6]));
      await database.saveMeal(
        TestData.sampleMeal(id: 'old', photoPaths: [ref]),
      );
      await database.importAll({'version': '1.0', 'meals': []});

      expect(await database.deleteOrphanPhotos(), 0);
      await database.restoreLastImportBackup();

      final restored = database.getMealById('old')!;
      expect(await photos.read(restored.photoPaths.single), [4, 5, 6]);
    },
  );

  test('migrates inline photos inside the import backup', () async {
    final photo = inlinePhoto(4);
    await database.saveMeal(
      TestData.sampleMeal(id: 'old', photoPaths: [photo]),
    );
    await database.importAll({'version': '1.0', 'meals': []});
    expect(jsonEncode(database.getLastImportBackup()), contains(photo));

    await database.migrateInlinePhotos();

    final backup = jsonEncode(database.getLastImportBackup());
    expect(backup, isNot(contains(photo)));
    await database.restoreLastImportBackup();
    final restored = database.getMealById('old')!.photoPaths.single;
    expect(await photos.read(restored), base64Decode(photo));
  });

  test('orphan cleanup keeps referenced and recent photos', () async {
    final box = await Hive.openLazyBox<Uint8List>(PhotoStore.boxName);
    final old = DateTime.now()
        .subtract(PhotoStore.orphanMinAge * 2)
        .millisecondsSinceEpoch;
    await box.put('$old-orphan', Uint8List.fromList([1]));
    await box.put('$old-used', Uint8List.fromList([2]));
    await box.put('$old-pending', Uint8List.fromList([3]));
    final recent = await photos.save(Uint8List.fromList([4]));
    await database.saveMeal(
      TestData.sampleMeal(id: 'm1', photoPaths: ['kphoto:$old-used']),
    );
    final pending = await Hive.openBox<dynamic>(
      DatabaseService.pendingPhotosBoxName,
    );
    await pending.put(DatabaseService.pendingPhotosKey, [
      'kphoto:$old-pending',
    ]);

    expect(await database.deleteOrphanPhotos(), 1);

    expect(await photos.read('kphoto:$old-orphan'), isNull);
    expect(await photos.read('kphoto:$old-used'), [2]);
    expect(await photos.read('kphoto:$old-pending'), [3]);
    expect(await photos.read(recent), [4]);
  });
}

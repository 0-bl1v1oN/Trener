import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void main() {
  test('trainer UUID is generated once and remains stable', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final first = await db.getTrainerUuid();
    final second = await db.getTrainerUuid();

    expect(first, matches(_uuidV4));
    expect(second, first);
  });

  test('trainer UUID survives reopening the database', () async {
    final temp = await Directory.systemTemp.createTemp('trener-owner-uuid-');
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}identity.sqlite');

    final firstDb = AppDb.forTesting(NativeDatabase(file));
    final uuid = await firstDb.getTrainerUuid();
    await firstDb.close();

    final reopened = AppDb.forTesting(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await reopened.getTrainerUuid(), uuid);
  });

  test('backup contains and restores the trainer UUID', () async {
    final source = AppDb.forTesting(NativeDatabase.memory());
    final sourceUuid = await source.getTrainerUuid();
    final backup = await source.buildBackupPayload(
      appVersion: '1.9.9',
      buildNumber: '101',
    );
    final tables = backup['tables'] as Map<String, dynamic>;
    final settings = tables[source.appSettings.actualTableName] as List;

    expect(settings, contains(containsPair('setting_value', sourceUuid)));
    await source.close();

    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    expect(await restored.getTrainerUuid(), isNot(sourceUuid));

    await restored.importBackupPayload(backup);

    expect(await restored.getTrainerUuid(), sourceUuid);
  });

  test('old backup without trainer UUID gets one after restore', () async {
    final source = AppDb.forTesting(NativeDatabase.memory());
    final backup = await source.buildBackupPayload(
      appVersion: '1.9.9',
      buildNumber: '101',
    );
    backup['schemaVersion'] = 9;
    final tables = backup['tables'] as Map<String, dynamic>;
    tables.remove(source.appSettings.actualTableName);
    await source.close();

    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    final previousLocalUuid = await restored.getTrainerUuid();

    await restored.importBackupPayload(backup);
    final importedUuid = await restored.getTrainerUuid();

    expect(importedUuid, matches(_uuidV4));
    expect(importedUuid, isNot(previousLocalUuid));
    expect(await restored.getTrainerUuid(), importedUuid);
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/more/backup_compatibility.dart';

void main() {
  group('backup metadata', () {
    test('new export contains runtime metadata and existing header', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final payload = await db.buildBackupPayload(
        appVersion: '1.9.9',
        buildNumber: '101',
      );
      final meta = payload['backupMeta'] as Map<String, dynamic>;

      expect(payload['schemaVersion'], 11);
      expect(payload['exportedAt'], isA<String>());
      expect(meta['formatVersion'], supportedBackupFormatVersion);
      expect(meta['appVersion'], '1.9.9');
      expect(meta['buildNumber'], '101');
      expect(payload['tables'], isA<Map<String, dynamic>>());
    });

    test('legacy backup without metadata still imports', () async {
      final source = AppDb.forTesting(NativeDatabase.memory());
      await source.upsertClient(
        ClientsCompanion.insert(id: 'legacy-client', name: 'Legacy'),
      );
      final payload = await source.buildBackupPayload(
        appVersion: '1.9.9',
        buildNumber: '101',
      );
      payload.remove('backupMeta');
      await source.close();

      final restored = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await restored.importBackupPayload(payload);

      expect((await restored.getClientById('legacy-client'))?.name, 'Legacy');
    });
  });

  group('backup compatibility', () {
    test('semantic versions are compared numerically', () {
      expect(compareSemanticVersions('1.9.9', '1.10.0'), lessThan(0));
      expect(compareSemanticVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareSemanticVersions('1.9.9', '1.9.9'), 0);
    });

    test('classifies older, same, and newer application versions', () {
      BackupCompatibility classify(String version) {
        return classifyBackupCompatibility(
          header: BackupHeader(
            schemaVersion: 11,
            exportedAt: '2026-09-03T22:25:00',
            formatVersion: 1,
            appVersion: version,
            buildNumber: '101',
          ),
          currentAppVersion: '2.0.0',
          currentSchemaVersion: 11,
        );
      }

      expect(
        classify('1.9.9').appVersionRelation,
        BackupAppVersionRelation.older,
      );
      expect(
        classify('2.0.0').appVersionRelation,
        BackupAppVersionRelation.same,
      );
      expect(
        classify('2.1.0').appVersionRelation,
        BackupAppVersionRelation.newer,
      );
    });

    test('missing metadata is legacy', () {
      final header = BackupHeader.fromPayload(<String, dynamic>{
        'schemaVersion': 10,
        'exportedAt': '2026-08-11T21:22:14',
        'tables': <String, dynamic>{},
      });

      final result = classifyBackupCompatibility(
        header: header,
        currentAppVersion: '1.9.9',
        currentSchemaVersion: 11,
      );

      expect(result.appVersionRelation, BackupAppVersionRelation.legacy);
    });

    test('recognizes newer backup format and schema', () {
      const header = BackupHeader(
        schemaVersion: 12,
        exportedAt: '2026-09-03T22:25:00',
        formatVersion: 2,
        appVersion: '2.0.0',
        buildNumber: '110',
      );

      final result = classifyBackupCompatibility(
        header: header,
        currentAppVersion: '2.0.0',
        currentSchemaVersion: 11,
      );

      expect(result.appVersionRelation, BackupAppVersionRelation.same);
      expect(result.hasNewerFormat, isTrue);
      expect(result.hasNewerSchema, isTrue);
    });

    test('filename contains normalized version and full timestamp', () {
      expect(
        buildBackupFileName(
          appVersion: '1.9.9',
          createdAt: DateTime(2026, 9, 3, 22, 25),
        ),
        'Trener_backup_v1.9.9_2026-09-03_222500.json',
      );
      expect(
        buildBackupFileName(
          appVersion: '2.0.0 beta/1',
          createdAt: DateTime(2026, 9, 3, 22, 25, 1),
        ),
        'Trener_backup_v2.0.0_beta_1_2026-09-03_222501.json',
      );
    });
  });
}

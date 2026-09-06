import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/app/app_db_scope.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/programs/defalut_programs_screen.dart';
import 'package:myfitness/features/programs/exercise_catalog_screen.dart';
import 'package:myfitness/features/programs/exercise_merge_screen.dart';

void main() {
  Future<AppDb> openDb() async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    await db.getActiveExercises();
    return db;
  }

  Future<ExerciseIdentity> addIdentity(
    AppDb db, {
    required String uuid,
    required String name,
  }) async {
    final id = await db
        .into(db.exerciseIdentities)
        .insert(
          ExerciseIdentitiesCompanion.insert(
            externalId: uuid,
            canonicalName: Value(name),
            normalizedName: Value(AppDb.normalizeExerciseName(name)),
          ),
        );
    return (await db.getExerciseById(id))!;
  }

  Widget app(AppDb db, Widget home) => AppDbScope(
    db: db,
    child: MaterialApp(key: UniqueKey(), theme: ThemeData.dark(), home: home),
  );

  testWidgets('exact duplicate UI merges only after confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await openDb();
    addTearDown(db.close);
    await addIdentity(
      db,
      uuid: 'b0000000-0000-4000-8000-000000000001',
      name: 'UI duplicate',
    );
    final second = await addIdentity(
      db,
      uuid: 'b0000000-0000-4000-8000-000000000002',
      name: ' ui   DUPLICATE ',
    );

    await tester.pumpWidget(app(db, const ExerciseCatalogScreen()));
    await tester.pumpAndSettle();
    expect(
      (await db.getExerciseDuplicateGroups()).where(
        (group) => group.normalizedName == 'ui duplicate',
      ),
      hasLength(1),
    );
    await tester.tap(find.byKey(const Key('exercise_catalog_more')));
    await tester.pumpAndSettle();
    expect(find.text('Разобрать дубли'), findsOneWidget);
    expect(await db.getExerciseUuidAliases(), isEmpty);

    await tester.tap(find.text('Разобрать дубли'));
    await tester.pumpAndSettle();
    expect(find.text('Дубли упражнений'), findsOneWidget);
    final targetGroup = find.ancestor(
      of: find.text(second.canonicalName),
      matching: find.byType(ExpansionTile),
    );
    expect(targetGroup, findsOneWidget);
    await tester.tap(targetGroup);
    await tester.pumpAndSettle();
    expect(find.textContaining('базовые слоты:'), findsNWidgets(2));
    expect(find.text('Сделать основным'), findsNWidgets(2));

    await tester.tap(find.text('Сделать основным').first);
    await tester.pumpAndSettle();
    expect(find.text('Объединить упражнения?'), findsOneWidget);
    expect(
      find.textContaining('История тренировок сохранится'),
      findsOneWidget,
    );
    expect(await db.getExerciseUuidAliases(), isEmpty);

    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Удалено упражнений: 1'), findsOneWidget);
    expect(await db.getExerciseUuidAliases(), hasLength(1));
    expect(
      (await db.getExerciseDuplicateGroups()).where(
        (group) => group.normalizedName == 'ui duplicate',
      ),
      isEmpty,
    );
  });

  testWidgets('manual merge allows different names and mapping is copyable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await openDb();
    addTearDown(db.close);
    final canonical = await addIdentity(
      db,
      uuid: 'c0000000-0000-4000-8000-000000000001',
      name: 'Ручное имя Альфа 927',
    );
    final duplicate = await addIdentity(
      db,
      uuid: 'c0000000-0000-4000-8000-000000000002',
      name: 'Ручное имя Бета 927',
    );

    await tester.pumpWidget(app(db, const ManualExerciseMergeScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ручное имя');
    await tester.pumpAndSettle();
    final canonicalText = find.text(canonical.canonicalName);
    expect(canonicalText, findsOneWidget);
    final canonicalTile = find.ancestor(
      of: canonicalText,
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: canonicalTile, matching: find.byType(Radio<int>)),
    );
    await tester.pump();
    final duplicateText = find.text(duplicate.canonicalName);
    expect(duplicateText, findsOneWidget);
    final duplicateTile = find.ancestor(
      of: duplicateText,
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: duplicateTile, matching: find.byType(Checkbox)),
    );
    await tester.pump();
    await tester.tap(find.text('Объединить выбранные (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(
      await db.resolveCanonicalExerciseUuid(duplicate.externalId),
      canonical.externalId,
    );

    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(app(db, const ExerciseCatalogScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise_catalog_more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Скопировать mapping'));
    await tester.pumpAndSettle();

    final copied = jsonDecode(clipboardText!) as Map<String, dynamic>;
    final mapping = (copied['exercise_uuid_mapping'] as List).single as Map;
    expect(mapping['old_exercise_id'], duplicate.externalId);
    expect(mapping['canonical_exercise_id'], canonical.externalId);
    expect(find.text('Соответствия UUID скопированы'), findsOneWidget);
  });

  testWidgets(
    'catalog tab uses compact top actions and keeps list accessible',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await openDb();
      addTearDown(db.close);
      final filtered = await db.createExercise('UI поиск уникальный 731');
      ExerciseIdentity? last;
      for (var index = 0; index < 24; index++) {
        last = await db.createExercise(
          'Я UI нижнее упражнение ${index.toString().padLeft(2, '0')}',
        );
      }

      await tester.pumpWidget(app(db, const DefaultProgramsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('База упражнений'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('exercise_catalog_add')), findsOneWidget);
      expect(find.byKey(const Key('exercise_catalog_more')), findsOneWidget);

      await tester.tap(find.byKey(const Key('exercise_catalog_add')));
      await tester.pumpAndSettle();
      expect(find.text('Новое упражнение'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('exercise_catalog_more')));
      await tester.pumpAndSettle();
      expect(find.text('Обновить'), findsOneWidget);
      expect(find.text('Разобрать дубли'), findsOneWidget);
      expect(find.text('Объединить вручную'), findsOneWidget);
      expect(find.text('Проверить legacy-привязки'), findsOneWidget);
      expect(find.text('Скопировать mapping'), findsOneWidget);
      await tester.tap(find.text('Обновить'));
      await tester.pumpAndSettle();

      final search = find.byType(TextField);
      await tester.enterText(search, 'поиск уникальный 731');
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('exercise_${filtered.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('exercise_${last!.id}')), findsNothing);

      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      final lastTile = find.byKey(ValueKey('exercise_${last.id}'));
      await tester.scrollUntilVisible(
        lastTile,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(lastTile, findsOneWidget);
      expect(lastTile.hitTestable(), findsOneWidget);
    },
  );

  testWidgets('catalog mutations preserve scroll offset and search query', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await openDb();
    addTearDown(db.close);
    final exercises = <ExerciseIdentity>[];
    for (var index = 0; index < 50; index++) {
      exercises.add(
        await db.createExercise(
          'Позиция скролла ${index.toString().padLeft(2, '0')}',
        ),
      );
    }
    final target = exercises[35];

    await tester.pumpWidget(app(db, const ExerciseCatalogScreen()));
    await tester.pumpAndSettle();
    final search = find.byType(TextField).first;
    await tester.enterText(search, 'Позиция скролла');
    await tester.pumpAndSettle();

    Finder targetTile() => find.byKey(ValueKey('exercise_${target.id}'));
    await tester.scrollUntilVisible(
      targetTile(),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(targetTile()),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    final listView = tester.widget<ListView>(find.byType(ListView));
    final controller = listView.controller!;
    final offsetBeforeRename = controller.offset;
    expect(offsetBeforeRename, greaterThan(0));

    await tester.tap(
      find.descendant(
        of: targetTile(),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переименовать'));
    await tester.pumpAndSettle();
    final renameField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(renameField, 'Позиция скролла 35 изменено');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    expect((controller.offset - offsetBeforeRename).abs(), lessThan(2));
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Позиция скролла',
    );

    await tester.tap(
      find.descendant(
        of: targetTile(),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить упражнение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    final offsetAfterArchive = controller.offset;
    expect(offsetAfterArchive, greaterThan(0));
    expect(
      offsetAfterArchive,
      lessThanOrEqualTo(controller.position.maxScrollExtent),
    );
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Позиция скролла',
    );

    expect(await db.getExerciseById(target.id), isNull);
    await tester.tap(find.byKey(const Key('exercise_catalog_more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Обновить'));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    expect(
      controller.offset,
      lessThanOrEqualTo(controller.position.maxScrollExtent),
    );
    expect(targetTile(), findsNothing);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Позиция скролла',
    );
  });

  testWidgets('legacy tool shows candidates and requires correction preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await openDb();
    addTearDown(db.close);
    final legacy = await addIdentity(
      db,
      uuid: 'd0000000-0000-4000-8000-000000000001',
      name: 'Legacy curl UI',
    );
    final target = await addIdentity(
      db,
      uuid: 'd0000000-0000-4000-8000-000000000002',
      name: 'Legacy hammer UI',
    );
    await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            id: 'legacy-ui-client',
            externalId: const Value('d1000000-0000-4000-8000-000000000001'),
            name: 'Legacy UI client',
            gender: const Value('М'),
          ),
        );
    final template = (await db.getWorkoutTemplatesByGender('М')).first;
    final slot =
        await (db.select(db.workoutTemplateExercises)
              ..where((row) => row.templateId.equals(template.id))
              ..limit(1))
            .getSingle();
    await db
        .into(db.clientTemplateExerciseOverrides)
        .insert(
          ClientTemplateExerciseOverridesCompanion.insert(
            clientId: 'legacy-ui-client',
            templateExerciseId: slot.id,
            exerciseIdentityId: Value(legacy.id),
          ),
        );
    await db.customStatement(
      'INSERT INTO client_exercise_name_overrides '
      '(client_id, template_exercise_id, custom_name) VALUES (?, ?, ?)',
      ['legacy-ui-client', slot.id, 'Legacy hammer UI'],
    );
    final sessionId = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            externalId: const Value('d2000000-0000-4000-8000-000000000001'),
            clientId: 'legacy-ui-client',
            performedAt: DateTime(2026, 9, 4),
            planInstance: 1,
            gender: 'М',
            templateIdx: template.idx,
          ),
        );
    final resultId = await db
        .into(db.workoutExerciseResults)
        .insert(
          WorkoutExerciseResultsCompanion.insert(
            sessionId: sessionId,
            templateExerciseId: slot.id,
            exerciseIdentityId: Value(legacy.id),
            exerciseNameSnapshot: const Value('Legacy hammer UI'),
          ),
        );

    await tester.pumpWidget(app(db, const ExerciseCatalogScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise_catalog_more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Проверить legacy-привязки'));
    await tester.pumpAndSettle();

    expect(find.text('Legacy-привязки'), findsOneWidget);
    expect(find.byKey(const Key('legacy_orphan_bindings')), findsOneWidget);
    expect(find.text('Legacy hammer UI'), findsOneWidget);
    expect(
      find.textContaining('1 клиентов • 1 slots • 1 historical'),
      findsOneWidget,
    );
    await tester.tap(find.text('Legacy hammer UI'));
    await tester.pumpAndSettle();
    expect(
      find.text('Legacy UI client • ${template.title} • упражнение 1'),
      findsOneWidget,
    );
    expect(find.textContaining(legacy.externalId), findsOneWidget);
    expect(find.text('Предложено точное совпадение'), findsOneWidget);
    await tester.tap(find.byKey(const Key('legacy_suggest_exact')));
    await tester.pumpAndSettle();
    final groupCheckbox = find.byKey(
      const ValueKey('legacy_group_check_legacy hammer ui'),
    );
    await tester.tap(groupCheckbox);
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('legacy_apply_selected')))
          .onPressed,
      equals(null),
    );
    await tester.tap(groupCheckbox);
    await tester.pump();
    await tester.tap(find.byKey(const Key('legacy_apply_selected')));
    await tester.pumpAndSettle();

    expect(find.text('Исправить подтверждённые группы?'), findsOneWidget);
    expect(find.textContaining('historical results: 1'), findsOneWidget);
    expect(find.textContaining(target.externalId), findsWidgets);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    final unchanged = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.id.equals(resultId))).getSingle();
    expect(unchanged.exerciseIdentityId, legacy.id);
  });
}

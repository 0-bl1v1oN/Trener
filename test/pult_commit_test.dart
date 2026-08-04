import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myfitness/app/app_db_scope.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/pult/pult_screen.dart';
import 'package:myfitness/features/pult/pult_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru_RU', null));

  testWidgets(
    'Pult commits name once and saves weight/reps on submit or focus loss',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({});

      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertClient(
        ClientsCompanion.insert(
          id: 'pult-commit-client',
          name: 'Клиент Пульта',
          gender: const Value('М'),
          plan: const Value('4'),
        ),
      );
      await db.ensureProgramStateForClient('pult-commit-client');
      final template =
          await (db.select(db.workoutTemplates)
                ..where((row) => row.gender.equals('М') & row.idx.equals(0)))
              .getSingle();
      final exercise =
          await (db.select(db.workoutTemplateExercises)
                ..where((row) => row.templateId.equals(template.id))
                ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)])
                ..limit(1))
              .getSingle();
      final day = DateTime(2026, 8, 5);
      await PultStore.addOrUpdateTab(
        PultTabEntry(
          clientId: 'pult-commit-client',
          clientName: 'Клиент Пульта',
          day: day,
          templateIdx: template.idx,
          absoluteIndex: 0,
        ),
      );

      await tester.pumpWidget(
        AppDbScope(
          db: db,
          child: const MaterialApp(
            locale: Locale('ru', 'RU'),
            supportedLocales: [Locale('ru', 'RU')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: PultScreen(),
          ),
        ),
      );
      await _pumpAsyncUi(tester);

      Finder nameField() => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller?.text == exercise.name,
      );
      expect(nameField(), findsOneWidget);

      await tester.enterText(nameField(), 'Название после Done');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Изменение упражнения'), findsOneWidget);
      await tester.tap(find.text('То же упражнение'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Изменение упражнения'), findsNothing);
      expect(await _effectiveName(db, exercise.id), 'Название после Done');

      final renamedField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.controller?.text == 'Название после Done',
      );
      await tester.enterText(renamedField, 'Название после focus loss');
      await tester.tapAt(const Offset(20, 90));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Изменение упражнения'), findsOneWidget);
      await tester.tap(find.text('То же упражнение'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Изменение упражнения'), findsNothing);
      expect(
        await _effectiveName(db, exercise.id),
        'Название после focus loss',
      );

      final weightField = find
          .byWidgetPredicate(
            (widget) =>
                widget is TextField && widget.decoration?.labelText == 'Вес',
          )
          .first;
      await tester.enterText(weightField, '47,5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 500));
      var drafts = await db.getWorkoutDraftResults(
        clientId: 'pult-commit-client',
        day: day,
        templateIdx: template.idx,
        absoluteIndex: 0,
      );
      expect(drafts[exercise.id]?.$1, 47.5);

      final repsField = find
          .byWidgetPredicate(
            (widget) =>
                widget is TextField && widget.decoration?.labelText == 'Пов',
          )
          .first;
      await tester.enterText(repsField, '13');
      await tester.tapAt(const Offset(20, 90));
      await tester.pump(const Duration(milliseconds: 500));
      drafts = await db.getWorkoutDraftResults(
        clientId: 'pult-commit-client',
        day: day,
        templateIdx: template.idx,
        absoluteIndex: 0,
      );
      expect(drafts[exercise.id]?.$1, 47.5);
      expect(drafts[exercise.id]?.$2, 13);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}

Future<void> _pumpAsyncUi(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Закрыть тренировочный день').evaluate().isNotEmpty) return;
  }
}

Future<String?> _effectiveName(AppDb db, int exerciseId) async {
  final row = await db
      .customSelect(
        '''
    SELECT COALESCE(o.custom_name, e.name) AS effective_name
    FROM workout_template_exercises e
    LEFT JOIN client_exercise_name_overrides o
      ON o.client_id = ? AND o.template_exercise_id = e.id
    WHERE e.id = ?
    ''',
        variables: [
          Variable.withString('pult-commit-client'),
          Variable.withInt(exerciseId),
        ],
      )
      .getSingle();
  return row.readNullable<String>('effective_name');
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import 'pult_store.dart';

class PultScreen extends StatefulWidget {
  const PultScreen({super.key});

  @override
  State<PultScreen> createState() => _PultScreenState();
}

class _PultScreenState extends State<PultScreen> {
  late final AppDb db;
  bool _dbInited = false;
  List<PultTabEntry> _tabs = const <PultTabEntry>[];
  String? _activeClientId;

  @override
  void initState() {
    super.initState();
    PultStore.revision.addListener(_reloadTabs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dbInited) return;
    db = AppDbScope.of(context);
    _dbInited = true;
    _reloadTabs();
  }

  @override
  void dispose() {
    PultStore.revision.removeListener(_reloadTabs);
    super.dispose();
  }

  Future<void> _reloadTabs() async {
    final tabs = await PultStore.loadTabs();
    if (!mounted) return;
    setState(() {
      _tabs = tabs;
      if (_tabs.isEmpty) {
        _activeClientId = null;
        return;
      }
      final hasActive =
          _activeClientId != null &&
          _tabs.any((item) => item.clientId == _activeClientId);
      _activeClientId = hasActive ? _activeClientId : _tabs.last.clientId;
    });
  }

  Future<_PultTabData> _loadTabData(PultTabEntry tab) async {
    final details = await db.getWorkoutDetailsForClientProgramSlot(
      clientId: tab.clientId,
      absoluteIndex: tab.absoluteIndex,
      templateIdx: tab.templateIdx,
    );
    final drafts = await db.getWorkoutDraftResults(
      clientId: tab.clientId,
      day: tab.day,
      templateIdx: tab.templateIdx,
      absoluteIndex: tab.absoluteIndex,
    );

    final exercises = details.$3.map((e) {
      final draft = drafts[e.templateExerciseId];
      if (draft == null) return e;
      return WorkoutExerciseVm(
        templateExerciseId: e.templateExerciseId,
        templateId: e.templateId,
        orderIndex: e.orderIndex,
        name: e.name,
        lastWeightKg: draft.$1,
        lastReps: draft.$2,
        supersetGroup: e.supersetGroup,
      );
    }).toList();

    return _PultTabData(
      clientName: tab.clientName,
      exercises: exercises,
      day: tab.day,
    );
  }

  String _fmtWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    PultTabEntry? activeTab;
    if (_tabs.isNotEmpty) {
      for (final tab in _tabs) {
        if (tab.clientId == _activeClientId) {
          activeTab = tab;
          break;
        }
      }
      activeTab ??= _tabs.last;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Пульт')),
      body: SafeArea(
        child: _tabs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dashboard_customize_rounded,
                        size: 46,
                        color: colors.primary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Пульт пока пуст',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Добавляй клиентов из календаря кнопкой «В Пульт», и они появятся здесь отдельными вкладками.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Container(
                    height: 66,
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.42,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.28),
                      ),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        final selected = tab.clientId == activeTab?.clientId;
                        return _PultClientTab(
                          title: tab.clientName,
                          selected: selected,
                          onTap: () => setState(() {
                            _activeClientId = tab.clientId;
                          }),
                          onClose: () => PultStore.removeTab(tab.clientId),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: activeTab == null
                        ? const SizedBox.shrink()
                        : FutureBuilder<_PultTabData>(
                            future: _loadTabData(activeTab),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snap.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Не удалось загрузить данные Пульта:\n${snap.error}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              final data = snap.data;
                              if (data == null) {
                                return const Center(child: Text('Нет данных'));
                              }

                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  16,
                                ),
                                children: [
                                  Text(
                                    data.clientName,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        colors: [
                                          colors.surface.withValues(
                                            alpha: 0.985,
                                          ),
                                          colors.surfaceContainerHighest
                                              .withValues(alpha: 0.92),
                                          colors.primary.withValues(
                                            alpha: 0.06,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: colors.outlineVariant.withValues(
                                          alpha: 0.36,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.shadow.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primaryContainer
                                                .withValues(alpha: 0.34),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(24),
                                                ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 6,
                                                child: Text(
                                                  'Упражнение',
                                                  style: theme
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'Вес',
                                                  textAlign: TextAlign.center,
                                                  style: theme
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'Повт.',
                                                  textAlign: TextAlign.center,
                                                  style: theme
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (data.exercises.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Text(
                                              'На ${DateFormat('dd.MM.yyyy', 'ru_RU').format(data.day)} для этого клиента пока нет упражнений.',
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          )
                                        else
                                          for (
                                            var i = 0;
                                            i < data.exercises.length;
                                            i++
                                          )
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: i == 0
                                                      ? BorderSide.none
                                                      : BorderSide(
                                                          color: colors
                                                              .outlineVariant
                                                              .withValues(
                                                                alpha: 0.18,
                                                              ),
                                                        ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 6,
                                                    child: Text(
                                                      data.exercises[i].name,
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      data
                                                                  .exercises[i]
                                                                  .lastWeightKg ==
                                                              null
                                                          ? '—'
                                                          : _fmtWeight(
                                                              data
                                                                  .exercises[i]
                                                                  .lastWeightKg!,
                                                            ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      data
                                                                  .exercises[i]
                                                                  .lastReps ==
                                                              null
                                                          ? '—'
                                                          : data
                                                                .exercises[i]
                                                                .lastReps
                                                                .toString(),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PultClientTab extends StatelessWidget {
  const _PultClientTab({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.only(left: 14, right: 8),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.84)
                : colors.surface.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.38)
                  : colors.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                iconSize: 18,
                splashRadius: 18,
                tooltip: 'Закрыть вкладку',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PultTabData {
  final String clientName;
  final DateTime day;
  final List<WorkoutExerciseVm> exercises;

  const _PultTabData({
    required this.clientName,
    required this.day,
    required this.exercises,
  });
}

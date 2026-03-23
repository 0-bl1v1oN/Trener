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
  late final PageController _pageController;
  bool _dbInited = false;
  List<PultTabEntry> _tabs = const <PultTabEntry>[];
  String? _activeClientId;
  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    _pageController.dispose();
    super.dispose();
  }

  int _activeTabIndexFor(List<PultTabEntry> tabs) {
    if (tabs.isEmpty) return 0;
    final index = tabs.indexWhere((item) => item.clientId == _activeClientId);
    return index >= 0 ? index : tabs.length - 1;
  }

  GlobalKey _tabKeyFor(String clientId) =>
      _tabKeys.putIfAbsent(clientId, GlobalKey.new);

  void _scrollActiveTabIntoView({bool animated = true}) {
    final activeClientId = _activeClientId;
    if (activeClientId == null) return;
    final context = _tabKeys[activeClientId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: animated ? const Duration(milliseconds: 220) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _reloadTabs() async {
    final tabs = await PultStore.loadTabs();
    if (!mounted) return;
    setState(() {
      _tabs = tabs;
      _tabKeys.removeWhere((clientId, _) {
        return !_tabs.any((tab) => tab.clientId == clientId);
      });
      if (_tabs.isEmpty) {
        _activeClientId = null;
        return;
      }
      final hasActive =
          _activeClientId != null &&
          _tabs.any((item) => item.clientId == _activeClientId);
      _activeClientId = hasActive ? _activeClientId : _tabs.last.clientId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _tabs.isEmpty) return;
      final targetPage = _activeTabIndexFor(_tabs);
      if (_pageController.page?.round() == targetPage) return;
      _pageController.jumpToPage(targetPage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabs.isEmpty) return;
      _scrollActiveTabIntoView(animated: false);
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
    final activeTabIndex = _activeTabIndexFor(_tabs);
    final activeTab = _tabs.isEmpty ? null : _tabs[activeTabIndex];

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
                        final selected = index == activeTabIndex;
                        return KeyedSubtree(
                          key: _tabKeyFor(tab.clientId),
                          child: _PultClientTab(
                            title: tab.clientName,
                            selected: selected,
                            onTap: () {
                              if (index == activeTabIndex) return;
                              setState(() {
                                _activeClientId = tab.clientId;
                              });
                              if (_pageController.hasClients) {
                                _pageController.jumpToPage(index);
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _scrollActiveTabIntoView();
                              });
                            },
                            onClose: () => PultStore.removeTab(tab.clientId),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: activeTab == null
                        ? const SizedBox.shrink()
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _tabs.length,
                            onPageChanged: (index) {
                              final nextClientId = _tabs[index].clientId;
                              if (nextClientId == _activeClientId) return;
                              setState(() {
                                _activeClientId = nextClientId;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _scrollActiveTabIntoView();
                              });
                            },
                            itemBuilder: (context, index) {
                              final tab = _tabs[index];
                              return FutureBuilder<_PultTabData>(
                                future: _loadTabData(tab),
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
                                    return const Center(
                                      child: Text('Нет данных'),
                                    );
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
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                            color: colors.outlineVariant
                                                .withValues(alpha: 0.36),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                      textAlign:
                                                          TextAlign.center,
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
                                                      textAlign:
                                                          TextAlign.center,
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
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                child: Text(
                                                  'На ${DateFormat('dd.MM.yyyy', 'ru_RU').format(data.day)} для этого клиента пока нет упражнений.',
                                                  textAlign: TextAlign.center,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
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
                                                          data
                                                              .exercises[i]
                                                              .name,
                                                          style: theme
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
    const animationDuration = Duration(milliseconds: 260);
    final titleStyle =
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? colors.onPrimaryContainer : colors.onSurface,
        ) ??
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: selected ? colors.onPrimaryContainer : colors.onSurface,
        );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedScale(
          duration: animationDuration,
          curve: Curves.easeInOutCubic,
          scale: selected ? 1 : 0.97,
          child: AnimatedContainer(
            duration: animationDuration,
            curve: Curves.easeInOutCubic,
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
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.shadow.withValues(alpha: 0.03),
                  blurRadius: selected ? 14 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: AnimatedDefaultTextStyle(
                    duration: animationDuration,
                    curve: Curves.easeInOutCubic,
                    style: titleStyle,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    end: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                  duration: animationDuration,
                  curve: Curves.easeInOutCubic,
                  builder: (context, iconColor, child) {
                    return IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onClose,
                      iconSize: 18,
                      splashRadius: 18,
                      tooltip: 'Закрыть вкладку',
                      color: iconColor,
                      icon: child!,
                    );
                  },
                  child: const Icon(Icons.close_rounded),
                ),
              ],
            ),
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

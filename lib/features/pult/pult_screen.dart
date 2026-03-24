import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

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
                    height: 72,
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.68,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              return _PultWorkoutPage(
                                key: ValueKey(
                                  '${tab.clientId}_${tab.day.toIso8601String()}_${tab.absoluteIndex}_${tab.templateIdx}',
                                ),
                                db: db,
                                tab: tab,
                                onCompleted: () =>
                                    PultStore.removeTab(tab.clientId),
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

class _PultWorkoutPage extends StatefulWidget {
  const _PultWorkoutPage({
    super.key,
    required this.db,
    required this.tab,
    required this.onCompleted,
  });

  final AppDb db;
  final PultTabEntry tab;
  final Future<void> Function() onCompleted;

  @override
  State<_PultWorkoutPage> createState() => _PultWorkoutPageState();
}

class _PultWorkoutPageState extends State<_PultWorkoutPage>
    with SingleTickerProviderStateMixin {
  static const String _attendanceMarker = '[attended]';
  static const String _headerVideoAsset = 'assets/branding/pult_header.mp4';

  final Map<int, TextEditingController> _kgControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _repsControllers =
      <int, TextEditingController>{};
  final Map<int, FocusNode> _kgFocusNodes = <int, FocusNode>{};
  final Map<int, FocusNode> _repsFocusNodes = <int, FocusNode>{};
  final Map<int, GlobalKey> _exerciseKeys = <int, GlobalKey>{};
  final ScrollController _pageScrollController = ScrollController();

  _PultTabData? _data;
  Object? _error;
  bool _loading = true;
  bool _completing = false;
  Timer? _draftDebounce;
  late final AnimationController _headerGlowController;
  VideoPlayerController? _headerVideoController;
  bool _headerVideoFailed = false;

  @override
  void initState() {
    super.initState();
    _headerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    unawaited(_initHeaderVideo());
    _load();
  }

  Future<void> _initHeaderVideo() async {
    final controller = VideoPlayerController.asset(_headerVideoAsset);
    _headerVideoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      await controller.dispose();
      _headerVideoController = null;
      if (!mounted) return;
      setState(() {
        _headerVideoFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    unawaited(_saveDrafts());
    for (final controller in [
      ..._kgControllers.values,
      ..._repsControllers.values,
    ]) {
      controller.dispose();
    }
    for (final node in [..._kgFocusNodes.values, ..._repsFocusNodes.values]) {
      node.dispose();
    }
    _headerVideoController?.dispose();
    _headerGlowController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final details = await widget.db.getWorkoutDetailsForClientProgramSlot(
        clientId: widget.tab.clientId,
        absoluteIndex: widget.tab.absoluteIndex,
        templateIdx: widget.tab.templateIdx,
      );
      final drafts = await widget.db.getWorkoutDraftResults(
        clientId: widget.tab.clientId,
        day: widget.tab.day,
        templateIdx: widget.tab.templateIdx,
        absoluteIndex: widget.tab.absoluteIndex,
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

      _disposeInputs();
      for (final e in exercises) {
        _exerciseKeys[e.templateExerciseId] = GlobalKey();
        _kgControllers[e.templateExerciseId] = TextEditingController(
          text: e.lastWeightKg == null ? '' : _fmtWeight(e.lastWeightKg!),
        )..addListener(_handleInputChanged);
        _repsControllers[e.templateExerciseId] = TextEditingController(
          text: e.lastReps?.toString() ?? '',
        )..addListener(_handleInputChanged);

        _kgFocusNodes[e.templateExerciseId] = FocusNode()
          ..addListener(() {
            final node = _kgFocusNodes[e.templateExerciseId];
            final controller = _kgControllers[e.templateExerciseId];
            if (node?.hasFocus == true && controller != null) {
              _scheduleSelectAll(controller);
              _scheduleBringIntoView(e.templateExerciseId);
            }
          });
        _repsFocusNodes[e.templateExerciseId] = FocusNode()
          ..addListener(() {
            final node = _repsFocusNodes[e.templateExerciseId];
            final controller = _repsControllers[e.templateExerciseId];
            if (node?.hasFocus == true && controller != null) {
              _scheduleSelectAll(controller);
              _scheduleBringIntoView(e.templateExerciseId);
            }
          });
      }

      if (!mounted) return;
      setState(() {
        _data = _PultTabData(
          clientName: widget.tab.clientName,
          exercises: exercises,
          day: widget.tab.day,
        );
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _disposeInputs() {
    for (final controller in [
      ..._kgControllers.values,
      ..._repsControllers.values,
    ]) {
      controller.dispose();
    }
    for (final node in [..._kgFocusNodes.values, ..._repsFocusNodes.values]) {
      node.dispose();
    }
    _kgControllers.clear();
    _repsControllers.clear();
    _kgFocusNodes.clear();
    _repsFocusNodes.clear();
    _exerciseKeys.clear();
  }

  void _handleInputChanged() {
    if (!mounted) return;
    setState(() {});
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 260), () {
      unawaited(_saveDrafts());
    });
  }

  void _scheduleBringIntoView(int exerciseId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _exerciseKeys[exerciseId]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.08,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _saveDrafts() async {
    final data = _data;
    if (data == null) return;

    await widget.db.saveWorkoutDraftResults(
      clientId: widget.tab.clientId,
      day: widget.tab.day,
      templateIdx: widget.tab.templateIdx,
      absoluteIndex: widget.tab.absoluteIndex,
      resultsByTemplateExerciseId: {
        for (final e in data.exercises)
          e.templateExerciseId: (
            _parseWeight(_kgControllers[e.templateExerciseId]?.text ?? ''),
            _parseReps(_repsControllers[e.templateExerciseId]?.text ?? ''),
          ),
      },
    );
  }

  Future<void> _completeDay() async {
    if (_completing || _data == null) return;

    setState(() => _completing = true);
    _draftDebounce?.cancel();

    try {
      final results = <int, (double? kg, int? reps)>{};
      for (final e in _data!.exercises) {
        results[e.templateExerciseId] = (
          _parseWeight(_kgControllers[e.templateExerciseId]?.text ?? ''),
          _parseReps(_repsControllers[e.templateExerciseId]?.text ?? ''),
        );
      }

      await widget.db.saveWorkoutResultsAndMarkDone(
        clientId: widget.tab.clientId,
        day: widget.tab.day,
        templateIdx: widget.tab.templateIdx,
        absoluteIndex: widget.tab.absoluteIndex,
        resultsByTemplateExerciseId: results,
      );

      final appointments = await widget.db.getAppointmentsForClientOnDay(
        clientId: widget.tab.clientId,
        day: widget.tab.day,
      );
      for (final appointment in appointments) {
        await widget.db.updateAppointmentNote(
          id: appointment.id,
          note: _withAttendanceMarker(appointment.note, true),
        );
      }

      await widget.onCompleted();
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  void _scheduleSelectAll(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  double? _parseWeight(String raw) {
    final s = raw.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  int? _parseReps(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  String? _withAttendanceMarker(String? note, bool done) {
    final current = (note ?? '').replaceAll(_attendanceMarker, '').trim();
    if (!done) return current.isEmpty ? null : current;
    return current.isEmpty ? _attendanceMarker : '$current $_attendanceMarker';
  }

  String _fmtWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  InputDecoration _cellDecoration(
    BuildContext context,
    String label, {
    required bool highlighted,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: TextStyle(
        color: colors.onSurfaceVariant.withValues(alpha: 0.72),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary.withValues(alpha: 0.86),
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: highlighted
          ? colors.primaryContainer.withValues(alpha: 0.28)
          : colors.surface.withValues(alpha: 0.42),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: highlighted
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.primary.withValues(alpha: 0.38),
              ),
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.primary.withValues(alpha: 0.72),
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Не удалось загрузить данные Пульта:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const Center(child: Text('Нет данных'));
    }

    return ListView(
      controller: _pageScrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        AnimatedBuilder(
          animation: _headerGlowController,
          builder: (context, _) {
            final t = _headerGlowController.value;
            final wave = math.sin(t * math.pi * 2);
            final wave2 = math.sin((t * math.pi * 2) + (math.pi / 2));

            final video = _headerVideoController;
            final hasVideo = video != null && video.value.isInitialized;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colors.surfaceContainerHighest,
                border: Border.all(
                  color: Color.lerp(
                    colors.primary.withValues(alpha: 0.42),
                    colors.tertiary.withValues(alpha: 0.45),
                    t,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      colors.primary.withValues(alpha: 0.22),
                      colors.tertiary.withValues(alpha: 0.34),
                      t,
                    )!,
                    blurRadius: 24 + (t * 20),
                    spreadRadius: 1 + (2 * wave.abs()),
                    offset: Offset(0, 10 + (4 * wave.abs())),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: hasVideo
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: video.value.size.width,
                                height: video.value.size.height,
                                child: VideoPlayer(video),
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.lerp(
                                      colors.primary.withValues(alpha: 0.55),
                                      colors.tertiary.withValues(alpha: 0.62),
                                      t,
                                    )!,
                                    Color.lerp(
                                      colors.primaryContainer.withValues(
                                        alpha: 0.92,
                                      ),
                                      colors.tertiaryContainer.withValues(
                                        alpha: 0.94,
                                      ),
                                      t,
                                    )!,
                                    Color.lerp(
                                      colors.surfaceContainerHighest.withValues(
                                        alpha: 0.92,
                                      ),
                                      colors.primary.withValues(alpha: 0.50),
                                      t,
                                    )!,
                                  ],
                                  transform: GradientRotation(
                                    (math.pi * 2) * t,
                                  ),
                                  stops: [0, 0.5 + (0.18 * wave), 1],
                                  begin: Alignment(
                                    -1.2 + (1.2 * t),
                                    -1.15 + (0.25 * wave),
                                  ),
                                  end: Alignment(
                                    1.15 - (1.0 * t),
                                    1.1 - (0.34 * wave2),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(
                                alpha: hasVideo ? 0.16 : 0.05,
                              ),
                              Colors.black.withValues(
                                alpha: hasVideo ? 0.08 : 0.0,
                              ),
                              Colors.black.withValues(
                                alpha: hasVideo ? 0.28 : 0.08,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -24 + (10 * wave2),
                      right: -18 + (10 * wave),
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            colors.primary.withValues(
                              alpha: hasVideo ? 0.28 : 0.18,
                            ),
                            colors.tertiary.withValues(
                              alpha: hasVideo ? 0.32 : 0.22,
                            ),
                            t,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -34 + (8 * wave),
                      left: 18 + (18 * t),
                      child: Container(
                        width: 142,
                        height: 142,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            colors.tertiary.withValues(
                              alpha: hasVideo ? 0.2 : 0.12,
                            ),
                            colors.primary.withValues(
                              alpha: hasVideo ? 0.24 : 0.17,
                            ),
                            t,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14 + (8 * wave2),
                      left: 86 + (24 * wave),
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface.withValues(
                            alpha: hasVideo ? 0.28 : 0.22,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.surface.withValues(
                                alpha: hasVideo ? 0.78 : 0.68,
                              ),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_headerVideoFailed)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Видео-фон не найден, включён анимированный градиент',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.onSurface.withValues(
                                              alpha: 0.78,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surface.withValues(
                                        alpha: 0.54,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'dd.MM.yyyy',
                                        'ru_RU',
                                      ).format(data.day),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  data.clientName,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.1,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                colors.surface.withValues(alpha: 0.985),
                colors.surfaceContainerHighest.withValues(alpha: 0.96),
                colors.primary.withValues(alpha: 0.08),
                colors.tertiary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.36),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
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
                  color: colors.primaryContainer.withValues(alpha: 0.34),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Упражнение',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Вес',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Повт.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
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
                for (var i = 0; i < data.exercises.length; i++)
                  Builder(
                    builder: (context) {
                      final exercise = data.exercises[i];
                      final kgController =
                          _kgControllers[exercise.templateExerciseId]!;
                      final repsController =
                          _repsControllers[exercise.templateExerciseId]!;
                      final hasKg = kgController.text.trim().isNotEmpty;
                      final hasReps = repsController.text.trim().isNotEmpty;

                      return Container(
                        key: _exerciseKeys[exercise.templateExerciseId],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? colors.surface.withValues(alpha: 0.08)
                              : Colors.transparent,
                          border: Border(
                            top: i == 0
                                ? BorderSide.none
                                : BorderSide(
                                    color: colors.outlineVariant.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.primaryContainer.withValues(
                                        alpha: 0.45,
                                      ),
                                      border: Border.all(
                                        color: colors.primary.withValues(
                                          alpha: 0.14,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        exercise.name,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              height: 1.35,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: kgController,
                                focusNode:
                                    _kgFocusNodes[exercise.templateExerciseId],
                                decoration: _cellDecoration(
                                  context,
                                  'Вес',
                                  highlighted: hasKg,
                                ),
                                onTap: () => _scheduleSelectAll(kgController),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: repsController,
                                focusNode:
                                    _repsFocusNodes[exercise
                                        .templateExerciseId],
                                decoration: _cellDecoration(
                                  context,
                                  'Пов',
                                  highlighted: hasReps,
                                ),
                                onTap: () => _scheduleSelectAll(repsController),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [colors.primaryContainer, colors.tertiaryContainer],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _completing ? null : _completeDay,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              backgroundColor: Colors.transparent,
              foregroundColor: colors.onPrimaryContainer,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: _completing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _completing
                  ? 'Закрываем тренировочный день…'
                  : 'Закрыть тренировочный день',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.only(left: 14, right: 8),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.88)
                : colors.surface.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.34)
                  : colors.outlineVariant.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.shadow.withValues(alpha: 0.02),
                blurRadius: selected ? 12 : 4,
                offset: const Offset(0, 3),
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

import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

_PrizeMeta _prizeMetaByTitle(String title) {
  final key = title.trim().toLowerCase();
  const map = <String, _PrizeMeta>{
    'главный приз: абонемент': _PrizeMeta(
      icon: Icons.workspace_premium_rounded,
      description:
          'Полноценный доступ к прогрессу. Ходи месяц бесплатно! (почти)',
    ),
    'счастливый день': _PrizeMeta(
      icon: Icons.auto_awesome,
      description:
          'Ты выбираешь 6 упражнений мечты — я строю тренировку вокруг твоих желаний.',
    ),
    'протеиновая вкусняшка': _PrizeMeta(
      icon: Icons.icecream_rounded,
      description:
          'Белковый бонус для восстановления и настроения. Вкусно, полезно, по-спортивному.',
    ),
    'день ног -50% весов': _PrizeMeta(
      icon: Icons.fitness_center,
      description:
          'Официальная амнистия. Работаем технично, чисто и без геройства.',
    ),
    'ревёрс': _PrizeMeta(
      icon: Icons.swap_calls_rounded,
      description: 'Сегодня ты — тренер. Команды, темп, контроль. Я выполняю.',
    ),
    'доп +2 крутки': _PrizeMeta(
      icon: Icons.casino_rounded,
      description: 'Два дополнительных шанса изменить свою судьбу в розыгрыше.',
    ),
    'день пп': _PrizeMeta(
      icon: Icons.spa_rounded,
      description:
          'Идеальное питание без компромиссов. Чисто. Дисциплинированно. Под отчёт.',
    ),
    'токсичная планка': _PrizeMeta(
      icon: Icons.hourglass_bottom_rounded,
      description:
          '40 секунд настоящей стойкости. Дополнительная нагрузка — в прямом смысле сверху.',
    ),
    'случайный день ног': _PrizeMeta(
      icon: Icons.shuffle_rounded,
      description:
          '6 упражнений из 50 — выбирает случай. Ноги скажут спасибо позже.',
    ),
    'реклама в сторис': _PrizeMeta(
      icon: Icons.campaign_rounded,
      description: 'Репост закрепа в сторис. Поддержка тренера — дело чести.',
    ),
    'братский стульчик': _PrizeMeta(
      icon: Icons.groups_2_rounded,
      description:
          'Командная выдержка. Плечо к плечу, минута характера. Если один — 15 кг в руки.',
    ),
  };

  return map[key] ??
      const _PrizeMeta(
        icon: Icons.card_giftcard_rounded,
        description: 'Описание приза появится здесь.',
      );
}

class ContestsScreen extends StatefulWidget {
  const ContestsScreen({super.key});

  @override
  State<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends State<ContestsScreen>
    with SingleTickerProviderStateMixin {
  static const _eventKey = '2026-02-23';

  late final AppDb _db;
  late final AnimationController _spinController;
  final _rng = Random();

  List<Client> _clients = const [];
  List<ContestWinnerVm> _winners = const [];
  List<_PrizeItem> _prizes = const [];

  String? _selectedClientId;
  ContestEntryVm? _entry;

  bool _loading = true;
  bool _spinning = false;
  bool _initialized = false;
  String? _currentPrize;
  final Set<String> _expandedPrizeTitles = <String>{};

  double _wheelTurns = 0;
  int _selectedIndex = 0;

  static const List<_PrizeItem> _defaultPrizes = [
    _PrizeItem(
      id: 0,
      title: 'Главный приз: Абонемент',
      weight: 0.02,
      isGood: true,
    ),
    _PrizeItem(id: 0, title: 'Счастливый день', weight: 0.12, isGood: true),
    _PrizeItem(
      id: 0,
      title: 'Протеиновая вкусняшка',
      weight: 0.11,
      isGood: true,
    ),
    _PrizeItem(id: 0, title: 'День ног -50% весов', weight: 0.10, isGood: true),
    _PrizeItem(id: 0, title: 'Ревёрс', weight: 0.10, isGood: true),
    _PrizeItem(id: 0, title: 'Доп +2 крутки', weight: 0.09, isGood: true),
    _PrizeItem(id: 0, title: 'День ПП', weight: 0.10, isGood: false),
    _PrizeItem(id: 0, title: 'Токсичная планка', weight: 0.10, isGood: false),
    _PrizeItem(id: 0, title: 'Случайный день ног', weight: 0.09, isGood: false),
    _PrizeItem(id: 0, title: 'Реклама в сторис', weight: 0.09, isGood: false),
    _PrizeItem(id: 0, title: 'Братский стульчик', weight: 0.09, isGood: false),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _db = AppDbScope.of(context);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _load();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _ensurePrizesSeeded() async {
    final existing = await _db.getContestPrizes(eventKey: _eventKey);
    final hasAny = existing.isNotEmpty;
    final hasNewMainPrize = existing.any(
      (p) => p.title.trim().toLowerCase() == 'главный приз: абонемент',
    );

    if (hasAny && hasNewMainPrize) return;

    await _db.replaceContestPrizes(
      eventKey: _eventKey,
      prizes: List.generate(
        _defaultPrizes.length,
        (i) => ContestPrizeVm(
          id: 0,
          title: _defaultPrizes[i].title,
          weight: _defaultPrizes[i].weight,
          isGood: _defaultPrizes[i].isGood,
          sortOrder: i,
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    await _db.ensureContestTables();
    await _ensurePrizesSeeded();
    final clients = await _db.getAllClients();
    final winners = await _db.getContestWinners(eventKey: _eventKey);
    final prizeRows = await _db.getContestPrizes(eventKey: _eventKey);

    String? selected = _selectedClientId;
    if (selected == null && clients.isNotEmpty) {
      selected = clients.first.id;
    }

    ContestEntryVm? entry;
    if (selected != null) {
      entry = await _db.getContestEntry(
        eventKey: _eventKey,
        clientId: selected,
      );
    }

    final prizes = prizeRows
        .map(
          (p) => _PrizeItem(
            id: p.id,
            title: p.title,
            weight: p.weight,
            isGood: p.isGood,
          ),
        )
        .toList(growable: false);

    if (!mounted) return;
    setState(() {
      _clients = clients;
      _winners = winners;
      _selectedClientId = selected;
      _entry = entry;
      _prizes = prizes;
      _currentPrize = entry?.currentPrize;
      _selectedIndex = _indexForPrize(entry?.currentPrize);
      _loading = false;
    });
  }

  Client? get _selectedClient {
    final id = _selectedClientId;
    if (id == null) return null;
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  int _attemptsForPlan(String? plan) {
    return switch (plan) {
      '12' => 3,
      '8' => 2,
      '4' => 1,
      _ => 0,
    };
  }

  bool get _isMaleClient => _selectedClient?.gender == 'М';

  int get _allowedAttempts {
    final client = _selectedClient;
    if (client == null) return 0;
    return _attemptsForPlan(client.plan);
  }

  int get _usedAttempts => _entry?.usedAttempts ?? 0;

  int get _remainingAttempts =>
      (_allowedAttempts - _usedAttempts).clamp(0, _allowedAttempts);

  bool get _isFinalized => (_entry?.finalPrize ?? '').isNotEmpty;

  Future<void> _selectClient(String? id) async {
    if (id == null) return;
    final entry = await _db.getContestEntry(eventKey: _eventKey, clientId: id);
    if (!mounted) return;
    setState(() {
      _selectedClientId = id;
      _entry = entry;
      _currentPrize = entry?.currentPrize;
      _selectedIndex = _indexForPrize(entry?.currentPrize);
    });
  }

  int _indexForPrize(String? prize) {
    if (prize == null) return 0;
    final idx = _prizes.indexWhere((p) => p.title == prize);
    return idx < 0 ? 0 : idx;
  }

  _PrizeMeta _metaForPrize(String title) => _prizeMetaByTitle(title);

  int _pickWeightedIndex() {
    final total = _prizes.fold<double>(0, (s, p) => s + p.weight);
    if (_prizes.isEmpty || total <= 0) return 0;

    final r = _rng.nextDouble() * total;
    var acc = 0.0;
    for (var i = 0; i < _prizes.length; i++) {
      acc += _prizes[i].weight;
      if (r <= acc) return i;
    }
    return _prizes.length - 1;
  }

  List<({double start, double sweep})> _weightedSectors() {
    if (_prizes.isEmpty) return const [];

    final rawTotal = _prizes.fold<double>(0, (s, p) => s + p.weight);
    final safeTotal = rawTotal > 0 ? rawTotal : _prizes.length.toDouble();

    var current = -pi / 2;
    final out = <({double start, double sweep})>[];
    for (final p in _prizes) {
      final safeWeight = rawTotal > 0 ? p.weight : 1.0;
      final sweep = (safeWeight / safeTotal) * 2 * pi;
      out.add((start: current, sweep: sweep));
      current += sweep;
    }
    return out;
  }

  Future<void> _spinRoulette() async {
    if (_spinning) return;
    if (_selectedClientId == null) return;
    if (_prizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Список призов пуст. Добавьте призы.')),
      );
      return;
    }
    if (!_isMaleClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Конкурс 23 февраля доступен только мужчинам.'),
        ),
      );
      return;
    }
    if (_allowedAttempts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У клиента нет активного абонемента 4/8/12.'),
        ),
      );
      return;
    }
    if (_isFinalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот клиент уже забрал приз.')),
      );
      return;
    }
    if (_remainingAttempts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Попытки закончились, можно только забрать текущий приз.',
          ),
        ),
      );
      return;
    }

    final prizeIndex = _pickWeightedIndex();
    final rounds = 4 + _rng.nextInt(3);
    final sectors = _weightedSectors();
    final selected = sectors[prizeIndex];
    final targetCenterTurns =
        (selected.start + (selected.sweep / 2)) / (2 * pi);

    final currentFraction = _wheelTurns - _wheelTurns.floorToDouble();
    final targetFractionRaw = 0.75 - targetCenterTurns;
    final targetFraction =
        targetFractionRaw - targetFractionRaw.floorToDouble();

    var alignDelta = targetFraction - currentFraction;
    if (alignDelta < 0) alignDelta += 1;

    final nextTurns = _wheelTurns + rounds + alignDelta;

    setState(() {
      _spinning = true;
      _selectedIndex = prizeIndex;
      _wheelTurns = nextTurns;
    });

    _spinController.forward(from: 0);
    await Future<void>.delayed(_spinController.duration!);

    final updated = await _db.recordContestSpin(
      eventKey: _eventKey,
      clientId: _selectedClientId!,
      maxAttempts: _allowedAttempts,
      prize: _prizes[prizeIndex].title,
    );

    if (!mounted) return;
    setState(() {
      _entry = updated;
      _currentPrize = updated.currentPrize;
      _selectedIndex = _indexForPrize(updated.currentPrize);
      _spinning = false;
    });
  }

  Future<void> _takePrize() async {
    if (_selectedClientId == null) return;
    if ((_entry?.currentPrize ?? '').isEmpty) return;

    final updated = await _db.finalizeContestPrize(
      eventKey: _eventKey,
      clientId: _selectedClientId!,
    );
    final winners = await _db.getContestWinners(eventKey: _eventKey);

    if (!mounted) return;
    setState(() {
      _entry = updated;
      _winners = winners;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Приз закреплён! Клиент больше не участвует.'),
      ),
    );
  }

  Future<void> _resetSelectedForTest() async {
    if (_selectedClientId == null) return;
    await _db.resetContestParticipant(
      eventKey: _eventKey,
      clientId: _selectedClientId!,
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Тестовый сброс выполнен. Клиент снова может участвовать.',
        ),
      ),
    );
  }

  Future<void> _removeWinnerForTest(ContestWinnerVm w) async {
    await _db.resetContestParticipant(
      eventKey: _eventKey,
      clientId: w.clientId,
    );
    await _load();
  }

  Future<void> _openPrizeEditor({
    _PrizeItem? prize,
    required int sortOrder,
  }) async {
    final title = TextEditingController(text: prize?.title ?? '');
    final weight = TextEditingController(
      text: ((prize?.weight ?? 0.1) * 100).toStringAsFixed(1),
    );
    var isGood = prize?.isGood ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(prize == null ? 'Новый приз' : 'Редактировать приз'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Название приза'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Вес, % (например 12.5)',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: isGood,
                onChanged: (v) => setLocal(() => isGood = v),
                title: const Text('Хороший приз'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            if (prize != null)
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Удалить'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (ok == null && prize != null) {
      await _db.deleteContestPrize(eventKey: _eventKey, id: prize.id);
      await _load();
      return;
    }

    if (ok != true) return;

    final parsedWeight =
        (double.tryParse(weight.text.replaceAll(',', '.')) ?? 0) / 100;
    if (title.text.trim().isEmpty || parsedWeight <= 0) return;

    await _db.upsertContestPrize(
      eventKey: _eventKey,
      id: prize?.id,
      title: title.text.trim(),
      weight: parsedWeight,
      isGood: isGood,
      sortOrder: sortOrder,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Конкурсы'),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colors.outlineVariant.withOpacity(0.7),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Конкурс на 23 февраля',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedClientId,
                            decoration: const InputDecoration(
                              labelText: 'Клиент',
                              border: OutlineInputBorder(),
                            ),
                            items: _clients
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _selectClient,
                          ),
                          const SizedBox(height: 10),
                          if (_selectedClient != null)
                            Text(
                              'Абонемент: ${_selectedClient!.plan ?? '—'} • Попыток: $_allowedAttempts • Осталось: $_remainingAttempts',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          if (_selectedClient != null && !_isMaleClient)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Для события 23 февраля рулетка доступна только мужчинам.',
                                style: TextStyle(color: colors.error),
                              ),
                            ),
                          if (_isFinalized)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Приз уже забран: ${_entry?.finalPrize}',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _selectedClientId == null
                                ? null
                                : _resetSelectedForTest,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Тестовый сброс участия'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RouletteCard(
                    prizes: _prizes,
                    selectedIndex: _selectedIndex,
                    turns: _wheelTurns,
                    currentPrize: _currentPrize,
                    spinning: _spinning,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              (_spinning ||
                                  _isFinalized ||
                                  !_isMaleClient ||
                                  _remainingAttempts <= 0)
                              ? null
                              : _spinRoulette,
                          icon: const Icon(Icons.casino_outlined),
                          label: Text(
                            _usedAttempts == 0 ? 'Крутить рулетку' : 'Переброс',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              (_spinning ||
                                  (_entry?.currentPrize ?? '').isEmpty ||
                                  _isFinalized)
                              ? null
                              : _takePrize,
                          icon: const Icon(Icons.redeem_outlined),
                          label: const Text('Забрать приз'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colors.outlineVariant.withOpacity(0.7),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Список призов',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Добавить приз',
                                onPressed: () =>
                                    _openPrizeEditor(sortOrder: _prizes.length),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_prizes.isEmpty)
                            const Text('Пока призов нет')
                          else
                            Column(
                              children: List.generate(_prizes.length, (i) {
                                final p = _prizes[i];
                                final meta = _metaForPrize(p.title);
                                final opened = _expandedPrizeTitles.contains(
                                  p.title,
                                );
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: colors.outlineVariant.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    initiallyExpanded: opened,
                                    onExpansionChanged: (v) {
                                      setState(() {
                                        if (v) {
                                          _expandedPrizeTitles.add(p.title);
                                        } else {
                                          _expandedPrizeTitles.remove(p.title);
                                        }
                                      });
                                    },
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: p.isGood
                                          ? colors.primaryContainer
                                          : colors.errorContainer,
                                      child: Icon(
                                        meta.icon,
                                        size: 18,
                                        color: p.isGood
                                            ? colors.onPrimaryContainer
                                            : colors.onErrorContainer,
                                      ),
                                    ),
                                    tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      12,
                                    ),
                                    title: Text(p.title),
                                    subtitle: Text(
                                      p.isGood ? 'Приз' : 'Анти-приз',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Редактировать приз',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _openPrizeEditor(
                                            prize: p,
                                            sortOrder: i,
                                          ),
                                        ),
                                        Icon(
                                          opened
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                        ),
                                      ],
                                    ),
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          meta.description,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colors.outlineVariant.withOpacity(0.7),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Архив выдачи призов',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_winners.isEmpty)
                            const Text('Пока никто не забрал приз')
                          else
                            Column(
                              children: _winners
                                  .map(
                                    (w) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(w.clientName),
                                      subtitle: Text(w.prize),
                                      trailing: IconButton(
                                        tooltip: 'Удалить из архива (тест)',
                                        onPressed: () =>
                                            _removeWinnerForTest(w),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RouletteCard extends StatelessWidget {
  const _RouletteCard({
    required this.prizes,
    required this.selectedIndex,
    required this.turns,
    required this.currentPrize,
    required this.spinning,
  });

  final List<_PrizeItem> prizes;
  final int selectedIndex;
  final double turns;
  final String? currentPrize;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final prizeLabel = currentPrize;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    colors.primaryContainer.withOpacity(0.45),
                    colors.tertiaryContainer.withOpacity(0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (prizes.isNotEmpty)
                      AnimatedRotation(
                        turns: turns,
                        duration: const Duration(milliseconds: 4200),
                        curve: Curves.easeOutExpo,
                        child: CustomPaint(
                          size: const Size(230, 230),
                          painter: _RoulettePainter(prizes: prizes),
                        ),
                      ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: CustomPaint(
                        size: const Size(28, 28),
                        painter: _PointerPainter(color: colors.error),
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x557C4DFF),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.casino, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              spinning
                  ? 'Крутим...'
                  : (currentPrize == null
                        ? 'Сделайте вращение'
                        : 'Текущий приз: $currentPrize'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!spinning && currentPrize != null && prizes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _prizeMetaByTitle(currentPrize).icon,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      prizes[selectedIndex].isGood
                          ? 'Хороший приз ✨'
                          : 'Не очень приз 😅',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoulettePainter extends CustomPainter {
  _RoulettePainter({required this.prizes});

  final List<_PrizeItem> prizes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFF4EEFF), Color(0xFFDCCBFF)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bgPaint);

    final rawTotal = prizes.fold<double>(0, (s, p) => s + p.weight);
    final safeTotal = rawTotal > 0 ? rawTotal : prizes.length.toDouble();

    var currentAngle = -pi / 2;

    for (var i = 0; i < prizes.length; i++) {
      final item = prizes[i];
      final safeWeight = rawTotal > 0 ? item.weight : 1.0;
      final sweep = (safeWeight / safeTotal) * 2 * pi;
      final isSuper = item.title.toLowerCase().contains('главный приз');
      final colors = isSuper
          ? [const Color(0xFFFFE082), const Color(0xFFFFB300)]
          : (item.isGood
                ? [const Color(0xFFFF8A80), const Color(0xFFE53935)]
                : [const Color(0xFF64B5F6), const Color(0xFF1976D2)]);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);

      canvas.drawArc(rect, currentAngle, sweep, true, paint);

      final sectorMid = currentAngle + (sweep / 2);
      final iconRadius = radius * 0.66;
      final iconOffset = Offset(
        center.dx + cos(sectorMid) * iconRadius,
        center.dy + sin(sectorMid) * iconRadius,
      );
      final iconData = _prizeMetaByTitle(item.title).icon;
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: max(11, min(18, sweep * 20)),
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Colors.white.withOpacity(0.96),
            shadows: const [
              Shadow(
                color: Color(0x55000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          iconOffset.dx - (iconPainter.width / 2),
          iconOffset.dy - (iconPainter.height / 2),
        ),
      );

      if (isSuper) {
        final superStripe = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = const Color(0xFFFFD54F).withOpacity(0.95);
        canvas.drawArc(
          rect.deflate(10),
          currentAngle + (sweep * 0.08),
          sweep * 0.84,
          false,
          superStripe,
        );
      }

      final sep = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.8);

      canvas.drawLine(
        center,
        center + Offset(cos(currentAngle) * radius, sin(currentAngle) * radius),
        sep,
      );
      currentAngle += sweep;
    }
    final sep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.8);
    canvas.drawLine(
      center,
      center + Offset(cos(currentAngle) * radius, sin(currentAngle) * radius),
      sep,
    );

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = const LinearGradient(
        colors: [Color(0xFF7C4DFF), Color(0xFF3F51B5)],
      ).createShader(rect);
    canvas.drawCircle(center, radius - 1, outer);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(center, radius - 9, inner);
  }

  @override
  bool shouldRepaint(covariant _RoulettePainter oldDelegate) =>
      oldDelegate.prizes != prizes;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PrizeMeta {
  final IconData icon;
  final String description;

  const _PrizeMeta({required this.icon, required this.description});
}

class _PrizeItem {
  final int id;
  final String title;
  final double weight;
  final bool isGood;

  const _PrizeItem({
    required this.id,
    required this.title,
    required this.weight,
    required this.isGood,
  });
}

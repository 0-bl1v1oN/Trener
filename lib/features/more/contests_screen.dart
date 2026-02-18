import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

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

  String? _selectedClientId;
  ContestEntryVm? _entry;

  bool _loading = true;
  bool _spinning = false;
  bool _initialized = false;
  String? _currentPrize;

  double _wheelTurns = 0;
  int _selectedIndex = 0;

  final List<_PrizeItem> _prizes = const [
    _PrizeItem('Суперприз: абонемент на месяц 🎉', 0.02, true),
    _PrizeItem('Скидка 50% на следующий абонемент', 0.14, true),
    _PrizeItem('Бесплатная персональная тренировка', 0.14, true),
    _PrizeItem('Спортивный шейкер в подарок', 0.14, true),
    _PrizeItem('Протеиновый батончик + вода', 0.14, true),
    _PrizeItem('Доп. разминка 5 минут 😅', 0.084, false),
    _PrizeItem('10 бурпи после тренировки', 0.084, false),
    _PrizeItem('Планка +60 секунд', 0.084, false),
    _PrizeItem('5 приседаний с паузой', 0.084, false),
    _PrizeItem('Селфи с тренером для архива 😄', 0.084, false),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _db = AppDbScope.of(context);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _load();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    await _db.ensureContestTables();
    final clients = await _db.getAllClients();
    final winners = await _db.getContestWinners(eventKey: _eventKey);

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

    if (!mounted) return;
    setState(() {
      _clients = clients;
      _winners = winners;
      _selectedClientId = selected;
      _entry = entry;
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

  int _pickWeightedIndex() {
    final r = _rng.nextDouble();
    var acc = 0.0;
    for (var i = 0; i < _prizes.length; i++) {
      acc += _prizes[i].weight;
      if (r <= acc) return i;
    }
    return _prizes.length - 1;
  }

  Future<void> _spinRoulette() async {
    if (_spinning) return;
    if (_selectedClientId == null) return;
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
    final targetSector = (2 * pi / _prizes.length) * prizeIndex;
    final nextTurns = _wheelTurns + rounds + (targetSector / (2 * pi));

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
                                      trailing: Text(
                                        '${w.finalizedAt.day.toString().padLeft(2, '0')}.${w.finalizedAt.month.toString().padLeft(2, '0')}',
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedRotation(
                    turns: turns,
                    duration: const Duration(milliseconds: 2300),
                    curve: Curves.easeOutCubic,
                    child: CustomPaint(
                      size: const Size(220, 220),
                      painter: _RoulettePainter(prizes: prizes),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 34,
                      color: colors.error,
                    ),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.casino),
                  ),
                ],
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
            if (!spinning && currentPrize != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  prizes[selectedIndex].isGood
                      ? 'Хороший приз ✨'
                      : 'Не очень приз 😅',
                  style: Theme.of(context).textTheme.bodySmall,
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
    final sweep = (2 * pi) / prizes.length;

    for (var i = 0; i < prizes.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = prizes[i].isGood
            ? const Color(0xFF7E57C2).withOpacity(0.80)
            : const Color(0xFFEF5350).withOpacity(0.74);
      canvas.drawArc(rect, (-pi / 2) + (i * sweep), sweep, true, paint);
    }

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF674EA7);
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant _RoulettePainter oldDelegate) => false;
}

class _PrizeItem {
  final String title;
  final double weight;
  final bool isGood;

  const _PrizeItem(this.title, this.weight, this.isGood);
}

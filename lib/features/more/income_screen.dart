import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  late final AppDb _db;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;

  PlanPricesVm _prices = const PlanPricesVm(
    plan4: 1800,
    plan8: 2900,
    plan12: 3500,
  );
  List<IncomeEntryVm> _incomes = const [];
  List<ExpenseEntryVm> _expenses = const [];
  List<IncomeMonthSummaryVm> _archive = const [];

  final _money = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );
  final _monthFmt = DateFormat('LLLL yyyy', 'ru_RU');
  final _dateFmt = DateFormat('d MMM', 'ru_RU');

  int get _monthIncome => _incomes.fold(0, (sum, e) => sum + e.amount);
  int get _monthExpense => _expenses.fold(0, (sum, e) => sum + e.amount);
  int get _monthNet => _monthIncome - _monthExpense;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = AppDbScope.of(context);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final prices = await _db.getPlanPrices();
    final incomes = await _db.getIncomeEntriesForMonth(_selectedMonth);
    final expenses = await _db.getExpenseEntriesForMonth(_selectedMonth);
    final archive = await _db.getIncomeArchive(limit: 12);

    if (!mounted) return;
    setState(() {
      _prices = prices;
      _incomes = incomes;
      _expenses = expenses;
      _archive = archive;
      _loading = false;
    });
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    await _load();
  }

  Future<void> _openPriceEditor() async {
    final p4 = TextEditingController(text: _prices.plan4.toString());
    final p8 = TextEditingController(text: _prices.plan8.toString());
    final p12 = TextEditingController(text: _prices.plan12.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Прайс абонементов'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PriceField(controller: p4, label: '4 занятия'),
            const SizedBox(height: 10),
            _PriceField(controller: p8, label: '8 занятий'),
            const SizedBox(height: 10),
            _PriceField(controller: p12, label: '12 занятий'),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Пробная тренировка: 0 ₽ (не учитывается в доходе)'),
            ),
          ],
        ),
        actions: [
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
    );

    if (ok != true) return;

    final next = PlanPricesVm(
      plan4: int.tryParse(p4.text.trim()) ?? _prices.plan4,
      plan8: int.tryParse(p8.text.trim()) ?? _prices.plan8,
      plan12: int.tryParse(p12.text.trim()) ?? _prices.plan12,
    );
    await _db.savePlanPrices(next);
    await _load();
  }

  Future<void> _openAddExpense() async {
    final amount = TextEditingController();
    final category = TextEditingController(text: 'Расходы зала');
    final note = TextEditingController();
    DateTime day = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Добавить расход'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Сумма (₽)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Категория'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Комментарий'),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Дата'),
                subtitle: Text(DateFormat('d MMMM yyyy', 'ru_RU').format(day)),
                trailing: const Icon(Icons.event),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: day,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2100),
                    locale: const Locale('ru', 'RU'),
                  );
                  if (picked == null) return;
                  setLocal(() => day = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final parsed = int.tryParse(amount.text.trim());
    if (parsed == null || parsed <= 0) return;

    await _db.addExpense(
      date: day,
      amount: parsed,
      category: category.text,
      note: note.text,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Доход'),
          actions: [
            IconButton(
              tooltip: 'Прайс',
              onPressed: _openPriceEditor,
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              tooltip: 'Обновить',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddExpense,
          icon: const Icon(Icons.remove_circle_outline),
          label: const Text('Расход'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    _MonthHeader(
                      title: _monthFmt.format(_selectedMonth),
                      onPrev: () => _changeMonth(-1),
                      onNext: () => _changeMonth(1),
                    ),
                    const SizedBox(height: 12),
                    _SummaryCards(
                      income: _money.format(_monthIncome),
                      expenses: _money.format(_monthExpense),
                      net: _money.format(_monthNet),
                    ),
                    const SizedBox(height: 14),
                    _BarsCard(
                      archive: _archive.take(6).toList(),
                      formatter: _money,
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Поступления за месяц',
                      icon: Icons.south_west,
                      child: _incomes.isEmpty
                          ? const Text('Поступлений пока нет')
                          : Column(
                              children: _incomes
                                  .map(
                                    (e) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        '${e.clientName} • абонемент ${e.plan}',
                                      ),
                                      subtitle: Text(_dateFmt.format(e.date)),
                                      trailing: Text(
                                        _money.format(e.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Расходы за месяц',
                      icon: Icons.north_east,
                      child: _expenses.isEmpty
                          ? const Text('Расходов пока нет')
                          : Column(
                              children: _expenses
                                  .map(
                                    (e) => Dismissible(
                                      key: ValueKey(e.id),
                                      background: Container(
                                        color: colors.errorContainer,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: const Icon(Icons.delete_outline),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (_) async {
                                        await _db.deleteExpense(e.id);
                                        await _load();
                                      },
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(e.category),
                                        subtitle: Text(
                                          '${_dateFmt.format(e.date)}${(e.note ?? '').isEmpty ? '' : ' • ${e.note}'}',
                                        ),
                                        trailing: Text(
                                          _money.format(e.amount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Архив по месяцам',
                      icon: Icons.history,
                      child: _archive.isEmpty
                          ? const Text('Архив пуст')
                          : Column(
                              children: _archive
                                  .map(
                                    (m) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        DateFormat(
                                          'LLLL yyyy',
                                          'ru_RU',
                                        ).format(m.monthStart),
                                      ),
                                      subtitle: Text(
                                        'Доход: ${_money.format(m.income)} • Расход: ${_money.format(m.expenses)}',
                                      ),
                                      trailing: Text(
                                        _money.format(m.net),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: m.net >= 0
                                              ? colors.primary
                                              : colors.error,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.income,
    required this.expenses,
    required this.net,
  });

  final String income;
  final String expenses;
  final String net;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallCard(
            title: 'Доход',
            value: income,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallCard(
            title: 'Расход',
            value: expenses,
            icon: Icons.trending_down,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallCard(
            title: 'Итог',
            value: net,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _BarsCard extends StatelessWidget {
  const _BarsCard({required this.archive, required this.formatter});

  final List<IncomeMonthSummaryVm> archive;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (archive.isEmpty) return const SizedBox.shrink();

    final list = archive.reversed.toList();
    final maxValue = list.fold<int>(
      1,
      (m, e) => e.net.abs() > m ? e.net.abs() : m,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Динамика (чистый результат)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: list
                    .map(
                      (e) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                formatter.format(e.net),
                                style: Theme.of(context).textTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 70 * (e.net.abs() / maxValue),
                                decoration: BoxDecoration(
                                  color: e.net >= 0
                                      ? colors.primary
                                      : colors.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'MM/yy',
                                  'ru_RU',
                                ).format(e.monthStart),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

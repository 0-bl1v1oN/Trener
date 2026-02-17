import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Меню')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    colors.primaryContainer.withOpacity(0.75),
                    colors.secondaryContainer.withOpacity(0.65),
                  ],
                ),
              ),
              child: Text(
                'Дополнительные разделы',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Разделы'),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                children: [
                  _MenuTile(
                    icon: Icons.tune,
                    title: 'Категории',
                    subtitle: 'Настройка видимости и создание категорий',
                    onTap: () => context.go('/calendar?openCategories=1'),
                  ),
                  _MenuTile(
                    icon: Icons.payments_outlined,
                    title: 'Доход',
                    subtitle: 'Анализ доходов и расходов (заглушка)',
                    onTap: () => context.push('/income'),
                  ),
                  _MenuTile(
                    icon: Icons.emoji_events_outlined,
                    title: 'Рекорды',
                    subtitle: 'Личные рекорды клиентов (заглушка)',
                    onTap: () => context.push('/records'),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

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
            _MenuTile(
              icon: Icons.tune,
              title: 'Категории',
              subtitle: 'Настройка видимости и создание категорий',
              iconColor: colors.primary,
              onTap: () => context.go('/calendar?openCategories=1'),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.payments_outlined,
              title: 'Доход',
              subtitle: 'Доходы, расходы, архив и прайс абонементов',
              iconColor: colors.tertiary,
              onTap: () => context.push('/income'),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.emoji_events_outlined,
              title: 'Рекорды',
              subtitle: 'Личные рекорды клиентов (заглушка)',
              iconColor: colors.secondary,
              onTap: () => context.push('/records'),
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
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

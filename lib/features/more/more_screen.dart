import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _items = <_MenuItem>[
    _MenuItem(
      icon: Icons.tune_rounded,
      title: 'Категории',
      description: 'Настройка и управление категориями',
      accent: Color(0xFFB982FF),
      route: '/calendar?openCategories=1',
      replaceRoute: true,
    ),
    _MenuItem(
      icon: Icons.casino_rounded,
      title: 'Конкурсы',
      description: 'Розыгрыши и результаты',
      accent: Color(0xFFFFAA45),
      route: '/contests',
    ),
    _MenuItem(
      icon: Icons.insights_rounded,
      title: 'Прогресс',
      description: 'Фото и динамика клиентов',
      accent: Color(0xFF8B7CFF),
      route: '/progress',
    ),
    _MenuItem(
      icon: Icons.sync_rounded,
      title: 'Синхронизация',
      description: 'Очередь отправки и журнал',
      accent: Color(0xFF35D6D0),
      route: '/sync',
    ),
    _MenuItem(
      icon: Icons.import_export_rounded,
      title: 'Экспорт / Импорт',
      description: 'Резервные копии данных',
      accent: Color(0xFF41D995),
      route: '/backup',
    ),
    _MenuItem(
      icon: Icons.payments_rounded,
      title: 'Доход',
      description: 'Доходы, расходы и аналитика',
      accent: Color(0xFFFF5FA2),
      route: '/income',
    ),
    _MenuItem(
      icon: Icons.emoji_events_rounded,
      title: 'Рекорды',
      description: 'Личные достижения клиентов',
      accent: Color(0xFF4D9CFF),
      route: '/records',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Меню')),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Выберите раздел',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 184,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _items[index];
                  return _MenuCard(
                    icon: item.icon,
                    title: item.title,
                    description: item.description,
                    accent: item.accent,
                    onTap: () => item.replaceRoute
                        ? context.go(item.route)
                        : context.push(item.route),
                  );
                }, childCount: _items.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.route,
    this.replaceRoute = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final String route;
  final bool replaceRoute;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(20);
    final cardBase = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.18),
      colors.surface,
    );

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: accent.withValues(alpha: 0.34)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(accent.withValues(alpha: 0.16), cardBase),
                  cardBase,
                  Color.alphaBlend(accent.withValues(alpha: 0.06), cardBase),
                ],
                stops: const [0, 0.58, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Icon(
                            icon,
                            size: 40,
                            color: accent,
                            shadows: [
                              Shadow(
                                color: accent.withValues(alpha: 0.32),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

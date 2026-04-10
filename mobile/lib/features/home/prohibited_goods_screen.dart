import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';

class ProhibitedGoodsScreen extends StatelessWidget {
  const ProhibitedGoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Запрещенные товары'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AlertHeader(),
                  SizedBox(height: 12),
                  _CategoryTile(
                    icon: Icons.broken_image_outlined,
                    title: 'Хрупкие и ломкие товары',
                    subtitle:
                        'Электронные сигареты, зеркала, порнографическая продукция, поврежденные товары и т.д.',
                  ),
                  _CategoryTile(
                    icon: Icons.gpp_bad_outlined,
                    title: 'Оружие и военные предметы',
                    subtitle:
                        'Ножи, оружие, электрошокеры, микрокамеры, микронаушники и т.д.',
                  ),
                  _CategoryTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Взрывоопасные материалы',
                    subtitle:
                        'Аккумуляторы, хлопушки, салюты, зажигалки и т.д.',
                  ),
                  _CategoryTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Дорогостоящие товары',
                    subtitle: 'Золото, серебро и другие ценные изделия.',
                  ),
                  _CategoryTile(
                    icon: Icons.no_drinks_outlined,
                    title: 'Наркотические и психотропные вещества',
                    subtitle: 'Любые запрещенные вещества.',
                  ),
                  _CategoryTile(
                    icon: Icons.medication_liquid_outlined,
                    title: 'Продукты питания и медицинские товары',
                    subtitle:
                        'Еда, БАДы, лекарства, медицинские препараты и т.д.',
                  ),
                  SizedBox(height: 14),
                  _ImportantBlock(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertHeader extends StatelessWidget {
  const _AlertHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4511E), Color(0xFFE64A19)],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.report_problem_rounded, color: Colors.white, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Товары, которые строго запрещены к отправке',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.brandRed),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportantBlock extends StatelessWidget {
  const _ImportantBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high_rounded, color: Color(0xFFE65100)),
              SizedBox(width: 8),
              Text(
                'ВАЖНО',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Телефоны, планшеты, ноутбуки, компьютеры и подобные товары принимаются только по предварительному согласованию.',
            style: TextStyle(height: 1.3),
          ),
          SizedBox(height: 6),
          Text(
            '• Если заказ оформлен без предупреждения, существует риск повреждения товара, и компания не несет ответственности за повреждения.',
            style: TextStyle(height: 1.3),
          ),
        ],
      ),
    );
  }
}

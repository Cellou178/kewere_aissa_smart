import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class FinanceCard extends StatelessWidget {
  final String title;
  final double montant;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const FinanceCard({
    super.key,
    required this.title,
    required this.montant,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  String _format(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M FCFA';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K FCFA';
    return '${v.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          Text(_format(montant), style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ])),
      ]),
    );
  }
}
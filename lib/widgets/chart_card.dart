import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final Color color;
  final double height;

  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.color = kBlue,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 16,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: height, child: chart),
      ]),
    );
  }
}
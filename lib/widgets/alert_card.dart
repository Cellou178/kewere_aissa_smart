import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class AlertCard extends StatelessWidget {
  final Map alerte;
  final VoidCallback? onTap;
  const AlertCard({super.key, required this.alerte, this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = alerte['type'] ?? 'info';
    final color = type == 'danger' ? kRed : type == 'warning' ? kOrange : kBlue;
    final icon = type == 'danger' ? Icons.dangerous_rounded
        : type == 'warning' ? Icons.warning_rounded : Icons.info_rounded;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
        child: ListTile(
          dense: true,
          leading: Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          title: Text(alerte['titre'] ?? alerte['message'] ?? '',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color)),
          subtitle: alerte['message'] != null && alerte['titre'] != null
              ? Text(alerte['message'], style: const TextStyle(fontSize: 10))
              : null,
          trailing: Icon(Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.4), size: 11),
        ),
      ),
    );
  }
}
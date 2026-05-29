import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;
  final bool loading;

  const CustomButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
            backgroundColor: color ?? kBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0),
        child: loading
            ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
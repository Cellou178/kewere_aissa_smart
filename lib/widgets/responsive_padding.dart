import 'package:flutter/material.dart';
import '../core/utils/responsive.dart';

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(
          horizontal: r.horizontalPadding,
          vertical: r.verticalPadding),
      child: child,
    );
  }
}
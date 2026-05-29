import 'package:flutter/material.dart';

class AppTransitions {
  // ── Fade transition ──
  static Route fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );

  // ── Slide from right ──
  static Route slideRight(Widget page) => PageRouteBuilder(
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: anim, curve: Curves.easeOutCubic)),
        child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );

  // ── Slide from bottom ──
  static Route slideUp(Widget page) => PageRouteBuilder(
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: anim, curve: Curves.easeOutCubic)),
        child: child),
    transitionDuration: const Duration(milliseconds: 350),
  );

  // ── Scale + Fade ──
  static Route scaleRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
          parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(curved),
              child: child));
    },
    transitionDuration: const Duration(milliseconds: 350),
  );

  // ── Slide + Fade ──
  static Route slideFade(Widget page,
      {Offset begin = const Offset(0.05, 0)}) =>
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => page,
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
              parent: anim, curve: Curves.easeOutCubic);
          return SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero)
                  .animate(curved),
              child: FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(curved),
                  child: child));
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}

// ── Animated Card ──
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.95, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTapDown: widget.onTap != null
                ? (_) => setState(() => _pressed = true) : null,
            onTapUp: widget.onTap != null
                ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: widget.onTap != null
                ? () => setState(() => _pressed = false) : null,
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer Loading ──
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
                begin: Alignment(_anim.value - 1, 0),
                end: Alignment(_anim.value + 1, 0),
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ])),
      ),
    );
  }
}

// ── Shimmer Card (skeleton) ──
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ShimmerWidget(width: 44, height: 44, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShimmerWidget(width: double.infinity, height: 14, borderRadius: 4),
            const SizedBox(height: 6),
            ShimmerWidget(width: 120, height: 10, borderRadius: 4),
          ])),
        ]),
        const SizedBox(height: 12),
        ShimmerWidget(width: double.infinity, height: 8, borderRadius: 4),
        const SizedBox(height: 6),
        ShimmerWidget(width: 200, height: 8, borderRadius: 4),
      ]),
    );
  }
}

// ── Shimmer KPI ──
class ShimmerKPI extends StatelessWidget {
  const ShimmerKPI({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(4, (i) => Expanded(
      child: Container(
        margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerWidget(width: 20, height: 20, borderRadius: 4),
              const SizedBox(height: 6),
              ShimmerWidget(width: 40, height: 16, borderRadius: 4),
              const SizedBox(height: 4),
              ShimmerWidget(width: 30, height: 8, borderRadius: 4),
            ]),
      ),
    )));
  }
}
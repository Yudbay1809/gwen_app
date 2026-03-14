import 'package:flutter/material.dart';

class MotionFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  const MotionFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.beginOffset = const Offset(0, 0.06),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<MotionFadeSlide> createState() => _MotionFadeSlideState();
}

class _MotionFadeSlideState extends State<MotionFadeSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _offset = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .chain(CurveTween(curve: widget.curve))
        .animate(_controller);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class MotionPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const MotionPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<MotionPressScale> createState() => _MotionPressScaleState();
}

class _MotionPressScaleState extends State<MotionPressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.borderRadius == null
            ? widget.child
            : ClipRRect(borderRadius: widget.borderRadius!, child: widget.child),
      ),
    );
  }
}

class MotionPulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlur;
  final Duration duration;

  const MotionPulseGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.maxBlur = 18,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<MotionPulseGlow> createState() => _MotionPulseGlowState();
}

class _MotionPulseGlowState extends State<MotionPulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final blur = widget.maxBlur * (0.6 + 0.4 * t);
        final spread = 1.5 + 1.5 * t;
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.35 + 0.25 * t),
                blurRadius: blur,
                spreadRadius: spread,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

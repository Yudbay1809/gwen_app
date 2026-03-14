import 'package:flutter/material.dart';
class BackSwipeWrapper extends StatefulWidget {
  final Widget child;

  const BackSwipeWrapper({super.key, required this.child});

  @override
  State<BackSwipeWrapper> createState() => _BackSwipeWrapperState();
}

class _BackSwipeWrapperState extends State<BackSwipeWrapper> {
  static const double _edgeWidth = 24;
  static const double _minDrag = 80;
  static const double _minVelocity = 350;

  bool _eligible = false;
  double _drag = 0;

  void _handleDragStart(DragStartDetails details) {
    _eligible = details.globalPosition.dx <= _edgeWidth;
    _drag = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_eligible) return;
    _drag += details.delta.dx;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_eligible) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_drag > _minDrag || velocity > _minVelocity) {
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigator.maybePop();
      }
    }
    _eligible = false;
    _drag = 0;
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.maybeOf(context);
    final canPop = navigator?.canPop() ?? false;
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: widget.child,
        ),
        if (canPop)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    final navigator = Navigator.maybeOf(context);
                    if (navigator != null && navigator.canPop()) navigator.maybePop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, size: 20),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

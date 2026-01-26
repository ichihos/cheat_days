import 'package:flutter/material.dart';

class MessieMascot extends StatefulWidget {
  final double size;
  final Duration duration;

  const MessieMascot({
    super.key,
    this.size = 190.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<MessieMascot> createState() => _MessieMascotState();
}

class _MessieMascotState extends State<MessieMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value), // Floating effect
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/messie.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.android, size: widget.size, color: Colors.green),
      ),
    );
  }
}

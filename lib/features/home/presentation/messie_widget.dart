import 'package:cheat_days/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class MessieWidget extends StatelessWidget {
  final String comment;
  final VoidCallback? onTap;

  const MessieWidget({super.key, required this.comment, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Speech Bubble
          Positioned(
            right: 80, // Position bubble to left of dino
            bottom: 40,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Small triangle for speech bubble
          Positioned(
            right: 85,
            bottom: 50,
            child: CustomPaint(painter: TrianglePainter()),
          ),

          // Dinosaur Character (Simple placeholder for now)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  // shape: BoxShape.circle,
                  // color: Colors.blueAccent, // Placeholder
                ),
                child: const Text(
                  "🦕", // Dino Emoji
                  style: TextStyle(fontSize: 80),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(10, 10);
    path.lineTo(0, 20);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

import 'package:flutter/material.dart';

class BuffaloNodeWidget extends StatelessWidget {
  final dynamic data;
  final bool founder;
  final String displayName;

  const BuffaloNodeWidget({Key? key, required this.data, this.founder = false, this.displayName = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 28, backgroundColor: Colors.deepPurple, child: Text(founder ? displayName : '${data['birthYear']}', style: const TextStyle(color: Colors.white))),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(founder ? 'Founder' : 'Born ${data['birthYear']}', style: const TextStyle(fontSize: 12)))
      ],
    );
  }
}

// Minimal curved arrow as placeholder
class CurvedArrowWidget extends StatelessWidget {
  const CurvedArrowWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(60, 30), painter: _ArrowPainter());
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final path = Path();
    path.moveTo(10, 25);
    path.cubicTo(30, 5, 30, 5, 50, 25);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

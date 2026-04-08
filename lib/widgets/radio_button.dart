import 'package:flutter/material.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';

class TickRadioButton extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const TickRadioButton({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor =AppColor.red,
    this.inactiveColor = Colors.grey,
    this.size = 24.0,
  });

  @override
  TickRadioButtonState createState() => TickRadioButtonState();
}

class TickRadioButtonState extends State<TickRadioButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onChanged != null) {
          widget.onChanged!(!widget.value);
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.value ? widget.activeColor : widget.inactiveColor,
            width: 2.0,
          ),
          color: widget.value ? widget.activeColor : Colors.transparent,
        ),
        child: widget.value
            ? CustomPaint(
                painter: _TickPainter(color: Colors.white),
                size: Size(widget.size, widget.size),
              )
            : null,
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  final Color color;

  _TickPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.65);
    path.lineTo(size.width * 0.75, size.height * 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
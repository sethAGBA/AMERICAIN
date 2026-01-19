import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class LudoDice extends StatefulWidget {
  final int? value; // Current value (1-6), null if waiting
  final bool isRolling;
  final bool isSelected;
  final VoidCallback? onTap;

  const LudoDice({
    super.key,
    this.value,
    this.isRolling = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<LudoDice> createState() => _LudoDiceState();
}

class _LudoDiceState extends State<LudoDice>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayedValue = 1;
  Timer? _rollingTimer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.isRolling) {
      _startRolling();
    } else if (widget.value != null) {
      _displayedValue = widget.value!;
    }
  }

  @override
  void didUpdateWidget(LudoDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _startRolling();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _stopRolling();
    } else if (!widget.isRolling &&
        widget.value != null &&
        widget.value != _displayedValue) {
      _displayedValue = widget.value!;
    }
  }

  void _startRolling() {
    _controller.repeat();
    _rollingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _displayedValue = _random.nextInt(6) + 1;
        });
      }
    });
  }

  void _stopRolling() {
    _rollingTimer?.cancel();
    _controller.stop();
    // Ensure we show the final actual value
    if (widget.value != null) {
      setState(() {
        _displayedValue = widget.value!;
      });
    }
  }

  @override
  void dispose() {
    _rollingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRolling ? null : widget.onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.yellow.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: widget.isSelected ? Colors.orange : Colors.grey.shade300,
            width: widget.isSelected ? 4 : 2,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = widget.isRolling ? _controller.value * 2 * pi : 0.0;
            return Transform.rotate(
              angle: angle,
              child: CustomPaint(painter: DiceFacePainter(_displayedValue)),
            );
          },
        ),
      ),
    );
  }
}

class DiceFacePainter extends CustomPainter {
  final int value;

  DiceFacePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final dotSize = size.width * 0.15;
    final center = size.center(Offset.zero);
    final w = size.width;
    final h = size.height;

    // Define dot positions
    final tl = Offset(w * 0.25, h * 0.25);
    final tr = Offset(w * 0.75, h * 0.25);
    final mid = center;
    final bl = Offset(w * 0.25, h * 0.75);
    final br = Offset(w * 0.75, h * 0.75);
    final ml = Offset(w * 0.25, h * 0.5);
    final mr = Offset(w * 0.75, h * 0.5);

    switch (value) {
      case 1:
        canvas.drawCircle(mid, dotSize, paint);
        break;
      case 2:
        canvas.drawCircle(tl, dotSize, paint);
        canvas.drawCircle(br, dotSize, paint);
        break;
      case 3:
        canvas.drawCircle(tl, dotSize, paint);
        canvas.drawCircle(mid, dotSize, paint);
        canvas.drawCircle(br, dotSize, paint);
        break;
      case 4:
        canvas.drawCircle(tl, dotSize, paint);
        canvas.drawCircle(tr, dotSize, paint);
        canvas.drawCircle(bl, dotSize, paint);
        canvas.drawCircle(br, dotSize, paint);
        break;
      case 5:
        canvas.drawCircle(tl, dotSize, paint);
        canvas.drawCircle(tr, dotSize, paint);
        canvas.drawCircle(mid, dotSize, paint);
        canvas.drawCircle(bl, dotSize, paint);
        canvas.drawCircle(br, dotSize, paint);
        break;
      case 6:
        canvas.drawCircle(tl, dotSize, paint);
        canvas.drawCircle(tr, dotSize, paint);
        canvas.drawCircle(ml, dotSize, paint);
        canvas.drawCircle(mr, dotSize, paint);
        canvas.drawCircle(bl, dotSize, paint);
        canvas.drawCircle(br, dotSize, paint);
        break;
      default:
        // Draw ? for unknown?? Should not happen
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DiceFacePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

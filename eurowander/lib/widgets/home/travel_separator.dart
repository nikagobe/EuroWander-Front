import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A travel-themed section separator with a dotted flight path line.
/// Breaks visual monotony between sections with personality.
class TravelSeparator extends StatelessWidget {
  const TravelSeparator({
    super.key,
    this.style = TravelSeparatorStyle.flightPath,
    this.padding,
  });

  final TravelSeparatorStyle style;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: switch (style) {
        TravelSeparatorStyle.flightPath => _FlightPathSeparator(),
        TravelSeparatorStyle.wave => _WaveSeparator(),
        TravelSeparatorStyle.dots => _DotsSeparator(),
      },
    );
  }
}

enum TravelSeparatorStyle { flightPath, wave, dots }

class _FlightPathSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Icon(Icons.radio_button_checked, size: 8, color: ew.textTertiary),
          const SizedBox(width: 4),
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(color: ew.textTertiary.withOpacity(0.3)),
              size: const Size(double.infinity, 1),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.flight_rounded, size: 16, color: AppColors.brandPrimary.withOpacity(0.5)),
          const SizedBox(width: 4),
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(color: ew.textTertiary.withOpacity(0.3)),
              size: const Size(double.infinity, 1),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.location_on_rounded, size: 10, color: ew.textTertiary),
        ],
      ),
    );
  }
}

class _WaveSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    return SizedBox(
      height: 20,
      child: CustomPaint(
        painter: _WavePainter(color: ew.textTertiary.withOpacity(0.15)),
        size: const Size(double.infinity, 20),
      ),
    );
  }
}

class _DotsSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ew.textTertiary.withOpacity(0.3),
          ),
        )),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = size.height * 0.3;
    final waveLength = size.width / 6;

    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x += waveLength) {
      path.quadraticBezierTo(
        x + waveLength / 4, size.height / 2 - waveHeight,
        x + waveLength / 2, size.height / 2,
      );
      path.quadraticBezierTo(
        x + waveLength * 3 / 4, size.height / 2 + waveHeight,
        x + waveLength, size.height / 2,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

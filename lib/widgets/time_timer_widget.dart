// lib/widgets/time_timer_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Benötigt für den Zugriff auf den TimerService
import '../services/timer_service.dart'; // Dein TimerService

// TimeTimerWidget benötigt den CustomPainter
class TimeTimerWidget extends StatelessWidget {
  const TimeTimerWidget({super.key});

  // Hilfsfunktion, um Sekunden in MM:SS Format zu konvertieren
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Ruft den aktuellen Zustand des TimerService ab und aktualisiert das Widget bei Änderungen
    final timerService = context.watch<TimerService>(); 
    final progress = timerService.timerProgress;
    final remainingTime = timerService.remainingSeconds;
    final elapsedProgress = 1.0 - progress; // 0.0 (Start) bis 1.0 (Ende)
    final appBackgroundColor = Colors.blueGrey[900]!;

    // Größe des Timers
    const size = 250.0;

    return Center(
      child: SizedBox(
        width: size + 40,
        height: size + 40,
        child: Stack(
          alignment: Alignment.center,          
          children: [
            // 1. Der Timer-Kreis (CustomPainter)
            CustomPaint(
              size: const Size(size, size),
              painter: TimerPainter(
                // progress ist der ELAPSED progress (0.0 -> 1.0)
                progress: elapsedProgress, 
                
                backgroundColor: appBackgroundColor, 
                
                progressColor: Colors.redAccent,
              ),
            ),
            
            // 2. Der Text in der Mitte
            Text(
              _formatTime(remainingTime),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class TimerPainter extends CustomPainter {
  final double progress; // Fortschritt von 0.0 bis 1.0
  final Color backgroundColor;
  final Color progressColor;

  TimerPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });


  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const double pi = 3.1415926535;

    // 1. Zeichne den VOLLEN ROTEN KREIS (die initiale Zeit)
    final initialTimePaint = Paint()
      ..color = progressColor // Rot
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, initialTimePaint); 

    // 2. Zeichne den Bogen des VERBRAUCHTEN Teils (mit der Hintergrundfarbe)
    final elapsedPaint = Paint()
      ..color = backgroundColor // Grau (Hintergrund)
      ..style = PaintingStyle.fill;

    // Startwinkel: Oben (12 Uhr Position)
    const startAngle = -pi / 2.0; 

    // Sweep-Winkel: Entspricht dem VERGANGENEN Fortschritt (progress geht von 0.0 auf 1.0)
    // Wir zeichnen positiv (im Uhrzeigersinn).
    final sweepAngle = 2 * pi * progress; 

    // Zeichne den grauen Bogen, der die rote Fläche überdeckt.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,       // Startet oben (12 Uhr)
      sweepAngle,       // Füllt im Uhrzeigersinn
      true,             // Schließt den Mittelpunkt ein (Kuchenstück)
      elapsedPaint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    // Das Widget muss neu gezeichnet werden, wenn sich der Fortschritt (progress) ändert
    return oldDelegate.progress != progress;
  }
}
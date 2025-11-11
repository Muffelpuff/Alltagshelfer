// lib/services/timer_service.dart

import 'dart:async';
import 'package:flutter/material.dart';

class TimerService extends ChangeNotifier {
  Timer? _timer; 
  int _secondsRemaining = 0; 
  int _totalDurationSeconds = 0; 
  bool _isFinished = true; 

  // --- Getter für die UI ---

  //bool get isFinished => _secondsRemaining <= 0;
  bool get isFinished => _isFinished;

  // Liefert den Timer-Fortschritt (1.0 = voll, 0.0 = leer)
  double get timerProgress {
    if (_totalDurationSeconds == 0 || _secondsRemaining <= 0) return 0.0;
    // Berechnet den verbleibenden Anteil
    return _secondsRemaining / _totalDurationSeconds; 
  }

  String get formattedTime { 
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    if (_secondsRemaining <= 0) return '00:00'; 
    return '$minutes:$seconds';
  }

  // --- Kontrollmethoden ---

  void start(int durationSeconds) {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
    }

    _secondsRemaining = durationSeconds;
    _totalDurationSeconds = durationSeconds; // WICHTIG: Dauer speichern!

    _isFinished = false; 
    
    notifyListeners(); 

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners(); 
      } else {
        _timer?.cancel();
        notifyListeners();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _secondsRemaining = 0;
    _totalDurationSeconds = 0; // Zurücksetzen
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Setzt den Timer sofort auf 0 (beendet die aktuelle Station) und stoppt ihn.
  void markAsFinished() {
    _timer?.cancel();
    _secondsRemaining = 0; // Setzt den Fortschritt auf 0%
    _isFinished = true;
    notifyListeners();
    print("TimerService: Station manuell als fertig markiert.");
  }
}
// lib/services/station_service.dart (Aktualisiert für Plan-Verwaltung)

import 'package:flutter/material.dart';
import '../models/station.dart';

class StationService extends ChangeNotifier {
  // Eine leere Liste, die vom PlanService geladen wird
  List<Station> _stations = [];
  int _currentIndex = 0;
  bool _isPlanFinished = false; 
  
  // --- Methode zur externen Aktualisierung des Plans ---
  // Wird vom PlanService aufgerufen, wenn ein neuer Benutzer ausgewählt wird
  void setPlan(List<Station> newStations) {
    _stations = newStations;
    _sortStationsByStartTime(); 
    _currentIndex = 0; // Startet immer beim ersten Element
    _isPlanFinished = _stations.isEmpty;
    notifyListeners();
  }

  // --- Getter ---
  List<Station> get stations => _stations;
  int get currentIndex => _currentIndex;
  bool get isPlanFinished => _isPlanFinished;
  
  Station get currentStation {
    if (_stations.isEmpty) {
      return Station(name: "Keine Station", mainImagePath: "", piktogramPath: "", startTime: "00:00");
    }
    return _stations[_currentIndex];
  }

  /// Prüft, ob eine Station (durch ihren Index) bereits abgeschlossen ist.
  /// Jede Station vor dem aktuellen Index gilt als abgeschlossen.
  bool isStationCompleted(int index) {
    return index < _currentIndex;
  }

  // --- Verwaltungsmethoden (mit Index-Logik) ---

  // Nur zum Hinzufügen/Bearbeiten/Löschen der aktuellen Liste (Änderung wird später an PlanService übermittelt)
  void addStation(Station station) {
    _stations.add(station);
    _sortStationsByStartTime();
    notifyListeners();
  }

  void updateStation(int index, Station newStation) {
    if (index >= 0 && index < _stations.length) {
      _stations[index] = newStation;
      _sortStationsByStartTime();
      notifyListeners();
    }
  }

  void deleteStation(int index) {
    if (index >= 0 && index < _stations.length) {
      _stations.removeAt(index);
      
      if (_currentIndex >= _stations.length) {
        _currentIndex = _stations.length > 0 ? _stations.length - 1 : 0;
      }
      
      notifyListeners();
    }
  }

  void _sortStationsByStartTime() {
    // Wenn keine Stationen oder nur eine vorhanden ist, brauchen wir nicht sortieren.
    if (_stations.length <= 1) return;

    // Sortiere die Liste mit einer benutzerdefinierten Vergleichsfunktion:
    _stations.sort((a, b) {
      // Vergleiche die Startzeiten direkt als String "HH:mm"
      // Da das Format konsistent ist, funktioniert der lexikographische Vergleich.
      return a.startTime.compareTo(b.startTime);
    });
  }
  
  // --- Navigation/Aktualisierung basierend auf der Uhrzeit ---

  // Aktualisiert die aktuelle Station basierend auf der tatsächlichen Zeit
  void updateCurrentStationByTime() {
    if (_isPlanFinished) return;
    if (_stations.isEmpty) return;

    final now = DateTime.now();
    int newIndex = _currentIndex; // Starte beim aktuellen Index
    bool stationChanged = false; // Flag, um Änderungen zu verfolgen

    // Die korrekte Station finden (basierend auf der Zeit)
    for (int i = 0; i < _stations.length; i++) {
      final stationTime = _parseTime(_stations[i].startTime);

      if (now.isAfter(stationTime)) {
        newIndex = i;
      } else {
        // Wenn die Zeit noch nicht erreicht ist, ist die vorherige Station
        // die aktuelle, es sei denn, es ist die allererste.
        break; 
      }
    }

    // Wenn der Index anders ist, hat sich die Station geändert
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      stationChanged = true;
    }
    
    if (stationChanged) {
      notifyListeners();
      print("StationService: Station gewechselt zu Index $_currentIndex");
    } else {
      
    }
  }

  int get currentStationDurationSeconds {
    if (_stations.isEmpty || _currentIndex >= _stations.length) {
      return 0; // Keine Stationen, keine Dauer
    }
    
    // 1. Hole die Startzeit der aktuellen Station
    final currentStation = _stations[_currentIndex];
    final now = DateTime.now();

    

    // 2. Suche die Startzeit der nächsten Station
    Station? nextStation;
    if (_currentIndex + 1 < _stations.length) {
      nextStation = _stations[_currentIndex + 1];
    } else {
      // Wenn es die letzte Station ist, nehmen wir eine feste Dauer 
      // (z.B. 10 Minuten) oder bis Mitternacht.
      // Für einfache Timings nehmen wir 10 Minuten (600 Sekunden).
      return 600; 
    }

    try {
      // Hilfsfunktion zur Umwandlung von "HH:mm" zu DateTime (heutiger Tag)
      DateTime _parseTime(String time) {
        final parts = time.split(':');
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      
      final currentTime = _parseTime(currentStation.startTime);
      final nextTime = _parseTime(nextStation!.startTime);
      
      // Berechne die Dauer (in Sekunden)
      final duration = nextTime.difference(currentTime);
      
      // Die Dauer muss positiv sein
      if (duration.inSeconds > 0) {
        return duration.inSeconds;
      }
      
      return 0; // Ungültige Dauer
      
    } catch (e) {
      print("Fehler beim Parsen der Startzeiten im StationService: $e");
      return 600; // Fallback auf 10 Minuten
    }
  }

  // Hilfsmethode: Wandelt eine Zeitangabe "HH:mm" in ein DateTime-Objekt des heutigen Tages um
  DateTime _parseTime(String time) {
    final now = DateTime.now();
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
    } catch (e) {
      print("Fehler beim Parsen der Zeit '$time': $e");
      // Fallback: Gibt die aktuelle Zeit zurück, um Abstürze zu vermeiden
      return now; 
    }
  }

  int get elapsedSeconds {
    if (_stations.isEmpty || _currentIndex >= _stations.length) {
      return 0;
    }
    
    final currentStation = _stations[_currentIndex];
    final now = DateTime.now();

    try {
      // Hilfsfunktion zur Umwandlung von "HH:mm" zu DateTime (heutiger Tag)
      DateTime _parseTime(String time) {
        final parts = time.split(':');
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      
      final startTime = _parseTime(currentStation.startTime);
      
      // Berechne die verstrichene Zeit
      final Duration elapsed = now.difference(startTime);
      
      // Die verstrichene Zeit sollte nicht negativ sein (außer wenn die App zu früh startet)
      return elapsed.inSeconds.clamp(0, currentStationDurationSeconds); 
      
    } catch (e) {
      print("Fehler beim Parsen der Startzeit für elapsedSeconds: $e");
      return 0;
    }
  }

  /// Erhöht den Index manuell und löst damit den Stationswechsel aus.
  void goToNextStation() {
    if (stations.isEmpty) return;
    if (_isPlanFinished) return;
    // Prüfen, ob wir uns VOR der letzten Station befinden
    if (_currentIndex < stations.length - 1) {
      _currentIndex++;
    } else if (stations.isNotEmpty) {
      // WICHTIG: Die letzte Station wurde gerade abgeschlossen!
      _isPlanFinished = true;
      // Den Index auf dem letzten Element lassen, oder optional auf stations.length setzen
      _currentIndex = stations.length - 1; 
    }
    
    // Benachrichtigt alle Hörer (MainScreen)
    notifyListeners();
  }
  
}
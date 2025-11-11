// lib/services/plan_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_plan.dart';
import '../models/station.dart';
import 'station_service.dart';
import '../screens/main_screen.dart';
import 'dart:async';

class PlanService extends ChangeNotifier {
  final StationService _stationService;
  List<UserPlan> _plans = [];
  UserPlan? _currentPlan;
  
  static const String _fileName = 'daily_plans_data.json';

  final Completer<void> _initializationCompleter = Completer<void>();

  // Konstruktor benötigt den StationService für die Aktualisierung
  PlanService(this._stationService) {
    print("PlanService: Konstruktor gestartet. Lade Pläne...");
    _loadPlans();
  }

  // --- Getter ---
  List<UserPlan> get plans => _plans;
  UserPlan? get currentPlan => _currentPlan;
  
  // --- Dateihandling ---
  
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<void> _loadPlans() async {
    try {
      final file = await _getLocalFile();
      
      // Fall 1: Datei existiert
      if (await file.exists()) {
        final contents = await file.readAsString();
        
        // Füge einen Check hinzu, falls die Datei leer ist
        if (contents.isNotEmpty) {
            final List<dynamic> jsonList = jsonDecode(contents);
            _plans = jsonList.map((json) => UserPlan.fromJson(json)).toList();
            print("PlanService: Pläne aus Datei geladen. Anzahl: ${_plans.length}");
        }
        
        // WICHTIG: Wenn die Datei existiert, ABER die Pläne leer sind, initialisiere NEU
        if (_plans.isEmpty) { 
            print("PlanService: Datei existiert, aber Pläne sind leer (oder defekt). Initialisiere Standardpläne...");
            await _initializeDefaultPlans();
            print("PlanService: Standardpläne initialisiert. Anzahl: ${_plans.length}");
        }
        
      } else {
        // Fall 2: Datei existiert NICHT (beim allerersten Start)
        print("PlanService: Keine Datei gefunden. Initialisiere Standardpläne...");
        await _initializeDefaultPlans(); 
        print("PlanService: Standardpläne initialisiert. Anzahl: ${_plans.length}");
      }
    } catch (e) {
      print("PlanService: KRITISCHER FEHLER beim Laden/Initialisieren: $e");
      // Bei einem Fehler (z.B. defektes JSON) immer neu initialisieren
      await _initializeDefaultPlans(); 
    }
    
    // Setze den ersten Plan als aktuellen Plan
    if (_plans.isNotEmpty) {
      _selectPlan(_plans.first.id);
      print("PlanService: Erster Plan ausgewählt: ${_currentPlan!.name}");
    } else {
      print("PlanService: ACHTUNG: Die Pläne sind immer noch leer.");
    }
    
    notifyListeners();
  }
  
  Future<void> _savePlans() async {
    final file = await _getLocalFile();
    final jsonList = _plans.map((plan) => plan.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
    print("PlanService: Pläne gespeichert.");
  }

  // KORREKTUR: Methode muss Future<void> zurückgeben und async sein
  Future<void> _initializeDefaultPlans() async { 
    // Erstelle Standardplan 1 (Leonid)
    final defaultStations1 = [
      Station(name: "Zähne putzen", mainImagePath: "assets/img/brush_main.png", piktogramPath: "assets/img/brush_pikt.png", startTime: "08:00"),
      Station(name: "Anziehen", mainImagePath: "assets/img/dress_main.png", piktogramPath: "assets/img/dress_pikt.png", startTime: "08:05"),
    ];
    // Erstelle Standardplan 2 (Anna)
    final defaultStations2 = [
      Station(name: "Frühstück", mainImagePath: "assets/img/eat_main.png", piktogramPath: "assets/img/eat_pikt.png", startTime: "08:30"),
      Station(name: "Schuhe anziehen", mainImagePath: "assets/img/shoes_main.png", piktogramPath: "assets/img/shoes_pikt.png", startTime: "08:45"),
    ];

    final List<UserPlan> defaultPlans = [
      UserPlan(
        id: '1', 
        name: 'Morgenplan',
        profileImagePath: 'assets/img/profile_1.png',
        stations: List<Station>.from(defaultStations1),
      ),
      UserPlan(
        id: '2', 
        name: 'Abendplan',
        profileImagePath: 'assets/img/profile_2.png',
        stations: List<Station>.from(defaultStations2),
      ),
    ];
    
    _plans = defaultPlans; // Zuweisung der Pläne
    await _savePlans(); // KORREKTUR: Auf das Speichern warten
  }

  // --- Plan-Verwaltung ---

  void _selectPlan(String id) {
    _currentPlan = _plans.firstWhere((p) => p.id == id, orElse: () => _plans.first);
    // Aktualisiere den aktiven Plan im StationService
    _stationService.setPlan(_currentPlan!.stations);
    // Beachte: _selectPlan sollte die Zeitnavigation NICHT direkt starten, 
    // das ist Aufgabe des MainScreen.
    notifyListeners();
  }
  
  // Wird vom Startbildschirm aufgerufen
  void selectPlanAndNavigate(BuildContext context, String id) {
    _selectPlan(id);
    // Navigiere zum Hauptbildschirm
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  // ... (restliche Methoden: saveCurrentPlanChanges, selectPlanId, addPlan, deletePlan, updateCurrentPlanDetails, updatePlan) ...
  // Diese können so bleiben, wie in der letzten Antwort korrigiert, solange sie Future<void> zurückgeben, wo asynchrone Arbeit anfällt.

  Future<void> addPlan(UserPlan newPlan) async { 
    _plans.add(newPlan);
    await _savePlans();
    notifyListeners();
  }

  Future<void> deletePlan(String id) async { 
    _plans.removeWhere((plan) => plan.id == id);
    
    if (_currentPlan?.id == id && _plans.isNotEmpty) {
      _selectPlan(_plans.first.id);
    } else if (_plans.isEmpty) {
      _currentPlan = null;
      _stationService.setPlan([]);
    }
    
    await _savePlans();
    notifyListeners();
  }
  
  // Diese Methode ist jetzt die Hauptmethode für Speichern/Aktualisieren
  Future<void> updatePlan(UserPlan updatedPlan) async {
    final index = _plans.indexWhere((p) => p.id == updatedPlan.id);
    if (index == -1) return;

    _plans[index] = updatedPlan;
    _currentPlan = updatedPlan;

    _stationService.setPlan(updatedPlan.stations);
    
    // Starte die Zeit-Navigation nach dem Speichern
    _stationService.updateCurrentStationByTime(); 
    
    await _savePlans();
    notifyListeners();
  }

  // Wird vom SupervisorScreen aufgerufen, um Änderungen zu speichern (kann vereinfacht werden)
  void saveCurrentPlanChanges() {
    if (_currentPlan != null) {
      _savePlans();
    }
  }

  // Aktualisiert Name und Bildpfad des aktuell ausgewählten Plans
  void updateCurrentPlanDetails(String newName, String newImagePath) {
    if (_currentPlan == null) return;
    
    final index = _plans.indexWhere((p) => p.id == _currentPlan!.id);
    if (index == -1) return;

    final updatedPlan = UserPlan(
      id: _currentPlan!.id,
      name: newName,
      profileImagePath: newImagePath,
      stations: _currentPlan!.stations,
    );

    _plans[index] = updatedPlan;
    _currentPlan = updatedPlan;
    
    _savePlans();
    notifyListeners();
  }
}
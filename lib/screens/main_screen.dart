// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // Für Image.file und File
import 'dart:async'; 
import '../services/station_service.dart';
import 'supervisor_screen.dart';
import '../services/timer_service.dart';
import '../models/station.dart'; 
import '../services/audio_service.dart'; 
import '../screens/end_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Interner Timer zur automatischen Aktualisierung der Station basierend auf der Zeit
  Timer? _updateTimer;
  
  // Private Variable zum sicheren Speichern des StationService (Behebt den dispose-Fehler)
  late StationService _stationService; 
  late TimerService _timerService;
  int? _lastLoadedStationIndex; 
  
  /*
  void _stationServiceListener() {
    // Holt den StationService hier, um ihn an _resetTimer zu übergeben
    // KORRIGIERT: Verwendet die Instanzvariable
    _resetTimer(_stationService); 
  }
  */

  // didChangeDependencies zum einmaligen und sicheren Abrufen des Providers
  @override
  void didChangeDependencies() {
      super.didChangeDependencies();
      // Hole und speichere den Provider hier sicher
      _stationService = Provider.of<StationService>(context, listen: false);
      _timerService = Provider.of<TimerService>(context, listen: false);

      // Wichtig: Jetzt hören wir explizit auf Änderungen im StationService, 
      // um den Timer neu zu starten, wenn die Station wechselt.
      _stationService.addListener(_handleStationChange);
      
      // Initialer Start beim ersten Laden
      _handleStationChange();
  }

  @override
  void initState() {
    super.initState();
    // Starte die automatische Aktualisierung, sobald der Kontext verfügbar ist
    Future.microtask(() => _setupServices());
  }

  @override
  void dispose() {
    _updateTimer?.cancel(); 
    // FEHLER BEHOBEN: Verwenden der gespeicherten Instanz
    _stationService.removeListener(_handleStationChange);
    super.dispose();
  }

  // Setzt die Services auf
  void _setupServices() {
      // KORRIGIERT: Verwenden der gespeicherten Instanz
      
      // 1. Initialisiere den Auto-Update-Timer (wie zuvor)
      _startAutoUpdate(_stationService);
      
      // 2. Setze den initialen Timer-Zähler für die UI
      _resetTimer(_stationService);
      
      // 3. Füge einen Listener hinzu: Verwenden der gespeicherten Instanz
      //_stationService.addListener(_stationServiceListener); 
  }

  // Startet den Countdown-Timer
  void _resetTimer(StationService stationService) {
    // Hole den TimerService
    final timerService = Provider.of<TimerService>(context, listen: false);
    
    // 1. Hole die GESAMTDAUER der aktuellen Station (z.B. 3600 Sekunden)
    final totalDuration = stationService.currentStationDurationSeconds;

    // 2. Hole die BEREITS VERSTRICHENE Zeit (z.B. 2400 Sekunden)
    final elapsed = stationService.elapsedSeconds;
    
    // 3. Berechne die TATSÄCHLICH VERBLEIBENDE Zeit
    final remainingTime = totalDuration - elapsed;

    // Starte den Timer neu mit der tatsächlich verbleibenden Zeit
    // Wichtig: Die verbleibende Zeit muss positiv sein.
    final duration = remainingTime.clamp(0, totalDuration);

    timerService.start(duration);
  }
  
  void _startAutoUpdate(StationService stationService) {
    final stationService = Provider.of<StationService>(context, listen: false);

    // Initial einmal aktualisieren
    stationService.updateCurrentStationByTime();
    
    // Jede Minute aktualisieren (oder alle 30 Sekunden für Genauigkeit)
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      stationService.updateCurrentStationByTime();
    });
  }


void _handleStationChange() {
  if (_stationService.currentStation == null) return;
  if (_stationService.currentIndex == _lastLoadedStationIndex) return; 

  final currentStation = _stationService.currentStation!;
  
  // 1. Berechne die verbleibende Zeit
  final totalDurationInSeconds = _calculateRemainingSeconds(currentStation);
  
  // 2. TimerService neu starten
  _timerService.start(totalDurationInSeconds);

  // Audio-Service abrufen (nehmen wir an, er ist auch über Provider verfügbar)
  final audioService = Provider.of<AudioService>(context, listen: false); 
  
  // Wenn ein Soundpfad existiert, spiele ihn ab
  if (currentStation.soundPath.isNotEmpty) {
    audioService.playStationSound(currentStation.soundPath);
  }
  
  _lastLoadedStationIndex = _stationService.currentIndex;
}


/// Berechnet die verbleibende Zeit, indem die verstrichene Zeit 
/// von der Gesamtdauer der aktuellen Station abgezogen wird.
int _calculateRemainingSeconds(Station currentStation) {
  // Die Dauer wird als Differenz zwischen aktueller und nächster Startzeit 
  // im Service berechnet.
  final totalDuration = _stationService.currentStationDurationSeconds;

  // Die bereits verstrichene Zeit seit dem geplanten Start der aktuellen Station.
  final elapsed = _stationService.elapsedSeconds;
  
  // Die TATSÄCHLICH VERBLEIBENDE Zeit
  final remainingTime = totalDuration - elapsed;

  // Gib die verbleibende Zeit (mindestens 0, maximal die Gesamtdauer) zurück.
  return remainingTime.clamp(0, totalDuration);
}

  // --- UI-BAUKASTEN-METHODEN ---

  @override
  Widget build(BuildContext context) {
    // Services abhören
    final stationService = Provider.of<StationService>(context);
    //final stationService = context.watch<StationService>();
    //final timerService = context.watch<TimerService>();
    final timerService = Provider.of<TimerService>(context, listen: false);
    final countdownColor = timerService.isFinished ? Colors.redAccent : Colors.lightGreenAccent;

    // Prüfen, ob Stationen vorhanden sind
    if (stationService.stations.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Aktuelle Stationsdaten
    final currentStation = stationService.currentStation;

    if (stationService.isPlanFinished) {
      // Stoppe jeglichen laufenden Sound, falls noch vorhanden (optional)
      Provider.of<AudioService>(context, listen: false).stopSound();
      
      return const EndScreen();
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[900], 
      appBar: AppBar(
        automaticallyImplyLeading: false, // Normalerweise unnötig, aber gute Praxis
        title: Text(
          '${currentStation.startTime} - ${currentStation.name}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent, // Transparent, da der Body den Hintergrund setzt
        elevation: 0,
        actions: [
          //  Der Button für den Supervisor Screen
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70, size: 30),
            onPressed: () async { // Den onPressed-Callback zu 'async' machen
              timerService.stop(); 
              
              // Navigiere und warte, bis der SupervisorScreen geschlossen wird
              await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const SupervisorScreen(),
                  ),
              );
              
              // DIESER CODE WIRD AUSGEFÜHRT, NACHDEM DER SUPERVISOR GESCHLOSSEN WURDE:
              
              // Timer neu starten, da sich die Stationsdaten geändert haben könnten
              final currentStation = stationService.currentStation;
              final totalDurationInSeconds = _calculateRemainingSeconds(currentStation);
              timerService.start(totalDurationInSeconds);

          },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [              
              
              // 1. OBERER BEREICH: Uhrzeit-Info und Countdown-Visualisierung
              Row( 
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                    // Linker Teil: Statische Startzeit (Ihre Column) ...
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          const Text('Startzeit:', style: TextStyle(fontSize: 20, color: Colors.white70)),
                          Text(currentStation.startTime, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                    ),

                    // Countdown-Ring und Text (Ihre Row) ...
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TimerRing(progress: timerService.timerProgress, isFinished: timerService.isFinished),
                        Text(
                          timerService.formattedTime,
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: countdownColor),
                        ),
                      ],
                    ),
                ],
              ),

              // Vertikaler Abstand
              const SizedBox(height: 30), // Fixer Abstand zum oberen Rand

              // 2. MITTLERER BEREICH: Bilder (nimmt den gesamten restlichen Platz ein, bis zum Button)
              Expanded( 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Hauptbild (links)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: _StationImage(
                          path: currentStation.mainImagePath, 
                          fallbackColor: Colors.indigo
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Piktogramm (rechts)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: _StationImage(
                          path: currentStation.piktogramPath, 
                          fallbackColor: Colors.teal
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Vertikaler Abstand zum Button
              const SizedBox(height: 30), 

              // 3. UNTERER BEREICH: Der "Abhaken" / Fertig-Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                child: ElevatedButton.icon(
                  onPressed: timerService.isFinished
                      ? null // Button ist nur deaktiviert, wenn die Station fertig ist
                      : () {
                          // Aktion zum sofortigen Beenden
                          timerService.markAsFinished();
                          stationService.goToNextStation();
                        },
                  icon: const Icon(Icons.check_circle_outline, size: 30),
                  label: const Text(
                    'Station abschließen / Abhaken',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: countdownColor, 
                    foregroundColor: Colors.black, 
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              // 4. HORIZONTALE VORSCHAU-LISTE
              const SizedBox(height: 20), // Abstand vom Button
              
              // NEU: Wickeln Sie die Vorschau in ein Center-Widget
              Center( 
                child: SizedBox(
                  // Die Breite kann auf unendlich gesetzt werden, da die ListView 
                  // selbst durch ihre Elemente (size=70.0) die Breite bestimmt.
                  // Wir müssen jedoch die Breite auf eine Grenze setzen, 
                  // falls die ListView NICHT die volle Breite nutzen soll.
                  // Da wir zentrieren wollen, ist es am einfachsten, hier 
                  // die volle Breite (oder eine hohe feste Zahl) zu lassen, 
                  // solange die Column auf Center steht.
                  height: 80, // Höhe der Vorschauliste
                  child: ListView.builder(
                    // ListView muss NICHT mehr shrinkWrap: true haben, wenn sie in einem 
                    // Container mit fester Höhe ist. Aber wir lassen es aus Sicherheitsgründen.
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: stationService.stations.length,
                    itemBuilder: (context, index) {
                      final station = stationService.stations[index];
                      return _StationPreviewItem(
                        station: station,
                        isCompleted: stationService.isStationCompleted(index),
                        isCurrent: stationService.currentIndex == index,
                      );
                    },
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
}
  
  // Zustand, wenn keine Stationen geladen sind
  Widget _buildEmptyState(BuildContext context) {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Keine Stationen gefunden.\nBitte über das Zahnrad eine Station hinzufügen.",
            style: TextStyle(fontSize: 20, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SupervisorScreen()),
              );
            },
            icon: const Icon(Icons.settings, color: Colors.black),
            label: const Text("Zur Verwaltung", style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
          )
        ],
      )
     );
  }
  
  // Bildschirm nach Abschluss des Plans
  Widget _buildFinishedScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 150),
          const SizedBox(height: 20),
          const Text(
            'Tagesplan abgeschlossen!',
            style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Aktualisiert den Index auf die erste Station basierend auf der aktuellen Zeit
              Provider.of<StationService>(context, listen: false).updateCurrentStationByTime();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            child: const Text('Neustart', style: TextStyle(fontSize: 24, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- HILFS-WIDGET FÜR DIE BILDER (mit File/Asset Logik) ---
class _StationImage extends StatelessWidget {
  final String path;
  final Color fallbackColor;

  const _StationImage({required this.path, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
        // Fallback, wenn kein Pfad angegeben ist
        return Container(
          decoration: BoxDecoration(
            color: fallbackColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white70, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.white, size: 50),
          ),
        );
    }
    
    Widget imageWidget;
    
    // 1. Prüfe, ob es sich um einen App-Asset-Pfad handelt (Standard-Pfade)
    if (path.startsWith('assets/')) {
      imageWidget = Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Asset Fehler: ${path.split('/').last}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
    } 
    // 2. Ansonsten behandle es als einen permanenten Systempfad (aus dem Dateipicker)
    else {
      final file = File(path);
      imageWidget = Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Datei nicht gefunden.\nPfad: ${path.split('/').last}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
    }
    
    // Umschließender Container für Rahmen
    return Container(
      decoration: BoxDecoration(
        color: fallbackColor.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white70, width: 2),
      ),
      padding: const EdgeInsets.all(8.0), 
      child: imageWidget,
    );
  }
}

// HILFS-WIDGET FÜR NUR DEN RING
class _TimerRing extends StatelessWidget {
  final double progress; 
  final bool isFinished;

  const _TimerRing({
    required this.progress,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    // KORRIGIERT: Größe nur für den Ring. Kann kleiner sein, da kein Text mehr darin ist.
    const double size = 70; 
    
    final countdownColor = isFinished ? Colors.redAccent : Colors.lightGreenAccent;
    const Color backgroundRingColor = Colors.white24; 
    const double strokeWidth = 15; 

    return Padding(
      padding: const EdgeInsets.only(right: 10.0), // Abstand zum Text
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Der äußere Ring (die gesamte Dauer)
            CircularProgressIndicator(
              value: 1.0, 
              strokeWidth: strokeWidth, 
              valueColor: const AlwaysStoppedAnimation<Color>(backgroundRingColor), 
              backgroundColor: Colors.transparent,
            ),
            
            // 2. Der Füllstand (der Countdown)
            CircularProgressIndicator(
              value: progress.clamp(0.001, 1.0), 
              strokeWidth: strokeWidth, 
              valueColor: AlwaysStoppedAnimation<Color>(countdownColor),
              backgroundColor: Colors.transparent, 
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/main_screen.dart (NEUES WIDGET am Ende der Datei)

class _StationPreviewItem extends StatelessWidget {
  final Station station;
  final bool isCompleted;
  final bool isCurrent;

  const _StationPreviewItem({
    required this.station,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 70.0;
    
    // Wähle den Rahmen basierend auf dem Status
    BoxDecoration decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isCurrent ? Colors.lightGreenAccent : (isCompleted ? Colors.green : Colors.white24),
        width: isCurrent ? 3.0 : 2.0,
      ),
      boxShadow: isCurrent 
        ? [BoxShadow(color: Colors.lightGreenAccent.withOpacity(0.5), blurRadius: 8)] 
        : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Container(
        width: size,
        height: size,
        decoration: decoration,
        clipBehavior: Clip.antiAlias, // Wichtig für abgerundete Ecken des Bildes
        child: Stack(
          children: [
            // 1. Das Bild (hier verwenden wir das Piktogramm für die Übersichtlichkeit)
            _StationImage(
              path: station.piktogramPath, 
              fallbackColor: Colors.blueGrey[700]!, // Dunkler Fallback
            ),
            
            // 2. Das Häkchen für abgeschlossene Stationen
            if (isCompleted)
              Container(
                color: Colors.black54, // Dunkle Überlagerung
                child: const Center(
                  child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 30),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

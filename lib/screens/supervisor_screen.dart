// lib/screens/supervisor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/station.dart';
import '../models/user_plan.dart';
import '../services/station_service.dart';
import '../services/plan_service.dart';
import 'profile_selection_screen.dart';

class SupervisorScreen extends StatelessWidget {
  const SupervisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _SupervisorScreenContent(),
    );
  }
}

class _SupervisorScreenContent extends StatefulWidget {
  const _SupervisorScreenContent();

  @override
  _SupervisorScreenState createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<_SupervisorScreenContent> {
  // --- Controller für Stations-Formular ---
  final _nameController = TextEditingController();
  final _mainImgController = TextEditingController();
  final _piktImgController = TextEditingController();
  final _startTimeController = TextEditingController();
  final TextEditingController _soundPathController = TextEditingController();

  // --- Controller für Profil-Formular ---
  final _profileNameController = TextEditingController();
  final _profileImgController = TextEditingController(); // Nur zur Anzeige des Pfades

  // --- State-Variablen ---
  int? _selectedIndex;
  
  // Temporäre Pfade für die Bildauswahl (wird für das Kopieren/Speichern benötigt)
  String? _pickedProfileImagePath;
  String? _pickedMainImagePath; 
  String? _pickedPiktogramPath; 


  @override
  void initState() {
    super.initState();
    // Initialisiere Formulare, wenn ein Plan geladen ist
    Future.microtask(_populateProfileFormOnLoad);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mainImgController.dispose();
    _piktImgController.dispose();
    _startTimeController.dispose();
    _profileNameController.dispose();
    _profileImgController.dispose();
    super.dispose();
  }

  // --- Helpers für Initialisierung und Formular-Management ---

  // Initialisiert das Profilformular beim Laden
  void _populateProfileFormOnLoad() {
    final planService = Provider.of<PlanService>(context, listen: false);
    if (planService.currentPlan != null) {
      _profileNameController.text = planService.currentPlan!.name;
      
      // Setze den Picker-Pfad auf den aktuell gespeicherten Pfad
      _pickedProfileImagePath = planService.currentPlan!.profileImagePath; 
      
      // Zeige den Dateinamen des gespeicherten Pfades an
      if (_pickedProfileImagePath != null && _pickedProfileImagePath!.isNotEmpty) {
        _profileImgController.text = _pickedProfileImagePath!.split('/').last;
      } else {
        _profileImgController.clear();
      }
    }
  }

  // Befüllt das Stationsformular, wenn eine Station ausgewählt wird
  void _populateStationForm(Station station, int index) {
    setState(() {
      _selectedIndex = index;
      
      // Setze die Picker-Pfade auf die aktuellen Pfade der Station
      _pickedMainImagePath = station.mainImagePath;
      _pickedPiktogramPath = station.piktogramPath;
    });
    
    _nameController.text = station.name;
    _startTimeController.text = station.startTime; // NEU: Startzeit
    
    // Zeige im Controller nur den Dateinamen an
    _mainImgController.text = station.mainImagePath.split('/').last;
    _piktImgController.text = station.piktogramPath.split('/').last;
  }

  // Löscht alle Inhalte der Stationsformulare und Picker-Pfade
  void _clearStationForm() {
    setState(() {
      _selectedIndex = null;
      _pickedMainImagePath = null; 
      _pickedPiktogramPath = null;
    });
    _nameController.clear();
    _mainImgController.clear();
    _piktImgController.clear();
    _startTimeController.clear();
    _soundPathController.clear();
  }

  // Erstellt ein Stations-Objekt aus den Formular-Daten
  Station? _createStationFromForm() {
    final name = _nameController.text.trim();
    final startTime = _startTimeController.text.trim(); // NEU

    if (name.isEmpty || startTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name und Startzeit (hh:mm) dürfen nicht leer sein.')),
      );
      return null;
    }
    
    // Einfache Validierung des Zeitformats (hh:mm)
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Startzeit muss im Format hh:mm (z.B. 08:30) sein.')),
      );
      return null;
    }

    // Die Pfade kommen entweder aus dem Picker (temporärer State) oder sind die alten, gespeicherten Pfade
    final mainPath = _pickedMainImagePath ?? _mainImgController.text;
    final piktPath = _pickedPiktogramPath ?? _piktImgController.text;
    final soundPath = _soundPathController.text;

    return Station(
      name: name,
      mainImagePath: mainPath,
      piktogramPath: piktPath,
      startTime: startTime,
      soundPath: soundPath,
    );
  }

  // --- Bildauswahl und Kopierlogik ---

  // Allgemeine Methode zum Auswählen und Kopieren eines Bildes
  Future<String?> _pickAndCopyImage({required String subfolder}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return null;
    
    final originalPath = result.files.single.path!;
    final fileName = result.files.single.name;

    try {
      // Permanenten Zielpfad festlegen (im angegebenen Unterordner)
      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/$subfolder');
      
      // Stelle sicher, dass der Zielordner existiert
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      final permanentFilePath = '${targetDir.path}/$fileName';

      // Datei kopieren
      final sourceFile = File(originalPath);
      final copiedFile = await sourceFile.copy(permanentFilePath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bild ausgewählt und gespeichert: $fileName'))
      );
      return copiedFile.path;
      
    } catch (e) {
      print("Fehler beim Kopieren der Datei: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Speichern der Bilddatei.')),
      );
      return null;
    }
  }

  // Methode zur Auswahl einer lokalen Audio-Datei
  Future<void> _pickSoundFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'], // Häufige Audioformate
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _soundPathController.text = result.files.single.path!;
      });
    }
  }

  // Spezifische Picker für die UI

  // 1. Profilbild-Picker
  Future<void> _pickProfileImage() async {
    final newPath = await _pickAndCopyImage(subfolder: 'profiles');
    if (newPath != null) {
      setState(() {
        _pickedProfileImagePath = newPath;
      });
      _profileImgController.text = newPath.split('/').last;
    }
  }

  // 2. Stationsbild-Picker
  Future<void> _pickStationImage(bool isMainImage) async {
    final newPath = await _pickAndCopyImage(subfolder: 'stations');
    if (newPath != null) {
      setState(() {
        if (isMainImage) {
          _pickedMainImagePath = newPath;
          _mainImgController.text = newPath.split('/').last;
        } else {
          _pickedPiktogramPath = newPath;
          _piktImgController.text = newPath.split('/').last;
        }
      });
    }
  }


  // --- CRUD-Aktionen für Pläne und Stationen ---

  // Aktualisiert das aktuelle Profil (Name und Bildpfad)
  void _handleUpdateProfile(PlanService planService) async {
    final currentPlan = planService.currentPlan;
    if (currentPlan == null) return;
    
    final newName = _profileNameController.text.trim();
    
    // Falls der Picker-Pfad gesetzt ist, verwende ihn, sonst verwende den alten Pfad
    final newImgPath = _pickedProfileImagePath ?? currentPlan.profileImagePath; 

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilname darf nicht leer sein.')),
      );
      return;
    }
    
    final updatedPlan = currentPlan.copyWith(
      name: newName,
      profileImagePath: newImgPath,
    );
    
    await planService.updatePlan(updatedPlan);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil aktualisiert!')),
    );

    
  }

  // Erstellt ein neues Profil mit Standardwerten
  void _handleAddProfile(PlanService planService) async {
    final planName = 'Neuer Plan ${planService.plans.length + 1}';
    final newPlan = UserPlan( 
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: planName,
      profileImagePath: '',
      stations: []
    );

    await planService.addPlan(newPlan);
    _populateProfileFormOnLoad(); // Formular auf den neuen Plan setzen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan "$planName" hinzugefügt!')),
    );
  }

  // Löscht das aktuelle Profil
  void _handleDeleteProfile(PlanService planService) async {
    final currentPlan = planService.currentPlan;
    if (currentPlan == null) return;
    
    await planService.deletePlan(currentPlan.id);
    
    // Nach dem Löschen zur Profilauswahl zurückkehren
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ProfileSelectionScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // Speichert die Stationen in den PlanService (wird von CRUD-Stationen aufgerufen)
  void _saveStationsToPlan(PlanService planService, List<Station> updatedStations) async {
    final currentPlan = planService.currentPlan;
    if (currentPlan == null) return;
    
    final updatedPlan = currentPlan.copyWith(stations: updatedStations);
    await planService.updatePlan(updatedPlan);
    
    // Auch den StationService neu laden, damit die Hauptansicht aktualisiert wird
    Provider.of<StationService>(context, listen: false).setPlan(updatedStations); 
  }

  // Fügt eine neue Station hinzu
  void _handleAddStation(PlanService planService) {
    final newStation = _createStationFromForm();
    if (newStation == null) return;

    final currentStations = List<Station>.from(planService.currentPlan!.stations);
    currentStations.add(newStation);
    
    _saveStationsToPlan(planService, currentStations);
    _clearStationForm();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Station "${newStation.name}" hinzugefügt!')),
    );
  }

  // Aktualisiert eine bestehende Station
  void _handleUpdateStation(PlanService planService) {
    final newStation = _createStationFromForm();
    if (newStation == null || _selectedIndex == null) return;
    
    final currentStations = List<Station>.from(planService.currentPlan!.stations);
    currentStations[_selectedIndex!] = newStation;
    
    _saveStationsToPlan(planService, currentStations);
    _clearStationForm();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Station "${newStation.name}" aktualisiert!')),
    );
  }

  // Löscht eine Station
  void _handleDeleteStation(PlanService planService) {
    if (_selectedIndex == null) return;
    
    final currentStations = List<Station>.from(planService.currentPlan!.stations);
    final deletedName = currentStations[_selectedIndex!].name;
    currentStations.removeAt(_selectedIndex!);
    
    _saveStationsToPlan(planService, currentStations);
    _clearStationForm();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Station "$deletedName" gelöscht!')),
    );
  }

  // Wichtig: Diese Funktion beendet den SupervisorScreen und geht zur Profilauswahl
  void _goToProfileSelection() {
    // Navigiert zur ProfileSelectionScreen und entfernt alle anderen Routen
    // (wichtig, um den Supervisor-Modus zu verlassen)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ProfileSelectionScreen()),
      (Route<dynamic> route) => false,
    );
  }


  // --- UI-Baukasten-Methoden ---

  @override
  Widget build(BuildContext context) {
    final planService = context.watch<PlanService>();
    final currentPlan = planService.currentPlan;

    

    if (currentPlan == null) {
      // Wichtig: Geben Sie einen Scaffold zurück, der den AppBar enthält, 
      // damit der Ladebildschirm nicht nur ein leerer weißer Body ist.
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tagesplan Verwaltung'),
          backgroundColor: Colors.blueGrey[800],
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _goToProfileSelection,
          ),
        ),
        body: _buildLoadingScreen(), 
      );
    }
    
    // Wenn currentPlan NICHT null ist, zeigen wir den Inhalt
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagesplan Verwaltung'),
        backgroundColor: Colors.blueGrey[800],
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _goToProfileSelection,
        ),
      ),
      backgroundColor: Colors.blueGrey[900], 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. LINKER BEREICH: Profil/Planübersicht und Stationsliste (Breiter)
              Expanded(
                flex: 2, // NEU: Linke Seite etwas breiter für Übersicht (z.B. 60%)
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildProfileOverview(context, currentPlan, planService), // Mit Daten füttern
                ),
              ),

              const SizedBox(width: 16),
              const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
              const SizedBox(width: 16),

              // 2. RECHTER BEREICH: Stations-Bearbeitung (Schmaler)
              Expanded(
                flex: 1, // NEU: Rechte Seite etwas schmaler (z.B. 40%)
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildStationManagement(context, currentPlan, planService), // Mit Daten füttern
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  


  Widget _buildProfileOverview(BuildContext context, UserPlan currentPlan, PlanService planService) {
    // LINKS: Zeigt die Planverwaltung und die Liste
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Profil-Management (Aktuelles Profil bearbeiten/wechseln)
        _buildPlanManagement(planService, currentPlan), // Ihre Plan-Verwaltung

        const SizedBox(height: 20),
        
        // 2. Stations-Liste
        Expanded( // Sorgt dafür, dass die Liste den restlichen Platz einnimmt
          child: SingleChildScrollView(
            child: _buildStationList(currentPlan.stations, planService), // Ihre Stationsliste
          ),
        ),
      ],
    );
  }

  // Stellt die Detailansicht und die Bearbeitung/Hinzufügung dar
  // ACHTUNG: Übergibt die benötigten Plan- und Service-Objekte
  Widget _buildStationManagement(BuildContext context, UserPlan currentPlan, PlanService planService) {
    // RECHTS: Zeigt das Stations-Formular (Bearbeiten/Hinzufügen)
    return SingleChildScrollView(
      child: _buildStationForm(planService), // Ihr Stations-Formular
    );
  }
  
  // 1. Profilverwaltung
  Widget _buildPlanManagement(PlanService planService, UserPlan currentPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aktuelles Profil bearbeiten:', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white30),
          
          _buildFormRow(label: 'Name:', controller: _profileNameController),
          
          // Bild auswählen
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickProfileImage,
                  icon: const Icon(Icons.folder_open, color: Colors.black),
                  label: const Text('Bild auswählen (.png/.jpg)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Zeige den ausgewählten/aktuellen Pfad an
          Text(
            'Aktuelles Bild: ${_pickedProfileImagePath == null || _pickedProfileImagePath!.isEmpty ? 'Kein neues Bild gewählt' : _profileImgController.text}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 15),
          
          // Aktionen
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleUpdateProfile(planService), 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Aktualisieren', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: planService.plans.length < 5 ? () => _handleAddProfile(planService) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Hinzufügen', style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: planService.plans.length > 1 ? () => _handleDeleteProfile(planService) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Löschen', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Stations-Formular (Hinzufügen/Bearbeiten)
  Widget _buildStationForm(PlanService planService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedIndex == null ? 'Neue Station hinzufügen:' : 'Station bearbeiten:', 
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
          ),
          const Divider(color: Colors.white30),

          _buildFormRow(label: 'Name:', controller: _nameController),
          _buildFormRow(
            label: 'Startzeit (hh:mm):', 
            controller: _startTimeController, 
            keyboardType: TextInputType.text
          ),

          // Auswahl-Button für Hauptbild
          _buildImageSelectionRow(
            label: 'Hauptbild wählen',
            onPressed: () => _pickStationImage(true),
            currentPath: _pickedMainImagePath,
            controller: _mainImgController, // Zur Anzeige des Dateinamens
          ),

          // Auswahl-Button für Piktogramm
          _buildImageSelectionRow(
            label: 'Piktogramm wählen',
            onPressed: () => _pickStationImage(false),
            currentPath: _pickedPiktogramPath,
            controller: _piktImgController, // Zur Anzeige des Dateinamens
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _soundPathController,
                    decoration: const InputDecoration(
                      labelText: 'Sound-Pfad (optional)',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true, // Der Pfad wird nur per Picker gesetzt
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickSoundFile, // Ruft die Methode zur Dateiauswahl auf
                  icon: const Icon(Icons.music_note),
                  label: const Text('Sound wählen'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 60),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Aktionen
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedIndex == null 
                      ? () => _handleAddStation(planService)
                      : () => _handleUpdateStation(planService),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  child: Text(
                    _selectedIndex == null ? 'Hinzufügen' : 'Speichern', 
                    style: const TextStyle(color: Colors.white)
                  ),
                ),
              ),
              if (_selectedIndex != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearStationForm,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Abbrechen', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleDeleteStation(planService),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Löschen', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 3. Stationsliste
  Widget _buildStationList(List<Station> stations, PlanService planService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stationsplan:', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white30),
          
          if (stations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Keine Stationen im Plan.', style: TextStyle(color: Colors.white70)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                return Card(
                  color: _selectedIndex == index ? Colors.blueGrey[700] : Colors.blueGrey[600],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text('${index + 1}.', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    title: Text(
                      '${station.startTime} - ${station.name}', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                    subtitle: Text(
                      'Bild: ${station.mainImagePath.split('/').last}', 
                      style: TextStyle(color: Colors.white70)
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.white),
                    onTap: () => _populateStationForm(station, index),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  // Ladezustand
  Widget _buildLoadingScreen() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}


// --- HILFS-WIDGETS ---

// Hilfswidget für einfache Textfelder
Widget _buildFormRow({
  required String label,
  required TextEditingController controller,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: Colors.blueGrey[700],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// Hilfswidget für Bildauswahl-Buttons
Widget _buildImageSelectionRow({
  required String label,
  required VoidCallback onPressed,
  String? currentPath,
  required TextEditingController controller, // Hier verwenden wir den Controller zur Anzeige
}) {
  final fileName = controller.text.isNotEmpty
      ? controller.text
      : 'Kein Bild ausgewählt';
      
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Datei auswählen', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Pfad: $fileName',
                style: TextStyle(
                  fontSize: 12, 
                  color: fileName.contains('Kein Bild') ? Colors.redAccent : Colors.lightGreen
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
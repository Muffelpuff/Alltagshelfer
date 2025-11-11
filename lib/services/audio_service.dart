// lib/services/audio_service.dart

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io'; // Für die Pfadprüfung (File)

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  AudioService() {
    // Optional: Konfigurieren Sie den Player, z.B. für Logs
    _player.setReleaseMode(ReleaseMode.stop); // Stoppt nach dem Abspielen
  }

  /// Startet die Wiedergabe eines Sounds über den gegebenen Pfad.
  /// Unterstützt lokale Dateien (aus Dateipicker) oder Assets.
  Future<void> playStationSound(String path) async {
    if (path.isEmpty) return;

    // Stoppe jegliche laufende Wiedergabe zuerst
    await _player.stop(); 

    // Wähle den Quelltyp basierend auf dem Pfad
    Source audioSource;
    
    // Annahme: Assets beginnen mit 'assets/', alles andere ist ein lokaler Pfad
    if (path.startsWith('assets/')) {
      audioSource = AssetSource(path.substring(7)); // 'assets/' entfernen
    } else if (File(path).existsSync()) {
      // Prüft, ob der Pfad eine lokale Datei ist und existiert
      audioSource = DeviceFileSource(path);
    } else {
      print("AudioService: Ungültiger oder nicht existierender Soundpfad: $path");
      return;
    }
    
    try {
      await _player.play(audioSource);
    } catch (e) {
      print("AudioService Fehler beim Abspielen von $path: $e");
    }
  }

  /// Stoppt die aktuelle Wiedergabe (wichtig beim Beenden der App)
  Future<void> stopSound() async {
    await _player.stop();
  }
  
  @override
  void dispose() {
    _player.dispose(); // Wichtig: Player beim Entfernen des Service freigeben
    super.dispose();
  }
}
// lib/screens/end_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/audio_service.dart';
import 'profile_selection_screen.dart';
// Importieren Sie Ihren ProfileSelectionScreen hier (Annahme: Sie haben eine Route dorthin)
// import 'profile_selection_screen.dart'; // Pfad anpassen, falls nötig

class EndScreen extends StatelessWidget {
  const EndScreen({super.key});

  // Annahme: Der ProfileSelectionScreen ist die Startseite oder die erste Route.
  // Wir verwenden hier popUntil, um alle Screens bis zum Root zu entfernen.
  void _goToStartScreen(BuildContext context) {
    // 1. Timer und Audio stoppen, falls sie noch aktiv sind
    Provider.of<TimerService>(context, listen: false).stop();
    Provider.of<AudioService>(context, listen: false).stopSound();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const ProfileSelectionScreen(), // Navigiert direkt zum Widget
      ),
      (Route<dynamic> route) => false, // Entfernt alle vorherigen Routen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade900, 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 150,
              ),
              const SizedBox(height: 30),
              
              const Text(
                'Tagesplan Abgeschlossen!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Alle Stationen wurden erfolgreich beendet. Gut gemacht!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              // NEU: Button zum Zurückkehren zur Startseite/Profilauswahl
              ElevatedButton.icon(
                onPressed: () => _goToStartScreen(context),
                icon: const Icon(Icons.people_alt, size: 24),
                label: const Text(
                  'Neuen Plan wählen',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
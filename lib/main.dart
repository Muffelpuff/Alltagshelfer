// lib/main.dart (KORRIGIERT UND VEREINFACHT)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'screens/profile_selection_screen.dart'; // NEUER STARTBILDSCHIRM
import 'services/timer_service.dart'; 
import 'services/station_service.dart'; 
import 'services/plan_service.dart';
import 'services/audio_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
        
        // 2. Station Service
        ChangeNotifierProvider(create: (_) => StationService()),

        ChangeNotifierProvider(create: (_) => AudioService()),

        // 3. Plan Service: Jetzt wieder ein normaler ChangeNotifierProvider!
        ChangeNotifierProvider( 
          create: (context) {
            // Holt eine Instanz des StationService
            final stationService = context.read<StationService>();
            return PlanService(stationService); // Übergibt ihn dem PlanService
          },
        ),
      ],
      child: const DailyPlannerApp(),
    ),
  );
}

class DailyPlannerApp extends StatelessWidget {
  const DailyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tagesplaner Timer',
      theme: ThemeData(
      ),
      // Startbildschirm ist jetzt der ProfileSelectionScreen
      home: const ProfileSelectionScreen(), 
      debugShowCheckedModeBanner: false, 
    );
  }
}
// lib/models/user_plan.dart

import 'station.dart';

class UserPlan {
  // WICHTIG: Die ID muss ein String sein, da sie aus den SharedPrefs kommt
  final String id; 
  final String name;
  final String profileImagePath;
  final List<Station> stations;

  UserPlan({
    required this.id,
    required this.name,
    required this.profileImagePath,
    required this.stations,
  });

  // Hinzufügen der copyWith-Methode (Fix für Fehler 246 und 293 in supervisor_screen.dart)
  UserPlan copyWith({
    String? id,
    String? name,
    String? profileImagePath,
    List<Station>? stations,
  }) {
    return UserPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      stations: stations ?? this.stations,
    );
  }

  factory UserPlan.fromJson(Map<String, dynamic> json) {
    // Wandelt die dynamische Liste in eine Liste von Stationen um
    final List<dynamic> stationsJson = json['stations'] as List<dynamic>;
    final stations = stationsJson
        .map((stationJson) => Station.fromJson(stationJson as Map<String, dynamic>))
        .toList();

    return UserPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImagePath: json['profileImagePath'] as String,
      stations: stations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImagePath': profileImagePath,
      // Wandelt die Liste der Stationen in JSON-Map-Objekte um
      'stations': stations.map((s) => s.toJson()).toList(),
    };
  }
}
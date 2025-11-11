// lib/models/station.dart

class Station {
  final String name;
  final String mainImagePath;
  final String piktogramPath;
  final String startTime; 
  final String soundPath;

  Station({
    required this.name,
    required this.mainImagePath,
    required this.piktogramPath,
    required this.startTime,
    this.soundPath = '',
  });

  // Anpassung der fromJson und toJson Methoden
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      name: json['name'] as String,
      mainImagePath: json['mainImagePath'] as String,
      piktogramPath: json['piktogramPath'] as String,
      startTime: json['startTime'] as String, 
      soundPath: json['soundPath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mainImagePath': mainImagePath,
      'piktogramPath': piktogramPath,
      'startTime': startTime,
      'soundPath': soundPath,
    };
  }
}
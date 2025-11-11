// lib/screens/profile_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/plan_service.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final planService = context.watch<PlanService>();
    final plans = planService.plans;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Wer bist du?',
              style: TextStyle(
                fontSize: 40, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
            const SizedBox(height: 50),
            
            Wrap(
              spacing: 30,
              runSpacing: 30,
              alignment: WrapAlignment.center,
              children: plans.map((plan) {
                return _ProfileCard(
                  name: plan.name,
                  imagePath: plan.profileImagePath,
                  onTap: () {
                    // Wählt den Plan und navigiert zum Hauptbildschirm
                    planService.selectPlanAndNavigate(context, plan.id);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.name,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              // Versuch, das Profilbild zu laden
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 70),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
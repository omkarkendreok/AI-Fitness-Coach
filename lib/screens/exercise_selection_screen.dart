import 'package:flutter/material.dart';

class ExerciseSelectionScreen extends StatelessWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Exercise"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _exerciseTile(
            title: "Push Ups",
            subtitle: "Upper body strength",
            icon: Icons.fitness_center,
            onTap: () {
              Navigator.pushNamed(
                context,
                "/exercise",
                arguments: {"exercise": "pushup"},
              );
            },
          ),

          _exerciseTile(
            title: "Squats",
            subtitle: "Leg strength training",
            icon: Icons.directions_run,
            onTap: () {
              Navigator.pushNamed(
                context,
                "/exercise",
                arguments: {"exercise": "squat"},
              );
            },
          ),

          _exerciseTile(
            title: "Bicep Curls",
            subtitle: "Arm strength training",
            icon: Icons.accessibility_new,
            onTap: () {
              Navigator.pushNamed(
                context,
                "/exercise",
                arguments: {"exercise": "bicep_curl"},
              );
            },
          ),

          // NEW — Lunges
          _exerciseTile(
            title: "Lunges",
            subtitle: "Lower body + balance",
            icon: Icons.directions_walk,
            onTap: () {
              Navigator.pushNamed(
                context,
                "/exercise",
                arguments: {"exercise": "lunge"},
              );
            },
          ),

          // NEW — Plank
          _exerciseTile(
            title: "Plank",
            subtitle: "Core stability",
            icon: Icons.accessibility,
            onTap: () {
              Navigator.pushNamed(
                context,
                "/exercise",
                arguments: {"exercise": "plank"},
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _exerciseTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

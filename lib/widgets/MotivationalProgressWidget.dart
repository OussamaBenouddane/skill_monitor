import 'package:flutter/material.dart';
import 'package:skill_monitor/utils/constants/colors.dart';

class MotivationalProgressWidget extends StatelessWidget {
  final List<Map<String, dynamic>> habits;
  final Map<int, Set<String>> selectedHabitsMap;

  const MotivationalProgressWidget({
    super.key,
    required this.habits,
    required this.selectedHabitsMap,
  });

  String _getMotivationalMessage(double progress) {
    if (progress == 0.0) {
      return 'Let\'s start crushing those habits!';
    } else if (progress <= 0.25) {
      return 'Great first steps! Keep it going!';
    } else if (progress <= 0.50) {
      return 'Halfway there! Stay focused!';
    } else if (progress < 1.0) {
      return 'So close! Push to the finish!';
    } else {
      return 'Nailed it! You\'re unstoppable!';
    }
  }

  double _calculateProgress() {
    final potentialHabits =
        habits.where((habit) => (habit['value'] as int) > 0).length;
    if (potentialHabits == 0) return 0.0;

    final completedHabits = habits.where((habit) {
      final habitName = habit['name'] as String;
      final habitValue = habit['value'] as int;
      final skillId = habit['skill_id'] as int;
      final selectedForSkill = selectedHabitsMap[skillId] ?? <String>{};
      return habitValue > 0 && selectedForSkill.contains(habitName);
    }).length;

    return completedHabits / potentialHabits;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final motivation = _getMotivationalMessage(progress);
    final potentialHabits =
        habits.where((habit) => (habit['value'] as int) > 0).length;
    final completedHabits = habits.where((habit) {
      final habitName = habit['name'] as String;
      final habitValue = habit['value'] as int;
      final skillId = habit['skill_id'] as int;
      final selectedForSkill = selectedHabitsMap[skillId] ?? <String>{};
      return habitValue > 0 && selectedForSkill.contains(habitName);
    }).length;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Black background for upper half
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100, // height of the black background
          child: Container(
            color: TColors.darkbg,
          ),
        ),

        // Your card with padding
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: TColors.purple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFD69B71),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                motivation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFD69B71)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Habits',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '$completedHabits/$potentialHabits',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

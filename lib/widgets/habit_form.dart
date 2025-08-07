import 'package:flutter/material.dart';

class HabitForm extends StatelessWidget {
  final int index;
  final HabitEntry habit;
  final VoidCallback? onDelete;
  final bool showDelete;

  const HabitForm({
    super.key,
    required this.index,
    required this.habit,
    this.onDelete,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Habit $index',
            ),
            const Spacer(),
            if (showDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: habit.nameController,
          decoration: InputDecoration(
            labelText: 'Habit Name',
            border: const OutlineInputBorder(),
          ),
        ),
        Row(
          children: [
            Text('Value: ${habit.value}'),
            Expanded(
              child: Slider(
                inactiveColor: Colors.white.withValues(alpha: 0.8),
                activeColor: const Color(0xFFD69B71),
                value: habit.value.toDouble(),
                min: -20,
                max: 20,
                divisions: 40,
                label: habit.value.toString(),
                onChanged: (newValue) {
                  habit.value = newValue.round();
                  (context as Element)
                      .markNeedsBuild(); // force rebuild to reflect slider text
                },
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}

class HabitEntry {
  final TextEditingController nameController;
  final int? id;
  final String? lastUpdated;
  int value;

  HabitEntry({
    required this.nameController,
    required this.value,
    this.lastUpdated,
    this.id,
  });
}

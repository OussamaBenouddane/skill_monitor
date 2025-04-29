import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
        ),
        Row(
          children: [
            Text('Value: ${habit.value}'),
            Expanded(
              child: Slider(
                value: habit.value.toDouble(),
                min: -20,
                max: 20,
                divisions: 40,
                label: habit.value.toString(),
                onChanged: (newValue) {
                  habit.value = newValue.round();
                  (context as Element).markNeedsBuild(); // force rebuild to reflect slider text
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
  int value;

  HabitEntry({
    required this.nameController,
    required this.value,
    this.id,
  });
}


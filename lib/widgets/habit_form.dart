import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitForm extends StatelessWidget {
  final int index;
  final HabitEntry habit;

  const HabitForm({super.key, required this.index, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habit $index',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
            Text(
              'Value: ${habit.value}',
            ),
            Expanded(
              child: Slider(
                value: habit.value.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                label: habit.value.toString(),
                onChanged: (newValue) {
                  habit.value = newValue.round();
                  (context as Element).markNeedsBuild();
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
  final TextEditingController nameController = TextEditingController();
  int value = 0;
}

import 'package:flutter/material.dart';

class SkillSetupScreen extends StatefulWidget {
  @override
  _SkillSetupScreenState createState() => _SkillSetupScreenState();
}

class _SkillSetupScreenState extends State<SkillSetupScreen> {
  final TextEditingController _skillNameController = TextEditingController();

  List<HabitEntry> _habits = [HabitEntry()];

  void _addHabit() {
    setState(() {
      _habits.add(HabitEntry());
    });
  }

  void _finish() {
    final skillName = _skillNameController.text;
    if (skillName.trim().isEmpty || _habits.any((h) => h.nameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter skill name and all habit names.'),
      ));
      return;
    }

    final habitData = _habits.map((h) => {
      'name': h.nameController.text,
      'value': h.value,
    }).toList();

    final data = {
      'skill': skillName,
      'habits': habitData,
    };

    print('Skill setup: $data'); // Just logs for now
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    _habits.forEach((h) => h.nameController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Skill')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _skillNameController,
              decoration: InputDecoration(labelText: 'Skill Name'),
            ),
            SizedBox(height: 20),
            ..._habits.asMap().entries.map((entry) {
              final index = entry.key;
              final habit = entry.value;
              return HabitForm(index: index + 1, habit: habit);
            }),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addHabit,
              icon: Icon(Icons.add),
              label: Text('Add Habit'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _finish,
              child: Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitEntry {
  final TextEditingController nameController = TextEditingController();
  int value = 0;
}

class HabitForm extends StatelessWidget {
  final int index;
  final HabitEntry habit;

  const HabitForm({required this.index, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habit $index', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: habit.nameController,
          decoration: InputDecoration(labelText: 'Habit Name'),
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
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
          ],
        ),
        Divider(),
      ],
    );
  }
}

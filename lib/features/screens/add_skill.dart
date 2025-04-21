import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillSetupScreen extends StatefulWidget {
  final String? existingSkillName;
  final List<Map<String, dynamic>>? existingHabits;

  const SkillSetupScreen({this.existingSkillName, this.existingHabits, super.key});

  @override
  State<SkillSetupScreen> createState() => _SkillSetupScreenState();
}

class _SkillSetupScreenState extends State<SkillSetupScreen> {
  final TextEditingController _skillNameController = TextEditingController();
  final RxBool isDarkMode = Get.isDarkMode.obs;

  List<HabitEntry> _habits = [HabitEntry()];
  bool get isEditing => widget.existingSkillName != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _skillNameController.text = widget.existingSkillName!;
      _habits = widget.existingHabits!.map((habit) {
        final entry = HabitEntry();
        entry.nameController.text = habit['name'];
        entry.value = habit['value'];
        return entry;
      }).toList();
    }
  }

  void _addHabit() {
    setState(() => _habits.add(HabitEntry()));
  }

  void _finish() {
    final skillName = _skillNameController.text.trim();
    if (skillName.isEmpty || _habits.any((h) => h.nameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter skill name and all habit names.')),
      );
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

    print('${isEditing ? "Edited" : "Created"} Skill: $data');
    Get.back();
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    for (var h in _habits) {
      h.nameController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: AppBar(
            title: Text(
              isEditing ? 'Edit Skill' : 'Add New Skill',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              IconButton(
                icon: Icon(isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => isDarkMode.toggle(),
              )
            ],
          ),
          backgroundColor: isDarkMode.value ? Colors.black : Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: _skillNameController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Skill Name',
                    labelStyle: GoogleFonts.poppins(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ..._habits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final habit = entry.value;
                  return HabitForm(index: index + 1, habit: habit);
                }),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _addHabit,
                  icon: const Icon(Icons.add),
                  label: Text('Add Habit', style: GoogleFonts.poppins()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _finish,
                  child: Text(
                    isEditing ? 'Save Changes' : 'Finish',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class HabitEntry {
  final TextEditingController nameController = TextEditingController();
  int value = 0;
}

class HabitForm extends StatelessWidget {
  final int index;
  final HabitEntry habit;

  const HabitForm({super.key, required this.index, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habit $index', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: habit.nameController,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            labelText: 'Habit Name',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
        ),
        Row(
          children: [
            Text('Value: ${habit.value}', style: GoogleFonts.poppins()),
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
        const Divider(),
      ],
    );
  }
}

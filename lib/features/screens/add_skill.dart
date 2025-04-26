import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_monitor/sqflite.dart';
import 'package:skill_monitor/widgets/habit_form.dart';

class SkillSetupScreen extends StatefulWidget {
  final String? existingSkillName;
  final List<Map<String, dynamic>>? existingHabits;
  final int? id;

  const SkillSetupScreen({
    this.existingSkillName,
    this.existingHabits,
    this.id,
    super.key,
  });

  @override
  State<SkillSetupScreen> createState() => _SkillSetupScreenState();
}

class _SkillSetupScreenState extends State<SkillSetupScreen> {
  final TextEditingController _skillNameController = TextEditingController();
  final RxBool isDarkMode = Get.isDarkMode.obs;
  final SqlDb sqlDb = SqlDb();

  List<HabitEntry> _habits = [HabitEntry()];
  bool get isEditing => widget.existingSkillName != null;
  bool _isSaving = false;

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

  void _finish() async {
    final skillName = _skillNameController.text.trim();
    final nonEmptyHabits =
        _habits.where((h) => h.nameController.text.trim().isNotEmpty).toList();

    if (skillName.isEmpty || nonEmptyHabits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skill name and at least one habit are required.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        // UPDATE existing skill
        await sqlDb.updateData('''
          UPDATE skills SET skill = "$skillName" WHERE id = ${widget.id}
        ''');

        // DELETE old habits
        await sqlDb.deleteData('''
          DELETE FROM habits WHERE skill_id = ${widget.id}
        ''');

        // INSERT new habits
        for (var habit in nonEmptyHabits) {
          final habitName = habit.nameController.text.trim();
          final habitValue = habit.value;
          await sqlDb.insertData('''
            INSERT INTO habits (skill_id, name, value, last_updated)
            VALUES (${widget.id}, "$habitName", $habitValue, "")
          ''');
        }
      } else {
        // INSERT new skill - ensure we set initial score and level
        int skillId = await sqlDb.insertData('''
          INSERT INTO skills (skill, score, level) 
          VALUES ("$skillName", 0, 1)
        ''');

        // INSERT new habits
        for (var habit in nonEmptyHabits) {
          final habitName = habit.nameController.text.trim();
          final habitValue = habit.value;
          await sqlDb.insertData('''
            INSERT INTO habits (skill_id, name, value, last_updated)
            VALUES ($skillId, "$habitName", $habitValue, "")
          ''');
        }
      }

      Get.back(result: true); // let Home know it should refresh
    } catch (e) {
      debugPrint('Error saving skill: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save skill.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            ),
            actions: [
              IconButton(
                icon:
                    Icon(isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => isDarkMode.toggle(),
              )
            ],
          ),
          backgroundColor: isDarkMode.value ? Colors.black : Colors.white,
          body: _isSaving
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      TextField(
                        controller: _skillNameController,
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
                        label: const Text(
                          'Add Habit',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _finish,
                        child: Text(
                          isEditing ? 'Save Changes' : 'Finish',
                        ),
                      ),
                    ],
                  ),
                ),
        ));
  }
}

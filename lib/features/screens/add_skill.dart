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

  List<HabitEntry> _habits = [];
  final Set<int> _removedHabitIds = {};
  bool _isSaving = false;

  bool get isEditing => widget.existingSkillName != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      _skillNameController.text = widget.existingSkillName!;
      debugPrint('--- INIT HABITS ---');

      _habits = widget.existingHabits!.map((habit) {
        debugPrint('Loaded habit from DB: id=${habit['id']}, name="${habit['name']}", value=${habit['value']}');
        return HabitEntry(
          nameController: TextEditingController(text: habit['name']),
          value: habit['value'],
          id: habit['id'],
        );
      }).toList();
    } else {
      _habits = [
        HabitEntry(nameController: TextEditingController(), value: 1),
      ];
    }
  }

  void _addHabit() {
    setState(() {
      _habits.add(HabitEntry(nameController: TextEditingController(), value: 1));
    });
  }

  void _removeHabit(int index) {
    final habit = _habits[index];
    debugPrint('Removing habit at index $index: id=${habit.id}, name="${habit.nameController.text}"');
    setState(() {
      if (habit.id != null) {
        _removedHabitIds.add(habit.id!);
      }
      _habits.removeAt(index);
    });
  }

  Future<void> _finish() async {
    debugPrint('--- STARTING FINISH ---');
    final skillName = _skillNameController.text.trim();
    debugPrint('Skill name: "$skillName"');

    debugPrint('Habits count (total): ${_habits.length}');
    final nonEmptyHabits = _habits.where((h) => h.nameController.text.trim().isNotEmpty).toList();
    debugPrint('Habits count (non-empty): ${nonEmptyHabits.length}');
    debugPrint('Removed habit IDs: $_removedHabitIds');

    if (skillName.isEmpty || nonEmptyHabits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill name and at least one habit are required.')),
      );
      return;
    }

    if (nonEmptyHabits.any((h) => h.value == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit values must not equal 0.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final timestamp = DateTime.now().toIso8601String();

      if (isEditing) {
        debugPrint('Mode: EDIT');
        debugPrint('Updating skill "$skillName"');
        await sqlDb.updateData(
          'UPDATE skills SET skill = ? WHERE id = ?',
          [skillName, widget.id],
        );

        for (var habit in nonEmptyHabits) {
          final name = habit.nameController.text.trim();
          final value = habit.value;

          if (habit.id != null) {
            debugPrint('Updating habit id=${habit.id}: name="$name", value=$value');
            await sqlDb.updateData(
              'UPDATE habits SET name = ?, value = ? WHERE id = ? AND skill_id = ?',
              [name, value, habit.id, widget.id],
            );
          } else {
            debugPrint('Inserting new habit for skill id=${widget.id}: name="$name", value=$value');
            await sqlDb.insertData(
              'INSERT INTO habits (skill_id, name, value, last_updated) VALUES (?, ?, ?, ?)',
              [widget.id, name, value, timestamp],
            );
          }
        }

        for (int id in _removedHabitIds) {
          debugPrint('Deleting removed habit with id=$id');
          await sqlDb.deleteData('DELETE FROM habits WHERE id = ?', [id]);
        }
      } else {
        debugPrint('Mode: CREATE');
        final skillId = await sqlDb.insertData(
          'INSERT INTO skills (skill, score, level) VALUES (?, 0, 1)',
          [skillName],
        );
        debugPrint('Created new skill with id=$skillId');

        for (var habit in nonEmptyHabits) {
          final name = habit.nameController.text.trim();
          final value = habit.value;

          debugPrint('Inserting habit for skill id=$skillId: name="$name", value=$value');
          await sqlDb.insertData(
            'INSERT INTO habits (skill_id, name, value, last_updated) VALUES (?, ?, ?, ?)',
            [skillId, name, value, timestamp],
          );
        }
      }

      debugPrint('--- FINISH SUCCESS ---');
      Get.back(result: true);
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
            title: Text(isEditing ? 'Edit Skill' : 'Add New Skill'),
            actions: [
              IconButton(
                icon: Icon(isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => isDarkMode.toggle(),
              ),
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
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            ..._habits.asMap().entries.map((entry) {
                              final index = entry.key;
                              final habit = entry.value;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: HabitForm(
                                  key: ValueKey('${habit.id ?? ''}_$index'),
                                  index: index + 1,
                                  habit: habit,
                                  showDelete: _habits.length > 1,
                                  onDelete: () => _removeHabit(index),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _addHabit,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Habit'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _finish,
                        child: Text(isEditing ? 'Save Changes' : 'Finish'),
                      ),
                    ],
                  ),
                ),
        ));
  }
}

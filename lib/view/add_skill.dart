import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../db/db_helper.dart';
import '../model/habit_model.dart';
import '../model/skill_model.dart';
import '../services/sharedpref_service.dart';
import '../widgets/habit_form.dart';
import '../controllers/composite_controller.dart';

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
  final SqlDb sqlDb = SqlDb();

  final isDarkMode = Get.isDarkMode.obs;
  final isSaving = false.obs;

  final habits = <HabitEntry>[].obs;
  final removedHabitIds = <int>{}.obs;

  // Track original habit data to detect modifications
  final Map<int, Map<String, dynamic>> originalHabits = {};

  bool get isEditing => widget.existingSkillName != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      _skillNameController.text = widget.existingSkillName!;
      habits.assignAll(
        widget.existingHabits!.map((habit) {
          // Store original habit data for comparison
          if (habit['id'] != null) {
            originalHabits[habit['id']] = {
              'name': habit['name'],
              'value': habit['value'],
            };
          }

          return HabitEntry(
            nameController: TextEditingController(text: habit['name']),
            value: habit['value'],
            id: habit['id'],
            lastUpdated: habit['last_updated'],
          );
        }),
      );
    } else {
      habits.add(HabitEntry(nameController: TextEditingController(), value: 1));
    }
  }

  void _addHabit() {
    habits.add(HabitEntry(nameController: TextEditingController(), value: 1));
  }

  void _removeHabit(int index) {
    final habit = habits[index];
    if (habit.id != null) {
      removedHabitIds.add(habit.id!);
      // Keep the original habit data for reference during removal
      // (it's already stored in originalHabits map)
    }
    habit.nameController.dispose(); // Clean up the controller
    habits.removeAt(index);
  }

  /// Handle habit modifications - clear SharedPrefs for modified habits, keep unmodified ones
  Future<void> _handleHabitModifications(
    List<HabitEntry> nonEmptyHabits,
  ) async {
    try {
      final controller = Get.find<CompositeController>();
      final prefs = Get.find<SharedPrefsService>();
      final skillId = widget.id!;

      // Check each habit for modifications
      for (var habit in nonEmptyHabits) {
        if (habit.id != null && originalHabits.containsKey(habit.id)) {
          // This is an existing habit - check if it was modified
          final original = originalHabits[habit.id!]!;
          final currentName = habit.nameController.text.trim();
          final currentValue = habit.value;

          final isModified =
              original['name'] != currentName ||
              original['value'] != currentValue;

          if (isModified) {
            // Habit was modified - clear its SharedPrefs data and uncheck it
            final habitKey = '${skillId}_${habit.id}';
            controller.habitStates.remove(habitKey);
            await prefs.remove('habit_$habitKey');

            print(
              'Cleared data for modified habit: ${habit.id} (${original['name']} -> $currentName, ${original['value']} -> $currentValue)',
            );
          } else {
            // Habit was not modified - keep it checked if it was checked
            print(
              'Habit not modified, keeping state: ${habit.id} ($currentName, $currentValue)',
            );
          }
        } else if (habit.id == null) {
          // This is a new habit - no need to do anything special
          print('New habit added: ${habit.nameController.text.trim()}');
        }
      }

      // Handle removed habits - clear their SharedPrefs data
      for (final habitId in removedHabitIds) {
        final habitKey = '${skillId}_${habitId}';
        controller.habitStates.remove(habitKey);
        await prefs.remove('habit_$habitKey');
        print('Cleared data for removed habit: $habitId');
      }
    } catch (e) {
      // Controller might not be initialized, which is fine
      print(
        'Note: Controller not found during habit modification handling: $e',
      );
    }
  }

  Future<void> _finish() async {
    final skillName = _skillNameController.text.trim();
    final nonEmptyHabits =
        habits.where((h) => h.nameController.text.trim().isNotEmpty).toList();

    if (skillName.isEmpty || nonEmptyHabits.isEmpty) {
      Get.snackbar("Error", "Skill name and at least one habit are required.");
      return;
    }

    if (nonEmptyHabits.any((h) => h.value == 0)) {
      Get.snackbar("Error", "Habit values must not equal 0.");
      return;
    }

    isSaving.value = true;

    try {
      if (isEditing) {
        // Handle habit modifications for existing skills
        await _handleHabitModifications(nonEmptyHabits);

        // Get existing skill data to preserve score and level
        final existingSkill = await _getExistingSkillData(widget.id!);

        await sqlDb.updateSkill(
          Skill(
            id: widget.id!,
            skill: skillName,
            score: existingSkill.score, // Preserve existing score
            level: existingSkill.level, // Preserve existing level
          ),
        );

        for (var habit in nonEmptyHabits) {
          final name = habit.nameController.text.trim();
          if (habit.id != null) {
            // Update existing habit - preserve lastUpdated
            await sqlDb.updateHabit(
              Habit(
                id: habit.id!,
                skillId: widget.id!,
                name: name,
                value: habit.value,
                lastUpdated:
                    habit.lastUpdated ?? '', // Preserve existing lastUpdated
              ),
            );
          } else {
            // New habit - empty lastUpdated
            await sqlDb.addHabit(
              Habit(
                skillId: widget.id!,
                name: name,
                value: habit.value,
                lastUpdated: '', // New habits start with empty lastUpdated
              ),
            );
          }
        }

        for (final id in removedHabitIds) {
          await sqlDb.deleteHabit(id);
        }
      } else {
        // Create new skill
        final skillId = await sqlDb.addSkill(
          Skill(skill: skillName, score: 0, level: 1),
        );

        for (var habit in nonEmptyHabits) {
          await sqlDb.addHabit(
            Habit(
              skillId: skillId,
              name: habit.nameController.text.trim(),
              value: habit.value,
              lastUpdated: '', // New habits start with empty lastUpdated
            ),
          );
        }
      }

      // Add a small delay to ensure database operations are complete
      await Future.delayed(const Duration(milliseconds: 100));

      Get.back(result: true);
    } catch (e) {
      Get.snackbar("Error", "Failed to save skill: $e");
    } finally {
      isSaving.value = false;
    }
  }

  /// Get existing skill data to preserve score and level during edits
  Future<Skill> _getExistingSkillData(int skillId) async {
    final db = await sqlDb.db;
    final result = await db.query(
      'skills',
      where: 'id = ?',
      whereArgs: [skillId],
    );

    if (result.isNotEmpty) {
      return Skill.fromMap(result.first);
    }

    // Fallback if skill not found
    return Skill(id: skillId, skill: '', score: 0, level: 1);
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    for (var h in habits) {
      h.nameController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Edit Skill' : 'Add New Skill')),
        backgroundColor: isDarkMode.value ? Colors.black : Colors.white,
        body:
            isSaving.value
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _skillNameController,
                        decoration: InputDecoration(
                          labelText: 'Skill Name',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            ...habits.asMap().entries.map((entry) {
                              final index = entry.key;
                              final habit = entry.value;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
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
                                  showDelete: habits.length > 1,
                                  onDelete: () => _removeHabit(index),
                                ),
                              );
                            }),
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
      ),
    );
  }
}

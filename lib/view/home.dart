import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/composite_controller.dart';
import '../utils/constants/system.dart';
import '../widgets/card_widget.dart';
import '../widgets/oops_widget.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/MotivationalProgressWidget.dart';
import 'add_skill.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final controller = Get.put(CompositeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomAppbar(),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.skillWithHabitsList.isEmpty) {
                return const Oops();
              }

              // Prepare data for motivational widget
              final allHabits = <Map<String, dynamic>>[];
              final selectedHabitsMap = <int, Set<String>>{};

              for (var skillData in controller.skillWithHabitsList) {
                final skillId = skillData.skill.id!;
                selectedHabitsMap[skillId] = <String>{};

                for (var habit in skillData.habits) {
                  allHabits.add({
                    'name': habit.name,
                    'value': habit.value,
                    'skill_id': skillId,
                  });

                  if (controller.isHabitCompleted(skillId, habit.id!)) {
                    selectedHabitsMap[skillId]!.add(habit.name);
                  }
                }
              }

              return Column(
                children: [
                  // Motivational Progress Widget
                  MotivationalProgressWidget(
                    habits: allHabits,
                    selectedHabitsMap: selectedHabitsMap,
                  ),

                  // Skills List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 24, bottom: 100),
                      itemCount: controller.skillWithHabitsList.length,
                      itemBuilder: (context, index) {
                        final skillData = controller.skillWithHabitsList[index];
                        final skill = skillData.skill;
                        final habits = skillData.habits;
                        final skillId = skill.id!;

                        // Prepare habits data for the card widget
                        final habitsForCard =
                            habits.map((habit) {
                              final isSelected = controller.isHabitCompleted(
                                skillId,
                                habit.id!,
                              );
                              return {
                                'name': habit.name,
                                'value': habit.value,
                                'contribution': isSelected ? habit.value : 0,
                              };
                            }).toList();

                        final selectedHabits =
                            habits
                                .where(
                                  (habit) => controller.isHabitCompleted(
                                    skillId,
                                    habit.id!,
                                  ),
                                )
                                .map((habit) => habit.name)
                                .toSet();

                        return FadeTransition(
                          opacity:
                              controller.getAnimationForSkill(skillId) ??
                              const AlwaysStoppedAnimation(1.0),
                          child: SkillCard(
                            id: skillId,
                            name: skill.skill,
                            level: skill.level,
                            score: skill.score,
                            habits: habitsForCard,
                            selectedHabits: selectedHabits,
                            isMaxed: skill.level >= 10,
                            maxValue:
                                skill.level < 10
                                    ? SystemConstants.levelRequirements[skill
                                        .level] // Index is level (0-based offset for next requirement)
                                    : SystemConstants.levelRequirements.last,

                            onHabitChanged: (
                              habitName,
                              checked, {
                              bool resetDate = false,
                            }) {
                              final habit = habits.firstWhere(
                                (h) => h.name == habitName,
                              );
                              controller.toggleHabit(
                                skillId,
                                habit.id!,
                                checked ?? false,
                              );
                            },
                            onUpdateScore: () {
                              // Manual score updates if needed
                            },
                            onEdit: () async {
                              final existingHabits =
                                  habits
                                      .map(
                                        (habit) => {
                                          'id': habit.id,
                                          'name': habit.name,
                                          'value': habit.value,
                                          'last_updated': habit.lastUpdated,
                                        },
                                      )
                                      .toList();

                              final result = await Get.to(
                                () => SkillSetupScreen(
                                  existingSkillName: skill.skill,
                                  existingHabits: existingHabits,
                                  id: skillId,
                                ),
                              );

                              if (result == true) {
                                await controller.loadSkillsWithHabits();
                              }
                            },
                            onDelete: () async {
                              final confirmed = await Get.dialog<bool>(
                                AlertDialog(
                                  title: const Text('Delete Skill'),
                                  content: Text(
                                    'Are you sure you want to delete "${skill.skill}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Get.back(result: true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await controller.deleteSkill(skillId);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const SkillSetupScreen());
          if (result == true) {
            await controller.loadSkillsWithHabits();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
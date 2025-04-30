import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/features/screens/add_skill.dart';
import 'package:skill_monitor/sqflite.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
import 'package:skill_monitor/utils/constants/system.dart';
import 'package:skill_monitor/widgets/MotivationalProgressWidget.dart';
import 'package:skill_monitor/widgets/card_widget.dart';
import 'package:skill_monitor/widgets/customAppbar.dart';
import 'package:skill_monitor/widgets/oops_widget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final SqlDb dbHelper = SqlDb();
  List<Map<String, dynamic>> skills = [];
  final Set<int> _expandedIndices = {};
  final Map<int, Set<String>> _selectedHabits = {};
  // Track habit contributions to scores
  final Map<int, Map<String, int>> _habitScoreContributions = {};
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<double>> _animations = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSkillsFromDatabase();
  }

  Future<void> _loadSkillsFromDatabase() async {
    setState(() => _isLoading = true);
    const query = '''
  SELECT s.id as skill_id, s.skill, s.score, s.level,
         h.id as habit_id, h.name, h.value, h.last_updated, h.contribution
  FROM skills s
  LEFT JOIN habits h ON s.id = h.skill_id
''';

    final List<Map<dynamic, dynamic>> data = await dbHelper.readData(query);
    final Map<int, Map<String, dynamic>> grouped = {};
    final String today = dbHelper.getCurrentDate();

    _selectedHabits.clear();
    _habitScoreContributions.clear();

    for (var row in data) {
      final int id = row['skill_id'];
      if (!grouped.containsKey(id)) {
        grouped[id] = {
          "id": id,
          "name": row['skill'] ?? 'Unnamed Skill',
          "score": row['score'] ?? 0,
          "level": row['level']?.clamp(1, 10) ?? 1,
          "habits": <Map<String, dynamic>>[],
        };
        
        _habitScoreContributions[id] = {};
      }

      if (row['name'] != null) {
        final habitId = row['habit_id'];
        final habitName = row['name'];
        final lastUpdated = row['last_updated'];
        final contribution = row['contribution'] ?? 0;

        grouped[id]!['habits'].add({
          "id": habitId,
          "name": habitName,
          "value": row['value'] ?? 0,
          "last_updated": lastUpdated,
          "contribution": contribution,
        });

        // Track habit contribution to the skill score
        _habitScoreContributions[id]![habitName] = contribution;

        if (lastUpdated == today) {
          _selectedHabits.putIfAbsent(id, () => <String>{}).add(habitName);
        }
      }
    }

    skills = grouped.values.toList();
    skills.sort((a, b) {
      if (a['level'] == 10 && b['level'] != 10) return 1;
      if (a['level'] != 10 && b['level'] == 10) return -1;
      return 0;
    });

    for (var skill in skills) {
      final id = skill['id'];
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      final animation = Tween<double>(
        begin: skill['score'].toDouble(),
        end: skill['score'].toDouble(),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      _animationControllers[id] = controller;
      _animations[id] = animation;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteSkill(int skillId) async {
    setState(() => _isLoading = true);
    await dbHelper.deleteData(
      'DELETE FROM habits WHERE skill_id = ?',
      [skillId],
    );

    await dbHelper.deleteData(
      'DELETE FROM skills WHERE id = ?',
      [skillId],
    );

    _animationControllers[skillId]?.dispose();
    _animationControllers.remove(skillId);
    _animations.remove(skillId);
    _selectedHabits.remove(skillId);
    _habitScoreContributions.remove(skillId);
    await _loadSkillsFromDatabase();
  }

  Future<void> _updateScoreAndLevel(int skillId, int index, String habitName, bool isChecked) async {
    final habits = skills[index]['habits'] as List<Map<String, dynamic>>;
    
    // Find habit in the list
    final habit = habits.firstWhere(
      (h) => h['name'] == habitName,
      orElse: () => {'name': habitName, 'value': 0}
    );
    
    final habitValue = habit['value'] as int;
    int scoreChange = 0;
    
    // Get the current contribution of this habit (if any)
    final currentContribution = _habitScoreContributions[skillId]?[habitName] ?? 0;
    
    // Calculate score change
    if (isChecked) {
      // Add points only if there's no current contribution
      if (currentContribution == 0) {
        scoreChange = habitValue;
      }
    } else {
      // Remove points if there was a contribution
      if (currentContribution > 0) {
        scoreChange = -currentContribution;
      }
    }
    
    // If no score change, exit early
    if (scoreChange == 0) return;
    
    // Update skill score
    int oldScore = skills[index]['score'];
    int newScore = oldScore + scoreChange;
    if (newScore < 0) newScore = 0;
    
    // Calculate level based on accumulated score
    int totalScore = newScore;
    int newLevel = 1;

    for (int i = 0; i < SystemConstants.levelRequirements.length; i++) {
      final requirement = SystemConstants.levelRequirements[i];
      if (totalScore >= requirement) {
        totalScore -= requirement;
        newLevel++;
      } else {
        break;
      }
    }

    if (newLevel > 10) newLevel = 10;

    // Update database with new score and level
    await dbHelper.updateData(
      'UPDATE skills SET score = ?, level = ? WHERE id = ?',
      [newScore, newLevel, skillId],
    );

    // Track contribution for this habit
    if (isChecked) {
      await _updateHabitContribution(skillId, habitName, habitValue);
      _habitScoreContributions[skillId]![habitName] = habitValue;
    } else {
      await _updateHabitContribution(skillId, habitName, 0);
      _habitScoreContributions[skillId]![habitName] = 0;
    }

    setState(() {
      skills[index]['score'] = newScore;
      skills[index]['level'] = newLevel;

      _animationControllers[skillId]?.stop();
      _animations[skillId] = Tween<double>(
        begin: oldScore.toDouble(),
        end: newScore.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationControllers[skillId]!,
        curve: Curves.easeInOut,
      ));
      _animationControllers[skillId]!
        ..reset()
        ..forward();
    });
  }

  Future<void> _updateHabitDate(int skillId, String habitName) async {
    await dbHelper.updateHabitDate(skillId, habitName);
  }

  Future<void> _updateHabitContribution(int skillId, String habitName, int contribution) async {
    await dbHelper.updateData(
      'UPDATE habits SET contribution = ? WHERE skill_id = ? AND name = ?',
      [contribution, skillId, habitName],
    );
  }

  Future<void> _resetHabitDate(int skillId, String habitName) async {
    await dbHelper.updateData(
      'UPDATE habits SET last_updated = ? WHERE skill_id = ? AND name = ?',
      ['', skillId, habitName],
    );
  }

  int _getCurrentLevelRequirement(int level) {
    if (level <= 0 || level > SystemConstants.levelRequirements.length) {
      return SystemConstants.levelRequirements[0];
    }
    return SystemConstants.levelRequirements[level - 1];
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Aggregate all habits from all skills, including the skill ID
    final List<Map<String, dynamic>> allHabits = skills.expand((skill) {
      final skillId = skill['id'] as int;
      final habits = skill['habits'] as List<Map<String, dynamic>>;
      return habits.map((habit) => {
            ...habit,
            'skill_id': skillId, // Add skill_id to each habit
          });
    }).toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : skills.isEmpty
              ? const Oops()
              : Column(
                  children: [
                    const CustomAppbar(),
                    MotivationalProgressWidget(
                      habits: allHabits,
                      selectedHabitsMap: _selectedHabits, // Pass the entire map
                    ),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 12, bottom: 20),
                        itemCount: skills.length,
                        itemBuilder: (context, index) {
                          final skill = skills[index];
                          final id = skill['id'];
                          final name = skill['name'];
                          final level = skill['level'];
                          final isExpanded = _expandedIndices.contains(index);
                          final selected = _selectedHabits[id] ?? <String>{};
                          final isMaxed = level >= 10;
                          final maxValue = _getCurrentLevelRequirement(level);

                          return Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _animations[id]!,
                                builder: (context, child) {
                                  return SkillCard(
                                    id: id,
                                    name: name,
                                    level: level,
                                    score: _animations[id]!.value.round(),
                                    habits: skill['habits']
                                        as List<Map<String, dynamic>>,
                                    isExpanded: isExpanded,
                                    selectedHabits: selected,
                                    isMaxed: isMaxed,
                                    maxValue: maxValue,
                                    isDark: isDark,
                                    onTap: () => setState(() => isExpanded
                                        ? _expandedIndices.remove(index)
                                        : _expandedIndices.add(index)),
                                    onHabitChanged: (habitName, value,
                                        {bool resetDate = false}) async {
                                      setState(() {
                                        if (value == true) {
                                          _selectedHabits
                                              .putIfAbsent(id, () => <String>{})
                                              .add(habitName);
                                          _updateHabitDate(id, habitName);
                                        } else {
                                          _selectedHabits[id]
                                              ?.remove(habitName);
                                          if (resetDate) {
                                            _resetHabitDate(id, habitName);
                                          }
                                        }
                                      });
                                      
                                      // Update score when habit status changes
                                      await _updateScoreAndLevel(id, index, habitName, value == true);
                                    },
                                    onUpdateScore: () {
                                      // This is now handled directly in onHabitChanged
                                    },
                                    onEdit: () async {
                                      final result =
                                          await Get.to(() => SkillSetupScreen(
                                                id: skill['id'],
                                                existingHabits: skill['habits'],
                                                existingSkillName:
                                                    skill['name'],
                                              ));
                                      if (result == true) {
                                        await _loadSkillsFromDatabase();
                                        setState(() {});
                                      }
                                    },
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete Skill'),
                                          content: Text(
                                              'Are you sure you want to delete "$name"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deleteSkill(id);
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TColors.primary,
        elevation: 0,
        onPressed: () async {
          final result = await Get.to(() => const SkillSetupScreen());
          if (result == true) {
            await _loadSkillsFromDatabase();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
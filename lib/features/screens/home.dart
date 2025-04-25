import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/features/screens/add_skill.dart';
import 'package:skill_monitor/sqflite.dart';
import 'package:skill_monitor/theme_controller.dart';
import 'package:skill_monitor/utils/constants/text_strings.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

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
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<double>> _animations = {};

  final List<int> levelRequirements = [
    100, 200, 300, 400, 500, 600, 700, 800, 900, 1000
  ];

  final Map<int, String> levelLabels = {
    1: "Beginner — Starting things out",
    2: "Learner — Picking up speed",
    3: "Novice — Getting the hang of it",
    4: "Explorer — Staying consistent",
    5: "Improver — Seeing real progress",
    6: "Practitioner — Skill is building",
    7: "Advanced — Getting sharp",
    8: "Pro — Almost there",
    9: "Expert — Owning it",
    10: "Master — You maxed this skill",
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSkillsFromDatabase();
  }

  Future<void> _loadSkillsFromDatabase() async {
    setState(() => _isLoading = true);
    final query = '''
      SELECT s.id as skill_id, s.skill, s.score, s.level,
             h.name, h.value, h.last_updated
      FROM skills s
      LEFT JOIN habits h ON s.id = h.skill_id
    ''';

    final List<Map<dynamic, dynamic>> data = await dbHelper.readData(query);
    final Map<int, Map<String, dynamic>> grouped = {};

    for (var row in data) {
      final int id = row['skill_id'];
      if (!grouped.containsKey(id)) {
        grouped[id] = {
          "id": id,
          "name": row['skill'],
          "score": row['score'] ?? 0,
          "level": row['level'] ?? 1,
          "habits": <Map<String, dynamic>>[],
        };
      }
      if (row['name'] != null) {
        grouped[id]!['habits'].add({
          "name": row['name'],
          "value": row['value'],
          "last_updated": row['last_updated'],
        });
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
          vsync: this, duration: const Duration(milliseconds: 400));
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
    await dbHelper.deleteData('DELETE FROM habits WHERE skill_id = $skillId');
    await dbHelper.deleteData('DELETE FROM skills WHERE id = $skillId');
    await _loadSkillsFromDatabase();
  }

  Future<void> _updateScoreAndLevel(int skillId, int index) async {
    final selected = _selectedHabits[skillId] ?? {};
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No habits selected to update')),
      );
      return;
    }
    
    final habits = skills[index]['habits'] as List;

    int newScore = 0;
    List<String> updatedHabits = [];
    
    for (var habit in habits) {
      if (selected.contains(habit['name'])) {
        newScore += habit['value'] as int;
        updatedHabits.add(habit['name']);
      }
    }

    int oldScore = skills[index]['score'];
    int oldLevel = skills[index]['level'];
    int currentScore = oldScore + newScore;
    int newLevel = oldLevel;

    while (newLevel < levelRequirements.length &&
        currentScore >= levelRequirements[newLevel - 1]) {
      currentScore -= levelRequirements[newLevel - 1];
      newLevel++;
    }

    if (newLevel > 10) newLevel = 10;

    await dbHelper.updateData(
      'UPDATE skills SET score = $currentScore, level = $newLevel WHERE id = $skillId',
    );

    // Update timestamps for each selected habit
    for (String habitName in updatedHabits) {
      await _updateHabitDate(skillId, habitName);
    }

    // Clear selections after updating
    setState(() {
      _selectedHabits[skillId]?.clear();
      skills[index]['score'] = currentScore;
      skills[index]['level'] = newLevel;

      _animationControllers[skillId]!.stop();
      _animations[skillId] = Tween<double>( 
        begin: oldScore.toDouble(),
        end: currentScore.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationControllers[skillId]!,
        curve: Curves.easeInOut,
      ));
      _animationControllers[skillId]!
        ..reset()
        ..forward();
    });
    
    // Force reload to get fresh last_updated values
    await _loadSkillsFromDatabase();
  }

  Future<void> _updateHabitDate(int skillId, String habitName) async {
    await dbHelper.updateHabitDate(skillId, habitName);
  }

  bool _canUpdateHabit(String? lastUpdated) {
    final currentDate = dbHelper.getCurrentDate();
    // Allow update if never updated before or last updated on a different day
    return lastUpdated == null || lastUpdated.isEmpty || lastUpdated != currentDate;
  }

  // Get the max value for the current level
  int _getCurrentLevelRequirement(int level) {
    if (level <= 0 || level > levelRequirements.length) {
      return 100; // Default to first level requirement
    }
    return levelRequirements[level - 1];
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

    return Scaffold(
      appBar: AppBar(
        title: Text(TTexts.homeAppBarTitle),
        actions: [
          IconButton(
            icon: Icon(Get.find<ThemeController>().isDarkMode.value
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: Get.find<ThemeController>().toggleTheme,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : skills.isEmpty
              ? const Center(
                  child: Text("No skills added yet. Tap + to get started!"))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    final id = skill['id'];
                    final name = skill['name'];
                    final level = skill['level'];
                    final score = skill['score'];
                    final isExpanded = _expandedIndices.contains(index);
                    final selected = _selectedHabits[id] ?? <String>{};
                    final isMaxed = level >= 10;
                    final maxValue = _getCurrentLevelRequirement(level);

                    return Dismissible(
                      key: ValueKey(id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        return await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Skill'),
                            content:
                                Text('Are you sure you want to delete "$name"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _deleteSkill(id),
                      background: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: GestureDetector(
                          onTap: isMaxed
                              ? null
                              : () => setState(() => isExpanded
                                  ? _expandedIndices.remove(index)
                                  : _expandedIndices.add(index)),
                          child: Card(
                            color: isMaxed ? Colors.grey.shade300 : null,
                            margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge),
                                                const SizedBox(height: 4),
                                                Text(levelLabels[level] ?? '',
                                                    style: const TextStyle(fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                          SleekCircularSlider(
                                            appearance: CircularSliderAppearance(
                                              size: 80,
                                              customColors: CustomSliderColors(
                                                trackColor: isDark
                                                    ? Colors.grey.shade700
                                                    : Colors.grey.shade300,
                                                progressBarColor: isDark
                                                    ? Colors.blue.shade400
                                                    : Colors.blue.shade600,
                                              ),
                                              infoProperties: InfoProperties(
                                                mainLabelStyle: TextStyle(
                                                  color: isDark ? Colors.white : Colors.black,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                modifier: (double value) {
                                                  return "Lv $level";
                                                },
                                              ),
                                            ),
                                            initialValue: score.toDouble(),
                                            min: 0,
                                            max: maxValue.toDouble(),
                                            onChange: (value) {},
                                          ),
                                        ],
                                      ),
                                      if (isExpanded)
                                        Column(
                                          children: [
                                            const SizedBox(height: 12),
                                            Column(
                                              children: (skill['habits'] as List)
                                                  .map<Widget>((habit) {
                                                final habitName = habit['name'];
                                                final lastUpdated =
                                                    habit['last_updated'];
                                                final canUpdate = _canUpdateHabit(lastUpdated);
                                                
                                                return CheckboxListTile(
                                                  value: selected.contains(habitName),
                                                  onChanged: canUpdate ? (bool? value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _selectedHabits.putIfAbsent(
                                                          skill['id'], 
                                                          () => <String>{}
                                                        ).add(habitName);
                                                      } else {
                                                        _selectedHabits[skill['id']]?.remove(habitName);
                                                      }
                                                    });
                                                  } : null,
                                                  title: Text(habitName),
                                                  subtitle: !canUpdate 
                                                      ? const Text('Already updated today', 
                                                          style: TextStyle(color: Colors.red))
                                                      : null,
                                                );
                                              }).toList(),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await _updateScoreAndLevel(id, index);
                                              },
                                              child: const Text('Update Score'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                if (isMaxed)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Icon(Icons.lock, color: Colors.black45),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const SkillSetupScreen());
          if (result == true) {
            _loadSkillsFromDatabase();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
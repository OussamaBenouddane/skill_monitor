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
             h.habit, h.value, h.last_updated
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
          "score": row['score'],
          "level": row['level'],
          "habits": <Map<String, dynamic>>[],
        };
      }
      if (row['habit'] != null) {
        grouped[id]!['habits'].add({
          "name": row['habit'],
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
    final habits = skills[index]['habits'] as List;

    int newScore = 0;
    for (var habit in habits) {
      if (selected.contains(habit['name'])) {
        newScore += habit['value'] as int;
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

    setState(() {
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
  }

  Future<void> _updateHabitDate(int skillId, String habitName) async {
    await dbHelper.updateHabitDate(skillId, habitName);
  }

  bool _canUpdateHabit(String lastUpdated) {
    final currentDate = dbHelper.getCurrentDate();
    return lastUpdated != currentDate;
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
                    final isExpanded = _expandedIndices.contains(index);
                    final selected = _selectedHabits[id] ?? <String>{};
                    final isMaxed = skill['level'] >= 10;

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
                                                Text(levelLabels[skill['level']] ?? '',
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
                                            ),
                                            initialValue: skill['score'].toDouble(),
                                            min: 0,
                                            max: 1000,
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
                                                return CheckboxListTile(
                                                  value: selected
                                                      .contains(habitName),
                                                  onChanged: (bool? value) async {
                                                    if (_canUpdateHabit(lastUpdated)) {
                                                      setState(() {
                                                        if (value == true) {
                                                          selected.add(habitName);
                                                        } else {
                                                          selected.remove(habitName);
                                                        }
                                                      });
                                                      await _updateHabitDate(
                                                          skill['id'], habitName);
                                                    }
                                                  },
                                                  title: Text(habitName),
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
    );
  }
}

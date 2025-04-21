// import statements
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_monitor/features/screens/add_skill.dart';
import 'package:skill_monitor/theme_controller.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
import 'package:skill_monitor/utils/constants/sizes.dart';
import 'package:skill_monitor/utils/constants/text_strings.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> skills = [
    {
      "name": "Flutter",
      "score": 10,
      "habits": [
        {"name": "Learn", "value": 10},
        {"name": "Build", "value": 10}
      ],
      "level": 1
    },
    {
      "name": "JavaScript",
      "score": 30,
      "habits": [
        {"name": "Watch", "value": 10},
        {"name": "Practice", "value": 10}
      ],
      "level": 2
    },
  ];

  final Set<int> _expandedIndices = {};
  final Map<String, Set<String>> _selectedHabits = {};
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    for (var skill in skills) {
      final name = skill['name'];
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      final animation = Tween<double>(
        begin: skill['score'].toDouble(),
        end: skill['score'].toDouble(),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      _animationControllers[name] = controller;
      _animations[name] = animation;
    }
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
    final ThemeController themeController = Get.find();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          TTexts.homeAppBarTitle,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Obx(() => Icon(themeController.isDarkMode.value
                ? Icons.light_mode
                : Icons.dark_mode)),
            onPressed: themeController.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: _buildSkillList(isDark),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () => Get.to(() => SkillSetupScreen()),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? Colors.tealAccent.shade400 : Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          TTexts.addSkill,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildSkillList(bool isDark) {
    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) => _buildSkillCard(context, index, isDark),
    );
  }

  Widget _buildSkillCard(BuildContext context, int index, bool isDark) {
    final skill = skills[index];
    final name = skill['name'];
    final isExpanded = _expandedIndices.contains(index);
    final habitSelections = _selectedHabits[name] ?? {};

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => isExpanded
                ? _expandedIndices.remove(index)
                : _expandedIndices.add(index));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: TSizes.spaceBtwSections),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800
                  : const Color.fromARGB(101, 176, 198, 255),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TSizes.sm),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkillHeader(context, skill, isDark),
                    if (isExpanded)
                      _buildExpandedSection(
                          context, skill, habitSelections, index, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -14,
          left: 12,
          child: Row(
            children: [
              _buildIconButton(
                icon: Icons.edit,
                color: Colors.black87,
                onTap: () {
                  Get.to(() => SkillSetupScreen(
                        existingSkillName: skill['name'],
                        existingHabits: skill['habits'],
                      ));
                },
              ),
              const SizedBox(width: 10),
              _buildIconButton(
                icon: Icons.delete,
                color: Colors.redAccent,
                onTap: () => _confirmDelete(context, name),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillHeader(
      BuildContext context, Map<String, dynamic> skill, bool isDark) {
    final name = skill['name'];
    final animation = _animations[name]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Text(
                    "${TTexts.score}${animation.value.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) => SleekCircularSlider(
              appearance: CircularSliderAppearance(
                size: 80,
                customColors: CustomSliderColors(
                  trackColor:
                      isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  progressBarColor:
                      isDark ? Colors.tealAccent : Colors.blueAccent,
                ),
              ),
              min: 0,
              max: 100,
              initialValue: animation.value,
              innerWidget: (value) => Center(
                child: Text(
                  "${TTexts.level}${skill["level"]}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context, Map<String, dynamic> skill,
      Set<String> habitSelections, int index, bool isDark) {
    final name = skill['name'];
    return Column(
      children: [
        ...List<Widget>.from(skill['habits'].map<Widget>((habit) {
          final habitName = habit['name'];
          final habitValue = habit['value'];
          return Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CheckboxListTile(
              title: Text(
                habitName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              value: habitSelections.contains(habitName),
              onChanged: (value) {
                setState(() {
                  final updatedSet = Set<String>.from(habitSelections);
                  double oldScore = skills[index]['score'].toDouble();
                  double newScore = value == true
                      ? (oldScore + habitValue).clamp(0, 100)
                      : (oldScore - habitValue).clamp(0, 100);

                  skills[index]['score'] = newScore;
                  if (value == true) {
                    updatedSet.add(habitName);
                  } else {
                    updatedSet.remove(habitName);
                  }
                  _selectedHabits[name] = updatedSet;

                  _animationControllers[name]!.stop();
                  _animations[name] = Tween<double>(
                    begin: oldScore,
                    end: newScore,
                  ).animate(CurvedAnimation(
                    parent: _animationControllers[name]!,
                    curve: Curves.easeInOut,
                  ));
                  _animationControllers[name]!
                    ..reset()
                    ..forward();
                });
              },
            ),
          );
        })),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showSnackBar(context, name),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.teal : Colors.blueAccent,
              ),
              child: Text(
                TTexts.updateScore,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ),
        )
      ],
    );
  }

  void _showSnackBar(BuildContext context, String skillName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Button tapped for $skillName')),
    );
  }

  void _confirmDelete(BuildContext context, String skillName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete '$skillName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              print('Skill deleted: $skillName');
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/features/screens/add_skill.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
import 'package:skill_monitor/utils/constants/sizes.dart';
import 'package:skill_monitor/utils/constants/text_strings.dart';
import 'package:skill_monitor/utils/helpers/helper_functions.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> skills = [
    {
      "name": "flutter",
      "score": 10,
      "habits": [
        {"name": "learn", "value": 10},
        {"name": "build", "value": 10}
      ],
      "level": 1
    },
    {
      "name": "JS",
      "score": 30,
      "habits": [
        {"name": "watch", "value": 10},
        {"name": "practice", "value": 10}
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
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(title: const Text(TTexts.homeAppBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: _buildSkillList(),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () => Get.to(() => SkillSetupScreen()),
        child: const Text(TTexts.addSkill),
      ),
    );
  }

  Widget _buildSkillList() {
    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) => _buildSkillCard(context, index),
    );
  }

  Widget _buildSkillCard(BuildContext context, int index) {
    final skill = skills[index];
    final name = skill['name'];
    final isExpanded = _expandedIndices.contains(index);
    final habitSelections = _selectedHabits[name] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          setState(() => isExpanded
              ? _expandedIndices.remove(index)
              : _expandedIndices.add(index));
        },
        child: Padding(
          padding: const EdgeInsets.all(TSizes.sm),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkillHeader(context, skill),
                if (isExpanded)
                  _buildExpandedSection(context, skill, habitSelections, index)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillHeader(BuildContext context, Map<String, dynamic> skill) {
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
                Text(name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Text(
                    "${TTexts.score}${animation.value.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.bodySmall,
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
                  trackColor: TColors.trackColor,
                  progressBarColor: TColors.progressBarColor,
                ),
              ),
              min: 0,
              max: 100,
              initialValue: animation.value,
              innerWidget: (value) => Center(
                child: Text(
                  "${TTexts.level}${skill["level"]}",
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context, Map<String, dynamic> skill,
      Set<String> habitSelections, int index) {
    final name = skill['name'];
    return Column(
      children: [
        ...List<Widget>.from(skill['habits'].map<Widget>((habit) {
          final habitName = habit['name'];
          final habitValue = habit['value'];
          return Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CheckboxListTile(
              title: Text(habitName,
                  style: Theme.of(context).textTheme.headlineSmall),
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
              child: const Text(TTexts.updateScore),
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
}

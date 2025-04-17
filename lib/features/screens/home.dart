import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/features/screens/add_skill.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
import 'package:skill_monitor/utils/constants/sizes.dart';
import 'package:skill_monitor/utils/constants/text_strings.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> skills = [
    {
      "name": "flutter",
      "score": 10,
      "habits": ["learn", "build"],
      "level": 1
    },
    {
      "name": "JS",
      "score": 30,
      "habits": ["watch", "practice"],
      "level": 2
    },
  ];

  Set<int> expandedIndices = {};
  Map<String, Set<String>> selectedHabits = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(TTexts.homeAppBarTitle)),
      body: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: skillView(skills, context)),
      floatingActionButton: ElevatedButton(
          onPressed: () {
            Get.to(() => SkillSetupScreen());
          },
          child: const Text(TTexts.addSkill)),
    );
  }

  ListView skillView(skills, context2) {
    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final isExpanded = expandedIndices.contains(index);
        final habitSelections = selectedHabits[skill['name']] ?? {};

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
          child: Material(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    expandedIndices.remove(index);
                  } else {
                    expandedIndices.add(index);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(TSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${skill["name"]}',
                                  style: Theme.of(context2)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${TTexts.score}${skill["score"]}',
                                  style: Theme.of(context2).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          SleekCircularSlider(
                            appearance: CircularSliderAppearance(
                              size: 80,
                              customColors: CustomSliderColors(
                                trackColor: TColors.trackColor,
                                progressBarColor: TColors.progressBarColor,
                              ),
                            ),
                            min: 0,
                            max: 100,
                            initialValue: skill["score"].toDouble(),
                            innerWidget: (double value) {
                              return Center(
                                child: Text(
                                  "${TTexts.level}${skill["level"]}",
                                  style:
                                      Theme.of(context2).textTheme.labelLarge,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded) ...[
                      ...skill['habits'].map<Widget>((habit) {
                        final isChecked = habitSelections.contains(habit);
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: CheckboxListTile(
                            title: Text(habit,
                                style:
                                    Theme.of(context2).textTheme.headlineSmall),
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                final selected =
                                    selectedHabits[skill['name']] ?? {};
                                if (value == true) {
                                  selected.add(habit);
                                } else {
                                  selected.remove(habit);
                                }
                                selectedHabits[skill['name']] = selected;
                              });
                            },
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context2)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text('Button tapped for ${skill["name"]}'),
                              ));
                            },
                            child: const Text(TTexts.updateScore),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

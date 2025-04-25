import 'package:flutter/material.dart';
import 'package:skill_monitor/sqflite.dart';
import 'package:skill_monitor/utils/constants/system.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class SkillCard extends StatefulWidget {
  final int id;
  final String name;
  final int level;
  final int score;
  final List<Map<String, dynamic>> habits;
  final bool isExpanded;
  final Set<String> selectedHabits;
  final bool isMaxed;
  final int maxValue;
  final bool isDark;
  final SqlDb dbHelper; // Inject SqlDb
  final VoidCallback onTap;
  final Function(String, bool?) onHabitChanged;
  final VoidCallback onUpdateScore;

  const SkillCard({
    super.key,
    required this.id,
    required this.name,
    required this.level,
    required this.score,
    required this.habits,
    required this.isExpanded,
    required this.selectedHabits,
    required this.isMaxed,
    required this.maxValue,
    required this.isDark,
    required this.dbHelper,
    required this.onTap,
    required this.onHabitChanged,
    required this.onUpdateScore,
  });

  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> {
  bool _canUpdateHabit(String? lastUpdated) {
    final currentDate = widget.dbHelper.getCurrentDate();
    return lastUpdated == null ||
        lastUpdated.isEmpty ||
        lastUpdated != currentDate;
  }

  @override
  Widget build(BuildContext context) {
    // Validate level
    final levelLabel =
        SystemConstants.levelLabels[widget.level] ?? 'Unknown Level';

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: widget.isMaxed ? null : widget.onTap,
        child: Card(
          elevation: 0,
          color: widget.isMaxed ? Colors.white : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                levelLabel,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SleekCircularSlider(
                          appearance: CircularSliderAppearance(
                            size: 75,
                            customColors: CustomSliderColors(
                              hideShadow: true,
                              trackColor: widget.isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              dotColor: Colors.blue.shade600,
                              progressBarColor: Colors.blue.shade600,
                            ),
                            infoProperties: InfoProperties(
                              mainLabelStyle: TextStyle(
                                color:
                                    widget.isDark ? Colors.white : Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              modifier: (double value) => "Lvl ${widget.level}",
                            ),
                          ),
                          initialValue:
                              widget.score.clamp(0, widget.maxValue).toDouble(),
                          min: 0,
                          max: widget.maxValue.toDouble(),
                          onChange: null,
                        ),
                      ],
                    ),
                    if (widget.isExpanded)
                      Column(
                        children: [
                          ...widget.habits.map<Widget>((habit) {
                            final habitName =
                                habit['name'] as String? ?? 'Unnamed Habit';
                            final lastUpdated =
                                habit['last_updated'] as String?;
                            final canUpdate = _canUpdateHabit(lastUpdated);

                            return Row(
                              children: [
                                Transform.scale(
                                  scale:
                                      1.3, // Adjust scale to make checkbox bigger (e.g., 1.5 for 50% larger)
                                  child: Checkbox(
                                    value: canUpdate
                                        ? widget.selectedHabits
                                            .contains(habitName)
                                        : true,
                                    onChanged: canUpdate
                                        ? (bool? value) => widget
                                            .onHabitChanged(habitName, value)
                                        : null,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    habitName.toUpperCase(),
                                    style: TextStyle(
                                      decoration: !canUpdate
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                !canUpdate
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        child: Text(
                                          "+ ${habit['value']} XP",
                                          style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : const SizedBox(),
                              ],
                            );
                          }),
                          ElevatedButton(
                            onPressed:
                                widget.isMaxed ? null : widget.onUpdateScore,
                            child: const Text('Update Score'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (widget.isMaxed)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Tooltip(
                    message: 'Skill is fully mastered',
                    child: Icon(Icons.lock, color: Colors.black45),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

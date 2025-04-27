import 'package:flutter/material.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
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
  final VoidCallback onTap;
  final Function(String, bool?, {bool resetDate}) onHabitChanged;
  final VoidCallback onUpdateScore;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
    required this.onTap,
    required this.onHabitChanged,
    required this.onUpdateScore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> {
  @override
  Widget build(BuildContext context) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Card Content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        SleekCircularSlider(
                          appearance: CircularSliderAppearance(
                            size: 75,
                            customColors: CustomSliderColors(
                              hideShadow: true,
                              trackColor: widget.isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              dotColor: TColors.primary,
                              progressBarColor: TColors.primary,
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
                        const SizedBox(width: 16),
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
                      ],
                    ),
                    if (widget.isExpanded) ...[
                      ...widget.habits.map<Widget>((habit) {
                        final habitName =
                            habit['name'] as String? ?? 'Unnamed Habit';
                        final isChecked =
                            widget.selectedHabits.contains(habitName);

                        return Row(
                          children: [
                            Transform.scale(
                              scale: 1.3,
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    // When unchecking, pass resetDate: true
                                    widget.onHabitChanged(habitName, value,
                                        resetDate: value == false);
                                    widget.onUpdateScore();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                habitName.toUpperCase(),
                                style: TextStyle(
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (isChecked)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Text(
                                  "+ ${habit['value']} XP",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              ),
              // Edit and Delete floating buttons
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: widget.onEdit,
                      tooltip: 'Edit Skill',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete Skill',
                    ),
                  ],
                ),
              ),
              if (widget.isMaxed)
                const Positioned(
                  bottom: 10,
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

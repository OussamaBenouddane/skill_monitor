import 'package:flutter/material.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
import 'package:skill_monitor/utils/constants/system.dart';
import 'package:skill_monitor/widgets/action_icon.dart';
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: widget.isMaxed
                ? Border.all(color: TColors.primary, width: 2)
                : null,
            color: widget.isDark ? Colors.grey.shade800 : Colors.white,
          ),
          child: Stack(
            children: [
              // Card Content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            mainAxisSize:
                                MainAxisSize.min, // Minimize vertical space
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  widget.isMaxed
                                      ? const SizedBox()
                                      : Row(
                                          children: [
                                            ActionIcon(
                                              icon: Icons.edit,
                                              tooltip: 'Edit Skill',
                                              onTap: widget.onEdit,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            ActionIcon(
                                              icon: Icons.delete,
                                              tooltip: 'Delete Skill',
                                              onTap: widget.onDelete,
                                              color: Colors.red,
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                              widget.isMaxed
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: TColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'You mastered this skill!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      levelLabel,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              if (!widget.isMaxed) 
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${widget.score} / ${widget.maxValue} XP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.isExpanded) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...widget.habits.map<Widget>((habit) {
                        final habitName =
                            habit['name'] as String? ?? 'Unnamed Habit';
                        final isChecked =
                            widget.selectedHabits.contains(habitName);
                        final contribution = habit['contribution'] ?? 0;
                        final habitValue = habit['value'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 1.3,
                                child: SizedBox(
                                  height: 30,
                                  width: 24,
                                  child: Checkbox(
                                    activeColor: TColors.primary,
                                    value: isChecked,
                                    onChanged: (bool? value) {
                                      widget.onHabitChanged(habitName, value,
                                          resetDate: value == false);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  habitName,
                                  style: TextStyle(
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    fontWeight: isChecked 
                                        ? FontWeight.normal 
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: habitValue > 0
                                      ? isChecked && contribution > 0 
                                          ? TColors.primary.withOpacity(0.2)
                                          : Colors.grey.shade200
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Text(
                                  "${habitValue} XP",
                                  style: TextStyle(
                                    color: habitValue > 0
                                        ? isChecked && contribution > 0
                                            ? TColors.primary
                                            : Colors.grey.shade700
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
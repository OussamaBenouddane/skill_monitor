import 'habit_model.dart';
import 'skill_model.dart';

class SkillWithHabits {
  final Skill skill;
  final List<Habit> habits;

  SkillWithHabits({required this.skill, required this.habits});

  SkillWithHabits copyWith({Skill? skill, List<Habit>? habits}) {
    return SkillWithHabits(
      skill: skill ?? this.skill,
      habits: habits ?? this.habits,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/composite_model.dart';
import '../model/skill_model.dart';
import '../model/habit_model.dart';
import '../db/db_helper.dart';
import '../services/sharedpref_service.dart';
import '../utils/constants/system.dart';
import 'skillcard_controller.dart';

class CompositeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final skillWithHabitsList = <SkillWithHabits>[].obs;
  final isLoading = false.obs;

  final dbHelper = SqlDb();
  final _prefs = Get.find<SharedPrefsService>();

  // Track habit states in memory for UI updates
  final habitStates =
      <String, bool>{}.obs; // key: "skillId_habitId", value: isCompleted

  // Store original skill data (before preview changes)
  final Map<int, Skill> _originalSkillData = {};

  // Current date for comparison
  late String today;

  /// Animation controllers per skill ID
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<double>> _fadeAnimations = {};

  static const _animationDuration = Duration(milliseconds: 300);
  static const _animationCurve = Curves.easeIn;

  // Get SkillCard controller instance
  SkillCardController get skillCardController => 
      Get.put(SkillCardController(), tag: 'skill_card');

  @override
  void onInit() {
    super.onInit();
    today = DateTime.now().toIso8601String().split('T').first;
  }

  @override
  void onClose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Calculate level and score with proper overflow handling and level protection
  /// allowLevelDown: true during preview phase, false when applying to database
  /// originalDbLevel: the level currently saved in database (for preview bounds checking)
  Map<String, int> calculateLevelAndScore(
    int currentLevel, 
    int currentScore, 
    int scoreChange,
    {bool allowLevelDown = false, int? originalDbLevel}
  ) {
    int newScore = currentScore + scoreChange;
    int newLevel = currentLevel;

    if (scoreChange > 0) {
      // Handle positive score changes (level ups with overflow)
      while (newLevel < SystemConstants.levelRequirements.length - 1) {
        final currentLevelRequirement = SystemConstants.levelRequirements[newLevel];
        
        if (newScore >= currentLevelRequirement) {
          // Level up and carry over excess score
          final overflow = newScore - currentLevelRequirement;
          newLevel++;
          newScore = overflow;
          
          // Check if we can level up again with the overflow
          if (newLevel < SystemConstants.levelRequirements.length - 1 &&
              newScore >= SystemConstants.levelRequirements[newLevel]) {
            continue; // Keep checking for multiple level ups
          } else {
            break;
          }
        } else {
          break;
        }
      }
    } else if (scoreChange < 0) {
      // Handle negative score changes
      if (allowLevelDown && originalDbLevel != null) {
        // During preview: allow level downs but not below the database level
        while (newLevel > originalDbLevel && newScore < 0) {
          // Go down a level and add the previous level's requirement to score
          newLevel--;
          if (newLevel > 0) {
            newScore += SystemConstants.levelRequirements[newLevel - 1];
          }
        }
        
        // If we've reached the database level and score is still negative, clamp to 0
        if (newScore < 0) {
          newScore = 0;
          newLevel = originalDbLevel; // Don't go below database level
        }
      } else if (allowLevelDown) {
        // Fallback for cases where originalDbLevel is not provided
        while (newLevel > 1 && newScore < 0) {
          newLevel--;
          if (newLevel > 0) {
            newScore += SystemConstants.levelRequirements[newLevel - 1];
          }
        }
        
        if (newScore < 0) {
          newScore = 0;
          newLevel = 1;
        }
      } else {
        // After DB save: no level downs, keep original level and clamp score to 0
        if (newScore < 0) {
          newScore = 0;
          newLevel = currentLevel; // Keep the original level, don't allow decrease
        }
      }
    }

    return {
      'level': newLevel,
      'score': newScore,
    };
  }

  /// Load all skills with habits and handle daily reset
  Future<void> loadSkillsWithHabits() async {
    try {
      isLoading.value = true;

      final lastOpenDate = _prefs.getString('lastOpenDate') ?? '';
      final isNewDay = lastOpenDate != today;

      // If it's a new day, apply pending changes and reset
      if (isNewDay) {
        await _applyPendingChanges();
        await _clearDailyData();
        await _prefs.setString('lastOpenDate', today);
        
        // Clear expansion states on new day
        skillCardController.clearAll();
      }

      // Load fresh data from database
      final data = await dbHelper.getAllSkillsWithHabits();
      skillWithHabitsList.assignAll(data);

      // Sort skills: maxed skills (level 10) go to the bottom
      skillWithHabitsList.sort((a, b) {
        if (a.skill.level == 10 && b.skill.level != 10) return 1;
        if (a.skill.level != 10 && b.skill.level == 10) return -1;
        return 0;
      });

      // Store original skill data for preview calculations
      _storeOriginalSkillData();

      // Clear existing animations
      for (var controller in _animationControllers.values) {
        controller.dispose();
      }
      _animationControllers.clear();
      _fadeAnimations.clear();

      // Load current habit states from SharedPreferences (only if same day)
      if (!isNewDay) {
        await _loadHabitStates();
        // Update UI previews based on loaded states
        _updateAllSkillScorePreviews();
      } else {
        habitStates.clear();
      }

      // Initialize animations
      for (var skill in skillWithHabitsList) {
        _initAnimation(skill.skill.id!);
      }
    } catch (e) {
      print('Error loading skills with habits: $e');
      // Ensure we don't stay in loading state
    } finally {
      isLoading.value = false;
    }
  }

  /// Store original skill data for preview calculations
  void _storeOriginalSkillData() {
    _originalSkillData.clear();
    for (var skillData in skillWithHabitsList) {
      _originalSkillData[skillData.skill.id!] = skillData.skill;
    }
  }

  /// Load habit states from SharedPreferences (only for today)
  Future<void> _loadHabitStates() async {
    habitStates.clear();

    for (var skillData in skillWithHabitsList) {
      for (var habit in skillData.habits) {
        final key = '${skillData.skill.id}_${habit.id}';
        final habitData = _prefs.getString('habit_$key');
        
        if (habitData != null) {
          // Format: "date|completed" e.g., "2024-01-15|true"
          final parts = habitData.split('|');
          if (parts.length == 2 && parts[0] == today) {
            final isCompleted = parts[1] == 'true';
            habitStates[key] = isCompleted;
          }
        }
      }
    }
  }

  /// Apply all pending changes to database and update skill scores/levels
  Future<void> _applyPendingChanges() async {
    final keys =
        _prefs.getKeys().where((key) => key.startsWith('habit_')).toList();

    // Group changes by skill
    final Map<int, List<Map<String, dynamic>>> changesBySkill = {};

    for (var key in keys) {
      final habitData = _prefs.getString(key) ?? '';
      if (habitData.isEmpty) continue;

      // Parse habit data: "date|completed"
      final parts = habitData.split('|');
      if (parts.length != 2) continue;

      final date = parts[0];
      final isCompleted = parts[1] == 'true';
      
      if (!isCompleted || date.isEmpty) continue; // Only process completed habits

      // Extract skillId and habitId from key format: "habit_skillId_habitId"
      final keyParts = key.replaceFirst('habit_', '').split('_');
      if (keyParts.length != 2) continue;

      final skillId = int.tryParse(keyParts[0]);
      final habitId = int.tryParse(keyParts[1]);
      if (skillId == null || habitId == null) continue;

      changesBySkill.putIfAbsent(skillId, () => []);
      changesBySkill[skillId]!.add({
        'habitId': habitId,
        'isCompleted': isCompleted,
        'date': date,
      });
    }

    // Apply changes to each skill
    for (var entry in changesBySkill.entries) {
      final skillId = entry.key;
      final changes = entry.value;

      await _applySkillChanges(skillId, changes);
    }
  }

  /// Apply changes for a specific skill (DATABASE UPDATE - NO LEVEL DOWNS)
  Future<void> _applySkillChanges(
    int skillId,
    List<Map<String, dynamic>> changes,
  ) async {
    // Get current skill data from database (not from UI list which might have preview changes)
    final db = await dbHelper.db;
    final skillResult = await db.query(
      'skills',
      where: 'id = ?',
      whereArgs: [skillId],
    );
    
    if (skillResult.isEmpty) return;
    
    final currentSkill = Skill.fromMap(skillResult.first);
    final habits = await dbHelper.getHabitsBySkillId(skillId);

    int totalScoreChange = 0;

    // Calculate total score change and update habits
    for (var change in changes) {
      final habitId = change['habitId'] as int;
      final isCompleted = change['isCompleted'] as bool;
      final date = change['date'] as String;

      final habit = habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));

      if (isCompleted) {
        totalScoreChange += habit.value;

        // Update habit in database with the completion date
        final updatedHabit = habit.copyWith(lastUpdated: date);
        await dbHelper.updateHabit(updatedHabit);
      }
    }

    // Calculate new level and score - NO LEVEL DOWNS when applying to DB
    final result = calculateLevelAndScore(
      currentSkill.level, 
      currentSkill.score, 
      totalScoreChange,
      allowLevelDown: false, // No level downs when saving to database
      // originalDbLevel not needed when allowLevelDown is false
    );

    final updatedSkill = currentSkill.copyWith(
      score: result['score']!,
      level: result['level']!,
    );

    await dbHelper.updateSkill(updatedSkill);
  }

  /// Clear daily data from SharedPreferences
  Future<void> _clearDailyData() async {
    final keys =
        _prefs.getKeys().where((key) => key.startsWith('habit_')).toList();

    for (var key in keys) {
      await _prefs.remove(key);
    }

    habitStates.clear();
  }

  /// Toggle habit completion (immediate UI update, deferred DB update)
  Future<void> toggleHabit(int skillId, int habitId, bool isCompleted) async {
    final key = '${skillId}_${habitId}';

    // Update UI state immediately
    habitStates[key] = isCompleted;

    // Store in SharedPreferences for persistence with date
    if (isCompleted) {
      // Format: "date|completed"
      await _prefs.setString('habit_$key', '$today|true');
    } else {
      await _prefs.remove('habit_$key');
    }

    // Update UI to reflect score changes immediately (for preview)
    _updateSkillScorePreview(skillId);
  }

  /// Update skill score preview based on current habit states (PREVIEW - RESPECTS DB LEVEL)
  void _updateSkillScorePreview(int skillId) {
    final skillIndex = skillWithHabitsList.indexWhere(
      (s) => s.skill.id == skillId,
    );
    if (skillIndex == -1) return;

    final skillData = skillWithHabitsList[skillIndex];
    final originalSkill = _originalSkillData[skillId];
    if (originalSkill == null) return;

    int scoreChange = 0;

    // Calculate score change from current habit states
    for (var habit in skillData.habits) {
      final key = '${skillId}_${habit.id}';
      final isCompleted = habitStates[key] ?? false;
      if (isCompleted) {
        scoreChange += habit.value;
      }
    }

    // Calculate preview level and score - RESPECTS DATABASE LEVEL as MINIMUM
    final result = calculateLevelAndScore(
      originalSkill.level,
      originalSkill.score,
      scoreChange,
      allowLevelDown: true, // Allow level downs during preview
      originalDbLevel: originalSkill.level, // Pass the database level as minimum
    );

    // Update the skill in the list with preview values
    skillWithHabitsList[skillIndex] = SkillWithHabits(
      skill: originalSkill.copyWith(
        score: result['score']!,
        level: result['level']!
      ),
      habits: skillData.habits,
    );
  }

  /// Update all skill score previews
  void _updateAllSkillScorePreviews() {
    for (var skillData in skillWithHabitsList) {
      _updateSkillScorePreview(skillData.skill.id!);
    }
  }

  /// Get habit completion state
  bool isHabitCompleted(int skillId, int habitId) {
    final key = '${skillId}_${habitId}';
    return habitStates[key] ?? false;
  }

  /// Add a skill
  Future<void> addSkill(Skill skill) async {
    final id = await dbHelper.addSkill(skill);
    final newSkill = skill.copyWith(id: id);
    skillWithHabitsList.add(SkillWithHabits(skill: newSkill, habits: []));
    _originalSkillData[id] = newSkill;
    _initAnimation(id);
  }

  /// Update a skill
  Future<void> updateSkill(Skill skill) async {
    await dbHelper.updateSkill(skill);
    _originalSkillData[skill.id!] = skill;
    _replaceSkill(skill);
  }

  /// Delete a skill with fade animation
  Future<void> deleteSkill(int skillId) async {
    final controller = _animationControllers[skillId];
    if (controller != null) {
      await controller.reverse();
      controller.dispose();
    }

    // Clear related habit states
    final keysToRemove =
        habitStates.keys.where((key) => key.startsWith('${skillId}_')).toList();
    for (var key in keysToRemove) {
      habitStates.remove(key);
    }

    // Clear SharedPreferences
    for (var key in keysToRemove) {
      await _prefs.remove('habit_$key');
    }

    // Remove expansion state for this skill
    skillCardController.removeSkill(skillId);

    await dbHelper.deleteSkill(skillId);
    skillWithHabitsList.removeWhere((s) => s.skill.id == skillId);
    _originalSkillData.remove(skillId);
    _animationControllers.remove(skillId);
    _fadeAnimations.remove(skillId);
  }

  /// Add a habit
  Future<void> addHabit(Habit habit) async {
    final id = await dbHelper.addHabit(habit);
    final newHabit = habit.copyWith(id: id);
    _updateSkillHabits(habit.skillId, (habits) => [...habits, newHabit]);
  }

  /// Update a habit
  Future<void> updateHabit(Habit habit) async {
    await dbHelper.updateHabit(habit);
    _updateSkillHabits(
      habit.skillId,
      (habits) => habits.map((h) => h.id == habit.id ? habit : h).toList(),
    );
  }

  /// Delete a habit
  Future<void> deleteHabit(int habitId, int skillId) async {
    // Clear habit state
    final key = '${skillId}_${habitId}';
    habitStates.remove(key);

    // Clear SharedPreferences
    await _prefs.remove('habit_$key');

    await dbHelper.deleteHabit(habitId);
    _updateSkillHabits(
      skillId,
      (habits) => habits.where((h) => h.id != habitId).toList(),
    );

    // Update preview after habit deletion
    _updateSkillScorePreview(skillId);
  }

  /// Utility methods for bulk expansion control
  void expandAllSkills() {
    final skillIds = skillWithHabitsList
        .where((s) => s.skill.level < 10) // Only non-maxed skills
        .map((s) => s.skill.id!)
        .toList();
    skillCardController.expandAll(skillIds);
  }

  void collapseAllSkills() {
    skillCardController.collapseAll();
  }

  /// ===== Private helpers =====

  void _replaceSkill(Skill skill) {
    final index = skillWithHabitsList.indexWhere((s) => s.skill.id == skill.id);
    if (index != -1) {
      skillWithHabitsList[index] = SkillWithHabits(
        skill: skill,
        habits: skillWithHabitsList[index].habits,
      );
    }
  }

  void _updateSkillHabits(
    int skillId,
    List<Habit> Function(List<Habit>) updateFn,
  ) {
    final index = skillWithHabitsList.indexWhere((s) => s.skill.id == skillId);
    if (index != -1) {
      final current = skillWithHabitsList[index];
      final updatedHabits = updateFn(current.habits);
      skillWithHabitsList[index] = SkillWithHabits(
        skill: current.skill,
        habits: updatedHabits,
      );
    }
  }

  void _initAnimation(int skillId) {
    final controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..forward();
    final fade = CurvedAnimation(parent: controller, curve: _animationCurve);
    _animationControllers[skillId] = controller;
    _fadeAnimations[skillId] = fade;
  }

  Animation<double>? getAnimationForSkill(int skillId) =>
      _fadeAnimations[skillId];
}
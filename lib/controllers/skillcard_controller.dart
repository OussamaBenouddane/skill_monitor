import 'package:get/get.dart';

class SkillCardController extends GetxController {
  // Track expanded state for each skill card by skill ID
  final RxMap<int, bool> _expandedStates = <int, bool>{}.obs;
  
  /// Check if a skill card is expanded
  bool isExpanded(int skillId) {
    return _expandedStates[skillId] ?? false;
  }
  
  /// Toggle expansion state for a specific skill card
  void toggleExpansion(int skillId) {
    final currentState = _expandedStates[skillId] ?? false;
    _expandedStates[skillId] = !currentState;
  }
  
  /// Set expansion state for a specific skill card
  void setExpansion(int skillId, bool isExpanded) {
    _expandedStates[skillId] = isExpanded;
  }
  
  /// Collapse all skill cards
  void collapseAll() {
    final skillIds = List<int>.from(_expandedStates.keys);
    for (final skillId in skillIds) {
      _expandedStates[skillId] = false;
    }
  }
  
  /// Expand all skill cards
  void expandAll(List<int> skillIds) {
    for (final skillId in skillIds) {
      _expandedStates[skillId] = true;
    }
  }
  
  /// Remove expansion state for a deleted skill
  void removeSkill(int skillId) {
    _expandedStates.remove(skillId);
  }
  
  /// Clear all expansion states (useful for new day reset)
  void clearAll() {
    _expandedStates.clear();
  }
  
  /// Get all currently expanded skill IDs
  List<int> getExpandedSkillIds() {
    return _expandedStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get expansion states as a map (for debugging or persistence)
  Map<int, bool> getExpandedStates() {
    return Map<int, bool>.from(_expandedStates);
  }
}
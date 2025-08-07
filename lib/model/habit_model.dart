class Habit {
  final int? id;
  final int skillId;
  final String name;
  final int value;
  final String lastUpdated;

  Habit({
    this.id,
    required this.skillId,
    required this.name,
    required this.value,
    required this.lastUpdated, // Made required, no default
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      skillId: map['skill_id'],
      name: map['name'],
      value: map['value'],
      lastUpdated: map['last_updated'] ?? '', // Handle null from DB
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skill_id': skillId,
      'name': name,
      'value': value,
      'last_updated': lastUpdated,
    };
  }

  Habit copyWith({
    int? id,
    int? skillId,
    String? name,
    int? value,
    String? lastUpdated,
  }) {
    return Habit(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      name: name ?? this.name,
      value: value ?? this.value,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

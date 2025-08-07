class Skill {
  final int? id;
  final String skill;
  final int score;
  final int level;

  Skill({this.id, required this.skill, this.score = 0, this.level = 1});

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'],
      skill: map['skill'],
      score: map['score'],
      level: map['level'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'skill': skill, 'score': score, 'level': level};
  }

  Skill copyWith({int? id, String? skill, int? score, int? level}) {
    return Skill(
      id: id ?? this.id,
      skill: skill ?? this.skill,
      score: score ?? this.score,
      level: level ?? this.level,
    );
  }
}
